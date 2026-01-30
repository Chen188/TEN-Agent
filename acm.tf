# ACM Certificate Configuration
resource "aws_acm_certificate" "main" {
  count = var.enable_custom_domain ? 1 : 0
  domain_name = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}", var.domain_name]
  validation_method = var.certificate_validation_method
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-certificate" })
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_custom_domain && var.certificate_validation_method == "DNS" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = local.route53_zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count = var.enable_custom_domain && var.certificate_validation_method == "DNS" ? 1 : 0
  certificate_arn = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  timeouts { create = "15m" }
}
