# TEN-Agent Terraform 快速参考

## 🚀 快速命令

### 初始化和部署
```bash
# 初始化
./deploy.sh init

# 开发环境部署
./deploy.sh plan dev
./deploy.sh apply dev

# 生产环境部署
./deploy.sh plan prod
./deploy.sh apply prod
```

### 日常运维
```bash
# 查看服务状态
./deploy.sh status dev

# 查看日志
./deploy.sh logs dev astra-agents       # astra_agents 日志
./deploy.sh logs dev playground         # playground 日志
./deploy.sh logs dev nova-sonic         # nova sonic 日志
./deploy.sh logs dev graph-designer     # graph designer 日志

# 扩展服务
./deploy.sh scale dev astra-agents 3    # 扩展到 3 个实例

# 强制更新服务（不改变配置）
./deploy.sh update dev astra-agents     # 更新单个服务
./deploy.sh update dev all              # 更新所有服务

# 查看输出
./deploy.sh output
```

### 销毁资源
```bash
./deploy.sh destroy dev
```

## 📋 环境变量配置

创建 `.env.sh` 文件：
```bash
#!/bin/bash
export TF_VAR_agora_app_id="YOUR_VALUE"
export TF_VAR_agora_app_certificate="YOUR_VALUE"
export TF_VAR_aws_access_key_id="YOUR_VALUE"
export TF_VAR_aws_secret_access_key="YOUR_VALUE"
export TF_VAR_azure_stt_key="YOUR_VALUE"
export TF_VAR_azure_stt_region="eastus"
export TF_VAR_azure_tts_key="YOUR_VALUE"
export TF_VAR_azure_tts_region="eastus"
export TF_VAR_openai_api_key="YOUR_VALUE"
export TF_VAR_qwen_api_key="YOUR_VALUE"
export TF_VAR_cosy_tts_key="YOUR_VALUE"
export TF_VAR_elevenlabs_tts_key="YOUR_VALUE"
```

加载环境变量：
```bash
source .env.sh
```

## 🔍 Terraform 原生命令

```bash
# 初始化
terraform init

# 计划（开发环境）
terraform plan -var-file="dev.tfvars"

# 应用（开发环境）
terraform apply -var-file="dev.tfvars"

# 销毁（开发环境）
terraform destroy -var-file="dev.tfvars"

# 查看输出
terraform output
terraform output alb_dns_name
terraform output service_endpoints

# 查看状态
terraform show
terraform state list

# 格式化代码
terraform fmt

# 验证配置
terraform validate
```

## 🔧 AWS CLI 命令

```bash
# 设置变量
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw astra_agents_service_name)

# 列出服务
aws ecs list-services --cluster $CLUSTER_NAME

# 查看服务详情
aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME

# 列出任务
aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status RUNNING

# 查看任务详情
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN

# 扩展服务
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 3

# 强制重新部署
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment

# 查看日志
aws logs tail /ecs/ten-agent-dev/astra-agents --follow

# 检查目标组健康状态
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw astra_agents_target_group_arn)

# 更新密钥
SECRET_NAME=$(terraform output -raw secrets_name)
aws secretsmanager get-secret-value --secret-id $SECRET_NAME
aws secretsmanager update-secret --secret-id $SECRET_NAME --secret-string '{"KEY":"VALUE"}'
```

## 📊 服务映射

| Docker Compose 名称 | ECS 服务名称 | Terraform 输出 |
|-------------------|------------|---------------|
| astra_agents_dev | astra-agents | astra_agents_service_name |
| astra_playground_dev | astra-playground | astra_playground_service_name |
| nova_sonic_server | nova-sonic-server | nova_sonic_service_name |
| astra_graph_designer | graph-designer | graph_designer_service_name |

## 🔑 密钥列表

所有密钥都存储在 AWS Secrets Manager 中：

| 密钥名称 | 用途 | 服务 |
|---------|------|------|
| AGORA_APP_ID | Agora 应用 ID | astra_agents |
| AGORA_APP_CERTIFICATE | Agora 证书 | astra_agents |
| AWS_ACCESS_KEY_ID | AWS 访问密钥 | astra_agents, nova_sonic |
| AWS_SECRET_ACCESS_KEY | AWS 密钥 | astra_agents, nova_sonic |
| AZURE_STT_KEY | Azure 语音转文本 | astra_agents |
| AZURE_TTS_KEY | Azure 文本转语音 | astra_agents |
| OPENAI_API_KEY | OpenAI API | astra_agents |
| QWEN_API_KEY | Qwen API | astra_agents |
| COSY_TTS_KEY | Cosy TTS | astra_agents |
| ELEVENLABS_TTS_KEY | ElevenLabs TTS | astra_agents |

## 📁 文件说明

| 文件名 | 说明 |
|-------|------|
| main.tf | 主配置文件（提供者、数据源、本地变量）|
| variables.tf | 所有变量定义 |
| ecs.tf | ECS 集群、任务定义、服务配置 |
| secrets.tf | AWS Secrets Manager 配置 |
| networking.tf | VPC、子网、安全组、负载均衡器 |
| outputs.tf | 输出定义 |
| dev.tfvars | 开发环境配置 |
| prod.tfvars | 生产环境配置 |
| terraform.tfvars.example | 变量示例文件 |
| deploy.sh | 部署辅助脚本 |
| README.md | 完整文档 |
| DEPLOYMENT_GUIDE.md | 详细部署指南 |

## 🌐 端口映射

| 服务 | 容器端口 | ALB 路由 |
|-----|---------|---------|
| astra_agents | 8080 | / (默认) |
| astra_agents | 8001 | N/A |
| astra_playground | 3000 | /playground* |
| nova_sonic | 3333 | /nova-sonic* |
| graph_designer | 3000 | /graph-designer* |

## 💰 资源配置对比

### 开发环境
- astra_agents: 1 vCPU, 2 GB
- astra_playground: 0.5 vCPU, 1 GB
- nova_sonic: 0.5 vCPU, 1 GB
- graph_designer: 0.5 vCPU, 1 GB
- 副本数: 各 1 个
- 自动扩展: 关闭

### 生产环境
- astra_agents: 4 vCPU, 8 GB
- astra_playground: 1 vCPU, 2 GB
- nova_sonic: 2 vCPU, 4 GB
- graph_designer: 1 vCPU, 2 GB
- 副本数: 各 2 个
- 自动扩展: 开启（2-10 实例）

## 🆘 常见问题快速修复

### 容器无法启动
```bash
# 查看任务详情
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN

# 查看日志
aws logs tail /ecs/ten-agent-dev/astra-agents --follow
```

### 健康检查失败
```bash
# 检查目标组健康
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw astra_agents_target_group_arn)
```

### 更新密钥后重启服务
```bash
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment
```

### Terraform 状态不一致
```bash
terraform refresh -var-file="dev.tfvars"
```

## 📞 获取帮助

- 查看完整文档: `cat README.md`
- 查看部署指南: `cat DEPLOYMENT_GUIDE.md`
- 查看脚本帮助: `./deploy.sh help`

## ⚡ 一键部署（从零开始）

```bash
# 1. 配置环境变量
cat > .env.sh << 'EOF'
export TF_VAR_agora_app_id="YOUR_VALUE"
export TF_VAR_openai_api_key="YOUR_VALUE"
# ... 添加其他变量
EOF
chmod +x .env.sh
source .env.sh

# 2. 部署
./deploy.sh init
./deploy.sh apply dev

# 3. 获取访问 URL
terraform output alb_dns_name
```

访问: `http://<ALB_DNS>`
