# Root Module Outputs
# Requirement 11.4: Output essential values (ALB DNS name, ECR repository URLs, ECS cluster name)

#------------------------------------------------------------------------------
# VPC Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

output "nat_gateway_ip" {
  description = "The Elastic IP of the NAT Gateway"
  value       = module.vpc.nat_gateway_ip
}

#------------------------------------------------------------------------------
# ECR Outputs
#------------------------------------------------------------------------------

output "ecr_repository_urls" {
  description = "Map of ECR repository names to URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository names to ARNs"
  value       = module.ecr.repository_arns
}

#------------------------------------------------------------------------------
# ALB Outputs
#------------------------------------------------------------------------------

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "The hosted zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

#------------------------------------------------------------------------------
# ECS Outputs
#------------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_service_arns" {
  description = "Map of ECS service names to ARNs"
  value       = module.ecs.service_arns
}

output "cloudmap_namespace_id" {
  description = "The ID of the Cloud Map namespace"
  value       = module.ecs.cloudmap_namespace_id
}

#------------------------------------------------------------------------------
# DNS Outputs
#------------------------------------------------------------------------------

output "frontend_url" {
  description = "The full URL for the frontend service"
  value       = "https://${aws_route53_record.frontend.fqdn}"
}

output "backend_url" {
  description = "The full URL for the backend service"
  value       = "https://${aws_route53_record.backend.fqdn}"
}

output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

#------------------------------------------------------------------------------
# Secrets Outputs (sensitive)
#------------------------------------------------------------------------------

output "secret_arns" {
  description = "Map of secret names to ARNs"
  value       = module.secrets.secret_arns
  sensitive   = true
}
