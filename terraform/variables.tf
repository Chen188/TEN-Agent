# ===================================================
# TEN-Agent Terraform Configuration - Variables
# ===================================================

# ----- General Variables -----
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ten-agent"
}

variable "environment" {
  description = "Environment name (dev, prod, staging)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ----- Networking Variables -----
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# ----- ECS Variables -----
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for ECS cluster"
  type        = bool
  default     = true
}

variable "astra_agents_cpu" {
  description = "CPU units for astra_agents service (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}

variable "astra_agents_memory" {
  description = "Memory for astra_agents service in MB"
  type        = number
  default     = 4096
}

variable "astra_agents_desired_count" {
  description = "Desired number of astra_agents tasks"
  type        = number
  default     = 1
}

variable "astra_playground_cpu" {
  description = "CPU units for astra_playground service"
  type        = number
  default     = 512
}

variable "astra_playground_memory" {
  description = "Memory for astra_playground service in MB"
  type        = number
  default     = 1024
}

variable "astra_playground_desired_count" {
  description = "Desired number of astra_playground tasks"
  type        = number
  default     = 1
}

variable "nova_sonic_cpu" {
  description = "CPU units for nova_sonic_server service"
  type        = number
  default     = 1024
}

variable "nova_sonic_memory" {
  description = "Memory for nova_sonic_server service in MB"
  type        = number
  default     = 2048
}

variable "nova_sonic_desired_count" {
  description = "Desired number of nova_sonic_server tasks"
  type        = number
  default     = 1
}

variable "graph_designer_cpu" {
  description = "CPU units for graph_designer service"
  type        = number
  default     = 512
}

variable "graph_designer_memory" {
  description = "Memory for graph_designer service in MB"
  type        = number
  default     = 1024
}

variable "graph_designer_desired_count" {
  description = "Desired number of graph_designer tasks"
  type        = number
  default     = 1
}

# ----- Container Images -----
variable "astra_agents_image" {
  description = "Docker image for astra_agents service"
  type        = string
  default     = "ghcr.io/ten-framework/astra_agents_build:0.3.5"
}

variable "astra_playground_image" {
  description = "Docker image for astra_playground service"
  type        = string
  default     = "node:20-alpine"
}

variable "nova_sonic_image" {
  description = "Docker image for nova_sonic_server service"
  type        = string
  default     = "ghcr.io/chen188/nova-sonic-server:latest"
}

variable "graph_designer_image" {
  description = "Docker image for graph_designer service"
  type        = string
  default     = "agoraio/astra_graph_designer:0.1.0"
}

# ----- Port Configuration -----
variable "graph_designer_server_port" {
  description = "Port for graph designer server"
  type        = number
  default     = 8001
}

variable "server_port" {
  description = "Main server port for astra_agents"
  type        = number
  default     = 8080
}

variable "playground_port" {
  description = "Port for playground service"
  type        = number
  default     = 3000
}

variable "nova_sonic_port" {
  description = "Port for nova sonic server"
  type        = number
  default     = 3333
}

variable "graph_designer_ui_port" {
  description = "Port for graph designer UI"
  type        = number
  default     = 3001
}

# ----- Secrets Configuration -----
# Note: Actual secret values should be provided via environment-specific tfvars
variable "agora_app_id" {
  description = "Agora App ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "agora_app_certificate" {
  description = "Agora App Certificate"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for application"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for application"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_bedrock_model" {
  description = "AWS Bedrock Model name"
  type        = string
  default     = ""
}

variable "azure_stt_key" {
  description = "Azure Speech-to-Text API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_stt_region" {
  description = "Azure Speech-to-Text Region"
  type        = string
  default     = ""
}

variable "azure_tts_key" {
  description = "Azure Text-to-Speech API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_tts_region" {
  description = "Azure Text-to-Speech Region"
  type        = string
  default     = ""
}

variable "cosy_tts_key" {
  description = "Cosy TTS API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "elevenlabs_tts_key" {
  description = "ElevenLabs TTS API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "litellm_model" {
  description = "LiteLLM Model name"
  type        = string
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_base_url" {
  description = "OpenAI Base URL"
  type        = string
  default     = ""
}

variable "openai_model" {
  description = "OpenAI Model name"
  type        = string
  default     = "gpt-4"
}

variable "openai_proxy_url" {
  description = "OpenAI Proxy URL"
  type        = string
  default     = ""
}

variable "qwen_api_key" {
  description = "Qwen API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "log_path" {
  description = "Path for application logs"
  type        = string
  default     = "/var/log/ten-agent"
}

# ----- Load Balancer Configuration -----
variable "enable_alb" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = true
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "Health check path for services"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 3
}

# ----- CloudWatch Logs -----
variable "log_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 7
}

# ----- Auto Scaling -----
variable "enable_autoscaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 75
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 75
}
