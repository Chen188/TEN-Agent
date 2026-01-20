#!/bin/bash

# ===================================================
# TEN-Agent Terraform Deployment Script
# ===================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
}

check_prerequisites() {
    print_header "检查先决条件"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform 未安装"
        exit 1
    fi
    print_success "Terraform 已安装: $(terraform version | head -n1)"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI 未安装"
        exit 1
    fi
    print_success "AWS CLI 已安装: $(aws --version)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS 凭证未配置或无效"
        exit 1
    fi
    print_success "AWS 凭证有效"
    
    # Check environment file
    if [ ! -f "$SCRIPT_DIR/.env.sh" ]; then
        print_warning ".env.sh 文件不存在"
        print_info "请创建 .env.sh 文件并设置所有必需的环境变量"
        print_info "参考 terraform.tfvars.example 文件"
    else
        print_success ".env.sh 文件存在"
    fi
}

load_environment() {
    if [ -f "$SCRIPT_DIR/.env.sh" ]; then
        print_info "加载环境变量..."
        source "$SCRIPT_DIR/.env.sh"
        print_success "环境变量已加载"
    fi
}

show_usage() {
    cat << EOF
使用方法: $0 [命令] [环境]

命令:
    init        初始化 Terraform
    plan        显示部署计划
    apply       应用配置并部署
    destroy     销毁所有资源
    output      显示输出值
    status      显示服务状态
    logs        查看服务日志
    scale       扩展服务
    update      强制更新服务
    help        显示此帮助信息

环境:
    dev         开发环境（默认）
    prod        生产环境

示例:
    $0 init
    $0 plan dev
    $0 apply prod
    $0 status dev
    $0 logs dev astra-agents
    $0 scale dev astra-agents 3

EOF
}

terraform_init() {
    print_header "初始化 Terraform"
    cd "$SCRIPT_DIR"
    terraform init
    print_success "Terraform 初始化完成"
}

terraform_plan() {
    local env=${1:-dev}
    print_header "创建 Terraform 计划 (环境: $env)"
    cd "$SCRIPT_DIR"
    
    if [ ! -f "${env}.tfvars" ]; then
        print_error "配置文件 ${env}.tfvars 不存在"
        exit 1
    fi
    
    terraform plan -var-file="${env}.tfvars" -out="${env}.tfplan"
    print_success "计划已创建: ${env}.tfplan"
}

terraform_apply() {
    local env=${1:-dev}
    print_header "应用 Terraform 配置 (环境: $env)"
    cd "$SCRIPT_DIR"
    
    if [ ! -f "${env}.tfplan" ]; then
        print_warning "计划文件 ${env}.tfplan 不存在，创建新计划..."
        terraform_plan "$env"
    fi
    
    print_warning "即将部署到 $env 环境"
    read -p "确认继续？(yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "部署已取消"
        exit 0
    fi
    
    terraform apply "${env}.tfplan"
    rm -f "${env}.tfplan"
    print_success "部署完成"
    
    print_info "获取输出信息..."
    terraform output
}

terraform_destroy() {
    local env=${1:-dev}
    print_header "销毁 Terraform 资源 (环境: $env)"
    cd "$SCRIPT_DIR"
    
    if [ ! -f "${env}.tfvars" ]; then
        print_error "配置文件 ${env}.tfvars 不存在"
        exit 1
    fi
    
    print_warning "即将销毁 $env 环境的所有资源"
    print_warning "此操作不可逆！"
    read -p "确认继续？输入环境名称 '$env' 以确认: " confirm
    if [ "$confirm" != "$env" ]; then
        print_info "销毁已取消"
        exit 0
    fi
    
    terraform destroy -var-file="${env}.tfvars"
    print_success "资源已销毁"
}

show_output() {
    print_header "Terraform 输出"
    cd "$SCRIPT_DIR"
    terraform output
}

show_status() {
    local env=${1:-dev}
    print_header "服务状态 (环境: $env)"
    cd "$SCRIPT_DIR"
    
    # Get cluster name
    cluster_name=$(terraform output -raw ecs_cluster_name 2>/dev/null)
    if [ -z "$cluster_name" ]; then
        print_error "无法获取集群名称。请确保已部署。"
        exit 1
    fi
    
    print_info "ECS 集群: $cluster_name"
    
    # List services
    print_info "服务列表:"
    aws ecs list-services --cluster "$cluster_name" --output table
    
    # Show service details
    print_info "服务详情:"
    service_names=(
        $(terraform output -raw astra_agents_service_name 2>/dev/null)
        $(terraform output -raw astra_playground_service_name 2>/dev/null)
        $(terraform output -raw nova_sonic_service_name 2>/dev/null)
        $(terraform output -raw graph_designer_service_name 2>/dev/null)
    )
    
    for service in "${service_names[@]}"; do
        if [ -n "$service" ]; then
            echo ""
            print_info "服务: $service"
            aws ecs describe-services \
                --cluster "$cluster_name" \
                --services "$service" \
                --query 'services[0].{name:serviceName,status:status,desired:desiredCount,running:runningCount,pending:pendingCount}' \
                --output table
        fi
    done
    
    # Show ALB URL
    alb_dns=$(terraform output -raw alb_dns_name 2>/dev/null)
    if [ -n "$alb_dns" ]; then
        echo ""
        print_success "负载均衡器 URL: http://$alb_dns"
    fi
}

