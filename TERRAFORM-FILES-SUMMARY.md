# TEN-Agent Terraform 配置文件说明

本文档列出了所有生成的 Terraform 配置文件及其用途。

## 📁 核心 Terraform 配置文件

### 1. main.tf
**用途**: 主配置文件
- Provider 配置 (AWS)
- Terraform 版本要求
- 后端配置（可选的 S3 backend）
- 数据源定义（可用区、账号信息）
- 本地变量定义

### 2. variables.tf (12K)
**用途**: 变量定义文件
包含所有可配置的变量：
- 基础配置（项目名、环境、区域）
- 网络配置（VPC CIDR、子网、NAT Gateway）
- ECS 配置（CPU、内存、副本数）
- ALB 配置（健康检查、超时设置）
- 域名和 SSL 配置
- 应用配置（端口、worker 数量）
- 自动扩展配置
- 安全配置

### 3. outputs.tf (8.3K)
**用途**: 输出定义文件
输出部署后的重要信息：
- VPC 和子网 ID
- ECS 集群信息
- ALB DNS 名称和端点
- 服务 URL
- Secrets Manager ARN
- IAM 角色 ARN
- CloudWatch 日志组
- 部署说明和后续步骤

## 🏗️ 基础设施模块文件

### 4. networking.tf (11K)
**用途**: 网络资源定义
创建和配置：
- VPC（虚拟私有云）
- 公有子网和私有子网
- Internet Gateway
- NAT Gateways 和 EIP
- 路由表和路由规则
- 安全组（ALB 和 ECS 任务）
- VPC Endpoints（可选，已注释）

### 5. ecs.tf (11K)
**用途**: ECS 集群和服务配置
定义：
- CloudWatch 日志组（agents, playground, nova_sonic）
- ECS 集群（Fargate 启动类型）
- 三个 ECS 服务（agents, playground, nova_sonic）
- 服务发现配置
- 部署策略和断路器
- 自动扩展目标和策略

### 6. tasks.tf (8.6K)
**用途**: ECS 任务定义
基于 docker-compose.yml 转换的任务定义：
- **Agents Task**: 主应用服务
  - 端口：8080, 49483
  - 环境变量配置
  - Secrets Manager 集成
  - 健康检查配置
- **Playground Task**: 前端应用
  - 端口：3000
  - Node.js 运行时
- **Nova Sonic Task**: 语音处理服务
  - 端口：3333
  - AWS 凭证集成

### 7. alb.tf (9.2K)
**用途**: 应用负载均衡器配置
配置：
- Application Load Balancer
- 目标组（agents, playground, nova_sonic, graph_designer）
- HTTP 监听器（多端口）
- HTTPS 监听器（基于域名路由）
- 监听器规则（子域名路由）
- HTTP 到 HTTPS 重定向

## 🔒 安全和访问控制

### 8. iam.tf (6.9K)
**用途**: IAM 角色和策略
定义：
- **ECS Task Execution Role**: 用于拉取镜像和写日志
  - ECR 访问权限
  - Secrets Manager 读取权限
  - CloudWatch Logs 写入权限
- **ECS Task Role**: 应用运行时使用
  - AWS Bedrock 访问权限
  - Polly TTS 权限
  - S3 访问权限（可选）
  - CloudWatch 指标权限
- **Auto Scaling Role**: 自动扩展权限

### 9. secrets.tf (8.9K)
**用途**: AWS Secrets Manager 配置
创建和管理密钥：
- Agora 配置（App ID, Certificate）
- AWS 服务凭证（Access Key, Secret Key）
- Azure 服务密钥（STT, TTS）
- TTS 服务密钥（Cosy, ElevenLabs）
- LLM 服务密钥（OpenAI, Qwen）
- 所有密钥初始值为占位符，需要部署后更新

## 🌐 域名和证书

### 10. route53.tf (3.2K)
**用途**: DNS 配置
管理：
- Route 53 托管区域（可选创建或使用现有）
- A 记录（指向 ALB）
  - api.domain.com -> Agents
  - app.domain.com -> Playground
  - sonic.domain.com -> Nova Sonic
- 根域名记录

### 11. acm.tf (1.3K)
**用途**: SSL/TLS 证书管理
配置：
- ACM 证书请求（主域名 + 通配符）
- DNS 验证记录（自动创建）
- 证书验证等待
- 支持 DNS 和 EMAIL 验证方法

## 📋 环境配置文件

### 12. environments/dev.tfvars
**用途**: 开发环境配置
特点：
- 较小的资源配置（节省成本）
- 单个 NAT Gateway
- 禁用 Container Insights
- 短日志保留期（3 天）
- 启用容器调试

### 13. environments/staging.tfvars
**用途**: 预发布环境配置
特点：
- 中等资源配置
- 每个 AZ 一个 NAT Gateway
- 启用 Container Insights
- 中等日志保留期（7 天）
- 可选自定义域名

### 14. environments/prod.tfvars
**用途**: 生产环境配置
特点：
- 高性能资源配置
- 3 个可用区部署
- 多副本服务
- 启用删除保护
- 长日志保留期（30 天）
- 必须使用自定义域名
- 禁用容器调试

### 15. terraform.tfvars.example
**用途**: 配置模板文件
- 包含所有可配置参数的说明
- 提供默认值参考
- 作为创建实际 terraform.tfvars 的模板

## 📖 文档文件

