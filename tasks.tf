# ==============================================================================
# TEN-Agent ECS Deployment - Task Definitions
# ==============================================================================
# This file defines ECS task definitions for all services based on docker-compose

# ==============================================================================
# Task Definition - Agents Service
# ==============================================================================
# Corresponds to astra_agents_dev in docker-compose.yml

resource "aws_ecs_task_definition" "agents" {
  family                   = "${local.name_prefix}-agents"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["agents"]
  memory                   = var.ecs_task_memory["agents"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "agents"
      image     = var.agents_image
      essential = true

      portMappings = [
        {
          containerPort = var.server_port
          protocol      = "tcp"
          name          = "server"
        },
        {
          containerPort = var.graph_designer_server_port
          protocol      = "tcp"
          name          = "graph-designer"
        }
      ]

      environment = [
        {
          name  = "LOG_PATH"
          value = var.log_path
        },
        {
          name  = "GRAPH_DESIGNER_SERVER_PORT"
          value = tostring(var.graph_designer_server_port)
        },
        {
          name  = "SERVER_PORT"
          value = tostring(var.server_port)
        },
        {
          name  = "WORKERS_MAX"
          value = tostring(var.workers_max)
        },
        {
          name  = "WORKER_QUIT_TIMEOUT_SECONDES"
          value = tostring(var.worker_quit_timeout_seconds)
        },
        {
          name  = "AWS_BEDROCK_MODEL"
          value = var.aws_bedrock_model
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "AZURE_STT_REGION"
          value = var.aws_region
        },
        {
          name  = "AZURE_TTS_REGION"
          value = var.aws_region
        },
        {
          name  = "LITELLM_MODEL"
          value = var.litellm_model
        },
        {
          name  = "OPENAI_BASE_URL"
          value = var.openai_base_url
        },
        {
          name  = "OPENAI_MODEL"
          value = var.openai_model
        },
        {
          name  = "OPENAI_PROXY_URL"
          value = var.openai_proxy_url
        }
      ]

      secrets = [
        {
          name      = "AGORA_APP_ID"
          valueFrom = aws_secretsmanager_secret.agora_app_id.arn
        },
        {
          name      = "AGORA_APP_CERTIFICATE"
          valueFrom = aws_secretsmanager_secret.agora_app_certificate.arn
        },
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = aws_secretsmanager_secret.aws_access_key_id.arn
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = aws_secretsmanager_secret.aws_secret_access_key.arn
        },
        {
          name      = "AZURE_STT_KEY"
          valueFrom = aws_secretsmanager_secret.azure_stt_key.arn
        },
        {
          name      = "AZURE_TTS_KEY"
          valueFrom = aws_secretsmanager_secret.azure_tts_key.arn
        },
        {
          name      = "COSY_TTS_KEY"
          valueFrom = aws_secretsmanager_secret.cosy_tts_key.arn
        },
        {
          name      = "ELEVENLABS_TTS_KEY"
          valueFrom = aws_secretsmanager_secret.elevenlabs_tts_key.arn
        },
        {
          name      = "OPENAI_API_KEY"
          valueFrom = aws_secretsmanager_secret.openai_api_key.arn
        },
        {
          name      = "QWEN_API_KEY"
          valueFrom = aws_secretsmanager_secret.qwen_api_key.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.agents.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.server_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agents-task"
    }
  )
}

# ==============================================================================
# Task Definition - Playground Service
# ==============================================================================
# Corresponds to astra_playground_dev in docker-compose.yml

resource "aws_ecs_task_definition" "playground" {
  family                   = "${local.name_prefix}-playground"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["playground"]
  memory                   = var.ecs_task_memory["playground"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "playground"
      image     = var.playground_image
      essential = true

      command = [
        "sh",
        "-c",
        "apk add --no-cache git && cd /tmp && git clone https://github.com/ten-framework/TEN-Agent.git && cd TEN-Agent/playground && npm i && npm run dev"
      ]

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
          name          = "http"
        }
      ]

      environment = [
        {
          name  = "NEXT_PUBLIC_REQUEST_URL"
          value = var.enable_custom_domain ? "https://${var.subdomain_agents}.${var.domain_name}" : "http://${aws_lb.main.dns_name}:${var.server_port}"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.playground.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-playground-task"
    }
  )
}

# ==============================================================================
# Task Definition - Nova Sonic Service
# ==============================================================================
# Corresponds to nova_sonic_server in docker-compose.yml

resource "aws_ecs_task_definition" "nova_sonic" {
  family                   = "${local.name_prefix}-nova-sonic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu["nova_sonic"]
  memory                   = var.ecs_task_memory["nova_sonic"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "nova-sonic"
      image     = var.nova_sonic_image
      essential = true

      portMappings = [
        {
          containerPort = 3333
          protocol      = "tcp"
          name          = "http"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      secrets = [
        {
          name      = "AWS_ACCESS_KEY_ID"
          valueFrom = aws_secretsmanager_secret.aws_access_key_id.arn
        },
        {
          name      = "AWS_SECRET_ACCESS_KEY"
          valueFrom = aws_secretsmanager_secret.aws_secret_access_key.arn
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

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3333/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nova-sonic-task"
    }
  )
}
