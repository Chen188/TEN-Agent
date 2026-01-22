# Root Module - Main Configuration
# This file composes all child modules to create the complete infrastructure
# Requirement 11.2: Use a root module that composes all child modules

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  
  frontend_fqdn = "${var.frontend_subdomain}.${var.domain_name}"
  backend_fqdn  = "${var.backend_subdomain}.${var.domain_name}"
}

#------------------------------------------------------------------------------
# VPC Module
# Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7
#------------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}

#------------------------------------------------------------------------------
# ECR Module
# Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6
#------------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  project_name          = var.project_name
  repository_names      = ["astra-agents", "astra-playground", "nova-sonic-server"]
  image_retention_count = var.ecr_image_retention_count
  tags                  = local.common_tags
}

#------------------------------------------------------------------------------
# Secrets Module
# Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
#------------------------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name

  agora_credentials = {
    app_id          = var.agora_app_id
    app_certificate = var.agora_app_certificate
  }

  aws_credentials = {
    access_key_id     = var.aws_access_key_id
    secret_access_key = var.aws_secret_access_key
  }

  tts_keys = {
    cosy_tts_key       = var.cosy_tts_key
    elevenlabs_tts_key = var.elevenlabs_tts_key
  }

  cognito_config = {
    client_id     = var.cognito_client_id
    client_secret = var.cognito_client_secret
    user_pool_id  = var.cognito_user_pool_id
    domain        = var.cognito_domain
    region        = var.cognito_region
  }

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# ACM Certificate (created in root to break circular dependency)
# Requirement 4.1: Create ACM certificate for wildcard domain
# Requirement 4.2: Configure DNS validation using Route 53
#------------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "main" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.domain_name}-wildcard-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

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

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

#------------------------------------------------------------------------------
# ALB Module
# Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7
#------------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn
  frontend_host     = local.frontend_fqdn
  backend_host      = local.backend_fqdn
  enable_blue_green = var.enable_blue_green

  depends_on = [module.vpc, aws_acm_certificate_validation.main]
}

#------------------------------------------------------------------------------
# DNS Records (Route 53 A records pointing to ALB)
# Requirements: 4.3, 4.4
#------------------------------------------------------------------------------
resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.frontend_fqdn
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "backend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.backend_fqdn
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

#------------------------------------------------------------------------------
# ECS Module
# Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.x, 8.x, 9.x, 10.x
#------------------------------------------------------------------------------
module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id

  # Target groups for ALB registration
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  backend_target_group_arn  = module.alb.backend_target_group_arn

  # ECR repository URLs - map service names to URLs
  ecr_repository_urls = {
    backend    = module.ecr.repository_urls["astra-agents"]
    frontend   = module.ecr.repository_urls["astra-playground"]
    nova_sonic = module.ecr.repository_urls["nova-sonic-server"]
  }

  # Secret ARNs for ECS task definitions
  secret_arns = module.secrets.secret_arns

  # Environment variables
  bedrock_model      = var.aws_bedrock_model
  oauth_enabled      = var.oauth_enabled
  frontend_url       = "https://${local.frontend_fqdn}"
  oauth_redirect_url = "https://${local.backend_fqdn}/oauth/callback"
  backend_url        = "https://${local.backend_fqdn}"

  # Task sizing
  backend_cpu       = var.backend_cpu
  backend_memory    = var.backend_memory
  frontend_cpu      = var.frontend_cpu
  frontend_memory   = var.frontend_memory
  nova_sonic_cpu    = var.nova_sonic_cpu
  nova_sonic_memory = var.nova_sonic_memory

  # Cost optimization
  use_fargate_spot = var.use_fargate_spot

  # Blue/Green deployment
  enable_blue_green = var.enable_blue_green

  tags = local.common_tags

  depends_on = [module.vpc, module.alb, module.ecr, module.secrets]
}

#------------------------------------------------------------------------------
# CodeDeploy Module (Blue/Green Deployments)
# Only created when enable_blue_green is true
#------------------------------------------------------------------------------
module "codedeploy" {
  source = "./modules/codedeploy"
  count  = var.enable_blue_green ? 1 : 0

  project_name = var.project_name

  ecs_cluster_name      = module.ecs.cluster_name
  backend_service_name  = "${var.project_name}-backend"
  frontend_service_name = "${var.project_name}-frontend"

  https_listener_arn = module.alb.https_listener_arn

  backend_target_group_name        = module.alb.backend_target_group_name
  backend_target_group_green_name  = module.alb.backend_target_group_green_name
  frontend_target_group_name       = module.alb.frontend_target_group_name
  frontend_target_group_green_name = module.alb.frontend_target_group_green_name

  deployment_config        = var.codedeploy_deployment_config
  wait_for_approval        = var.codedeploy_wait_for_approval
  termination_wait_minutes = var.codedeploy_termination_wait_minutes

  tags = local.common_tags

  depends_on = [module.ecs, module.alb]
}
