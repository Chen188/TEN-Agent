# DNS Module - Main Configuration
# Creates ACM certificate, DNS validation, and Route 53 records
# Requirements: 4.1, 4.2, 4.3, 4.4, 4.5

#------------------------------------------------------------------------------
# Data Source: Existing Route 53 Hosted Zone
# Requirement 4.5: Reference existing Route 53 hosted zone for domain
#------------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

#------------------------------------------------------------------------------
# ACM Certificate
# Requirement 4.1: Create ACM certificate for wildcard domain
#------------------------------------------------------------------------------
resource "aws_acm_certificate" "main" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = {
    Name = "${var.domain_name}-wildcard-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# DNS Validation Records
# Requirement 4.2: Configure DNS validation for ACM certificate using Route 53
#------------------------------------------------------------------------------
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

#------------------------------------------------------------------------------
# ACM Certificate Validation
# Requirement 4.2: Wait for DNS validation to complete
#------------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

#------------------------------------------------------------------------------
# Frontend DNS Record
# Requirement 4.3: Create Route 53 A records for frontend subdomain pointing to ALB
#------------------------------------------------------------------------------
resource "aws_route53_record" "frontend" {
  count = var.create_dns_records && var.alb_dns_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.frontend_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

#------------------------------------------------------------------------------
# Backend DNS Record
# Requirement 4.4: Create Route 53 A records for backend subdomain pointing to ALB
#------------------------------------------------------------------------------
resource "aws_route53_record" "backend" {
  count = var.create_dns_records && var.alb_dns_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.backend_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
