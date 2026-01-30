#!/bin/bash
# ==============================================================================
# TEN-Agent 部署验证脚本
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

ENVIRONMENT="${1:-dev}"
REGION="${2:-us-east-1}"

echo "======================================"
echo "TEN-Agent 部署验证"
echo "环境: $ENVIRONMENT"
echo "区域: $REGION"
echo "======================================"
echo ""

# 1. 检查 Terraform 状态
print_info "检查 Terraform 状态..."
if terraform show &> /dev/null; then
    print_success "Terraform 状态正常"
else
    print_error "Terraform 状态异常"
    exit 1
fi

# 2. 获取集群信息
print_info "获取 ECS 集群信息..."
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null)
if [ -z "$CLUSTER_NAME" ]; then
    print_error "无法获取集群名称"
    exit 1
fi
print_success "集群: $CLUSTER_NAME"

# 3. 检查 ECS 服务状态
print_info "检查 ECS 服务状态..."
services=$(aws ecs list-services --cluster "$CLUSTER_NAME" --region "$REGION" \
    --query 'serviceArns[*]' --output text)

service_count=0
healthy_count=0

for service_arn in $services; do
    service_name=$(basename "$service_arn")
    service_count=$((service_count + 1))
    
    status=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$service_name" \
        --region "$REGION" --query 'services[0].[runningCount, desiredCount]' --output text)
    
    running=$(echo "$status" | awk '{print $1}')
    desired=$(echo "$status" | awk '{print $2}')
    
    if [ "$running" -eq "$desired" ] && [ "$running" -gt 0 ]; then
        print_success "服务 $service_name: $running/$desired 运行中"
        healthy_count=$((healthy_count + 1))
    else
        print_warning "服务 $service_name: $running/$desired (不正常)"
    fi
done

# 4. 检查 ALB 目标组健康状态
print_info "检查 ALB 目标组健康状态..."
target_groups=$(terraform output -json target_group_arns 2>/dev/null | jq -r '.[]')

for tg_arn in $target_groups; do
    tg_name=$(aws elbv2 describe-target-groups --target-group-arns "$tg_arn" \
        --region "$REGION" --query 'TargetGroups[0].TargetGroupName' --output text)
    
    health=$(aws elbv2 describe-target-health --target-group-arn "$tg_arn" \
        --region "$REGION" --query 'TargetHealthDescriptions[*].TargetHealth.State' --output text)
    
    healthy=$(echo "$health" | grep -c "healthy" || true)
    total=$(echo "$health" | wc -w)
    
    if [ "$total" -gt 0 ]; then
        if [ "$healthy" -eq "$total" ]; then
            print_success "目标组 $tg_name: $healthy/$total 健康"
        else
            print_warning "目标组 $tg_name: $healthy/$total 健康"
        fi
    else
        print_warning "目标组 $tg_name: 无目标"
    fi
done

# 5. 检查 Secrets Manager
print_info "检查 Secrets Manager 密钥..."
secrets=$(terraform output -json secrets_arns 2>/dev/null | jq -r '.[]')
secret_with_placeholder=0

for secret_arn in $secrets; do
    secret_value=$(aws secretsmanager get-secret-value --secret-id "$secret_arn" \
        --region "$REGION" --query 'SecretString' --output text 2>/dev/null || echo "")
    
    if echo "$secret_value" | grep -q "REPLACE_WITH_ACTUAL"; then
        secret_with_placeholder=$((secret_with_placeholder + 1))
    fi
done

if [ "$secret_with_placeholder" -gt 0 ]; then
    print_warning "发现 $secret_with_placeholder 个密钥仍使用占位符值"
    print_info "请运行: ./deploy.sh secrets -e $ENVIRONMENT"
else
    print_success "所有密钥已设置"
fi

# 6. 测试服务端点
print_info "测试服务端点..."
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null)

if [ -n "$ALB_DNS" ]; then
    # 测试 Agents API
    if curl -sf "http://${ALB_DNS}:8080/health" > /dev/null 2>&1; then
        print_success "Agents API 可访问"
    else
        print_warning "Agents API 不可访问 (可能正在启动中)"
    fi
    
    # 测试 Playground
    if curl -sf "http://${ALB_DNS}:3000" > /dev/null 2>&1; then
        print_success "Playground 可访问"
    else
        print_warning "Playground 不可访问 (可能正在启动中)"
    fi
    
    # 测试 Nova Sonic
    if curl -sf "http://${ALB_DNS}:3333/health" > /dev/null 2>&1; then
        print_success "Nova Sonic 可访问"
    else
        print_warning "Nova Sonic 不可访问 (可能正在启动中)"
    fi
fi

# 7. 检查 CloudWatch 日志
print_info "检查 CloudWatch 日志..."
log_groups=$(terraform output -json cloudwatch_log_groups 2>/dev/null | jq -r '.[]')

for log_group in $log_groups; do
    stream_count=$(aws logs describe-log-streams --log-group-name "$log_group" \
        --region "$REGION" --query 'logStreams[*]' --output text | wc -l)
    
    if [ "$stream_count" -gt 0 ]; then
        print_success "日志组 $log_group: $stream_count 个日志流"
    else
        print_warning "日志组 $log_group: 无日志流"
    fi
done

# 总结
echo ""
echo "======================================"
echo "验证总结"
echo "======================================"
echo "ECS 服务: $healthy_count/$service_count 正常"

if [ "$secret_with_placeholder" -gt 0 ]; then
    echo "Secrets: ⚠ 需要更新"
else
    echo "Secrets: ✓ 已配置"
fi

if [ "$healthy_count" -eq "$service_count" ] && [ "$secret_with_placeholder" -eq 0 ]; then
    print_success "部署验证通过！"
    echo ""
    echo "服务访问地址:"
    terraform output service_urls
    exit 0
else
    print_warning "部署验证部分通过，请检查上述警告"
    exit 1
fi
