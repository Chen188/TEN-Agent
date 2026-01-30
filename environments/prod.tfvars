# ==============================================================================
# Production Environment Configuration
# ==============================================================================

# 基础配置
project_name = "ten-agent"
environment  = "prod"
aws_region   = "us-east-1"
owner_tag    = "Production Team"

# 网络配置 - 生产环境高可用
vpc_cidr               = "10.2.0.0/16"
availability_zones_count = 3  # 使用 3 个可用区
enable_nat_gateway     = true
single_nat_gateway     = false  # 每个 AZ 一个 NAT Gateway

# ECS 配置 - 高性能资源配置
ecs_task_cpu = {
  agents     = "2048"  # 2 vCPU
  playground = "1024"
  nova_sonic = "1024"
}

ecs_task_memory = {
  agents     = "4096"  # 4 GB
  playground = "2048"
  nova_sonic = "2048"
}

ecs_service_desired_count = {
  agents     = 2  # 至少 2 个实例
  playground = 2
  nova_sonic = 1
}

ecs_service_min_capacity = {
  agents     = 2
  playground = 1
  nova_sonic = 1
}

ecs_service_max_capacity = {
  agents     = 10
  playground = 5
  nova_sonic = 3
}

# 日志和监控 - 生产环境完整监控
log_retention_days       = 30
enable_container_insights = true
enable_ecs_exec          = false  # 生产环境禁用直接访问

# ALB 配置 - 启用保护和日志
enable_deletion_protection = true
enable_alb_access_logs    = true
alb_access_logs_bucket    = "ten-agent-prod-alb-logs"  # 需要预先创建
alb_idle_timeout          = 120

# 健康检查配置
health_check_interval = 30
health_check_timeout  = 10
healthy_threshold     = 3
unhealthy_threshold   = 2

# 自动扩展
enable_autoscaling        = true
autoscaling_cpu_target    = 60
autoscaling_memory_target = 70
scale_in_cooldown         = 300
scale_out_cooldown        = 60

# 域名配置
enable_custom_domain         = true
domain_name                  = "ten-agent.example.com"
subdomain_agents             = "api"
subdomain_playground         = "app"
subdomain_nova_sonic         = "sonic"
certificate_validation_method = "DNS"

# 安全配置
enable_kms_encryption = true
secret_recovery_window_days = 30

# 访问控制（可选 - 限制特定 IP）
# allowed_cidr_blocks = [
#   "10.0.0.0/8",      # 内网
#   "203.0.113.0/24"   # 办公室 IP
# ]

# 应用配置
workers_max = 200
worker_quit_timeout_seconds = 60

# 应用服务配置
aws_bedrock_model  = "anthropic.claude-v2"
litellm_model      = "gpt-4o"
openai_model       = "gpt-4o"
