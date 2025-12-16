# TEN-Agent Terraform 快速开始指南

## 🚀 5 分钟快速部署

### 前置条件检查

```bash
# 检查工具是否安装
terraform version  # 需要 >= 1.5.0
aws --version      # 需要 AWS CLI v2
aws sts get-caller-identity  # 验证 AWS 凭证
```

### 快速部署步骤

```bash
# 1. 进入项目目录
cd /path/to/TEN-Agent

# 2. 复制配置文件
cp terraform.tfvars.example terraform.tfvars

# 3. 编辑配置（可选，使用默认值也可以）
vim terraform.tfvars

# 4. 初始化 Terraform
terraform init

# 5. 查看执行计划
terraform plan

# 6. 部署！
terraform apply

# 7. 查看部署信息
terraform output
```

### 使用辅助脚本（推荐）

```bash
# 初始化
./deploy.sh init

# 部署开发环境
./deploy.sh apply -e dev

# 查看状态
./deploy.sh status -e dev

# 查看日志
./deploy.sh logs -e dev agents

# 验证部署
./validate-deployment.sh dev
```

## 📋 部署后必做事项

### 1. 更新 Secrets Manager 密钥

**重要**: 必须更新密钥，否则应用无法工作！

```bash
# 方法 1: 使用 AWS CLI
aws secretsmanager put-secret-value \
  --secret-id ten-agent-dev/agora-app-id \
  --secret-string "YOUR_ACTUAL_AGORA_APP_ID"

# 方法 2: 使用 AWS Console
# 访问 https://console.aws.amazon.com/secretsmanager/
# 选择密钥 -> Edit -> 替换值 -> Save

# 方法 3: 使用辅助脚本（需要先创建 .env 文件）
./deploy.sh secrets -e dev
```

### 2. 重启服务以应用新密钥

```bash
# 使用辅助脚本
./deploy.sh restart -e dev

# 或使用 AWS CLI
CLUSTER=$(terraform output -raw ecs_cluster_name)
aws ecs update-service --cluster $CLUSTER \
  --service ten-agent-dev-agents --force-new-deployment
```

### 3. 测试服务

```bash
# 获取 ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name)

# 测试各服务
curl http://${ALB_DNS}:8080/health  # Agents API
curl http://${ALB_DNS}:3000         # Playground
curl http://${ALB_DNS}:3333/health  # Nova Sonic
```

## 🔧 常用命令

### Terraform 基础命令

```bash
# 初始化（首次使用或更新 provider）
terraform init

# 格式化代码
terraform fmt

# 验证配置
terraform validate

# 查看执行计划
terraform plan

# 部署
terraform apply

# 销毁
terraform destroy

# 查看输出
terraform output
terraform output -json
terraform output alb_dns_name
```

### 使用环境配置文件

```bash
# 开发环境
terraform apply -var-file="environments/dev.tfvars"

# 预发布环境
terraform apply -var-file="environments/staging.tfvars"

# 生产环境
terraform apply -var-file="environments/prod.tfvars"
```

### 使用 Terraform Workspaces

```bash
# 创建并切换到开发环境
terraform workspace new dev
terraform workspace select dev

# 创建生产环境
terraform workspace new prod
terraform workspace select prod

# 查看当前环境
terraform workspace show

# 列出所有环境
terraform workspace list
```

### AWS CLI 常用命令

```bash
# ECS 服务状态
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services ten-agent-dev-agents

# 查看任务
aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name)

# 查看日志
aws logs tail /ecs/ten-agent-dev/agents --follow

# 更新密钥
aws secretsmanager put-secret-value \
  --secret-id ten-agent-dev/openai-api-key \
  --secret-string "sk-..."

# 重启服务
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service ten-agent-dev-agents \
  --force-new-deployment
```

## 📊 监控和调试

### 查看服务状态

```bash
# 使用辅助脚本
./deploy.sh status -e dev

# 或使用 AWS CLI
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services ten-agent-dev-agents \
  --query 'services[0].[serviceName,status,runningCount,desiredCount]'
```

### 查看日志

