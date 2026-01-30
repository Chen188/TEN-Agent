# ==============================================================================
# TEN-Agent ECS Deployment - Route 53 DNS Configuration
# ==============================================================================
# This file defines Route 53 hosted zone and DNS records

# ==============================================================================
# Route 53 Hosted Zone
# ==============================================================================
# Create a new hosted zone if route53_zone_id is not provided

resource "aws_route53_zone" "main" {
  count = var.enable_custom_domain && var.route53_zone_id == "" ? 1 : 0

  name = var.domain_name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-hosted-zone"
    }
  )
}

# Data source for existing hosted zone (if provided)
data "aws_route53_zone" "existing" {
  count = var.enable_custom_domain && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
}

# Local value to reference the correct zone ID
locals {
  route53_zone_id = var.enable_custom_domain ? (
    var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone.main[0].zone_id
  ) : null
}

# ==============================================================================
# DNS Records for Services
# ==============================================================================

# A Record - Agents Service
resource "aws_route53_record" "agents" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.route53_zone_id
  name    = "${var.subdomain_agents}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# A Record - Playground Service
resource "aws_route53_record" "playground" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.route53_zone_id
  name    = "${var.subdomain_playground}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# A Record - Nova Sonic Service
resource "aws_route53_record" "nova_sonic" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.route53_zone_id
  name    = "${var.subdomain_nova_sonic}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# A Record - Root domain (optional - redirects to playground)
resource "aws_route53_record" "root" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ==============================================================================
# DNS Records for ACM Certificate Validation
# ==============================================================================
# These records are automatically created by the ACM certificate validation process
# See acm.tf for the certificate validation configuration
