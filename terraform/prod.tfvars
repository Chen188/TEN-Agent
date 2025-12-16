# ===================================================
# TEN-Agent Terraform Configuration - Production Environment
# ===================================================

# ----- General Configuration -----
project_name = "ten-agent"
environment  = "prod"
aws_region   = "us-west-2"

# ----- Networking Configuration -----
vpc_cidr             = "10.1.0.0/16"                              # Different CIDR for prod
availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"] # More AZs for prod
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]

# ----- ECS Configuration - Production (Higher resources) -----
enable_container_insights = true

# astra_agents service
astra_agents_cpu           = 4096 # Higher for prod
astra_agents_memory        = 8192 # Higher for prod
astra_agents_desired_count = 2    # Multiple instances for HA

# astra_playground service
astra_playground_cpu           = 1024 # Higher for prod
astra_playground_memory        = 2048 # Higher for prod
astra_playground_desired_count = 2    # Multiple instances for HA

# nova_sonic service
nova_sonic_cpu           = 2048 # Higher for prod
nova_sonic_memory        = 4096 # Higher for prod
nova_sonic_desired_count = 2    # Multiple instances for HA

# graph_designer service
graph_designer_cpu           = 1024
graph_designer_memory        = 2048
graph_designer_desired_count = 2 # Multiple instances for HA

# ----- Container Images -----
# In production, consider using specific version tags instead of 'latest'
astra_agents_image     = "ghcr.io/ten-framework/astra_agents_build:0.3.5"
astra_playground_image = "node:20-alpine"
nova_sonic_image       = "ghcr.io/chen188/nova-sonic-server:latest" # Consider specific version
graph_designer_image   = "agoraio/astra_graph_designer:0.1.0"

# ----- Port Configuration -----
graph_designer_server_port = 8001
server_port                = 8080
playground_port            = 3000
nova_sonic_port            = 3333
graph_designer_ui_port     = 3001

# ----- Load Balancer Configuration -----
enable_alb                       = true
alb_ingress_cidr_blocks          = ["0.0.0.0/0"] # Consider restricting to specific IPs/ranges
health_check_path                = "/"
health_check_interval            = 30
health_check_timeout             = 5
health_check_healthy_threshold   = 3 # More checks for prod
health_check_unhealthy_threshold = 2 # Faster detection for prod

# ----- CloudWatch Logs - Production (Longer retention) -----
log_retention_days = 30 # Longer retention for prod
log_path           = "/var/log/ten-agent"

# ----- Auto Scaling - Enabled for Production -----
enable_autoscaling        = true
autoscaling_min_capacity  = 2  # Always maintain at least 2 instances
autoscaling_max_capacity  = 10 # Allow scaling up to 10 instances
autoscaling_cpu_target    = 70 # Lower target for more headroom
autoscaling_memory_target = 70 # Lower target for more headroom

# ----- Tags -----
tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Application = "TEN-Agent"
  Environment = "Production"
  Compliance  = "Required"
  Backup      = "Daily"
}

# ----- Secrets Configuration -----
# NOTE: Sensitive values MUST be provided via environment variables in production:
# export TF_VAR_agora_app_id="your-value"
# export TF_VAR_agora_app_certificate="your-value"
# export TF_VAR_aws_access_key_id="your-value"
# export TF_VAR_aws_secret_access_key="your-value"
# export TF_VAR_azure_stt_key="your-value"
# export TF_VAR_azure_tts_key="your-value"
# export TF_VAR_cosy_tts_key="your-value"
# export TF_VAR_elevenlabs_tts_key="your-value"
# export TF_VAR_openai_api_key="your-value"
# export TF_VAR_qwen_api_key="your-value"
#
# For CI/CD, use your pipeline's secret management system
# For Terraform Cloud/Enterprise, use sensitive workspace variables
