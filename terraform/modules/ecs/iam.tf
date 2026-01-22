# ECS Module - IAM Roles and Policies
# Creates IAM roles for ECS task execution and task roles
# Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# ECS Task Execution Role
# Requirements: 10.1, 10.2, 10.3
# - Pull images from ECR
# - Read secrets from Secrets Manager
# - Write logs to CloudWatch
#------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ecs-task-execution-role"
    }
  )
}

# Attach AWS managed policy for basic ECS task execution
# Requirement 10.1: Permissions to pull images from ECR
# Requirement 10.3: Permissions to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for Secrets Manager access
# Requirement 10.2: Permissions to read secrets from Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.project_name}-ecs-task-execution-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecretValue"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = values(var.secret_arns)
      },
      {
        Sid    = "DecryptSecrets"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Backend Task Role
# Requirement 10.4: Permissions to access AWS Bedrock
# Requirement 10.6: Permissions to interact with Cognito (if OAuth enabled)
#------------------------------------------------------------------------------

resource "aws_iam_role" "backend_task" {
  name = "${var.project_name}-backend-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-backend-task-role"
    }
  )
}

# Bedrock access policy for backend
# Requirement 10.4: Backend service permissions to access AWS Bedrock
resource "aws_iam_role_policy" "backend_bedrock" {
  name = "${var.project_name}-backend-bedrock-policy"
  role = aws_iam_role.backend_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      }
    ]
  })
}

# Cognito access policy for backend (conditional)
# Requirement 10.6: If OAUTH_ENABLED is true, backend task role has Cognito permissions
resource "aws_iam_role_policy" "backend_cognito" {
  count = var.oauth_enabled ? 1 : 0

  name = "${var.project_name}-backend-cognito-policy"
  role = aws_iam_role.backend_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CognitoUserPoolAccess"
        Effect = "Allow"
        Action = [
          "cognito-idp:GetUser",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminRespondToAuthChallenge",
          "cognito-idp:DescribeUserPool",
          "cognito-idp:DescribeUserPoolClient"
        ]
        Resource = "arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Nova Sonic Task Role
# Requirement 10.5: Permissions to access AWS Bedrock
#------------------------------------------------------------------------------

resource "aws_iam_role" "nova_sonic_task" {
  name = "${var.project_name}-nova-sonic-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nova-sonic-task-role"
    }
  )
}

# Bedrock access policy for nova-sonic
# Requirement 10.5: Nova sonic service permissions to access AWS Bedrock
resource "aws_iam_role_policy" "nova_sonic_bedrock" {
  name = "${var.project_name}-nova-sonic-bedrock-policy"
  role = aws_iam_role.nova_sonic_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Frontend Task Role (minimal permissions)
#------------------------------------------------------------------------------

resource "aws_iam_role" "frontend_task" {
  name = "${var.project_name}-frontend-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-frontend-task-role"
    }
  )
}
