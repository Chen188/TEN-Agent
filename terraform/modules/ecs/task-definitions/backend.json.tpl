[
  {
    "name": "backend",
    "image": "${image_url}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {"name": "AWS_REGION", "value": "${aws_region}"},
      {"name": "AWS_BEDROCK_MODEL", "value": "${bedrock_model}"},
      {"name": "OAUTH_ENABLED", "value": "${oauth_enabled}"},
      {"name": "FRONTEND_URL", "value": "${frontend_url}"},
      {"name": "OAUTH_REDIRECT_URL", "value": "${oauth_redirect_url}"},
      {"name": "NOVA_SONIC_URL", "value": "http://nova-sonic.local:3333"},
      {"name": "WORKERS_MAX", "value": "100"},
      {"name": "WORKER_QUIT_TIMEOUT_SECONDES", "value": "60"},
      {"name": "LOG_PATH", "value": "/tmp"},
      {"name": "SERVER_PORT", "value": "8080"}
    ],
    "secrets": [
      {"name": "AGORA_APP_ID", "valueFrom": "${agora_secret_arn}:AGORA_APP_ID::"},
      {"name": "AGORA_APP_CERTIFICATE", "valueFrom": "${agora_secret_arn}:AGORA_APP_CERTIFICATE::"},
      {"name": "AWS_ACCESS_KEY_ID", "valueFrom": "${aws_secret_arn}:AWS_ACCESS_KEY_ID::"},
      {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "${aws_secret_arn}:AWS_SECRET_ACCESS_KEY::"},
      {"name": "COSY_TTS_KEY", "valueFrom": "${tts_secret_arn}:COSY_TTS_KEY::"},
      {"name": "ELEVENLABS_TTS_KEY", "valueFrom": "${tts_secret_arn}:ELEVENLABS_TTS_KEY::"},
      {"name": "COGNITO_CLIENT_ID", "valueFrom": "${cognito_secret_arn}:COGNITO_CLIENT_ID::"},
      {"name": "COGNITO_CLIENT_SECRET", "valueFrom": "${cognito_secret_arn}:COGNITO_CLIENT_SECRET::"},
      {"name": "COGNITO_USER_POOL_ID", "valueFrom": "${cognito_secret_arn}:COGNITO_USER_POOL_ID::"},
      {"name": "COGNITO_DOMAIN", "valueFrom": "${cognito_secret_arn}:COGNITO_DOMAIN::"},
      {"name": "COGNITO_REGION", "valueFrom": "${cognito_secret_arn}:COGNITO_REGION::"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "backend"
      }
    }
  }
]
