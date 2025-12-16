# ===================================================
# TEN-Agent Terraform Configuration - Main
# ===================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ten-agent/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      },
      var.tags
    )
  }
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Local values
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  # Service configuration
  services = {
    astra_agents = {
      name          = "astra-agents"
      image         = var.astra_agents_image
      cpu           = var.astra_agents_cpu
      memory        = var.astra_agents_memory
      desired_count = var.astra_agents_desired_count
      port_mappings = [
        {
          container_port = var.graph_designer_server_port
          host_port      = var.graph_designer_server_port
          protocol       = "tcp"
        },
        {
          container_port = var.server_port
          host_port      = var.server_port
          protocol       = "tcp"
        }
      ]
      environment_secrets = [
        "AGORA_APP_ID",
        "AGORA_APP_CERTIFICATE",
        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY",
        "AWS_BEDROCK_MODEL",
        "AWS_REGION",
        "AZURE_STT_KEY",
        "AZURE_STT_REGION",
        "AZURE_TTS_KEY",
        "AZURE_TTS_REGION",
        "COSY_TTS_KEY",
        "ELEVENLABS_TTS_KEY",
        "LITELLM_MODEL",
        "OPENAI_API_KEY",
        "OPENAI_BASE_URL",
        "OPENAI_MODEL",
        "OPENAI_PROXY_URL",
        "QWEN_API_KEY"
      ]
      health_check_path = "/"
    }
    astra_playground = {
      name          = "astra-playground"
      image         = var.astra_playground_image
      cpu           = var.astra_playground_cpu
      memory        = var.astra_playground_memory
      desired_count = var.astra_playground_desired_count
      port_mappings = [
        {
          container_port = var.playground_port
          host_port      = var.playground_port
          protocol       = "tcp"
        }
      ]
      environment_secrets = []
      health_check_path   = "/"
    }
    nova_sonic = {
      name          = "nova-sonic-server"
      image         = var.nova_sonic_image
      cpu           = var.nova_sonic_cpu
      memory        = var.nova_sonic_memory
      desired_count = var.nova_sonic_desired_count
      port_mappings = [
        {
          container_port = var.nova_sonic_port
          host_port      = var.nova_sonic_port
          protocol       = "tcp"
        }
      ]
      environment_secrets = [
        "AWS_REGION",
        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY"
      ]
      health_check_path = "/"
    }
    graph_designer = {
      name          = "graph-designer"
      image         = var.graph_designer_image
      cpu           = var.graph_designer_cpu
      memory        = var.graph_designer_memory
      desired_count = var.graph_designer_desired_count
      port_mappings = [
        {
          container_port = 3000
          host_port      = var.graph_designer_ui_port
          protocol       = "tcp"
        }
      ]
      environment_secrets = []
      health_check_path   = "/"
    }
  }
}
