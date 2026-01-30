# TEN-Agent AWS ECS 部署指南

本文档介绍如何使用 Terraform 将 TEN-Agent 部署到 AWS ECS (Fargate)。

## 目录

- [架构概览](#架构概览)
- [前置条件](#前置条件)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [环境管理](#环境管理)
- [部署步骤](#部署步骤)
- [部署后配置](#部署后配置)
- [常见问题](#常见问题)
- [清理资源](#清理资源)

## 架构概览

该 Terraform 配置将 docker-compose.yml 中的服务部署到 AWS ECS，包括：

### 部署的服务

1. **Agents Service** (`astra_agents_dev`)
   - 主应用服务
   - 端口：8080 (API), 49483 (Graph Designer)
   - 支持多个 AI 服务：Agora, AWS Bedrock, Azure STT/TTS, OpenAI 等

2. **Playground Service** (`astra_playground_dev`)
   - 前端 Web 应用
   - 端口：3000
   - Node.js/Next.js 应用

3. **Nova Sonic Service** (`nova_sonic_server`)
   - AWS 语音处理服务
   - 端口：3333

### AWS 资源

- **ECS Cluster**: Fargate 启动类型，按需扩展
- **Application Load Balancer**: 多端口路由，支持 HTTPS
- **VPC**: 自定义 VPC，公有和私有子网
- **Secrets Manager**: 安全存储 API 密钥和敏感信息
- **CloudWatch Logs**: 集中日志管理
- **Route 53 & ACM**: 自定义域名和 SSL 证书（可选）
- **IAM Roles**: 最小权限原则的角色和策略
- **Auto Scaling**: 基于 CPU/内存的自动扩展

## 前置条件

### 必需工具

1. **Terraform** >= 1.5.0
   ```bash
   # 安装 Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform version
   ```

2. **AWS CLI** >= 2.0
   ```bash
   # 安装 AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   aws --version
   ```

### AWS 账号配置

1. **配置 AWS 凭证**
   ```bash
   aws configure
   # 输入:
   # - AWS Access Key ID
   # - AWS Secret Access Key
   # - Default region (如: us-east-1)
   # - Default output format (建议: json)
   ```

2. **验证权限**
   确保 AWS 账号有以下权限：
   - ECS、EC2、VPC 管理
   - IAM 角色创建
   - Secrets Manager 管理
   - CloudWatch Logs 管理
   - Route 53 和 ACM（如果使用自定义域名）

### 准备 API 密钥

在部署前准备好以下服务的 API 密钥：
- Agora App ID 和 Certificate (必需)
- AWS 凭证（用于 Bedrock、Polly 等）
- Azure STT/TTS Key 和 Region
- OpenAI API Key
- 其他第三方服务密钥（Cosy TTS, ElevenLabs, Qwen 等）

## 目录结构

```
TEN-Agent/
├── main.tf              # 主配置文件，Provider 配置
├── variables.tf         # 所有可配置变量
├── outputs.tf           # 输出值定义
├── ecs.tf              # ECS 集群和服务配置
├── tasks.tf            # ECS 任务定义
├── networking.tf       # VPC、子网、安全组
├── alb.tf              # 应用负载均衡器
├── secrets.tf          # AWS Secrets Manager
├── route53.tf          # Route 53 DNS 配置
├── acm.tf              # ACM SSL 证书
├── iam.tf              # IAM 角色和策略
├── terraform-README.md # 本文档
└── environments/       # 环境特定配置（可选）
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

## 快速开始

### 基础部署（开发环境）

1. **初始化 Terraform**
   ```bash
   cd /path/to/TEN-Agent
   terraform init
   ```

2. **查看执行计划**
   ```bash
   terraform plan
   ```

3. **部署基础设施**
   ```bash
   terraform apply
   # 输入 'yes' 确认部署
   ```

4. **获取输出信息**
   ```bash
   terraform output
   ```

## 配置说明

### 核心变量

在 `variables.tf` 中配置，或创建 `terraform.tfvars` 文件：

```hcl
# terraform.tfvars 示例

# 基础配置
project_name = "ten-agent"
environment  = "dev"  # 可选: dev, staging, prod
aws_region   = "us-east-1"

# ECS 配置 - 按环境调整资源
ecs_task_cpu = {
  agents     = "1024"   # dev: 512, prod: 2048
  playground = "512"
  nova_sonic = "512"
}

ecs_task_memory = {
  agents     = "2048"   # dev: 1024, prod: 4096
  playground = "1024"
  nova_sonic = "1024"
}

ecs_service_desired_count = {
  agents     = 1        # prod: 2-4
  playground = 1
  nova_sonic = 1
}

# 自定义域名（可选）
enable_custom_domain = true
domain_name          = "ten-agent.example.com"
subdomain_agents     = "api"
subdomain_playground = "app"
subdomain_nova_sonic = "sonic"

# 安全配置
enable_deletion_protection = false  # prod 环境建议设为 true
enable_ecs_exec           = true    # 启用容器调试
log_retention_days        = 7       # prod: 30

# 自动扩展
enable_autoscaling       = true
autoscaling_cpu_target   = 70
autoscaling_memory_target = 80
```

### 环境特定配置

创建环境特定的配置文件：

**environments/dev.tfvars**
```hcl
environment = "dev"
ecs_task_cpu = {
  agents     = "512"
  playground = "512"
  nova_sonic = "512"
}
ecs_task_memory = {
  agents     = "1024"
  playground = "1024"
  nova_sonic = "1024"
}
enable_deletion_protection = false
log_retention_days = 3
single_nat_gateway = true  # 成本优化
```

**environments/prod.tfvars**
```hcl
environment = "prod"
ecs_task_cpu = {
  agents     = "2048"
  playground = "1024"
  nova_sonic = "1024"
}
ecs_task_memory = {
  agents     = "4096"
  playground = "2048"
  nova_sonic = "2048"
}
ecs_service_desired_count = {
  agents     = 2
  playground = 2
  nova_sonic = 1
}
enable_deletion_protection = true
log_retention_days = 30
single_nat_gateway = false  # 高可用
enable_custom_domain = true
```

## 环境管理

### 方法 1: 使用 Terraform Workspaces

```bash
# 创建开发环境
terraform workspace new dev
terraform workspace select dev
terraform apply

# 创建生产环境
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"

# 查看当前环境
terraform workspace show

# 列出所有环境
terraform workspace list
```

### 方法 2: 使用独立的状态文件

```bash
# 开发环境
terraform apply -var-file="environments/dev.tfvars" \
  -state="terraform-dev.tfstate"

# 生产环境
terraform apply -var-file="environments/prod.tfvars" \
  -state="terraform-prod.tfstate"
```

### 方法 3: 使用独立目录

```
terraform/
├── dev/
│   ├── main.tf -> ../main.tf
│   ├── variables.tf -> ../variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf -> ../main.tf
    ├── variables.tf -> ../variables.tf
    └── terraform.tfvars
```

## 部署步骤

### 1. 准备阶段

```bash
# 克隆或进入项目目录
cd /path/to/TEN-Agent

# 创建环境配置文件
cat > terraform.tfvars << EOF
project_name = "ten-agent"
environment  = "dev"
aws_region   = "us-east-1"
EOF

# 初始化 Terraform
terraform init
```

### 2. 验证配置

```bash
# 验证语法
terraform validate

# 格式化代码
terraform fmt

# 查看执行计划
terraform plan
```

### 3. 部署基础设施

```bash
# 部署
terraform apply

# 或者使用自动批准（生产环境慎用）
terraform apply -auto-approve

# 使用特定环境配置
terraform apply -var-file="environments/prod.tfvars"
```

### 4. 等待部署完成

部署过程约 10-15 分钟，包括：
- VPC 和网络资源创建 (~2-3 分钟)
- ECS 集群创建 (~1 分钟)
- ALB 创建和配置 (~3-5 分钟)
- 域名和证书验证 (~5-10 分钟，如果启用)
- ECS 服务启动 (~2-3 分钟)

### 5. 验证部署

```bash
# 查看输出
terraform output

# 获取 ALB DNS
terraform output alb_dns_name

# 获取服务 URL
terraform output service_urls

# 查看 ECS 集群状态
aws ecs list-services --cluster $(terraform output -raw ecs_cluster_name)
```

## 部署后配置

### 1. 更新 Secrets Manager 密钥

**重要**: 部署后必须更新所有密钥，否则应用无法正常工作！

#### 方法 A: 使用 AWS CLI

```bash
# 设置变量
ENVIRONMENT="dev"
PROJECT="ten-agent"

# 更新 Agora 配置
aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/agora-app-id" \
  --secret-string "YOUR_AGORA_APP_ID"

aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/agora-app-certificate" \
  --secret-string "YOUR_AGORA_APP_CERTIFICATE"

# 更新 AWS 凭证
aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/aws-access-key-id" \
  --secret-string "YOUR_AWS_ACCESS_KEY_ID"

aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/aws-secret-access-key" \
  --secret-string "YOUR_AWS_SECRET_ACCESS_KEY"

# 更新 OpenAI API Key
aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/openai-api-key" \
  --secret-string "YOUR_OPENAI_API_KEY"

# 更新其他密钥...
```

#### 方法 B: 使用 AWS Console

1. 访问 [AWS Secrets Manager Console](https://console.aws.amazon.com/secretsmanager/)
2. 选择相应的 secret
3. 点击 "Retrieve secret value"
4. 点击 "Edit"
5. 替换占位符为实际值
6. 点击 "Save"

#### 批量更新脚本

创建 `update-secrets.sh`:

```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
PROJECT="ten-agent"

echo "更新 ${PROJECT}-${ENVIRONMENT} 的 secrets..."

# 从 .env 文件读取（确保 .env 不提交到 git）
source .env

aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/agora-app-id" \
  --secret-string "${AGORA_APP_ID}"

aws secretsmanager put-secret-value \
  --secret-id "${PROJECT}-${ENVIRONMENT}/agora-app-certificate" \
  --secret-string "${AGORA_APP_CERTIFICATE}"

# ... 添加其他密钥

echo "Secrets 更新完成！"
```

使用:
```bash
chmod +x update-secrets.sh
./update-secrets.sh dev
```

### 2. 重启 ECS 服务以应用新密钥

```bash
# 获取集群和服务名称
CLUSTER=$(terraform output -raw ecs_cluster_name)

# 强制重新部署所有服务
aws ecs update-service \
  --cluster ${CLUSTER} \
  --service ten-agent-dev-agents \
  --force-new-deployment

aws ecs update-service \
  --cluster ${CLUSTER} \
  --service ten-agent-dev-playground \
  --force-new-deployment

aws ecs update-service \
  --cluster ${CLUSTER} \
  --service ten-agent-dev-nova-sonic \
  --force-new-deployment

# 等待服务稳定
aws ecs wait services-stable --cluster ${CLUSTER} --services \
  ten-agent-dev-agents \
  ten-agent-dev-playground \
  ten-agent-dev-nova-sonic
```

### 3. 配置域名（如果使用自定义域名）

如果创建了新的 Route 53 托管区域：

```bash
# 获取 nameservers
terraform output route53_nameservers

# 输出示例：
# [
#   "ns-1234.awsdns-12.org",
#   "ns-5678.awsdns-34.com",
#   "ns-9012.awsdns-56.net",
#   "ns-3456.awsdns-78.co.uk"
# ]
```

在域名注册商处更新 nameservers，指向上述 NS 记录。

### 4. 验证部署

```bash
# 获取服务 URL
terraform output service_urls

# 测试 Agents API
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://${ALB_DNS}:8080/health

# 测试 Playground
curl http://${ALB_DNS}:3000

# 测试 Nova Sonic
curl http://${ALB_DNS}:3333/health

# 如果使用自定义域名
curl https://api.your-domain.com/health
curl https://app.your-domain.com
```

### 5. 查看日志

```bash
# 查看 CloudWatch 日志组
aws logs tail /ecs/ten-agent-dev/agents --follow

# 查看特定服务的日志
aws logs tail /ecs/ten-agent-dev/playground --follow --since 10m

# 在 AWS Console 查看
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups"
```

## 常见问题

### 1. 任务无法启动

**症状**: ECS 服务显示任务不断启动和停止

**排查步骤**:
```bash
# 查看服务事件
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services ten-agent-dev-agents \
  --query 'services[0].events[0:5]'

# 查看任务详情
aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name ten-agent-dev-agents

# 查看任务停止原因
aws ecs describe-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --tasks <task-arn> \
  --query 'tasks[0].stoppedReason'
```

**常见原因**:
- Secrets 未更新或值不正确
- 容器健康检查失败
- 内存或 CPU 配置不足
- 镜像拉取失败

### 2. 无法访问服务

**检查 ALB 和目标组**:
```bash
# 查看目标组健康状态
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -json target_group_arns | jq -r '.agents')

# 查看 ALB 监听器
aws elbv2 describe-listeners \
  --load-balancer-arn $(terraform output -raw alb_arn)
```

**检查安全组**:
- 确保 ALB 安全组允许入站流量
- 确保 ECS 任务安全组允许来自 ALB 的流量

### 3. 证书验证失败

**DNS 验证**:
```bash
# 查看证书状态
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn)

# 检查 DNS 记录
dig _<validation-name>.your-domain.com CNAME
```

**解决方案**:
- 确保域名 nameservers 正确指向 Route 53
- 等待 DNS 传播（可能需要几分钟到几小时）
- 检查 Route 53 中验证记录是否正确创建

### 4. 成本优化

**减少开发环境成本**:

```hcl
# terraform.tfvars for dev
single_nat_gateway = true           # 使用单个 NAT Gateway
ecs_task_cpu = { agents = "512" }  # 减少 CPU
ecs_task_memory = { agents = "1024" }  # 减少内存
log_retention_days = 3              # 减少日志保留
enable_container_insights = false   # 禁用 Container Insights
```

**使用 Fargate Spot**:

修改 `ecs.tf` 中的容量提供者策略：
```hcl
default_capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  weight            = 1
  base              = 0
}
```

### 5. 调试容器

**启用 ECS Exec**:
```hcl
# terraform.tfvars
enable_ecs_exec = true
```

**连接到容器**:
```bash
# 获取任务 ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name ten-agent-dev-agents \
  --query 'taskArns[0]' --output text)

# 执行命令
aws ecs execute-command \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --task ${TASK_ARN} \
  --container agents \
  --interactive \
  --command "/bin/bash"
```

## 高级配置

### 1. 启用 ALB 访问日志

```hcl
# terraform.tfvars
enable_alb_access_logs = true
alb_access_logs_bucket = "my-alb-logs-bucket"
```

### 2. 配置 VPC Endpoints

在 `networking.tf` 中取消注释 VPC Endpoints 配置，以减少 NAT Gateway 流量费用。

### 3. 使用私有 Docker 镜像

更新 `variables.tf` 中的镜像变量：
```hcl
agents_image = "<account-id>.dkr.ecr.<region>.amazonaws.com/ten-agent:latest"
```

确保 ECS 任务执行角色有 ECR 访问权限。

### 4. 配置自动扩展策略

```hcl
# terraform.tfvars
enable_autoscaling = true
ecs_service_min_capacity = {
  agents     = 1
  playground = 1
  nova_sonic = 1
}
ecs_service_max_capacity = {
  agents     = 10
  playground = 5
  nova_sonic = 3
}
autoscaling_cpu_target = 70
autoscaling_memory_target = 80
```

### 5. 多区域部署

创建多个 Terraform 配置目录，每个区域一个：
```bash
terraform/
├── us-east-1/
│   └── main.tf (provider region = "us-east-1")
├── eu-west-1/
│   └── main.tf (provider region = "eu-west-1")
└── ap-southeast-1/
    └── main.tf (provider region = "ap-southeast-1")
```

## 监控和告警

### 1. 查看 CloudWatch 指标

```bash
# ECS 服务 CPU 使用率
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=ten-agent-dev-agents \
               Name=ClusterName,Value=ten-agent-dev-ecs-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### 2. 创建告警

添加到 Terraform 配置：
```hcl
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ECS CPU utilization too high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.agents.name
  }
}
```

## 清理资源

### 完全删除

```bash
# 销毁所有资源
terraform destroy

# 或使用环境特定配置
terraform destroy -var-file="environments/dev.tfvars"

# 自动批准（慎用）
terraform destroy -auto-approve
```

### 保留某些资源

在资源中添加 `prevent_destroy` 生命周期：
```hcl
resource "aws_s3_bucket" "important" {
  lifecycle {
    prevent_destroy = true
  }
}
```

### 清理顺序

Terraform 会自动处理依赖关系，但手动清理顺序：
1. ECS 服务
2. ECS 任务定义
3. ALB 和目标组
4. ECS 集群
5. NAT Gateways 和 EIPs
6. 子网和路由表
7. VPC

### 注意事项

- **Secrets Manager**: 有 7 天恢复窗口（默认），立即删除设置 `recovery_window_in_days = 0`
- **CloudWatch Logs**: 日志组不会自动删除，需要手动清理
- **S3 Buckets**: 必须为空才能删除
- **Route 53**: 托管区域删除前需要删除所有记录（NS 和 SOA 除外）

## 故障排查清单

### 部署失败

- [ ] 检查 Terraform 版本
- [ ] 验证 AWS 凭证
- [ ] 检查 AWS 配额限制
- [ ] 查看 Terraform 错误消息
- [ ] 检查资源命名冲突

### 服务无法启动

- [ ] 查看 ECS 服务事件
- [ ] 检查 CloudWatch 日志
- [ ] 验证 Secrets Manager 密钥
- [ ] 检查 IAM 角色权限
- [ ] 验证容器镜像可访问

### 网络问题

- [ ] 检查安全组规则
- [ ] 验证子网路由表
- [ ] 确认 NAT Gateway 配置
- [ ] 检查网络 ACL
- [ ] 验证 ALB 监听器配置

### 域名/证书问题

- [ ] 检查 Route 53 nameservers
- [ ] 验证 ACM 证书状态
- [ ] 确认 DNS 记录正确
- [ ] 检查证书验证记录
- [ ] 等待 DNS 传播

## 最佳实践

1. **使用远程状态存储**: 配置 S3 backend 存储 Terraform 状态
2. **启用状态锁定**: 使用 DynamoDB 防止并发修改
3. **使用变量文件**: 不要硬编码敏感信息
4. **标签策略**: 为所有资源添加统一标签
5. **模块化**: 将可重用组件提取为模块
6. **版本控制**: 锁定 provider 和模块版本
7. **CI/CD 集成**: 使用 GitOps 工作流
8. **安全扫描**: 使用 tfsec 或 checkov 扫描配置
9. **文档更新**: 保持文档与代码同步
10. **定期备份**: 导出 Terraform 状态和配置

## 参考资源

- [Terraform AWS Provider 文档](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS 最佳实践](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [AWS Fargate 定价](https://aws.amazon.com/fargate/pricing/)
- [TEN-Agent 项目](https://github.com/ten-framework/TEN-Agent)

## 支持

如有问题或需要帮助：
1. 查看此文档的故障排查部分
2. 检查 AWS CloudWatch 日志
3. 查看 Terraform 计划输出
4. 提交 Issue 到项目仓库

---

**版本**: 1.0.0
**最后更新**: 2024-12-16
