# ALB Module Variables
# Defines input variables for the Application Load Balancer module

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier where ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB placement"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "frontend_host" {
  description = "Frontend hostname for host-based routing (e.g., astra.example.com)"
  type        = string
}

variable "backend_host" {
  description = "Backend hostname for host-based routing (e.g., astra-backend.example.com)"
  type        = string
}

variable "frontend_port" {
  description = "Port for frontend target group"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port for backend target group"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Default health check path for target groups"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive successful health checks required"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks required"
  type        = number
  default     = 3
}

variable "enable_blue_green" {
  description = "Enable blue/green deployment with CodeDeploy"
  type        = bool
  default     = false
}
