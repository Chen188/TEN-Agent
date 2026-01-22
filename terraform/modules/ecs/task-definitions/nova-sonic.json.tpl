[
  {
    "name": "nova-sonic",
    "image": "${image_url}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3333,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {"name": "AWS_REGION", "value": "${aws_region}"}
    ],
    "secrets": [
      {"name": "AWS_ACCESS_KEY_ID", "valueFrom": "${aws_secret_arn}:AWS_ACCESS_KEY_ID::"},
      {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "${aws_secret_arn}:AWS_SECRET_ACCESS_KEY::"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "nova-sonic"
      }
    }
  }
]
