# ===================================================
# TEN-Agent Terraform Configuration - Outputs
# ===================================================

# ----- General Outputs -----
output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ----- Networking Outputs -----
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = aws_nat_gateway.main[*].id
}

# ----- Load Balancer Outputs -----
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.enable_alb ? aws_lb.main[0].dns_name : "ALB not enabled"
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.enable_alb ? aws_lb.main[0].arn : null
}

output "alb_zone_id" {
  description = "Hosted Zone ID of the Application Load Balancer"
  value       = var.enable_alb ? aws_lb.main[0].zone_id : null
}

output "alb_url" {
  description = "URL to access the Application Load Balancer"
  value       = var.enable_alb ? "http://${aws_lb.main[0].dns_name}" : "ALB not enabled"
}

# ----- Security Group Outputs -----
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

# ----- ECS Outputs -----
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

# ----- ECS Services Outputs -----
output "astra_agents_service_name" {
  description = "Name of the astra_agents ECS service"
  value       = aws_ecs_service.astra_agents.name
}

output "astra_agents_service_id" {
  description = "ID of the astra_agents ECS service"
  value       = aws_ecs_service.astra_agents.id
}

output "astra_playground_service_name" {
  description = "Name of the astra_playground ECS service"
  value       = aws_ecs_service.astra_playground.name
}

output "astra_playground_service_id" {
  description = "ID of the astra_playground ECS service"
  value       = aws_ecs_service.astra_playground.id
}

output "nova_sonic_service_name" {
  description = "Name of the nova_sonic ECS service"
  value       = aws_ecs_service.nova_sonic.name
}

output "nova_sonic_service_id" {
  description = "ID of the nova_sonic ECS service"
  value       = aws_ecs_service.nova_sonic.id
}

# ----- ECS Task Definition Outputs -----
output "astra_agents_task_definition_arn" {
  description = "ARN of the astra_agents task definition"
  value       = aws_ecs_task_definition.astra_agents.arn
}

output "astra_playground_task_definition_arn" {
  description = "ARN of the astra_playground task definition"
  value       = aws_ecs_task_definition.astra_playground.arn
}

output "nova_sonic_task_definition_arn" {
  description = "ARN of the nova_sonic task definition"
  value       = aws_ecs_task_definition.nova_sonic.arn
}

# ----- IAM Outputs -----
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

# ----- Secrets Manager Outputs -----
output "secrets_arn" {
  description = "ARN of the secrets manager secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
  sensitive   = true
}

output "secrets_name" {
  description = "Name of the secrets manager secret"
  value       = aws_secretsmanager_secret.app_secrets.name
}

# ----- CloudWatch Logs Outputs -----
output "astra_agents_log_group" {
  description = "CloudWatch log group for astra_agents"
  value       = aws_cloudwatch_log_group.astra_agents.name
}

output "astra_playground_log_group" {
  description = "CloudWatch log group for astra_playground"
  value       = aws_cloudwatch_log_group.astra_playground.name
}

output "nova_sonic_log_group" {
  description = "CloudWatch log group for nova_sonic"
  value       = aws_cloudwatch_log_group.nova_sonic.name
}

# ----- Target Group Outputs -----
output "astra_agents_target_group_arn" {
  description = "ARN of astra_agents target group"
  value       = var.enable_alb ? aws_lb_target_group.astra_agents[0].arn : null
}

output "astra_playground_target_group_arn" {
  description = "ARN of astra_playground target group"
  value       = var.enable_alb ? aws_lb_target_group.astra_playground[0].arn : null
}

output "nova_sonic_target_group_arn" {
  description = "ARN of nova_sonic target group"
  value       = var.enable_alb ? aws_lb_target_group.nova_sonic[0].arn : null
}

# ----- Service Endpoints -----
output "service_endpoints" {
  description = "Service endpoints for accessing each service via ALB"
  value = var.enable_alb ? {
    astra_agents     = "http://${aws_lb.main[0].dns_name}"
    astra_playground = "http://${aws_lb.main[0].dns_name}/playground"
    nova_sonic       = "http://${aws_lb.main[0].dns_name}/nova-sonic"
  } : {}
}

# ----- Connection Commands -----
output "aws_cli_commands" {
  description = "Useful AWS CLI commands for managing the deployment"
  value = {
    view_logs_astra_agents = "aws logs tail ${aws_cloudwatch_log_group.astra_agents.name} --follow --region ${var.aws_region}"

    view_logs_playground = "aws logs tail ${aws_cloudwatch_log_group.astra_playground.name} --follow --region ${var.aws_region}"

    view_logs_nova_sonic = "aws logs tail ${aws_cloudwatch_log_group.nova_sonic.name} --follow --region ${var.aws_region}"

    list_tasks = "aws ecs list-tasks --cluster ${aws_ecs_cluster.main.name} --region ${var.aws_region}"

    describe_services = "aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.astra_agents.name} ${aws_ecs_service.astra_playground.name} ${aws_ecs_service.nova_sonic.name} --region ${var.aws_region}"

    update_service = "aws ecs update-service --cluster ${aws_ecs_cluster.main.name} --service <SERVICE_NAME> --force-new-deployment --region ${var.aws_region}"
  }
}

# ----- Summary -----
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    project           = var.project_name
    environment       = var.environment
    region            = var.aws_region
    ecs_cluster       = aws_ecs_cluster.main.name
    load_balancer_url = var.enable_alb ? "http://${aws_lb.main[0].dns_name}" : "ALB not enabled"
    services_deployed = 3
    service_names = [
      aws_ecs_service.astra_agents.name,
      aws_ecs_service.astra_playground.name,
      aws_ecs_service.nova_sonic.name
    ]
  }
}
