#!/bin/bash
# ==============================================================================
# TEN-Agent ECS Deployment Script
# ==============================================================================
# 简化 Terraform 部署流程的辅助脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用帮助
show_help() {
    cat << HELP
TEN-Agent ECS 部署脚本

用法: $0 <命令> [选项]

命令:
    init        初始化 Terraform
    plan        查看执行计划
    apply       部署基础设施
    destroy     销毁基础设施
    output      显示输出信息
    status      查看部署状态
    logs        查看服务日志
    secrets     更新 Secrets Manager 密钥
    restart     重启 ECS 服务

选项:
    -e, --environment <env>    环境名称 (dev/staging/prod)，默认: dev
    -r, --region <region>      AWS 区域，默认: us-east-1
    -y, --yes                  自动确认，跳过交互提示
    -h, --help                显示此帮助信息

示例:
    $0 init
    $0 plan -e dev
    $0 apply -e prod -y
    $0 logs -e dev agents
    $0 secrets -e dev

环境:
    AWS_PROFILE    使用特定的 AWS 配置文件
    TF_LOG         设置 Terraform 日志级别 (TRACE/DEBUG/INFO/WARN/ERROR)

HELP
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v terraform &> /dev/null; then
        missing_deps+=("terraform")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_deps+=("aws-cli")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少依赖: ${missing_deps[*]}"
        print_info "请先安装必要的工具"
        exit 1
    fi
}

# 解析命令行参数
ENVIRONMENT="dev"
REGION="us-east-1"
AUTO_APPROVE=""
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        init|plan|apply|destroy|output|status|logs|secrets|restart)
            COMMAND="$1"
            shift
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -y|--yes)
            AUTO_APPROVE="-auto-approve"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证环境参数
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "无效的环境: $ENVIRONMENT (必须是 dev, staging 或 prod)"
    exit 1
fi

# 设置变量文件
VAR_FILE="environments/${ENVIRONMENT}.tfvars"
if [ ! -f "$VAR_FILE" ]; then
    print_warning "环境配置文件不存在: $VAR_FILE"
    print_info "将使用默认配置"
    VAR_FILE=""
fi

# 执行命令
case $COMMAND in
    init)
        print_info "初始化 Terraform..."
        terraform init
        print_success "Terraform 初始化完成"
        ;;
        
    plan)
        print_info "生成执行计划 (环境: $ENVIRONMENT)..."
        if [ -n "$VAR_FILE" ]; then
            terraform plan -var-file="$VAR_FILE"
        else
            terraform plan
        fi
        ;;
        
    apply)
        print_info "部署基础设施 (环境: $ENVIRONMENT)..."
        if [ -z "$AUTO_APPROVE" ]; then
            print_warning "即将部署到 $ENVIRONMENT 环境"
            read -p "确认继续? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                print_info "已取消部署"
                exit 0
            fi
        fi
        
        if [ -n "$VAR_FILE" ]; then
            terraform apply -var-file="$VAR_FILE" $AUTO_APPROVE
        else
            terraform apply $AUTO_APPROVE
        fi
        print_success "部署完成！"
        print_info "运行 '$0 output' 查看部署信息"
        ;;
        
    destroy)
        print_warning "准备销毁 $ENVIRONMENT 环境的所有资源"
        if [ -z "$AUTO_APPROVE" ]; then
            read -p "确认销毁所有资源? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                print_info "已取消销毁操作"
                exit 0
            fi
        fi
        
        if [ -n "$VAR_FILE" ]; then
            terraform destroy -var-file="$VAR_FILE" $AUTO_APPROVE
        else
            terraform destroy $AUTO_APPROVE
        fi
        print_success "资源已销毁"
        ;;
        
    output)
        print_info "获取部署信息..."
        terraform output
        ;;
        
    status)
        print_info "检查 ECS 服务状态 (环境: $ENVIRONMENT)..."
        CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null)
        
        if [ -z "$CLUSTER_NAME" ]; then
            print_error "无法获取集群名称，请确保已部署基础设施"
            exit 1
        fi
        
        print_info "ECS 集群: $CLUSTER_NAME"
        aws ecs list-services --cluster "$CLUSTER_NAME" --region "$REGION" \
            --query 'serviceArns[*]' --output text | tr '\t' '\n' | while read service_arn; do
            service_name=$(basename "$service_arn")
            print_info "服务: $service_name"
            aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$service_name" --region "$REGION" \
                --query 'services[0].[runningCount, desiredCount, status]' --output text
        done
        ;;
        
    logs)
        SERVICE="${2:-agents}"
        print_info "查看 $SERVICE 服务日志 (环境: $ENVIRONMENT)..."
        LOG_GROUP="/ecs/ten-agent-${ENVIRONMENT}/${SERVICE}"
        aws logs tail "$LOG_GROUP" --follow --region "$REGION"
        ;;
        
    secrets)
        print_info "更新 Secrets Manager 密钥 (环境: $ENVIRONMENT)..."
        print_warning "此功能需要你提供实际的密钥值"
        
        # 检查 .env 文件
        if [ -f ".env" ]; then
            print_info "从 .env 文件读取配置..."
            source .env
            
            PROJECT="ten-agent"
            
            # 更新每个密钥
            for secret in "agora-app-id" "agora-app-certificate" "aws-access-key-id" \
                         "aws-secret-access-key" "azure-stt-key" "azure-tts-key" \
                         "cosy-tts-key" "elevenlabs-tts-key" "openai-api-key" "qwen-api-key"; do
                
                secret_id="${PROJECT}-${ENVIRONMENT}/${secret}"
                var_name=$(echo "$secret" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
                var_value="${!var_name}"
                
                if [ -n "$var_value" ]; then
                    print_info "更新密钥: $secret_id"
                    aws secretsmanager put-secret-value \
                        --secret-id "$secret_id" \
                        --secret-string "$var_value" \
                        --region "$REGION" || print_warning "跳过: $secret_id"
                fi
            done
            
            print_success "密钥更新完成"
            print_info "运行 '$0 restart' 重启服务以应用新配置"
        else
            print_error ".env 文件不存在"
            print_info "请创建 .env 文件并设置所需的环境变量"
            exit 1
        fi
        ;;
        
    restart)
        print_info "重启 ECS 服务 (环境: $ENVIRONMENT)..."
        CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null)
        
        if [ -z "$CLUSTER_NAME" ]; then
            print_error "无法获取集群名称"
            exit 1
        fi
        
        # 获取所有服务并重启
        services=$(aws ecs list-services --cluster "$CLUSTER_NAME" --region "$REGION" \
            --query 'serviceArns[*]' --output text)
        
        for service_arn in $services; do
            service_name=$(basename "$service_arn")
            print_info "重启服务: $service_name"
            aws ecs update-service \
                --cluster "$CLUSTER_NAME" \
                --service "$service_name" \
                --force-new-deployment \
                --region "$REGION" > /dev/null
        done
        
        print_success "所有服务已触发重启"
        print_info "等待服务稳定..."
        aws ecs wait services-stable --cluster "$CLUSTER_NAME" --services $services --region "$REGION"
        print_success "服务重启完成"
        ;;
        
    "")
        print_error "请指定命令"
        show_help
        exit 1
        ;;
        
    *)
        print_error "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
