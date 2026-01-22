# Secrets Module Outputs
# Exposes secret ARNs and IAM policy for use by other modules

# Map of secret name to ARN for ECS task definitions
# Requirement 3.5: ECS task definitions use Secrets Manager ARNs with valueFrom syntax
output "secret_arns" {
  description = "Map of secret name to ARN for use in ECS task definitions"
  value = {
    agora           = aws_secretsmanager_secret.agora.arn
    aws_credentials = aws_secretsmanager_secret.aws_credentials.arn
    tts             = aws_secretsmanager_secret.tts.arn
    cognito         = aws_secretsmanager_secret.cognito.arn
  }
}

# IAM policy ARN for ECS task execution role
# Requirement 3.6: IAM policies allowing ECS tasks to read from Secrets Manager
output "secrets_policy_arn" {
  description = "IAM policy ARN for reading secrets from Secrets Manager"
  value       = aws_iam_policy.secrets_read.arn
}

# Individual secret ARNs for convenience
output "agora_secret_arn" {
  description = "ARN of the Agora credentials secret"
  value       = aws_secretsmanager_secret.agora.arn
}

output "aws_credentials_secret_arn" {
  description = "ARN of the AWS credentials secret"
  value       = aws_secretsmanager_secret.aws_credentials.arn
}

output "tts_secret_arn" {
  description = "ARN of the TTS API keys secret"
  value       = aws_secretsmanager_secret.tts.arn
}

output "cognito_secret_arn" {
  description = "ARN of the Cognito configuration secret"
  value       = aws_secretsmanager_secret.cognito.arn
}
