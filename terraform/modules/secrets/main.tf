# Secrets Module - Main Configuration
# Creates AWS Secrets Manager secrets for sensitive configuration data
# Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6

#------------------------------------------------------------------------------
# Agora Credentials Secret
# Requirement 3.1: Secrets Manager secret for Agora credentials
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "agora" {
  name        = "${var.project_name}/agora-credentials"
  description = "Agora App ID and Certificate for real-time communication"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-agora-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "agora" {
  secret_id = aws_secretsmanager_secret.agora.id
  secret_string = jsonencode({
    AGORA_APP_ID          = var.agora_credentials.app_id
    AGORA_APP_CERTIFICATE = var.agora_credentials.app_certificate
  })
}

#------------------------------------------------------------------------------
# AWS Credentials Secret
# Requirement 3.2: Secrets Manager secret for AWS credentials
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "aws_credentials" {
  name        = "${var.project_name}/aws-credentials"
  description = "AWS Access Key and Secret for service authentication"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-aws-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "aws_credentials" {
  secret_id = aws_secretsmanager_secret.aws_credentials.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = var.aws_credentials.access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_credentials.secret_access_key
  })
}

#------------------------------------------------------------------------------
# TTS API Keys Secret
# Requirement 3.3: Secrets Manager secret for TTS API keys
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "tts" {
  name        = "${var.project_name}/tts-keys"
  description = "TTS API keys for Cosy and ElevenLabs"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-tts-keys"
    }
  )
}

resource "aws_secretsmanager_secret_version" "tts" {
  secret_id = aws_secretsmanager_secret.tts.id
  secret_string = jsonencode({
    COSY_TTS_KEY       = var.tts_keys.cosy_tts_key
    ELEVENLABS_TTS_KEY = var.tts_keys.elevenlabs_tts_key
  })
}

#------------------------------------------------------------------------------
# Cognito OAuth Configuration Secret
# Requirement 3.4: Secrets Manager secret for Cognito OAuth configuration
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "cognito" {
  name        = "${var.project_name}/cognito-config"
  description = "Cognito OAuth configuration for authentication"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-cognito-config"
    }
  )
}

resource "aws_secretsmanager_secret_version" "cognito" {
  secret_id = aws_secretsmanager_secret.cognito.id
  secret_string = jsonencode({
    COGNITO_CLIENT_ID     = var.cognito_config.client_id
    COGNITO_CLIENT_SECRET = var.cognito_config.client_secret
    COGNITO_USER_POOL_ID  = var.cognito_config.user_pool_id
    COGNITO_DOMAIN        = var.cognito_config.domain
    COGNITO_REGION        = var.cognito_config.region
  })
}

#------------------------------------------------------------------------------
# IAM Policy for ECS Tasks to Read Secrets
# Requirement 3.6: IAM policies allowing ECS tasks to read from Secrets Manager
# Requirement 3.5: Support for valueFrom syntax in ECS task definitions
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.project_name}-secrets-read-policy"
  description = "IAM policy allowing ECS tasks to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecretValue"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.agora.arn,
          aws_secretsmanager_secret.aws_credentials.arn,
          aws_secretsmanager_secret.tts.arn,
          aws_secretsmanager_secret.cognito.arn
        ]
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
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-secrets-read-policy"
    }
  )
}