show_logs() {
    local env=${1:-dev}
    local service=${2:-astra-agents}
    print_header "查看日志 (环境: $env, 服务: $service)"
    cd "$SCRIPT_DIR"
    
    # Map service name to log group
    case $service in
        astra-agents)
            log_group=$(terraform output -raw astra_agents_log_group 2>/dev/null)
            ;;
        astra-playground|playground)
            log_group=$(terraform output -raw astra_playground_log_group 2>/dev/null)
            ;;
        nova-sonic)
            log_group=$(terraform output -raw nova_sonic_log_group 2>/dev/null)
            ;;
        graph-designer)
            log_group=$(terraform output -raw graph_designer_log_group 2>/dev/null)
            ;;
        *)
            print_error "未知服务: $service"
            print_info "可用服务: astra-agents, astra-playground, nova-sonic, graph-designer"
            exit 1
            ;;
    esac
    
    if [ -z "$log_group" ]; then
        print_error "无法获取日志组名称"
        exit 1
    fi
    
    print_info "日志组: $log_group"
    print_info "按 Ctrl+C 退出"
    aws logs tail "$log_group" --follow
}

scale_service() {
    local env=${1:-dev}
    local service=${2:-astra-agents}
    local count=${3:-1}
    print_header "扩展服务 (环境: $env, 服务: $service, 数量: $count)"
    cd "$SCRIPT_DIR"
    
    cluster_name=$(terraform output -raw ecs_cluster_name 2>/dev/null)
    if [ -z "$cluster_name" ]; then
        print_error "无法获取集群名称"
        exit 1
    fi
    
    # Map service name
    case $service in
        astra-agents)
            service_name=$(terraform output -raw astra_agents_service_name 2>/dev/null)
            ;;
        astra-playground|playground)
            service_name=$(terraform output -raw astra_playground_service_name 2>/dev/null)
            ;;
        nova-sonic)
            service_name=$(terraform output -raw nova_sonic_service_name 2>/dev/null)
            ;;
        graph-designer)
            service_name=$(terraform output -raw graph_designer_service_name 2>/dev/null)
            ;;
        *)
            print_error "未知服务: $service"
            exit 1
            ;;
    esac
    
    print_info "扩展服务 $service_name 到 $count 个实例..."
    aws ecs update-service \
        --cluster "$cluster_name" \
        --service "$service_name" \
        --desired-count "$count"
    
    print_success "服务已扩展"
}

update_service() {
    local env=${1:-dev}
    local service=${2:-astra-agents}
    print_header "强制更新服务 (环境: $env, 服务: $service)"
    cd "$SCRIPT_DIR"
    
    cluster_name=$(terraform output -raw ecs_cluster_name 2>/dev/null)
    if [ -z "$cluster_name" ]; then
        print_error "无法获取集群名称"
        exit 1
    fi
    
    # Map service name
    case $service in
        astra-agents)
            service_name=$(terraform output -raw astra_agents_service_name 2>/dev/null)
            ;;
        astra-playground|playground)
            service_name=$(terraform output -raw astra_playground_service_name 2>/dev/null)
            ;;
        nova-sonic)
            service_name=$(terraform output -raw nova_sonic_service_name 2>/dev/null)
            ;;
        graph-designer)
            service_name=$(terraform output -raw graph_designer_service_name 2>/dev/null)
            ;;
        all)
            print_info "更新所有服务..."
            for svc in astra-agents astra-playground nova-sonic graph-designer; do
                update_service "$env" "$svc"
            done
            return
            ;;
        *)
            print_error "未知服务: $service"
            exit 1
            ;;
    esac
    
    print_info "强制更新服务 $service_name..."
    aws ecs update-service \
        --cluster "$cluster_name" \
        --service "$service_name" \
        --force-new-deployment
    
    print_success "服务更新已启动"
}

# Main script
main() {
    local command=${1:-help}
    local env=${2:-dev}
    
    case $command in
        init)
            check_prerequisites
            terraform_init
            ;;
        plan)
            check_prerequisites
            load_environment
            terraform_plan "$env"
            ;;
        apply)
            check_prerequisites
            load_environment
            terraform_apply "$env"
            ;;
        destroy)
            check_prerequisites
            load_environment
            terraform_destroy "$env"
            ;;
        output)
            show_output
            ;;
        status)
            show_status "$env"
            ;;
        logs)
            local service=${3:-astra-agents}
            show_logs "$env" "$service"
            ;;
        scale)
            local service=${3:-astra-agents}
            local count=${4:-1}
            scale_service "$env" "$service" "$count"
            ;;
        update)
            local service=${3:-all}
            update_service "$env" "$service"
            ;;
        help|*)
            show_usage
            ;;
    esac
}

# Run main
main "$@"
