# Secrets Module Variables
# Defines input variables for the Secrets module

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "agora_credentials" {
  description = "Agora App ID and Certificate for real-time communication"
  type = object({
    app_id          = string
    app_certificate = string
  })
  sensitive = true
}

variable "aws_credentials" {
  description = "AWS Access Key and Secret for service authentication"
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  sensitive = true
}

variable "tts_keys" {
  description = "TTS API keys for Cosy and ElevenLabs"
  type = object({
    cosy_tts_key       = string
    elevenlabs_tts_key = string
  })
  sensitive = true
  default = {
    cosy_tts_key       = ""
    elevenlabs_tts_key = ""
  }
}

variable "cognito_config" {
  description = "Cognito OAuth configuration for authentication"
  type = object({
    client_id     = string
    client_secret = string
    user_pool_id  = string
    domain        = string
    region        = string
  })
  sensitive = true
  default = {
    client_id     = ""
    client_secret = ""
    user_pool_id  = ""
    domain        = ""
    region        = "us-east-1"
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
