# TEN-Agent AWS 部署检查清单

## ☑️ 部署前准备

### 1. 工具安装
- [ ] Terraform >= 1.0 已安装
- [ ] AWS CLI >= 2.0 已安装并配置
- [ ] jq 已安装（可选）

验证：
```bash
terraform --version
aws --version
aws sts get-caller-identity
```

### 2. AWS 账户配置
- [ ] 拥有有效的 AWS 账户
- [ ] AWS 凭证已配置（~/.aws/credentials 或环境变量）
- [ ] IAM 权限包含以下服务：
  - [ ] EC2（VPC、子网、安全组）
  - [ ] ECS（集群、服务、任务定义）
  - [ ] IAM（角色、策略）
  - [ ] CloudWatch（日志组）
  - [ ] Secrets Manager
  - [ ] Elastic Load Balancing
  - [ ] Application Auto Scaling
- [ ] 已选择部署区域（默认：us-west-2）

### 3. API 密钥准备
- [ ] Agora App ID
- [ ] Agora App Certificate
- [ ] AWS Access Key ID（应用使用）
- [ ] AWS Secret Access Key（应用使用）
- [ ] Azure Speech-to-Text Key
- [ ] Azure Speech-to-Text Region
- [ ] Azure Text-to-Speech Key
- [ ] Azure Text-to-Speech Region
- [ ] OpenAI API Key
- [ ] Qwen API Key
- [ ] Cosy TTS Key（可选）
- [ ] ElevenLabs TTS Key（可选）

### 4. 容器镜像访问
- [ ] GitHub Container Registry 访问凭证（如果镜像是私有的）
- [ ] 确认可以访问以下镜像：
  - [ ] ghcr.io/ten-framework/astra_agents_build:0.3.5
  - [ ] node:20-alpine
  - [ ] ghcr.io/chen188/nova-sonic-server:latest

### 5. 配置文件准备
- [ ] 已复制 terraform.tfvars.example
- [ ] 已创建 .env.sh 文件
- [ ] 已设置所有必需的环境变量
- [ ] 已审查 dev.tfvars 或 prod.tfvars
- [ ] 已根据需要调整资源配置（CPU、内存、副本数）

## ☑️ 部署流程

### 步骤 1: 环境准备
- [ ] 切换到 terraform 目录
```bash
cd /projects/sandbox/TEN-Agent/terraform
```

- [ ] 创建并配置 .env.sh
```bash
cat > .env.sh << 'EOF'
#!/bin/bash
export TF_VAR_agora_app_id="YOUR_VALUE"
# ... 添加所有变量
EOF
chmod +x .env.sh
```

- [ ] 加载环境变量
```bash
source .env.sh
```

### 步骤 2: Terraform 初始化
- [ ] 运行初始化命令
```bash
./deploy.sh init
# 或
terraform init
```

- [ ] 确认初始化成功
- [ ] 检查 .terraform 目录已创建

### 步骤 3: 配置验证
- [ ] 运行验证命令
```bash
terraform validate
```

- [ ] 格式化配置文件
```bash
terraform fmt
```

### 步骤 4: 部署计划
- [ ] 创建部署计划（开发环境）
```bash
./deploy.sh plan dev
# 或
terraform plan -var-file="dev.tfvars" -out=dev.tfplan
```

- [ ] 仔细审查计划输出
- [ ] 确认将创建的资源数量和类型
- [ ] 确认没有意外的资源删除

### 步骤 5: 执行部署
- [ ] 应用配置
```bash
./deploy.sh apply dev
# 或
terraform apply dev.tfplan
```

- [ ] 等待部署完成（通常 10-15 分钟）
- [ ] 记录输出信息

### 步骤 6: 部署验证
- [ ] 获取 ALB DNS 名称
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
echo $ALB_DNS
```

- [ ] 查看所有输出
```bash
terraform output
```

- [ ] 检查 ECS 集群状态
```bash
./deploy.sh status dev
```

## ☑️ 部署后验证

### 1. 服务健康检查
- [ ] 所有 ECS 服务状态为 ACTIVE
```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
aws ecs describe-services --cluster $CLUSTER_NAME \
  --services $(terraform output -raw astra_agents_service_name) \
  --query 'services[0].{name:serviceName,status:status,running:runningCount,desired:desiredCount}'
