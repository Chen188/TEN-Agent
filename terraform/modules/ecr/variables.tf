# ECR Module Variables
# Defines inputs for ECR repository creation and configuration

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "repository_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["astra-agents", "astra-playground", "nova-sonic-server"]
}

variable "image_retention_count" {
  description = "Number of images to retain per repository"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
