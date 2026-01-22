# Root Module Variables
# This file defines all configurable variables for the Terraform deployment

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "astra"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Single availability zone for cost optimization (deprecated, use availability_zones)"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zones" {
  description = "List of availability zones for deployment (minimum 2 for ALB)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (deprecated, use public_subnet_cidrs)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (deprecated, use private_subnet_cidrs)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for cost optimization"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Domain Configuration
#------------------------------------------------------------------------------

variable "domain_name" {
  description = "Base domain name (must exist in Route 53)"
  type        = string
  default     = "example.com"
}

variable "frontend_subdomain" {
  description = "Subdomain for frontend service"
  type        = string
  default     = "astra"
}

variable "backend_subdomain" {
  description = "Subdomain for backend service"
  type        = string
  default     = "astra-backend"
}

#------------------------------------------------------------------------------
# Agora Configuration (Sensitive)
#------------------------------------------------------------------------------

variable "agora_app_id" {
  description = "Agora App ID"
  type        = string
  sensitive   = true
}

variable "agora_app_certificate" {
  description = "Agora App Certificate"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# AWS Credentials for Services (Sensitive)
#------------------------------------------------------------------------------

variable "aws_access_key_id" {
  description = "AWS Access Key ID for services (used by containers)"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for services (used by containers)"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# AWS Bedrock Configuration
#------------------------------------------------------------------------------

variable "aws_bedrock_model" {
  description = "AWS Bedrock model identifier"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

#------------------------------------------------------------------------------
# TTS API Keys (Sensitive)
#------------------------------------------------------------------------------

variable "cosy_tts_key" {
  description = "Cosy TTS API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "elevenlabs_tts_key" {
  description = "ElevenLabs TTS API key"
  type        = string
  sensitive   = true
  default     = ""
}

#------------------------------------------------------------------------------
# OAuth / Cognito Configuration
#------------------------------------------------------------------------------

variable "oauth_enabled" {
  description = "Enable OAuth authentication"
  type        = bool
  default     = false
}

variable "cognito_client_id" {
  description = "Cognito Client ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cognito_client_secret" {
  description = "Cognito Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
  default     = ""
}

variable "cognito_domain" {
  description = "Cognito Domain"
  type        = string
  default     = ""
}

variable "cognito_region" {
  description = "Cognito Region"
  type        = string
  default     = "us-east-1"
}

#------------------------------------------------------------------------------
# ECS Task Sizing - Backend
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
# ECS Task Sizing - Frontend
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
# ECS Task Sizing - Nova Sonic
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

#------------------------------------------------------------------------------
# Cost Optimization
#------------------------------------------------------------------------------

variable "use_fargate_spot" {
  description = "Use Fargate Spot for cost savings (may cause interruptions)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# ECR Configuration
#------------------------------------------------------------------------------

variable "ecr_image_retention_count" {
  description = "Number of images to retain in ECR repositories"
  type        = number
  default     = 10

  validation {
    condition     = var.ecr_image_retention_count >= 1 && var.ecr_image_retention_count <= 100
    error_message = "ECR image retention count must be between 1 and 100."
  }
}


#------------------------------------------------------------------------------
# Blue/Green Deployment Configuration
#------------------------------------------------------------------------------

variable "enable_blue_green" {
  description = "Enable blue/green deployment with CodeDeploy for ECS services"
  type        = bool
  default     = false
}

variable "codedeploy_deployment_config" {
  description = "CodeDeploy deployment configuration name"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
  # Options:
  # - CodeDeployDefault.ECSAllAtOnce (instant traffic shift)
  # - CodeDeployDefault.ECSLinear10PercentEvery1Minutes
  # - CodeDeployDefault.ECSLinear10PercentEvery3Minutes
  # - CodeDeployDefault.ECSCanary10Percent5Minutes
  # - CodeDeployDefault.ECSCanary10Percent15Minutes
}

variable "codedeploy_wait_for_approval" {
  description = "Wait for manual approval before traffic shift in blue/green deployment"
  type        = bool
  default     = false
}

variable "codedeploy_termination_wait_minutes" {
  description = "Minutes to wait before terminating old tasks after successful deployment"
  type        = number
  default     = 5
}
