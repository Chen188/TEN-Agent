# TEN-Agent AWS ECS 部署指南

本指南提供详细的分步部署说明。

## 📋 部署前检查清单

### 1. AWS 账户准备

- [ ] 拥有有效的 AWS 账户
- [ ] 已安装并配置 AWS CLI
- [ ] 具有必要的 IAM 权限
- [ ] 已选择部署区域

```bash
# 验证 AWS 配置
aws sts get-caller-identity
aws configure list
```

### 2. 工具安装

- [ ] Terraform >= 1.0
- [ ] AWS CLI >= 2.0
- [ ] jq（可选，用于处理 JSON）

```bash
# 检查版本
terraform --version
aws --version
jq --version
```

### 3. API 密钥准备

- [ ] Agora App ID 和 Certificate
- [ ] AWS Access Key ID 和 Secret Access Key（应用使用）
- [ ] Azure Speech Services 密钥
- [ ] OpenAI API Key
- [ ] Qwen API Key
- [ ] 其他可选的 TTS 服务密钥

## 🚀 部署步骤

### 步骤 1: 准备项目目录

```bash
cd /projects/sandbox/TEN-Agent/terraform
```

### 步骤 2: 创建环境变量文件

创建一个包含所有敏感信息的脚本文件（不要提交到版本控制）：

```bash
cat > .env.sh << 'EOF'
#!/bin/bash

# Agora 配置
export TF_VAR_agora_app_id="YOUR_AGORA_APP_ID"
export TF_VAR_agora_app_certificate="YOUR_AGORA_APP_CERTIFICATE"

# AWS 配置（用于应用程序）
export TF_VAR_aws_access_key_id="YOUR_APP_AWS_ACCESS_KEY_ID"
export TF_VAR_aws_secret_access_key="YOUR_APP_AWS_SECRET_ACCESS_KEY"
export TF_VAR_aws_bedrock_model="anthropic.claude-v2"

# Azure 配置
export TF_VAR_azure_stt_key="YOUR_AZURE_STT_KEY"
export TF_VAR_azure_stt_region="eastus"
export TF_VAR_azure_tts_key="YOUR_AZURE_TTS_KEY"
export TF_VAR_azure_tts_region="eastus"

# OpenAI 配置
export TF_VAR_openai_api_key="YOUR_OPENAI_API_KEY"
export TF_VAR_openai_model="gpt-4"
export TF_VAR_openai_base_url=""
export TF_VAR_openai_proxy_url=""

# Qwen 配置
export TF_VAR_qwen_api_key="YOUR_QWEN_API_KEY"

# TTS 服务配置（可选）
export TF_VAR_cosy_tts_key="YOUR_COSY_TTS_KEY"
export TF_VAR_elevenlabs_tts_key="YOUR_ELEVENLABS_TTS_KEY"

# LiteLLM 配置（可选）
export TF_VAR_litellm_model=""

echo "✅ 环境变量已设置"
EOF

chmod +x .env.sh
```

### 步骤 3: 加载环境变量

```bash
source .env.sh
```

### 步骤 4: 初始化 Terraform

```bash
terraform init
```

预期输出：
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 步骤 5: 验证配置

```bash
terraform validate
```

预期输出：
```
Success! The configuration is valid.
```

### 步骤 6: 查看部署计划

#### 开发环境

```bash
terraform plan -var-file="dev.tfvars" -out=dev.tfplan
```

#### 生产环境

```bash
terraform plan -var-file="prod.tfvars" -out=prod.tfplan
```

仔细检查计划输出，确认要创建的资源。

### 步骤 7: 应用配置

#### 开发环境

```bash
terraform apply dev.tfplan
```

#### 生产环境

```bash
terraform apply prod.tfplan
```

部署过程通常需要 10-15 分钟。

### 步骤 8: 验证部署

```bash
# 获取输出信息
terraform output

# 获取 ALB DNS 名称
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "ALB DNS: $ALB_DNS"

# 测试服务
curl -I http://$ALB_DNS
```

### 步骤 9: 访问服务

```bash
# 获取所有服务端点
terraform output service_endpoints

# 访问各个服务
# - 主服务: http://<ALB_DNS>
# - Playground: http://<ALB_DNS>/playground
# - Nova Sonic: http://<ALB_DNS>/nova-sonic
# - Graph Designer: http://<ALB_DNS>/graph-designer
```

## 🔍 部署后检查

### 1. 检查 ECS 服务状态

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)

# 列出所有服务
aws ecs list-services --cluster $CLUSTER_NAME

# 查看服务详情
aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $(terraform output -raw astra_agents_service_name)
```

### 2. 检查任务运行状态

```bash
# 列出运行中的任务
aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status RUNNING

# 查看任务详情
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status RUNNING --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN
```

### 3. 检查健康状态

```bash
# 检查目标组健康状态
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw astra_agents_target_group_arn)
```

### 4. 查看日志

```bash
# 查看 astra_agents 日志
aws logs tail $(terraform output -raw astra_agents_log_group) --follow

# 查看 playground 日志
aws logs tail $(terraform output -raw astra_playground_log_group) --follow

