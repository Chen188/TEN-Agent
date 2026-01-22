# ALB Module Outputs
# Exposes ALB resources for use by other modules

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "frontend_target_group_arn" {
  description = "The ARN of the frontend target group"
  value       = aws_lb_target_group.frontend.arn
}

output "backend_target_group_arn" {
  description = "The ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}

# Blue/Green deployment outputs
output "frontend_target_group_green_arn" {
  description = "The ARN of the frontend green target group (for blue/green deployments)"
  value       = length(aws_lb_target_group.frontend_green) > 0 ? aws_lb_target_group.frontend_green[0].arn : null
}

output "backend_target_group_green_arn" {
  description = "The ARN of the backend green target group (for blue/green deployments)"
  value       = length(aws_lb_target_group.backend_green) > 0 ? aws_lb_target_group.backend_green[0].arn : null
}

output "frontend_target_group_name" {
  description = "The name of the frontend target group"
  value       = aws_lb_target_group.frontend.name
}

output "backend_target_group_name" {
  description = "The name of the backend target group"
  value       = aws_lb_target_group.backend.name
}

output "frontend_target_group_green_name" {
  description = "The name of the frontend green target group"
  value       = length(aws_lb_target_group.frontend_green) > 0 ? aws_lb_target_group.frontend_green[0].name : null
}

output "backend_target_group_green_name" {
  description = "The name of the backend green target group"
  value       = length(aws_lb_target_group.backend_green) > 0 ? aws_lb_target_group.backend_green[0].name : null
}
