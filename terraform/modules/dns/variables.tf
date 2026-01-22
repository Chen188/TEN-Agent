# DNS Module Variables
# Defines input variables for the DNS module

variable "domain_name" {
  description = "Base domain name (must exist in Route 53)"
  type        = string
}

variable "frontend_subdomain" {
  description = "Subdomain for frontend service"
  type        = string
}

variable "backend_subdomain" {
  description = "Subdomain for backend service"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for A record alias (optional - if not provided, DNS records won't be created)"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for A record alias (optional - if not provided, DNS records won't be created)"
  type        = string
  default     = ""
}

variable "create_dns_records" {
  description = "Whether to create DNS records (set to true after ALB is created)"
  type        = bool
  default     = true
}
