# ==============================================================================
# TEN-Agent ECS Deployment - Variables
# ==============================================================================
# This file defines all configurable variables for the infrastructure

# ==============================================================================
# General Configuration
# ==============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ten-agent"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "owner_tag" {
  description = "Owner tag for resources"
  type        = string
  default     = "DevOps Team"
}

# ==============================================================================
# Networking Configuration
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost optimization)"
  type        = bool
  default     = true
}

# ==============================================================================
# ECS Configuration
# ==============================================================================

variable "ecs_task_cpu" {
  description = "CPU units for ECS tasks by service"
  type = map(string)
  default = {
    agents     = "1024"  # 1 vCPU
    playground = "512"   # 0.5 vCPU
    nova_sonic = "512"   # 0.5 vCPU
  }
}

variable "ecs_task_memory" {
  description = "Memory (MB) for ECS tasks by service"
  type = map(string)
  default = {
    agents     = "2048"  # 2 GB
    playground = "1024"  # 1 GB
    nova_sonic = "1024"  # 1 GB
  }
}

variable "ecs_service_desired_count" {
  description = "Desired number of tasks per service"
  type = map(number)
  default = {
    agents     = 1
    playground = 1
    nova_sonic = 1
  }
}

variable "ecs_service_min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type = map(number)
  default = {
    agents     = 1
    playground = 1
    nova_sonic = 1
  }
}

variable "ecs_service_max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type = map(number)
  default = {
    agents     = 4
    playground = 2
    nova_sonic = 2
  }
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ==============================================================================
# Application Load Balancer Configuration
# ==============================================================================

variable "enable_alb_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (required if enable_alb_access_logs is true)"
  type        = string
  default     = ""
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path for target groups"
  type = map(string)
  default = {
    agents     = "/health"
    playground = "/"
    nova_sonic = "/health"
  }
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

variable "healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
}

# ==============================================================================
# Domain and SSL Configuration
# ==============================================================================

variable "enable_custom_domain" {
  description = "Enable custom domain with Route53 and ACM"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for the application (e.g., example.com)"
  type        = string
  default     = ""
}

variable "subdomain_agents" {
  description = "Subdomain for agents service (e.g., api)"
  type        = string
  default     = "api"
}

variable "subdomain_playground" {
  description = "Subdomain for playground service (e.g., app)"
  type        = string
  default     = "app"
}

variable "subdomain_nova_sonic" {
  description = "Subdomain for nova sonic service (e.g., sonic)"
  type        = string
  default     = "sonic"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (leave empty to create new zone)"
  type        = string
  default     = ""
}

variable "certificate_validation_method" {
  description = "Certificate validation method (DNS or EMAIL)"
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.certificate_validation_method)
    error_message = "Certificate validation method must be DNS or EMAIL"
  }
}

# ==============================================================================
# Application Configuration
# ==============================================================================

variable "log_path" {
  description = "Log path for application"
  type        = string
  default     = "/tmp"
}

variable "graph_designer_server_port" {
  description = "Graph designer server port"
  type        = number
  default     = 49483
}

variable "server_port" {
  description = "Server port"
  type        = number
  default     = 8080
}

variable "workers_max" {
  description = "Maximum number of workers"
  type        = number
  default     = 100
}

variable "worker_quit_timeout_seconds" {
  description = "Worker quit timeout in seconds"
  type        = number
  default     = 60
}

# ==============================================================================
# AWS Service Configuration
# ==============================================================================

variable "aws_bedrock_model" {
  description = "AWS Bedrock model name"
  type        = string
  default     = "anthropic.claude-v2"
}

variable "litellm_model" {
  description = "LiteLLM model name"
  type        = string
  default     = "gpt-4o-mini"
}

variable "openai_base_url" {
  description = "OpenAI base URL (leave empty for default)"
  type        = string
  default     = ""
}

variable "openai_model" {
  description = "OpenAI model name"
  type        = string
  default     = "gpt-4o-mini"
}

variable "openai_proxy_url" {
  description = "OpenAI proxy URL (leave empty for no proxy)"
  type        = string
  default     = ""
}

# ==============================================================================
# Service Images Configuration
# ==============================================================================

variable "agents_image" {
  description = "Docker image for agents service"
  type        = string
  default     = "ghcr.io/ten-framework/astra_agents_build:0.3.5"
}

variable "playground_image" {
  description = "Docker image for playground service"
  type        = string
  default     = "node:20-alpine"
}

variable "nova_sonic_image" {
  description = "Docker image for nova sonic service"
  type        = string
  default     = "ghcr.io/chen188/nova-sonic-server:latest"
}

# ==============================================================================
# Secrets Configuration
# ==============================================================================
# Note: Actual secret values should be set after infrastructure creation
# Use AWS Secrets Manager console or CLI to update secret values

variable "create_secrets" {
  description = "Create AWS Secrets Manager secrets (set to false if secrets already exist)"
  type        = bool
  default     = true
}

variable "secret_recovery_window_days" {
  description = "Recovery window for deleted secrets (0 for immediate deletion)"
  type        = number
  default     = 7
}

# ==============================================================================
# Auto Scaling Configuration
# ==============================================================================

variable "enable_autoscaling" {
  description = "Enable auto-scaling for ECS services"
  type        = bool
  default     = true
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "scale_in_cooldown" {
  description = "Cooldown period (seconds) after scale in"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period (seconds) after scale out"
  type        = number
  default     = 60
}

# ==============================================================================
# Security Configuration
# ==============================================================================

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for ECS cluster"
  type        = bool
  default     = true
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for logs and secrets"
  type        = bool
  default     = false
}

# ==============================================================================
# Environment-Specific Overrides
# ==============================================================================
# These variables automatically adjust based on environment

variable "environment_config" {
  description = "Environment-specific configuration overrides"
  type = map(object({
    ecs_task_cpu_agents      = string
    ecs_task_memory_agents   = string
    desired_count_agents     = number
    enable_deletion_protection = bool
    log_retention_days       = number
  }))
  default = {
    dev = {
      ecs_task_cpu_agents      = "512"
      ecs_task_memory_agents   = "1024"
      desired_count_agents     = 1
      enable_deletion_protection = false
      log_retention_days       = 3
    }
    staging = {
      ecs_task_cpu_agents      = "1024"
      ecs_task_memory_agents   = "2048"
      desired_count_agents     = 1
      enable_deletion_protection = false
      log_retention_days       = 7
    }
    prod = {
      ecs_task_cpu_agents      = "2048"
      ecs_task_memory_agents   = "4096"
      desired_count_agents     = 2
      enable_deletion_protection = true
      log_retention_days       = 30
    }
  }
}
