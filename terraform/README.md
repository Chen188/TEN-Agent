# TEN-Agent AWS ECS Terraform Configuration

本 Terraform 配置可将 TEN-Agent 应用程序部署到 AWS ECS（Elastic Container Service）使用 Fargate 启动类型。

## 📋 目录

- [架构概述](#架构概述)
- [服务说明](#服务说明)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [部署步骤](#部署步骤)
- [管理和运维](#管理和运维)
- [故障排查](#故障排查)
- [成本估算](#成本估算)
- [安全最佳实践](#安全最佳实践)

## 🏗️ 架构概述

此 Terraform 配置创建以下 AWS 资源：

- **VPC 网络**：包含公有和私有子网的完整 VPC 设置
- **ECS 集群**：使用 Fargate 运行容器化服务
- **Application Load Balancer**：用于流量分发和服务暴露
- **AWS Secrets Manager**：安全存储敏感配置
- **CloudWatch Logs**：集中化日志收集
- **IAM 角色和策略**：安全的服务权限管理

### 部署的服务

1. **astra_agents** - TEN-Agent 主服务
2. **astra_playground** - Web UI 界面
3. **nova_sonic_server** - Nova Sonic 服务器
4. **astra_graph_designer** - 图形设计器界面

## 📦 服务说明

### 1. astra_agents_dev
- **镜像**: `ghcr.io/ten-framework/astra_agents_build:0.3.5`
- **端口**: 8080（主服务）, 8001（图形设计器服务器）
- **环境变量**: 需要多个 API 密钥（Agora、AWS、Azure、OpenAI 等）
- **资源**: 2-4 vCPU, 4-8 GB 内存（可配置）

### 2. astra_playground_dev
- **镜像**: `node:20-alpine`
- **端口**: 3000
- **环境变量**: 无
- **资源**: 0.5-1 vCPU, 1-2 GB 内存（可配置）

### 3. nova_sonic_server
- **镜像**: `ghcr.io/chen188/nova-sonic-server:latest`
- **端口**: 3333
- **环境变量**: AWS 凭证
- **资源**: 1-2 vCPU, 2-4 GB 内存（可配置）

### 4. astra_graph_designer
- **镜像**: `agoraio/astra_graph_designer:0.1.0`
- **端口**: 3001（映射到容器的 3000）
- **环境变量**: 无
- **资源**: 0.5-1 vCPU, 1-2 GB 内存（可配置）

## 🔧 前置要求

### 必需工具
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) 已配置
- 有效的 AWS 账户和凭证

### AWS 权限要求
需要以下 AWS 服务的权限：
- EC2（VPC、Subnets、Security Groups）
- ECS（Clusters、Services、Task Definitions）
- IAM（Roles、Policies）
- CloudWatch（Log Groups）
- Secrets Manager
- Elastic Load Balancing
- Application Auto Scaling

### API 密钥和凭证
需要准备以下服务的 API 密钥：
- Agora App ID 和 Certificate
- AWS Access Key ID 和 Secret Access Key（用于应用程序）
- Azure Speech Services（STT/TTS）
- OpenAI API Key
- Qwen API Key
- Cosy TTS Key（可选）
- ElevenLabs TTS Key（可选）

## 🚀 快速开始

### 1. 克隆配置

```bash
cd /path/to/TEN-Agent/terraform
```

### 2. 配置环境变量

为了安全起见，建议使用环境变量提供敏感信息：

```bash
# 创建环境变量脚本（不要提交到版本控制）
cat > .env.sh << 'EOF'
#!/bin/bash
export TF_VAR_agora_app_id="YOUR_AGORA_APP_ID"
export TF_VAR_agora_app_certificate="YOUR_AGORA_APP_CERTIFICATE"
export TF_VAR_aws_access_key_id="YOUR_AWS_ACCESS_KEY_ID"
export TF_VAR_aws_secret_access_key="YOUR_AWS_SECRET_ACCESS_KEY"
export TF_VAR_azure_stt_key="YOUR_AZURE_STT_KEY"
export TF_VAR_azure_stt_region="YOUR_AZURE_STT_REGION"
export TF_VAR_azure_tts_key="YOUR_AZURE_TTS_KEY"
export TF_VAR_azure_tts_region="YOUR_AZURE_TTS_REGION"
export TF_VAR_openai_api_key="YOUR_OPENAI_API_KEY"
export TF_VAR_qwen_api_key="YOUR_QWEN_API_KEY"
export TF_VAR_cosy_tts_key="YOUR_COSY_TTS_KEY"
export TF_VAR_elevenlabs_tts_key="YOUR_ELEVENLABS_TTS_KEY"
EOF

chmod +x .env.sh
source .env.sh
```

### 3. 初始化 Terraform

```bash
terraform init
```

### 4. 选择环境并部署

#### 开发环境部署

```bash
# 查看计划
terraform plan -var-file="dev.tfvars"

# 应用配置
terraform apply -var-file="dev.tfvars"
```

#### 生产环境部署

```bash
# 查看计划
terraform plan -var-file="prod.tfvars"

# 应用配置
terraform apply -var-file="prod.tfvars"
```

### 5. 获取输出信息

```bash
# 查看所有输出
terraform output

# 查看 ALB DNS 名称
terraform output alb_dns_name

# 查看服务端点
terraform output service_endpoints
```

## ⚙️ 配置说明

### 文件结构

```
terraform/
├── main.tf                    # 主配置文件（提供者、数据源、本地变量）
├── variables.tf               # 变量定义
├── ecs.tf                     # ECS 集群、任务定义、服务
├── secrets.tf                 # AWS Secrets Manager 配置
├── networking.tf              # VPC、子网、安全组、负载均衡器
├── outputs.tf                 # 输出定义
├── terraform.tfvars.example   # 变量示例文件
├── dev.tfvars                 # 开发环境配置
├── prod.tfvars                # 生产环境配置
├── .gitignore                 # Git 忽略文件
└── README.md                  # 本文件
```

### 关键配置选项

#### 网络配置
- `vpc_cidr`: VPC CIDR 块（默认：10.0.0.0/16）
- `availability_zones`: 可用区列表
- `public_subnet_cidrs`: 公有子网 CIDR 列表
- `private_subnet_cidrs`: 私有子网 CIDR 列表

#### ECS 配置
- `enable_container_insights`: 启用 CloudWatch Container Insights
- `*_cpu`: 各服务的 CPU 单位（1024 = 1 vCPU）
- `*_memory`: 各服务的内存（MB）
- `*_desired_count`: 期望的任务数量

#### 自动扩展配置
- `enable_autoscaling`: 启用自动扩展
- `autoscaling_min_capacity`: 最小任务数
- `autoscaling_max_capacity`: 最大任务数
- `autoscaling_cpu_target`: CPU 目标利用率
- `autoscaling_memory_target`: 内存目标利用率

## 📝 部署步骤

### 完整部署流程

1. **准备工作**
   ```bash
   # 确认 AWS 凭证
   aws sts get-caller-identity
   
   # 设置环境变量
   source .env.sh
   ```

2. **初始化 Terraform**
   ```bash
   terraform init
   ```

3. **验证配置**
   ```bash
   terraform validate
   ```

4. **查看计划**
   ```bash
   terraform plan -var-file="dev.tfvars" -out=tfplan
   ```

5. **应用配置**
   ```bash
   terraform apply tfplan
   ```

6. **验证部署**
   ```bash
   # 获取 ALB DNS
   ALB_DNS=$(terraform output -raw alb_dns_name)
   
   # 测试服务
   curl http://$ALB_DNS
   ```

### 更新部署

```bash
# 修改配置后
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# 强制重新部署服务（不改变配置）
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw astra_agents_service_name) \
  --force-new-deployment
```

### 销毁资源

```bash
# 销毁所有资源
terraform destroy -var-file="dev.tfvars"
```

## 🔍 管理和运维

### 查看日志

```bash
# 使用 AWS CLI 查看日志
aws logs tail /ecs/ten-agent-dev/astra-agents --follow

# 或使用 Terraform 输出的命令
terraform output aws_cli_commands
```

### 查看服务状态

```bash
# 列出所有任务
aws ecs list-tasks --cluster $(terraform output -raw ecs_cluster_name)

# 查看服务详情
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services $(terraform output -raw astra_agents_service_name)
```

### 扩展服务

```bash
# 手动调整服务数量
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw astra_agents_service_name) \
  --desired-count 3
```

### 更新密钥

```bash
# 更新 Secrets Manager 中的密钥
aws secretsmanager update-secret \
  --secret-id $(terraform output -raw secrets_name) \
  --secret-string '{"OPENAI_API_KEY":"new-key-value"}'

# 重启服务以使用新密钥
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw astra_agents_service_name) \
  --force-new-deployment
```

## 🔧 故障排查

### 常见问题

#### 1. 容器无法启动

```bash
# 查看任务失败原因
aws ecs describe-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --tasks <task-id>

# 查看容器日志
aws logs tail /ecs/ten-agent-dev/astra-agents --follow
```

#### 2. 健康检查失败

- 检查容器是否正常启动
- 验证健康检查路径是否正确
- 确认端口映射配置正确

#### 3. 无法拉取镜像

- 确认 ECS 任务执行角色有 ECR 访问权限
- 对于私有 GitHub Container Registry，需要配置凭证

#### 4. 服务无法通过 ALB 访问

```bash
# 检查目标组健康状态
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw astra_agents_target_group_arn)
```

### 调试技巧

```bash
# 1. 启用详细日志
export TF_LOG=DEBUG

# 2. 查看 Terraform 状态
terraform show

# 3. 查看特定资源
terraform state show aws_ecs_service.astra_agents

# 4. 刷新状态
terraform refresh -var-file="dev.tfvars"
```

## 💰 成本估算

### 开发环境（每月大约）
- ECS Fargate 任务：~$80-120
- NAT Gateway：~$45
- Application Load Balancer：~$25
- CloudWatch Logs：~$5
- **总计**：~$155-195/月

### 生产环境（每月大约）
- ECS Fargate 任务（高可用）：~$300-500
- NAT Gateway（多 AZ）：~$135
- Application Load Balancer：~$25
- CloudWatch Logs：~$20
- Secrets Manager：~$1
- **总计**：~$481-681/月

> 注意：实际成本取决于流量、日志量和资源使用情况。

### 成本优化建议

1. **开发环境**：
   - 非工作时间停止服务
   - 减少日志保留天数
   - 使用较小的任务规格

2. **生产环境**：
   - 启用 Savings Plans
   - 使用 VPC Endpoints 减少 NAT Gateway 流量
   - 配置日志过滤器减少存储成本

## 🔒 安全最佳实践

### 1. 密钥管理

- ✅ 使用 AWS Secrets Manager 存储敏感信息
- ✅ 通过环境变量传递密钥到 Terraform
- ❌ 不要在 `.tfvars` 文件中硬编码密钥
- ❌ 不要将包含密钥的文件提交到版本控制

### 2. 网络安全

- 将 ECS 任务部署在私有子网
- 使用安全组限制流量
- 生产环境限制 ALB 访问来源
- 启用 VPC Flow Logs

### 3. IAM 最小权限原则

```bash
# 定期审查 IAM 策略
aws iam get-role-policy \
  --role-name $(terraform output -raw ecs_task_execution_role_arn | cut -d'/' -f2) \
  --policy-name <policy-name>
```

### 4. 日志和监控

- 启用 CloudWatch Container Insights
- 配置 CloudWatch 告警
- 定期审查访问日志
- 启用 AWS CloudTrail

### 5. 更新和补丁

- 定期更新容器镜像
- 使用特定版本标签而非 `latest`
- 测试更新后再部署到生产环境

## 📚 其他资源

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🤝 贡献

欢迎提交问题和改进建议。

## 📄 许可证

参考主项目的许可证。
