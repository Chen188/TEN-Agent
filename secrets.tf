# ==============================================================================
# TEN-Agent ECS Deployment - AWS Secrets Manager
# ==============================================================================
# This file defines AWS Secrets Manager secrets for sensitive information
# IMPORTANT: After deployment, update secret values in AWS Secrets Manager console

# ==============================================================================
# Agora Configuration Secrets
# ==============================================================================

resource "aws_secretsmanager_secret" "agora_app_id" {
  name                    = "${local.name_prefix}/agora-app-id"
  description             = "Agora App ID for TEN-Agent"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agora-app-id"
    }
  )
}

resource "aws_secretsmanager_secret_version" "agora_app_id" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.agora_app_id.id
  secret_string = "REPLACE_WITH_ACTUAL_AGORA_APP_ID"
}

resource "aws_secretsmanager_secret" "agora_app_certificate" {
  name                    = "${local.name_prefix}/agora-app-certificate"
  description             = "Agora App Certificate for TEN-Agent"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-agora-app-certificate"
    }
  )
}

resource "aws_secretsmanager_secret_version" "agora_app_certificate" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.agora_app_certificate.id
  secret_string = "REPLACE_WITH_ACTUAL_AGORA_APP_CERTIFICATE"
}

# ==============================================================================
# AWS Service Credentials
# ==============================================================================

resource "aws_secretsmanager_secret" "aws_access_key_id" {
  name                    = "${local.name_prefix}/aws-access-key-id"
  description             = "AWS Access Key ID for services (Bedrock, Polly, etc.)"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-aws-access-key-id"
    }
  )
}

resource "aws_secretsmanager_secret_version" "aws_access_key_id" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.aws_access_key_id.id
  secret_string = "REPLACE_WITH_ACTUAL_AWS_ACCESS_KEY_ID"
}

resource "aws_secretsmanager_secret" "aws_secret_access_key" {
  name                    = "${local.name_prefix}/aws-secret-access-key"
  description             = "AWS Secret Access Key for services (Bedrock, Polly, etc.)"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-aws-secret-access-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "aws_secret_access_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.aws_secret_access_key.id
  secret_string = "REPLACE_WITH_ACTUAL_AWS_SECRET_ACCESS_KEY"
}

# ==============================================================================
# Azure Configuration Secrets
# ==============================================================================

resource "aws_secretsmanager_secret" "azure_stt_key" {
  name                    = "${local.name_prefix}/azure-stt-key"
  description             = "Azure Speech-to-Text API Key"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-azure-stt-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "azure_stt_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.azure_stt_key.id
  secret_string = "REPLACE_WITH_ACTUAL_AZURE_STT_KEY"
}

resource "aws_secretsmanager_secret" "azure_tts_key" {
  name                    = "${local.name_prefix}/azure-tts-key"
  description             = "Azure Text-to-Speech API Key"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-azure-tts-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "azure_tts_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.azure_tts_key.id
  secret_string = "REPLACE_WITH_ACTUAL_AZURE_TTS_KEY"
}

# ==============================================================================
# TTS Service API Keys
# ==============================================================================

resource "aws_secretsmanager_secret" "cosy_tts_key" {
  name                    = "${local.name_prefix}/cosy-tts-key"
  description             = "Cosy TTS API Key"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cosy-tts-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "cosy_tts_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.cosy_tts_key.id
  secret_string = "REPLACE_WITH_ACTUAL_COSY_TTS_KEY"
}

resource "aws_secretsmanager_secret" "elevenlabs_tts_key" {
  name                    = "${local.name_prefix}/elevenlabs-tts-key"
  description             = "ElevenLabs TTS API Key"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-elevenlabs-tts-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "elevenlabs_tts_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.elevenlabs_tts_key.id
  secret_string = "REPLACE_WITH_ACTUAL_ELEVENLABS_TTS_KEY"
}

# ==============================================================================
# LLM Service API Keys
# ==============================================================================

resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "${local.name_prefix}/openai-api-key"
  description             = "OpenAI API Key"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-openai-api-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = "REPLACE_WITH_ACTUAL_OPENAI_API_KEY"
}

resource "aws_secretsmanager_secret" "qwen_api_key" {
  name                    = "${local.name_prefix}/qwen-api-key"
  description             = "Qwen API Key"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-qwen-api-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "qwen_api_key" {
  count = var.create_secrets ? 1 : 0

  secret_id     = aws_secretsmanager_secret.qwen_api_key.id
  secret_string = "REPLACE_WITH_ACTUAL_QWEN_API_KEY"
}

# ==============================================================================
# Output Secret ARNs for Reference
# ==============================================================================
# These are also available in outputs.tf but included here for convenience

output "secret_instructions" {
  description = "Instructions for updating secrets"
  value = <<-EOT
    ========================================
    IMPORTANT: Update Secret Values
    ========================================
    
    The following secrets have been created with placeholder values.
    You MUST update them with actual values before the application will work properly.
    
    Update secrets using AWS CLI:
    
    aws secretsmanager put-secret-value \
      --secret-id ${aws_secretsmanager_secret.agora_app_id.name} \
      --secret-string "YOUR_ACTUAL_VALUE"
    
    Or use AWS Console:
    1. Navigate to AWS Secrets Manager
    2. Select the secret
    3. Click "Retrieve secret value"
    4. Click "Edit"
    5. Replace the placeholder with actual value
    6. Save
    
    Secrets to update:
    - ${aws_secretsmanager_secret.agora_app_id.name}
    - ${aws_secretsmanager_secret.agora_app_certificate.name}
    - ${aws_secretsmanager_secret.aws_access_key_id.name}
    - ${aws_secretsmanager_secret.aws_secret_access_key.name}
    - ${aws_secretsmanager_secret.azure_stt_key.name}
    - ${aws_secretsmanager_secret.azure_tts_key.name}
    - ${aws_secretsmanager_secret.cosy_tts_key.name}
    - ${aws_secretsmanager_secret.elevenlabs_tts_key.name}
    - ${aws_secretsmanager_secret.openai_api_key.name}
    - ${aws_secretsmanager_secret.qwen_api_key.name}
    
    After updating secrets, restart ECS services:
    aws ecs update-service \
      --cluster ${local.name_prefix}-ecs-cluster \
      --service <service-name> \
      --force-new-deployment
    
    ========================================
  EOT
}
