# ==============================================================================
# Staging Environment Configuration
# ==============================================================================

# 基础配置
project_name = "ten-agent"
environment  = "staging"
aws_region   = "us-east-1"
owner_tag    = "DevOps Team"

# 网络配置
vpc_cidr               = "10.1.0.0/16"
availability_zones_count = 2
enable_nat_gateway     = true
single_nat_gateway     = false  # 每个 AZ 一个 NAT Gateway

# ECS 配置 - 中等资源配置
ecs_task_cpu = {
  agents     = "1024"  # 1 vCPU
  playground = "512"
  nova_sonic = "512"
}

ecs_task_memory = {
  agents     = "2048"  # 2 GB
  playground = "1024"
  nova_sonic = "1024"
}

ecs_service_desired_count = {
  agents     = 1
  playground = 1
  nova_sonic = 1
}

ecs_service_min_capacity = {
  agents     = 1
  playground = 1
  nova_sonic = 1
}

ecs_service_max_capacity = {
  agents     = 4
  playground = 2
  nova_sonic = 2
}

# 日志和监控
log_retention_days       = 7
enable_container_insights = true
enable_ecs_exec          = true

# ALB 配置
enable_deletion_protection = false
enable_alb_access_logs    = false
alb_idle_timeout          = 60

# 自动扩展
enable_autoscaling        = true
autoscaling_cpu_target    = 70
autoscaling_memory_target = 80

# 域名配置
enable_custom_domain = true
domain_name          = "staging.ten-agent.example.com"
subdomain_agents     = "api"
subdomain_playground = "app"
subdomain_nova_sonic = "sonic"

# 安全配置
enable_kms_encryption = false
secret_recovery_window_days = 7

# 应用配置
workers_max = 100
worker_quit_timeout_seconds = 60
