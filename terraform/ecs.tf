# ===================================================
# TEN-Agent Terraform Configuration - ECS
# ===================================================

# ----- ECS Cluster -----
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cluster"
    }
  )
}

# ----- CloudWatch Log Groups -----
resource "aws_cloudwatch_log_group" "astra_agents" {
  name              = "/ecs/${local.name_prefix}/astra-agents"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-astra-agents-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "astra_playground" {
  name              = "/ecs/${local.name_prefix}/astra-playground"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-astra-playground-logs"
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

# ----- IAM Role for ECS Task Execution -----
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-task-execution-role"
    }
  )
}

# ----- Attach AWS Managed Policy for ECS Task Execution -----
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ----- Attach Secrets Access Policy -----
resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# ----- IAM Role for ECS Tasks (Application Role) -----
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-task-role"
    }
  )
}

# ----- IAM Policy for ECS Task Role (Application Permissions) -----
resource "aws_iam_role_policy" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# ----- ECS Task Definition: astra_agents -----
resource "aws_ecs_task_definition" "astra_agents" {
  family                   = "${local.name_prefix}-astra-agents"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.astra_agents_cpu
  memory                   = var.astra_agents_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "astra-agents"
      image = var.astra_agents_image

      portMappings = [
        {
          containerPort = var.graph_designer_server_port
          protocol      = "tcp"
        },
        {
          containerPort = var.server_port
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "AGORA_APP_ID"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AGORA_APP_ID::"
        },
        {
          name      = "AGORA_APP_CERTIFICATE"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AGORA_APP_CERTIFICATE::"
        },
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AWS_ACCESS_KEY_ID::"
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AWS_SECRET_ACCESS_KEY::"
        },
        {
          name      = "AWS_BEDROCK_MODEL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AWS_BEDROCK_MODEL::"
        },
        {
          name      = "AZURE_STT_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AZURE_STT_KEY::"
        },
        {
          name      = "AZURE_STT_REGION"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AZURE_STT_REGION::"
        },
        {
          name      = "AZURE_TTS_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AZURE_TTS_KEY::"
        },
        {
          name      = "AZURE_TTS_REGION"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AZURE_TTS_REGION::"
        },
        {
          name      = "COSY_TTS_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:COSY_TTS_KEY::"
        },
        {
          name      = "ELEVENLABS_TTS_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:ELEVENLABS_TTS_KEY::"
        },
        {
          name      = "LITELLM_MODEL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:LITELLM_MODEL::"
        },
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:OPENAI_API_KEY::"
        },
        {
          name      = "OPENAI_BASE_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:OPENAI_BASE_URL::"
        },
        {
          name      = "OPENAI_MODEL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:OPENAI_MODEL::"
        },
        {
          name      = "OPENAI_PROXY_URL"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:OPENAI_PROXY_URL::"
        },
        {
          name      = "QWEN_API_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:QWEN_API_KEY::"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "LOG_PATH"
          value = var.log_path
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.astra_agents.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-astra-agents-task"
    }
  )
}

# ----- ECS Task Definition: astra_playground -----
resource "aws_ecs_task_definition" "astra_playground" {
  family                   = "${local.name_prefix}-astra-playground"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.astra_playground_cpu
  memory                   = var.astra_playground_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "astra-playground"
      image = var.astra_playground_image

      portMappings = [
        {
          containerPort = var.playground_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.astra_playground.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-astra-playground-task"
    }
  )
}

# ----- ECS Task Definition: nova_sonic -----
resource "aws_ecs_task_definition" "nova_sonic" {
  family                   = "${local.name_prefix}-nova-sonic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.nova_sonic_cpu
  memory                   = var.nova_sonic_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "nova-sonic-server"
      image = var.nova_sonic_image

      portMappings = [
        {
          containerPort = var.nova_sonic_port
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AWS_ACCESS_KEY_ID::"
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:AWS_SECRET_ACCESS_KEY::"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nova_sonic.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-task"
    }
  )
}

# ----- ECS Service: astra_agents -----
resource "aws_ecs_service" "astra_agents" {
  name            = "${local.name_prefix}-astra-agents"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.astra_agents.arn
  desired_count   = var.astra_agents_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.astra_agents[0].arn
      container_name   = "astra-agents"
      container_port   = var.server_port
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_iam_role_policy_attachment.secrets_access
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-astra-agents-service"
    }
  )
}

# ----- ECS Service: astra_playground -----
resource "aws_ecs_service" "astra_playground" {
  name            = "${local.name_prefix}-astra-playground"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.astra_playground.arn
  desired_count   = var.astra_playground_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.astra_playground[0].arn
      container_name   = "astra-playground"
      container_port   = var.playground_port
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_iam_role_policy_attachment.secrets_access
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-astra-playground-service"
    }
  )
}

# ----- ECS Service: nova_sonic -----
resource "aws_ecs_service" "nova_sonic" {
  name            = "${local.name_prefix}-nova-sonic"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nova_sonic.arn
  desired_count   = var.nova_sonic_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.enable_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.nova_sonic[0].arn
      container_name   = "nova-sonic-server"
      container_port   = var.nova_sonic_port
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_iam_role_policy_attachment.secrets_access
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-service"
    }
  )
}

# ----- Auto Scaling Target: astra_agents -----
resource "aws_appautoscaling_target" "astra_agents" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.astra_agents.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ----- Auto Scaling Policy: CPU -----
resource "aws_appautoscaling_policy" "astra_agents_cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${local.name_prefix}-astra-agents-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.astra_agents[0].resource_id
  scalable_dimension = aws_appautoscaling_target.astra_agents[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.astra_agents[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.autoscaling_cpu_target
  }
}

# ----- Auto Scaling Policy: Memory -----
resource "aws_appautoscaling_policy" "astra_agents_memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${local.name_prefix}-astra-agents-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.astra_agents[0].resource_id
  scalable_dimension = aws_appautoscaling_target.astra_agents[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.astra_agents[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.autoscaling_memory_target
  }
}
