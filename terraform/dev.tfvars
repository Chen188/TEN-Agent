# ===================================================
# TEN-Agent Terraform Configuration - Development Environment
# ===================================================

# ----- General Configuration -----
project_name = "ten-agent"
environment  = "dev"
aws_region   = "us-west-2"

# ----- Networking Configuration -----
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-west-2a", "us-west-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# ----- ECS Configuration - Development (Lower resources) -----
enable_container_insights = true

# astra_agents service
astra_agents_cpu           = 1024 # Lower for dev
astra_agents_memory        = 2048 # Lower for dev
astra_agents_desired_count = 1

# astra_playground service
astra_playground_cpu           = 512
astra_playground_memory        = 1024
astra_playground_desired_count = 1

# nova_sonic service
nova_sonic_cpu           = 512  # Lower for dev
nova_sonic_memory        = 1024 # Lower for dev
nova_sonic_desired_count = 1

# graph_designer service
graph_designer_cpu           = 512
graph_designer_memory        = 1024
graph_designer_desired_count = 1

# ----- Container Images -----
astra_agents_image     = "ghcr.io/ten-framework/astra_agents_build:0.3.5"
astra_playground_image = "node:20-alpine"
nova_sonic_image       = "ghcr.io/chen188/nova-sonic-server:latest"
graph_designer_image   = "agoraio/astra_graph_designer:0.1.0"

# ----- Port Configuration -----
graph_designer_server_port = 8001
server_port                = 8080
playground_port            = 3000
nova_sonic_port            = 3333
graph_designer_ui_port     = 3001

# ----- Load Balancer Configuration -----
enable_alb                       = true
alb_ingress_cidr_blocks          = ["0.0.0.0/0"] # Restrict this in production
health_check_path                = "/"
health_check_interval            = 30
health_check_timeout             = 5
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 3

# ----- CloudWatch Logs - Development (Shorter retention) -----
log_retention_days = 3 # Shorter retention for dev
log_path           = "/var/log/ten-agent"

# ----- Auto Scaling - Disabled for Development -----
enable_autoscaling        = false
autoscaling_min_capacity  = 1
autoscaling_max_capacity  = 2 # Lower max for dev
autoscaling_cpu_target    = 75
autoscaling_memory_target = 75

# ----- Tags -----
tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Application = "TEN-Agent"
  Environment = "Development"
}

# ----- Secrets Configuration -----
# NOTE: Sensitive values should be provided via environment variables:
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
