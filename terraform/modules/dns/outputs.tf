# DNS Module Outputs
# Exposes DNS resources for use by other modules

output "certificate_arn" {
  description = "The ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_arn_unvalidated" {
  description = "The ARN of the ACM certificate (before validation)"
  value       = aws_acm_certificate.main.arn
}

output "frontend_fqdn" {
  description = "Full frontend domain name"
  value       = var.create_dns_records && var.alb_dns_name != "" ? aws_route53_record.frontend[0].fqdn : "${var.frontend_subdomain}.${var.domain_name}"
}

output "backend_fqdn" {
  description = "Full backend domain name"
  value       = var.create_dns_records && var.alb_dns_name != "" ? aws_route53_record.backend[0].fqdn : "${var.backend_subdomain}.${var.domain_name}"
}

output "hosted_zone_id" {
  description = "The Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}
