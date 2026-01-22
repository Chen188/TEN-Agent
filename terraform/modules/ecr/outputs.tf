# ECR Module Outputs
# Requirement 2.6: Output repository URLs for CI/CD integration

# Map of repository name to URL
output "repository_urls" {
  description = "Map of repository name to repository URL"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
}

# Map of repository name to ARN
output "repository_arns" {
  description = "Map of repository name to repository ARN"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.arn
  }
}

# Individual repository URLs for convenience
output "astra_agents_url" {
  description = "ECR repository URL for astra-agents"
  value       = try(aws_ecr_repository.repositories["astra-agents"].repository_url, null)
}

output "astra_playground_url" {
  description = "ECR repository URL for astra-playground"
  value       = try(aws_ecr_repository.repositories["astra-playground"].repository_url, null)
}

output "nova_sonic_server_url" {
  description = "ECR repository URL for nova-sonic-server"
  value       = try(aws_ecr_repository.repositories["nova-sonic-server"].repository_url, null)
}
