# ==============================================================================
# TEN-Agent ECS Deployment - IAM Roles and Policies
# ==============================================================================
# This file defines IAM roles and policies for ECS tasks

# ==============================================================================
# ECS Task Execution Role
# ==============================================================================
# This role is used by ECS to pull container images and write logs

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.name_prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-task-execution-role"
    }
  )
}

data "aws_iam_policy_document" "ecs_task_execution_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy for accessing Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name   = "${local.name_prefix}-ecs-secrets-policy"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_secrets_access.json
}

data "aws_iam_policy_document" "ecs_secrets_access" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      aws_secretsmanager_secret.agora_app_id.arn,
      aws_secretsmanager_secret.agora_app_certificate.arn,
      aws_secretsmanager_secret.aws_access_key_id.arn,
      aws_secretsmanager_secret.aws_secret_access_key.arn,
      aws_secretsmanager_secret.azure_stt_key.arn,
      aws_secretsmanager_secret.azure_tts_key.arn,
      aws_secretsmanager_secret.cosy_tts_key.arn,
      aws_secretsmanager_secret.elevenlabs_tts_key.arn,
      aws_secretsmanager_secret.openai_api_key.arn,
      aws_secretsmanager_secret.qwen_api_key.arn,
    ]
  }

  # If using KMS encryption for secrets
  dynamic "statement" {
    for_each = var.enable_kms_encryption ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]

      resources = ["*"]
    }
  }
}

# Policy for CloudWatch Logs
resource "aws_iam_role_policy" "ecs_task_execution_logs" {
  name   = "${local.name_prefix}-ecs-logs-policy"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_logs_access.json
}

data "aws_iam_policy_document" "ecs_logs_access" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.agents.arn}:*",
      "${aws_cloudwatch_log_group.playground.arn}:*",
      "${aws_cloudwatch_log_group.nova_sonic.arn}:*"
    ]
  }
}

# ==============================================================================
# ECS Task Role
# ==============================================================================
# This role is used by the application running inside the container

resource "aws_iam_role" "ecs_task" {
  name               = "${local.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-task-role"
    }
  )
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Policy for application to access AWS services
resource "aws_iam_role_policy" "ecs_task_application" {
  name   = "${local.name_prefix}-ecs-application-policy"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_application.json
}

data "aws_iam_policy_document" "ecs_task_application" {
  # Allow access to AWS Bedrock
  statement {
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]

    resources = ["*"]
  }

  # Allow access to Polly TTS
  statement {
    effect = "Allow"

    actions = [
      "polly:SynthesizeSpeech",
      "polly:DescribeVoices"
    ]

    resources = ["*"]
  }

  # Allow access to S3 (if needed for file storage)
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${local.name_prefix}-*/*"
    ]
  }

  # Allow listing buckets
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${local.name_prefix}-*"
    ]
  }

  # Allow CloudWatch metrics and logs
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

# Policy for ECS Exec (debugging)
resource "aws_iam_role_policy" "ecs_task_exec" {
  count = var.enable_ecs_exec ? 1 : 0

  name   = "${local.name_prefix}-ecs-exec-policy"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_exec.json
}

data "aws_iam_policy_document" "ecs_exec" {
  statement {
    effect = "Allow"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = ["*"]
  }
}

# ==============================================================================
# Auto Scaling IAM Role
# ==============================================================================

resource "aws_iam_role" "ecs_autoscaling" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-ecs-autoscaling-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_autoscaling_assume[0].json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-autoscaling-role"
    }
  )
}

data "aws_iam_policy_document" "ecs_autoscaling_assume" {
  count = var.enable_autoscaling ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling" {
  count = var.enable_autoscaling ? 1 : 0

  role       = aws_iam_role.ecs_autoscaling[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}