```

- [ ] 所有任务状态为 RUNNING
```bash
aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status RUNNING
```

- [ ] 目标组健康检查通过
```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw astra_agents_target_group_arn)
```

### 2. 网络连接测试
- [ ] ALB 可以访问
```bash
curl -I http://$ALB_DNS
```

- [ ] astra_agents 服务响应
```bash
curl http://$ALB_DNS/
```

- [ ] astra_playground 服务响应
```bash
curl http://$ALB_DNS/playground
```

- [ ] nova_sonic 服务响应
```bash
curl http://$ALB_DNS/nova-sonic
```

### 3. 日志检查
- [ ] astra_agents 日志正常
```bash
./deploy.sh logs dev astra-agents
```

- [ ] astra_playground 日志正常
```bash
./deploy.sh logs dev playground
```

- [ ] nova_sonic 日志正常
```bash
./deploy.sh logs dev nova-sonic
```

- [ ] 无严重错误或异常

### 4. 密钥验证
- [ ] 密钥成功存储在 Secrets Manager
```bash
SECRET_NAME=$(terraform output -raw secrets_name)
aws secretsmanager describe-secret --secret-id $SECRET_NAME
```

- [ ] 容器可以访问密钥（检查日志中是否有密钥访问错误）

### 5. 资源验证
- [ ] VPC 已创建
- [ ] 子网已创建（公有和私有）
- [ ] 安全组已创建
- [ ] ALB 已创建并运行
- [ ] 目标组已创建
- [ ] ECS 集群已创建
- [ ] CloudWatch 日志组已创建

## ☑️ 监控和告警设置

### 1. CloudWatch 配置
- [ ] 启用 Container Insights
- [ ] 配置 CPU 使用率告警
- [ ] 配置内存使用率告警
- [ ] 配置服务健康告警
- [ ] 配置目标组不健康告警

### 2. 日志配置
- [ ] 日志正确写入 CloudWatch
- [ ] 日志保留期已设置
- [ ] 日志访问权限已配置

### 3. 指标监控
- [ ] ECS 服务指标可查看
- [ ] ALB 指标可查看
- [ ] 目标组指标可查看

## ☑️ 安全检查

### 1. 网络安全
- [ ] ECS 任务在私有子网中运行
- [ ] 安全组规则正确配置
- [ ] 不必要的端口已关闭
- [ ] ALB 访问限制已配置（生产环境）

### 2. 密钥安全
- [ ] 密钥未硬编码在配置文件中
- [ ] .env.sh 未提交到版本控制
- [ ] terraform.tfvars 未提交到版本控制
- [ ] Secrets Manager 访问权限最小化

### 3. IAM 安全
- [ ] IAM 角色遵循最小权限原则
- [ ] 任务执行角色权限正确
- [ ] 任务角色权限正确
- [ ] 密钥访问策略独立

### 4. 审计日志
- [ ] CloudTrail 已启用（可选）
- [ ] VPC Flow Logs 已启用（可选）
- [ ] ALB 访问日志已启用（可选）

## ☑️ 成本优化

### 1. 资源优化
- [ ] 开发环境使用较小的实例规格
- [ ] 非工作时间停止开发环境（可选）
- [ ] 日志保留期合理设置
- [ ] 未使用的资源已删除

### 2. 成本监控
- [ ] 设置成本预算告警
- [ ] 定期审查成本报告
- [ ] 标签已正确应用于资源

## ☑️ 文档和知识传递

### 1. 文档完整性
- [ ] README.md 已审查
- [ ] DEPLOYMENT_GUIDE.md 已审查
- [ ] QUICK_REFERENCE.md 已收藏
- [ ] 运维文档已创建

### 2. 团队准备
- [ ] 团队成员已了解架构
- [ ] 访问权限已分配
- [ ] 运维流程已定义
- [ ] 应急响应计划已制定

## ☑️ 备份和灾难恢复

### 1. 备份策略
- [ ] Terraform 状态文件备份（建议使用 S3 后端）
- [ ] 配置文件已备份
- [ ] 密钥备份计划已制定

### 2. 恢复测试
- [ ] 灾难恢复流程已文档化
- [ ] 恢复流程已测试（可选）
- [ ] RTO/RPO 目标已定义

## ☑️ 生产环境额外检查

### 仅用于生产环境部署
- [ ] 已充分测试开发环境
- [ ] 变更申请已批准
- [ ] 维护窗口已确定
- [ ] 回滚计划已准备
- [ ] 监控和告警已完全配置
- [ ] 团队成员已通知
- [ ] 用户已通知（如有必要）
- [ ] 多可用区配置已启用
- [ ] 自动扩展已启用并测试
- [ ] 负载测试已完成
- [ ] 安全扫描已完成
- [ ] 合规要求已满足

## ☑️ 部署完成后操作

### 1. 记录信息
- [ ] ALB DNS 名称已记录
- [ ] 所有服务端点已记录
- [ ] 访问凭证已安全存储
- [ ] 部署日期和版本已记录

### 2. 通知相关方
- [ ] 团队成员已通知
- [ ] 用户已通知（如适用）
- [ ] 文档已更新
- [ ] 知识库已更新

### 3. 后续监控
- [ ] 设置定期检查计划
- [ ] 监控前 24 小时的表现
- [ ] 收集用户反馈
- [ ] 记录任何问题和解决方案

## 📝 部署记录

| 项目 | 信息 |
|-----|------|
| 部署日期 | _______________ |
| 部署环境 | _______________ |
| 部署人员 | _______________ |
| Terraform 版本 | _______________ |
| AWS 区域 | _______________ |
| ECS 集群名称 | _______________ |
| ALB DNS | _______________ |
| 问题记录 | _______________ |
| 备注 | _______________ |

## ✅ 最终确认

- [ ] 所有检查项都已完成
- [ ] 所有服务正常运行
- [ ] 监控已配置
- [ ] 文档已完成
- [ ] 团队已准备好运维

## 🆘 如有问题

- 查看日志: `./deploy.sh logs dev <service-name>`
- 查看状态: `./deploy.sh status dev`
- 参考文档: README.md, DEPLOYMENT_GUIDE.md
- 联系 AWS 支持（如需要）

---

**部署成功！** 🎉

访问应用: `http://<YOUR_ALB_DNS>`