### 16. terraform-README.md (20K)
**用途**: 完整部署文档
内容：
- 架构概览
- 前置条件
- 详细部署步骤
- 配置说明
- 环境管理
- 部署后配置
- 故障排查
- 最佳实践
- 参考资源

### 17. TERRAFORM-QUICKSTART.md (8K)
**用途**: 快速开始指南
内容：
- 5 分钟快速部署
- 常用命令
- 监控和调试
- 环境管理
- 成本优化
- 故障排查

### 18. 本文件 (TERRAFORM-FILES-SUMMARY.md)
**用途**: 文件清单和说明

## 🛠️ 辅助脚本

### 19. deploy.sh (8.8K)
**用途**: 部署辅助脚本
功能：
- `init`: 初始化 Terraform
- `plan`: 查看执行计划
- `apply`: 部署基础设施
- `destroy`: 销毁资源
- `output`: 显示输出
- `status`: 查看 ECS 服务状态
- `logs`: 查看服务日志
- `secrets`: 批量更新密钥
- `restart`: 重启 ECS 服务

使用示例：
```bash
./deploy.sh apply -e dev
./deploy.sh status -e prod
./deploy.sh logs -e dev agents
```

### 20. validate-deployment.sh (5.8K)
**用途**: 部署验证脚本
检查项：
- Terraform 状态
- ECS 集群和服务状态
- ALB 目标组健康状态
- Secrets Manager 配置
- 服务端点可达性
- CloudWatch 日志

使用示例：
```bash
./validate-deployment.sh dev
./validate-deployment.sh prod us-west-2
```

## 🔐 安全文件

### 21. .gitignore.terraform
**用途**: Git 忽略规则
防止提交：
- Terraform 状态文件（*.tfstate）
- 变量文件（*.tfvars）
- 环境文件（.env）
- 本地 .terraform 目录
- 备份文件

**重要**: 将这些规则添加到项目的 .gitignore 文件中！

## 📊 文件大小统计

```
acm.tf                    1.3K
alb.tf                    9.2K
ecs.tf                   11.0K
iam.tf                    6.9K
main.tf                   1.8K
networking.tf            11.0K
outputs.tf                8.3K
route53.tf                3.2K
secrets.tf                8.9K
tasks.tf                  8.6K
variables.tf             12.0K

terraform-README.md      20.0K
TERRAFORM-QUICKSTART.md   8.0K

deploy.sh                 8.8K
validate-deployment.sh    5.8K

environments/dev.tfvars   2.0K
environments/staging.tfvars 2.0K
environments/prod.tfvars  2.5K
terraform.tfvars.example  4.5K

Total: ~135K
```

## 🎯 文件依赖关系

```
main.tf
  ├── variables.tf (变量定义)
  ├── networking.tf (依赖: variables)
  │     └── VPC, Subnets, Security Groups
  ├── iam.tf (依赖: variables, secrets.tf)
  │     └── Task Execution Role, Task Role
  ├── secrets.tf (依赖: variables)
  │     └── Secrets Manager Secrets
  ├── alb.tf (依赖: networking.tf, acm.tf)
  │     └── ALB, Target Groups, Listeners
  ├── ecs.tf (依赖: networking.tf, iam.tf, alb.tf)
  │     └── ECS Cluster, Services
  ├── tasks.tf (依赖: iam.tf, secrets.tf)
  │     └── Task Definitions
  ├── route53.tf (依赖: alb.tf)
  │     └── DNS Records
  ├── acm.tf (依赖: route53.tf)
  │     └── SSL Certificates
  └── outputs.tf (依赖: 所有资源)
        └── Output Values
```

## 🚀 使用流程

1. **准备阶段**
   - 复制 `terraform.tfvars.example` 为 `terraform.tfvars`
   - 编辑配置文件
   - 选择环境配置文件（dev/staging/prod）

2. **部署阶段**
   - 运行 `terraform init`
   - 运行 `terraform plan`
   - 运行 `terraform apply`

3. **配置阶段**
   - 更新 Secrets Manager 密钥
   - 配置域名（如果使用）
   - 重启服务

4. **验证阶段**
   - 运行 `validate-deployment.sh`
   - 测试服务端点
   - 检查日志

5. **维护阶段**
   - 监控服务状态
   - 查看日志
   - 调整配置
   - 更新应用

## 📝 注意事项

1. **不要提交敏感文件**
   - `*.tfvars` (除了 example)
   - `.env` 文件
   - `*.tfstate` 文件

2. **环境隔离**
   - 使用 Terraform Workspaces
   - 或使用独立的状态文件
   - 或使用独立的目录

3. **成本控制**
   - 开发环境使用小规格
   - 使用单个 NAT Gateway
   - 禁用不必要的功能

4. **安全最佳实践**
   - 使用 Secrets Manager 存储密钥
   - 定期轮换凭证
   - 启用日志和监控
   - 使用最小权限原则

5. **生产环境建议**
   - 使用 S3 backend
   - 启用删除保护
   - 配置备份策略
   - 设置告警

## 🔗 相关资源

- [完整文档](terraform-README.md)
- [快速开始](TERRAFORM-QUICKSTART.md)
- [Docker Compose 原文件](docker-compose.yml)
- [环境变量示例](.env.example)

---

**版本**: 1.0.0
**创建日期**: 2024-12-16
**维护者**: DevOps Team
