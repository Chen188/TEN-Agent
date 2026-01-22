# Terraform and Provider Version Constraints
# This file specifies the required versions for Terraform and providers

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Recommended: Configure remote backend for state management
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket         = "astra-terraform-state"
  #   key            = "ecs-deployment/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
