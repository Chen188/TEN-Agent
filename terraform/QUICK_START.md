# TEN-Agent 快速开始指南

## 🚀 5 分钟快速部署

### 前提条件
- ✅ AWS CLI 已配置
- ✅ 拥有所有必需的 API 密钥
- ✅ 有权限创建 AWS 资源

### 步骤 1: 设置环境变量 (2 分钟)

```bash
cd /projects/sandbox/TEN-Agent/terraform

# 创建环境变量文件
cat > .env.sh << 'EOL'
#!/bin/bash
# Agora
export TF_VAR_agora_app_id="YOUR_AGORA_APP_ID"
export TF_VAR_agora_app_certificate="YOUR_AGORA_APP_CERTIFICATE"

# AWS (用于应用程序)
export TF_VAR_aws_access_key_id="YOUR_AWS_ACCESS_KEY_ID"
export TF_VAR_aws_secret_access_key="YOUR_AWS_SECRET_ACCESS_KEY"

# Azure Speech Services
export TF_VAR_azure_stt_key="YOUR_AZURE_STT_KEY"
export TF_VAR_azure_stt_region="eastus"
export TF_VAR_azure_tts_key="YOUR_AZURE_TTS_KEY"
export TF_VAR_azure_tts_region="eastus"

# OpenAI
export TF_VAR_openai_api_key="YOUR_OPENAI_API_KEY"

# Qwen
export TF_VAR_qwen_api_key="YOUR_QWEN_API_KEY"

# TTS Services (可选)
export TF_VAR_cosy_tts_key="YOUR_COSY_TTS_KEY"
export TF_VAR_elevenlabs_tts_key="YOUR_ELEVENLABS_TTS_KEY"
EOL

# 赋予执行权限并加载
chmod +x .env.sh
source .env.sh
```

### 步骤 2: 一键部署 (3 分钟)

```bash
# 初始化 Terraform
./deploy.sh init

# 部署到开发环境
./deploy.sh apply dev
```

### 步骤 3: 获取访问地址

```bash
# 查看部署信息
./deploy.sh output

# 或获取 ALB DNS
terraform output -raw alb_dns_name
```

### 访问服务

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)

# 主服务
curl http://$ALB_DNS/

# Playground
curl http://$ALB_DNS/playground

# Nova Sonic
curl http://$ALB_DNS/nova-sonic

# Graph Designer
curl http://$ALB_DNS/graph-designer
```

---

## 📋 常用命令

### 查看状态
```bash
./deploy.sh status dev
```

### 查看日志
```bash
# astra-agents 日志
./deploy.sh logs dev astra-agents

# 其他服务日志
./deploy.sh logs dev astra-playground
./deploy.sh logs dev nova-sonic
./deploy.sh logs dev graph-designer
```

### 扩展服务
```bash
# 扩展到 3 个实例
./deploy.sh scale dev astra-agents 3
```

### 更新服务
```bash
# 更新特定服务
./deploy.sh update dev astra-agents

# 更新所有服务
./deploy.sh update dev all
```

### 销毁资源
```bash
./deploy.sh destroy dev
```

---

## 🔧 故障排查

### 问题：容器无法启动
```bash
# 查看日志
./deploy.sh logs dev astra-agents

# 查看任务详情
aws ecs describe-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --tasks <task-id>
```

### 问题：无法访问服务
```bash
# 检查目标组健康状态
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw astra_agents_target_group_arn)

# 检查安全组
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw ecs_tasks_security_group_id)
```

### 问题：密钥错误
```bash
# 查看密钥
SECRET_NAME=$(terraform output -raw secrets_name)
aws secretsmanager get-secret-value --secret-id $SECRET_NAME

# 更新密钥
aws secretsmanager update-secret \
  --secret-id $SECRET_NAME \
  --secret-string '{
    "OPENAI_API_KEY": "new-value"
  }'

# 重启服务
./deploy.sh update dev astra-agents
```

---

## 💡 提示

1. **首次部署**: 预计需要 5-10 分钟
2. **密钥更新**: 更新密钥后需要重启服务
3. **成本控制**: 开发环境不使用时可以销毁
4. **监控**: 启用 Container Insights 可以看到详细指标
5. **备份**: Terraform 状态文件要妥善保管

---

## 📞 获取帮助

- 查看完整文档: `cat README.md`
- 查看架构设计: `cat ARCHITECTURE.md`
- 查看部署指南: `cat DEPLOYMENT_GUIDE.md`
- 查看验证结果: `cat VALIDATION_RESULTS.md`

---

## 🎯 下一步

1. ✅ 验证所有服务正常运行
2. ✅ 查看日志确认无错误
3. ✅ 测试服务功能
4. 📊 配置 CloudWatch 告警
5. 🔒 配置自定义域名和 SSL
6. 🚀 部署到生产环境

---

**配置位置**: `/projects/sandbox/TEN-Agent/terraform/`  
**文档语言**: 中文  
**配置状态**: ✅ 生产就绪
