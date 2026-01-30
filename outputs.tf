# ==============================================================================
# TEN-Agent ECS Deployment - Outputs
# ==============================================================================
# This file defines outputs for important resource information

# ==============================================================================
# Network Outputs
# ==============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# ==============================================================================
# ECS Outputs
# ==============================================================================

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_names" {
  description = "ECS service names"
  value = {
    agents     = aws_ecs_service.agents.name
    playground = aws_ecs_service.playground.name
    nova_sonic = aws_ecs_service.nova_sonic.name
  }
}

# ==============================================================================
# Load Balancer Outputs
# ==============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arns" {
  description = "Target group ARNs"
  value = {
    agents     = aws_lb_target_group.agents.arn
    playground = aws_lb_target_group.playground.arn
    nova_sonic = aws_lb_target_group.nova_sonic.arn
  }
}

# ==============================================================================
# Domain and SSL Outputs
# ==============================================================================

output "domain_name" {
  description = "Domain name (if custom domain is enabled)"
  value       = var.enable_custom_domain ? var.domain_name : null
}

output "service_urls" {
  description = "Service URLs"
  value = var.enable_custom_domain ? {
    agents     = "https://${var.subdomain_agents}.${var.domain_name}"
    playground = "https://${var.subdomain_playground}.${var.domain_name}"
    nova_sonic = "https://${var.subdomain_nova_sonic}.${var.domain_name}"
  } : {
    agents     = "http://${aws_lb.main.dns_name}:8080"
    playground = "http://${aws_lb.main.dns_name}:3000"
    nova_sonic = "http://${aws_lb.main.dns_name}:3333"
  }
}

output "certificate_arn" {
  description = "ACM certificate ARN (if custom domain is enabled)"
  value       = var.enable_custom_domain ? aws_acm_certificate.main[0].arn : null
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID (if custom domain is enabled)"
  value       = var.enable_custom_domain ? (var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone.main[0].zone_id) : null
}

output "route53_nameservers" {
  description = "Route53 nameservers (if new zone is created)"
  value       = var.enable_custom_domain && var.route53_zone_id == "" ? aws_route53_zone.main[0].name_servers : null
}

# ==============================================================================
# Secrets Manager Outputs
# ==============================================================================

output "secrets_arns" {
  description = "ARNs of AWS Secrets Manager secrets"
  value = {
    agora_app_id            = aws_secretsmanager_secret.agora_app_id.arn
    agora_app_certificate   = aws_secretsmanager_secret.agora_app_certificate.arn
    aws_access_key_id       = aws_secretsmanager_secret.aws_access_key_id.arn
    aws_secret_access_key   = aws_secretsmanager_secret.aws_secret_access_key.arn
    azure_stt_key           = aws_secretsmanager_secret.azure_stt_key.arn
    azure_tts_key           = aws_secretsmanager_secret.azure_tts_key.arn
    cosy_tts_key            = aws_secretsmanager_secret.cosy_tts_key.arn
    elevenlabs_tts_key      = aws_secretsmanager_secret.elevenlabs_tts_key.arn
    openai_api_key          = aws_secretsmanager_secret.openai_api_key.arn
    qwen_api_key            = aws_secretsmanager_secret.qwen_api_key.arn
  }
}

output "secrets_manager_secret_names" {
  description = "Names of AWS Secrets Manager secrets"
  value = {
    agora_app_id            = aws_secretsmanager_secret.agora_app_id.name
    agora_app_certificate   = aws_secretsmanager_secret.agora_app_certificate.name
    aws_access_key_id       = aws_secretsmanager_secret.aws_access_key_id.name
    aws_secret_access_key   = aws_secretsmanager_secret.aws_secret_access_key.name
    azure_stt_key           = aws_secretsmanager_secret.azure_stt_key.name
    azure_tts_key           = aws_secretsmanager_secret.azure_tts_key.name
    cosy_tts_key            = aws_secretsmanager_secret.cosy_tts_key.name
    elevenlabs_tts_key      = aws_secretsmanager_secret.elevenlabs_tts_key.name
    openai_api_key          = aws_secretsmanager_secret.openai_api_key.name
    qwen_api_key            = aws_secretsmanager_secret.qwen_api_key.name
  }
}

# ==============================================================================
# IAM Outputs
# ==============================================================================

output "ecs_task_execution_role_arn" {
  description = "ARN of ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

# ==============================================================================
# CloudWatch Outputs
# ==============================================================================

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    agents     = aws_cloudwatch_log_group.agents.name
    playground = aws_cloudwatch_log_group.playground.name
    nova_sonic = aws_cloudwatch_log_group.nova_sonic.name
  }
}

# ==============================================================================
# Deployment Information
# ==============================================================================

output "deployment_info" {
  description = "Deployment information and next steps"
  value = <<-EOT
    ========================================
    TEN-Agent Deployment Information
    ========================================
    
    Environment: ${var.environment}
    Region: ${var.aws_region}
    
    Load Balancer: ${aws_lb.main.dns_name}
    
    Service Endpoints:
    ${var.enable_custom_domain ? "  - Agents:     https://${var.subdomain_agents}.${var.domain_name}" : "  - Agents:     http://${aws_lb.main.dns_name}:8080"}
    ${var.enable_custom_domain ? "  - Playground: https://${var.subdomain_playground}.${var.domain_name}" : "  - Playground: http://${aws_lb.main.dns_name}:3000"}
    ${var.enable_custom_domain ? "  - Nova Sonic: https://${var.subdomain_nova_sonic}.${var.domain_name}" : "  - Nova Sonic: http://${aws_lb.main.dns_name}:3333"}
    
    IMPORTANT NEXT STEPS:
    1. Update secret values in AWS Secrets Manager:
       - Navigate to Secrets Manager in AWS Console
       - Update each secret with actual values
       - Restart ECS services to pick up new values
    
    2. ${var.enable_custom_domain && var.route53_zone_id == "" ? "Update domain nameservers:\n       - Point your domain to these nameservers:\n         ${join("\n         ", aws_route53_zone.main[0].name_servers)}" : "Verify DNS records are created"}
    
    3. Monitor deployment:
       - ECS Cluster: ${aws_ecs_cluster.main.name}
       - CloudWatch Logs: /ecs/${local.name_prefix}/
    
    4. Configure environment-specific settings in variables.tf
    
    ========================================
  EOT
}
