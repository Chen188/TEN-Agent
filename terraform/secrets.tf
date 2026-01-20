# ===================================================
# TEN-Agent Terraform Configuration - Secrets Manager
# ===================================================

# Create a master secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${local.name_prefix}-secrets"
  description             = "Secrets for TEN-Agent application (${var.environment})"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-secrets"
    }
  )
}

# Store all secrets as a JSON object
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    AGORA_APP_ID          = var.agora_app_id
    AGORA_APP_CERTIFICATE = var.agora_app_certificate
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    AWS_BEDROCK_MODEL     = var.aws_bedrock_model
    AWS_REGION            = var.aws_region
    AZURE_STT_KEY         = var.azure_stt_key
    AZURE_STT_REGION      = var.azure_stt_region
    AZURE_TTS_KEY         = var.azure_tts_key
    AZURE_TTS_REGION      = var.azure_tts_region
    COSY_TTS_KEY          = var.cosy_tts_key
    ELEVENLABS_TTS_KEY    = var.elevenlabs_tts_key
    LITELLM_MODEL         = var.litellm_model
    OPENAI_API_KEY        = var.openai_api_key
    OPENAI_BASE_URL       = var.openai_base_url
    OPENAI_MODEL          = var.openai_model
    OPENAI_PROXY_URL      = var.openai_proxy_url
    QWEN_API_KEY          = var.qwen_api_key
  })
}

# IAM policy to allow ECS tasks to read secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${local.name_prefix}-secrets-access"
  description = "Allow ECS tasks to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.app_secrets.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
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

  tags = local.common_tags
}
