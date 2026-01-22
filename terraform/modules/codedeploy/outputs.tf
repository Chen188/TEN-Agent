# CodeDeploy Module Outputs

output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.ecs.name
}

output "codedeploy_app_arn" {
  description = "ARN of the CodeDeploy application"
  value       = aws_codedeploy_app.ecs.arn
}

output "backend_deployment_group_name" {
  description = "Name of the backend deployment group"
  value       = aws_codedeploy_deployment_group.backend.deployment_group_name
}

output "frontend_deployment_group_name" {
  description = "Name of the frontend deployment group"
  value       = aws_codedeploy_deployment_group.frontend.deployment_group_name
}

output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy IAM role"
  value       = aws_iam_role.codedeploy.arn
}
