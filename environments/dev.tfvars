# ==============================================================================
# Development Environment Configuration
# ==============================================================================

# 基础配置
project_name = "ten-agent"
environment  = "dev"
aws_region   = "us-east-1"
owner_tag    = "Development Team"

# 网络配置 - 开发环境使用单个 NAT Gateway 节省成本
vpc_cidr               = "10.0.0.0/16"
availability_zones_count = 2
enable_nat_gateway     = true
single_nat_gateway     = true  # 成本优化

# ECS 配置 - 较小的资源配置
ecs_task_cpu = {
  agents     = "512"   # 0.5 vCPU
  playground = "512"
  nova_sonic = "512"
}

ecs_task_memory = {
  agents     = "1024"  # 1 GB
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
  agents     = 2
  playground = 2
  nova_sonic = 2
}

# 日志和监控
log_retention_days       = 3
enable_container_insights = false  # 开发环境可禁用以节省成本
enable_ecs_exec          = true    # 启用容器调试

# ALB 配置
enable_deletion_protection = false
enable_alb_access_logs    = false
alb_idle_timeout          = 60

# 自动扩展
enable_autoscaling        = true
autoscaling_cpu_target    = 75
autoscaling_memory_target = 85

# 域名配置（可选）
enable_custom_domain = false
# domain_name          = "dev.ten-agent.example.com"
# subdomain_agents     = "api"
# subdomain_playground = "app"
# subdomain_nova_sonic = "sonic"

# 安全配置
enable_kms_encryption = false
secret_recovery_window_days = 0  # 立即删除，方便测试

# 应用配置
workers_max = 50
worker_quit_timeout_seconds = 30
