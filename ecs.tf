# ==============================================================================
# TEN-Agent ECS Deployment - ECS Cluster and Services
# ==============================================================================
# This file defines the ECS cluster and service configurations

# ==============================================================================
# CloudWatch Log Groups
# ==============================================================================

resource "aws_cloudwatch_log_group" "agents" {
  name              = "/ecs/${local.name_prefix}/agents"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agents-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "playground" {
  name              = "/ecs/${local.name_prefix}/playground"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-playground-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "nova_sonic" {
  name              = "/ecs/${local.name_prefix}/nova-sonic"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-logs"
    }
  )
}

# ==============================================================================
# ECS Cluster
# ==============================================================================

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-cluster"
    }
  )
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

# ==============================================================================
# ECS Service - Agents
# ==============================================================================

resource "aws_ecs_service" "agents" {
  name            = "${local.name_prefix}-agents"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.agents.arn
  desired_count   = var.ecs_service_desired_count["agents"]
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.agents.arn
    container_name   = "agents"
    container_port   = var.server_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.graph_designer.arn
    container_name   = "agents"
    container_port   = var.graph_designer_server_port
  }

  enable_execute_command = var.enable_ecs_exec

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agents-service"
    }
  )

  depends_on = [
    aws_lb_listener.agents,
    aws_lb_listener.graph_designer
  ]
}

# ==============================================================================
# ECS Service - Playground
# ==============================================================================

resource "aws_ecs_service" "playground" {
  name            = "${local.name_prefix}-playground"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.playground.arn
  desired_count   = var.ecs_service_desired_count["playground"]
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.playground.arn
    container_name   = "playground"
    container_port   = 3000
  }

  enable_execute_command = var.enable_ecs_exec

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-playground-service"
    }
  )

  depends_on = [aws_lb_listener.playground]
}

# ==============================================================================
# ECS Service - Nova Sonic
# ==============================================================================

resource "aws_ecs_service" "nova_sonic" {
  name            = "${local.name_prefix}-nova-sonic"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nova_sonic.arn
  desired_count   = var.ecs_service_desired_count["nova_sonic"]
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nova_sonic.arn
    container_name   = "nova-sonic"
    container_port   = 3333
  }

  enable_execute_command = var.enable_ecs_exec

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-service"
    }
  )

  depends_on = [aws_lb_listener.nova_sonic]
}

# ==============================================================================
# Auto Scaling Configuration - Agents Service
# ==============================================================================

resource "aws_appautoscaling_target" "agents" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.ecs_service_max_capacity["agents"]
  min_capacity       = var.ecs_service_min_capacity["agents"]
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.agents.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "agents_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-agents-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agents[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agents[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agents[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "agents_memory" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-agents-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.agents[0].resource_id
  scalable_dimension = aws_appautoscaling_target.agents[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.agents[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# ==============================================================================
# Auto Scaling Configuration - Playground Service
# ==============================================================================

resource "aws_appautoscaling_target" "playground" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.ecs_service_max_capacity["playground"]
  min_capacity       = var.ecs_service_min_capacity["playground"]
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.playground.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "playground_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-playground-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.playground[0].resource_id
  scalable_dimension = aws_appautoscaling_target.playground[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.playground[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# ==============================================================================
# Auto Scaling Configuration - Nova Sonic Service
# ==============================================================================

resource "aws_appautoscaling_target" "nova_sonic" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.ecs_service_max_capacity["nova_sonic"]
  min_capacity       = var.ecs_service_min_capacity["nova_sonic"]
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.nova_sonic.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "nova_sonic_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-nova-sonic-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.nova_sonic[0].resource_id
  scalable_dimension = aws_appautoscaling_target.nova_sonic[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.nova_sonic[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
