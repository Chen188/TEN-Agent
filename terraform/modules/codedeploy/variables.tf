# CodeDeploy Module Variables

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "backend_service_name" {
  description = "Name of the backend ECS service"
  type        = string
}

variable "frontend_service_name" {
  description = "Name of the frontend ECS service"
  type        = string
}

variable "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  type        = string
}

variable "backend_target_group_name" {
  description = "Name of the backend blue target group"
  type        = string
}

variable "backend_target_group_green_name" {
  description = "Name of the backend green target group"
  type        = string
}

variable "frontend_target_group_name" {
  description = "Name of the frontend blue target group"
  type        = string
}

variable "frontend_target_group_green_name" {
  description = "Name of the frontend green target group"
  type        = string
}

variable "deployment_config" {
  description = "CodeDeploy deployment configuration"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
  # Options: CodeDeployDefault.ECSLinear10PercentEvery1Minutes
  #          CodeDeployDefault.ECSLinear10PercentEvery3Minutes
  #          CodeDeployDefault.ECSCanary10Percent5Minutes
  #          CodeDeployDefault.ECSCanary10Percent15Minutes
  #          CodeDeployDefault.ECSAllAtOnce
}

variable "wait_for_approval" {
  description = "Wait for manual approval before traffic shift"
  type        = bool
  default     = false
}

variable "approval_wait_minutes" {
  description = "Minutes to wait for approval (if wait_for_approval is true)"
  type        = number
  default     = 60
}

variable "termination_wait_minutes" {
  description = "Minutes to wait before terminating old tasks after deployment"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
