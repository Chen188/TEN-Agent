# ECS Module Outputs
# Exposes ECS cluster, service, and Cloud Map namespace information

#------------------------------------------------------------------------------
# ECS Cluster Outputs
#------------------------------------------------------------------------------

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

#------------------------------------------------------------------------------
# Cloud Map Namespace Outputs
#------------------------------------------------------------------------------

output "cloudmap_namespace_id" {
  description = "ID of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.local.id
}

output "cloudmap_namespace_arn" {
  description = "ARN of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.local.arn
}

output "cloudmap_namespace_name" {
  description = "Name of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.local.name
}

output "nova_sonic_discovery_service_arn" {
  description = "ARN of the nova-sonic Cloud Map service discovery service"
  value       = aws_service_discovery_service.nova_sonic.arn
}

output "nova_sonic_discovery_service_name" {
  description = "Name of the nova-sonic Cloud Map service discovery service (nova-sonic.local)"
  value       = "${aws_service_discovery_service.nova_sonic.name}.${aws_service_discovery_private_dns_namespace.local.name}"
}

#------------------------------------------------------------------------------
# Service ARNs
#------------------------------------------------------------------------------

output "service_arns" {
  description = "Map of service name to ARN"
  value = {
    backend    = aws_ecs_service.backend.id
    frontend   = aws_ecs_service.frontend.id
    nova_sonic = aws_ecs_service.nova_sonic.id
  }
}

#------------------------------------------------------------------------------
# Security Group Outputs
#------------------------------------------------------------------------------

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}

output "frontend_security_group_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "nova_sonic_security_group_id" {
  description = "ID of the nova-sonic security group"
  value       = aws_security_group.nova_sonic.id
}

#------------------------------------------------------------------------------
# IAM Role Outputs
#------------------------------------------------------------------------------

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.name
}

output "backend_task_role_arn" {
  description = "ARN of the backend task role"
  value       = aws_iam_role.backend_task.arn
}

output "frontend_task_role_arn" {
  description = "ARN of the frontend task role"
  value       = aws_iam_role.frontend_task.arn
}

output "nova_sonic_task_role_arn" {
  description = "ARN of the nova-sonic task role"
  value       = aws_iam_role.nova_sonic_task.arn
}

#------------------------------------------------------------------------------
# CloudWatch Log Group Outputs
#------------------------------------------------------------------------------

output "log_group_names" {
  description = "Map of service name to CloudWatch log group name"
  value = {
    backend    = aws_cloudwatch_log_group.backend.name
    frontend   = aws_cloudwatch_log_group.frontend.name
    nova_sonic = aws_cloudwatch_log_group.nova_sonic.name
  }
}

output "log_group_arns" {
  description = "Map of service name to CloudWatch log group ARN"
  value = {
    backend    = aws_cloudwatch_log_group.backend.arn
    frontend   = aws_cloudwatch_log_group.frontend.arn
    nova_sonic = aws_cloudwatch_log_group.nova_sonic.arn
  }
}

#------------------------------------------------------------------------------
# Task Definition Outputs
#------------------------------------------------------------------------------

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}

output "backend_task_definition_family" {
  description = "Family of the backend task definition"
  value       = aws_ecs_task_definition.backend.family
}

output "backend_task_definition_revision" {
  description = "Revision of the backend task definition"
  value       = aws_ecs_task_definition.backend.revision
}
