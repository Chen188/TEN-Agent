# ECS Module Variables
# Defines input variables for the ECS module
# Requirements: 6.1, 6.2, 6.5, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC identifier for ECS resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

#------------------------------------------------------------------------------
# Load Balancer Configuration
#------------------------------------------------------------------------------

variable "alb_security_group_id" {
  description = "ALB security group ID for ingress rules"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "Frontend ALB target group ARN"
  type        = string
}

variable "backend_target_group_arn" {
  description = "Backend ALB target group ARN"
  type        = string
}

#------------------------------------------------------------------------------
# Container Configuration
#------------------------------------------------------------------------------

variable "ecr_repository_urls" {
  description = "Map of service name to ECR repository URL"
  type        = map(string)
  # Expected keys: backend, frontend, nova_sonic
}

variable "secret_arns" {
  description = "Map of secret name to ARN for ECS task definitions"
  type        = map(string)
  # Expected keys: agora, aws_credentials, tts, cognito
}

variable "environment_variables" {
  description = "Non-sensitive environment variables for ECS tasks"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Task Sizing Configuration
#------------------------------------------------------------------------------

variable "task_cpu" {
  description = "Default CPU units for ECS tasks (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Default memory in MB for ECS tasks"
  type        = number
  default     = 512

  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MB."
  }
}

#------------------------------------------------------------------------------
# Backend Task Configuration
# Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
#------------------------------------------------------------------------------

variable "backend_cpu" {
  description = "CPU units for backend task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.backend_cpu)
    error_message = "Backend CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "backend_memory" {
  description = "Memory in MB for backend task"
  type        = number
  default     = 512

  validation {
    condition     = var.backend_memory >= 512 && var.backend_memory <= 30720
    error_message = "Backend memory must be between 512 and 30720 MB."
  }
}

#------------------------------------------------------------------------------
# Frontend Task Configuration
# Requirements: 8.1, 8.2, 8.3
#------------------------------------------------------------------------------

variable "frontend_cpu" {
  description = "CPU units for frontend task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.frontend_cpu)
    error_message = "Frontend CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "frontend_memory" {
  description = "Memory in MB for frontend task"
  type        = number
  default     = 512

  validation {
    condition     = var.frontend_memory >= 512 && var.frontend_memory <= 30720
    error_message = "Frontend memory must be between 512 and 30720 MB."
  }
}

#------------------------------------------------------------------------------
# Nova Sonic Task Configuration
# Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
#------------------------------------------------------------------------------

variable "nova_sonic_cpu" {
  description = "CPU units for nova sonic task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.nova_sonic_cpu)
    error_message = "Nova Sonic CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "nova_sonic_memory" {
  description = "Memory in MB for nova sonic task"
  type        = number
  default     = 512

  validation {
    condition     = var.nova_sonic_memory >= 512 && var.nova_sonic_memory <= 30720
    error_message = "Nova Sonic memory must be between 512 and 30720 MB."
  }
}

variable "bedrock_model" {
  description = "AWS Bedrock model identifier"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "frontend_url" {
  description = "Frontend URL for CORS and OAuth redirect"
  type        = string
}

variable "oauth_redirect_url" {
  description = "OAuth redirect URL for authentication callback"
  type        = string
}

#------------------------------------------------------------------------------
# OAuth Configuration
#------------------------------------------------------------------------------

variable "oauth_enabled" {
  description = "Enable OAuth authentication (affects IAM permissions)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Cost Optimization
# Requirement 12.5: Use Fargate Spot capacity provider as optional configuration
#------------------------------------------------------------------------------

variable "use_fargate_spot" {
  description = "Use Fargate Spot for cost savings (may cause interruptions)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Backend URL Configuration
#------------------------------------------------------------------------------

variable "backend_url" {
  description = "Backend API URL for frontend to connect to (e.g., https://astra-backend.example.com)"
  type        = string
}

#------------------------------------------------------------------------------
# Blue/Green Deployment Configuration
#------------------------------------------------------------------------------

variable "enable_blue_green" {
  description = "Enable blue/green deployment with CodeDeploy"
  type        = bool
  default     = false
}
