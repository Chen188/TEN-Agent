# ECS Module - Main Configuration
# Creates ECS cluster with container insights and Cloud Map namespace
# Requirements: 6.1, 6.2, 6.5, 7.6, 7.7, 7.8, 8.4, 8.5, 8.6, 9.6, 9.7, 9.8, 9.9

#------------------------------------------------------------------------------
# ECS Cluster
#------------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = "${var.project_name}-cluster" })
}

#------------------------------------------------------------------------------
# ECS Cluster Capacity Providers
#------------------------------------------------------------------------------

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = var.use_fargate_spot ? ["FARGATE", "FARGATE_SPOT"] : ["FARGATE"]

  default_capacity_provider_strategy {
    base              = var.use_fargate_spot ? 0 : 1
    weight            = var.use_fargate_spot ? 0 : 100
    capacity_provider = "FARGATE"
  }

  dynamic "default_capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      base              = 1
      weight            = 100
      capacity_provider = "FARGATE_SPOT"
    }
  }
}

#------------------------------------------------------------------------------
# Cloud Map Private DNS Namespace
#------------------------------------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "local" {
  name        = "local"
  description = "Private DNS namespace for ECS service discovery"
  vpc         = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.project_name}-local-namespace" })
}

#------------------------------------------------------------------------------
# CloudWatch Log Groups
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 30
  tags              = merge(var.tags, { Name = "${var.project_name}-backend-logs", Service = "backend" })
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 30
  tags              = merge(var.tags, { Name = "${var.project_name}-frontend-logs", Service = "frontend" })
}

resource "aws_cloudwatch_log_group" "nova_sonic" {
  name              = "/ecs/${var.project_name}/nova-sonic"
  retention_in_days = 30
  tags              = merge(var.tags, { Name = "${var.project_name}-nova-sonic-logs", Service = "nova-sonic" })
}

#------------------------------------------------------------------------------
# Task Definitions
#------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.backend_task.arn

  container_definitions = templatefile("${path.module}/task-definitions/backend.json.tpl", {
    project_name       = var.project_name
    cpu                = var.backend_cpu
    memory             = var.backend_memory
    execution_role_arn = aws_iam_role.ecs_task_execution.arn
    task_role_arn      = aws_iam_role.backend_task.arn
    image_url          = var.ecr_repository_urls["backend"]
    aws_region         = var.aws_region
    bedrock_model      = var.bedrock_model
    oauth_enabled      = tostring(var.oauth_enabled)
    frontend_url       = var.frontend_url
    oauth_redirect_url = var.oauth_redirect_url
    agora_secret_arn   = var.secret_arns["agora"]
    aws_secret_arn     = var.secret_arns["aws_credentials"]
    tts_secret_arn     = var.secret_arns["tts"]
    cognito_secret_arn = var.secret_arns["cognito"]
    log_group          = aws_cloudwatch_log_group.backend.name
  })

  tags = merge(var.tags, { Name = "${var.project_name}-backend-task", Service = "backend" })
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = templatefile("${path.module}/task-definitions/frontend.json.tpl", {
    image_url   = var.ecr_repository_urls["frontend"]
    aws_region  = var.aws_region
    log_group   = aws_cloudwatch_log_group.frontend.name
    backend_url = var.backend_url
  })

  tags = merge(var.tags, { Name = "${var.project_name}-frontend-task", Service = "frontend" })
}

resource "aws_ecs_task_definition" "nova_sonic" {
  family                   = "${var.project_name}-nova-sonic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.nova_sonic_cpu
  memory                   = var.nova_sonic_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.nova_sonic_task.arn

  container_definitions = templatefile("${path.module}/task-definitions/nova-sonic.json.tpl", {
    image_url      = var.ecr_repository_urls["nova_sonic"]
    aws_region     = var.aws_region
    aws_secret_arn = var.secret_arns["aws_credentials"]
    log_group      = aws_cloudwatch_log_group.nova_sonic.name
  })

  tags = merge(var.tags, { Name = "${var.project_name}-nova-sonic-task", Service = "nova-sonic" })
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "Security group for backend ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on port 8080"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-backend-sg", Service = "backend" })
}

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "Security group for frontend ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on port 3000"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-frontend-sg", Service = "frontend" })
}

resource "aws_security_group" "nova_sonic" {
  name        = "${var.project_name}-nova-sonic-sg"
  description = "Security group for nova-sonic ECS service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from backend on port 3333"
    from_port       = 3333
    to_port         = 3333
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project_name}-nova-sonic-sg", Service = "nova-sonic" })
}

#------------------------------------------------------------------------------
# Cloud Map Service Discovery for Nova Sonic
#------------------------------------------------------------------------------

resource "aws_service_discovery_service" "nova_sonic" {
  name = "nova-sonic"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.local.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(var.tags, { Name = "${var.project_name}-nova-sonic-discovery", Service = "nova-sonic" })
}

#------------------------------------------------------------------------------
# ECS Services
#------------------------------------------------------------------------------

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = var.use_fargate_spot ? null : "FARGATE"

  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 1
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = 8080
  }

  dynamic "deployment_controller" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      type = "CODE_DEPLOY"
    }
  }

  depends_on = [aws_ecs_task_definition.backend, aws_ecs_cluster_capacity_providers.main]
  tags       = merge(var.tags, { Name = "${var.project_name}-backend-service", Service = "backend" })

  # Note: When enable_blue_green=true, CodeDeploy manages task_definition updates.
  # Terraform cannot dynamically ignore_changes, so after enabling blue/green,
  # you may need to use -ignore-changes flag or accept task_definition drift.
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = var.use_fargate_spot ? null : "FARGATE"

  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 1
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.frontend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 3000
  }

  dynamic "deployment_controller" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      type = "CODE_DEPLOY"
    }
  }

  depends_on = [aws_ecs_task_definition.frontend, aws_ecs_cluster_capacity_providers.main]
  tags       = merge(var.tags, { Name = "${var.project_name}-frontend-service", Service = "frontend" })
}

resource "aws_ecs_service" "nova_sonic" {
  name            = "${var.project_name}-nova-sonic"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nova_sonic.arn
  desired_count   = 1
  launch_type     = var.use_fargate_spot ? null : "FARGATE"

  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 1
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.nova_sonic.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.nova_sonic.arn
  }

  # No load_balancer block - nova_sonic is internal only

  depends_on = [aws_ecs_task_definition.nova_sonic, aws_ecs_cluster_capacity_providers.main]
  tags       = merge(var.tags, { Name = "${var.project_name}-nova-sonic-service", Service = "nova-sonic" })
}