```bash
# 使用辅助脚本（实时跟踪）
./deploy.sh logs -e dev agents

# 使用 AWS CLI
aws logs tail /ecs/ten-agent-dev/agents --follow --since 10m

# 查看特定时间段
aws logs filter-log-events \
  --log-group-name /ecs/ten-agent-dev/agents \
  --start-time $(date -d '1 hour ago' +%s)000
```

### 调试容器（如果启用了 ECS Exec）

```bash
# 获取任务 ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name ten-agent-dev-agents \
  --query 'taskArns[0]' --output text)

# 连接到容器
aws ecs execute-command \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --task $TASK_ARN \
  --container agents \
  --interactive \
  --command "/bin/bash"
```

## 🌍 环境管理

### 开发环境（低成本配置）

```hcl
# environments/dev.tfvars
environment = "dev"
single_nat_gateway = true
ecs_task_cpu = { agents = "512" }
ecs_task_memory = { agents = "1024" }
log_retention_days = 3
enable_container_insights = false
```

### 生产环境（高可用配置）

```hcl
# environments/prod.tfvars
environment = "prod"
single_nat_gateway = false
availability_zones_count = 3
ecs_task_cpu = { agents = "2048" }
ecs_task_memory = { agents = "4096" }
ecs_service_desired_count = { agents = 2 }
log_retention_days = 30
enable_deletion_protection = true
enable_custom_domain = true
```

## 🔐 安全最佳实践

### 1. 使用远程状态存储

```hcl
# main.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "ten-agent/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

初始化：
```bash
terraform init -backend-config="bucket=your-bucket"
```

### 2. 不要提交敏感文件

确保 `.gitignore` 包含：
```
*.tfvars
.env
*.tfstate
.terraform/
```

### 3. 使用最小权限原则

为 CI/CD 创建专用 IAM 用户，仅授予必要权限。

### 4. 定期轮换密钥

```bash
# 更新所有密钥
./deploy.sh secrets -e prod
./deploy.sh restart -e prod
```

## 💰 成本优化

### 开发环境节省成本

```hcl
# 使用单个 NAT Gateway
single_nat_gateway = true

# 使用较小的任务规格
ecs_task_cpu = { agents = "512" }
ecs_task_memory = { agents = "1024" }

# 禁用 Container Insights
enable_container_insights = false

# 减少日志保留时间
log_retention_days = 3

# 使用 Fargate Spot (ecs.tf 中配置)
```

### 非工作时间关闭开发环境

```bash
# 缩容到 0
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service ten-agent-dev-agents \
  --desired-count 0

# 恢复
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service ten-agent-dev-agents \
  --desired-count 1
```

## 🆘 故障排查

### 任务无法启动

```bash
# 查看服务事件
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services ten-agent-dev-agents \
  --query 'services[0].events[0:5]'

# 查看任务停止原因
TASK_ARN=$(aws ecs list-tasks --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name ten-agent-dev-agents --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $(terraform output -raw ecs_cluster_name) \
  --tasks $TASK_ARN --query 'tasks[0].stoppedReason'
```

### ALB 健康检查失败

```bash
# 查看目标组健康状态
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -json target_group_arns | jq -r '.agents')

# 检查安全组规则
aws ec2 describe-security-groups \
  --group-ids $(terraform output -json security_group_ids)
```

### 证书验证失败

```bash
# 查看证书状态
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn)

# 检查 DNS 记录
dig _validation-string.your-domain.com CNAME
```

## 📚 更多资源

- 完整文档: [terraform-README.md](terraform-README.md)
- 辅助脚本: [deploy.sh](deploy.sh)
- 验证脚本: [validate-deployment.sh](validate-deployment.sh)
- AWS ECS 文档: https://docs.aws.amazon.com/ecs/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/

## 🎯 下一步

1. ✅ 部署基础设施
2. ✅ 更新 Secrets Manager 密钥
3. ✅ 重启服务
4. ✅ 验证部署
5. ⚙️ 配置自定义域名（可选）
6. 📊 设置监控告警（可选）
7. 🔄 配置 CI/CD（可选）

---

**提示**: 使用 `./deploy.sh -h` 查看所有可用命令