# 查看 nova_sonic 日志
aws logs tail $(terraform output -raw nova_sonic_log_group) --follow

# 查看 graph_designer 日志
aws logs tail $(terraform output -raw graph_designer_log_group) --follow
```

## 🔄 更新部署

### 更新配置

1. 修改 `.tfvars` 文件或环境变量
2. 查看变更计划：
   ```bash
   terraform plan -var-file="dev.tfvars"
   ```
3. 应用变更：
   ```bash
   terraform apply -var-file="dev.tfvars"
   ```

### 更新容器镜像

1. 修改变量文件中的镜像标签
2. 应用配置：
   ```bash
   terraform apply -var-file="dev.tfvars"
   ```

### 强制重新部署（不改变配置）

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw astra_agents_service_name)

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment
```

## 🔧 常见操作

### 手动扩展服务

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw astra_agents_service_name)

# 扩展到 3 个实例
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --desired-count 3
```

### 更新密钥

```bash
SECRET_NAME=$(terraform output -raw secrets_name)

# 更新单个密钥
aws secretsmanager update-secret \
  --secret-id $SECRET_NAME \
  --secret-string '{
    "OPENAI_API_KEY": "new-key-value",
    "AGORA_APP_ID": "existing-value",
    ...
  }'

# 重启服务以使用新密钥
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment
```

### 查看成本

```bash
# 使用 AWS Cost Explorer API
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project
```

## 🛑 停止服务

### 临时停止（保留基础设施）

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)

# 将所有服务的期望数量设置为 0
aws ecs update-service --cluster $CLUSTER_NAME \
  --service $(terraform output -raw astra_agents_service_name) \
  --desired-count 0

aws ecs update-service --cluster $CLUSTER_NAME \
  --service $(terraform output -raw astra_playground_service_name) \
  --desired-count 0

aws ecs update-service --cluster $CLUSTER_NAME \
  --service $(terraform output -raw nova_sonic_service_name) \
  --desired-count 0

aws ecs update-service --cluster $CLUSTER_NAME \
  --service $(terraform output -raw graph_designer_service_name) \
  --desired-count 0
```

### 完全销毁

```bash
# 销毁所有资源
terraform destroy -var-file="dev.tfvars"
```

⚠️ **警告**：这将删除所有资源，包括日志和配置。

## 🔒 安全建议

1. **不要提交敏感信息**
   ```bash
   # 确保 .gitignore 包含：
   # *.tfvars（除了示例文件）
   # .env.sh
   # *.env
   ```

2. **使用 IAM 角色**
   - 生产环境建议使用 IAM 角色而非长期密钥
   - 启用 MFA

3. **限制网络访问**
   ```hcl
   # 在 prod.tfvars 中限制 ALB 访问
   alb_ingress_cidr_blocks = ["YOUR_OFFICE_IP/32"]
   ```

4. **启用日志审计**
   ```bash
   # 启用 CloudTrail
   aws cloudtrail create-trail --name ten-agent-trail \
     --s3-bucket-name your-cloudtrail-bucket
   ```

## 📊 监控设置

### 创建 CloudWatch 告警

```bash
# CPU 使用率告警
aws cloudwatch put-metric-alarm \
  --alarm-name ten-agent-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# 内存使用率告警
aws cloudwatch put-metric-alarm \
  --alarm-name ten-agent-high-memory \
  --alarm-description "Alert when memory exceeds 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### 配置日志洞察查询

```bash
# 在 CloudWatch Logs Insights 中运行查询
# 查询错误日志
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

## 🆘 故障排查

### 问题：容器无法启动

```bash
# 1. 查看任务状态
aws ecs describe-tasks \
  --cluster $CLUSTER_NAME \
  --tasks <task-id> \
  --query 'tasks[0].{status:lastStatus,reason:stoppedReason,containers:containers[0].reason}'

# 2. 查看容器日志
aws logs tail /ecs/ten-agent-dev/astra-agents --follow
```

### 问题：无法访问服务

```bash
# 1. 检查安全组
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw alb_security_group_id)

# 2. 检查目标组
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw astra_agents_target_group_arn)

# 3. 测试从 VPC 内部访问
# 如果外部无法访问但容器运行正常，可能是安全组或路由问题
```

### 问题：Terraform 状态不一致

```bash
# 刷新状态
terraform refresh -var-file="dev.tfvars"

# 如果问题持续，可能需要导入资源
terraform import aws_ecs_cluster.main <cluster-name>
```

## 📞 获取帮助

- 查看 CloudWatch 日志
- 检查 ECS 服务事件
- 查看 AWS 支持中心
- 参考 README.md 获取更多信息

## ✅ 部署验证检查清单

部署完成后，确认以下项目：

- [ ] 所有 ECS 服务状态为 ACTIVE
- [ ] 所有任务状态为 RUNNING
- [ ] 目标组健康检查通过
- [ ] ALB 可以访问
- [ ] 日志正常写入 CloudWatch
- [ ] 密钥正确加载到容器
- [ ] 监控和告警已配置

## 🎉 部署完成

恭喜！您已成功部署 TEN-Agent 到 AWS ECS。

访问服务：`http://<YOUR_ALB_DNS>`
