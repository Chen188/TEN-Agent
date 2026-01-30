# TEN-Agent Terraform 部署 - 文档索引

## 📖 从这里开始

欢迎使用 TEN-Agent AWS ECS Terraform 部署配置！本索引将帮助您快速找到需要的文档。

## 🎯 根据您的需求选择文档

### 我是新手，第一次部署
👉 **推荐阅读顺序**：
1. [TERRAFORM-DEPLOYMENT-SUMMARY.md](TERRAFORM-DEPLOYMENT-SUMMARY.md) - 了解已完成的工作和整体架构
2. [TERRAFORM-QUICKSTART.md](TERRAFORM-QUICKSTART.md) - 5分钟快速开始
3. [terraform-README.md](terraform-README.md) - 详细的部署步骤

### 我需要快速参考
👉 **快速查阅**：
- [TERRAFORM-QUICKSTART.md](TERRAFORM-QUICKSTART.md) - 常用命令和快速指南
- 使用 `./deploy.sh -h` 查看脚本帮助

### 我想了解文件结构
👉 **文件说明**：
- [TERRAFORM-FILES-SUMMARY.md](TERRAFORM-FILES-SUMMARY.md) - 每个文件的详细说明

### 我遇到了问题
👉 **故障排查**：
- [terraform-README.md](terraform-README.md) 中的"常见问题"和"故障排查"章节
- 运行 `./validate-deployment.sh` 检查部署状态
- 查看 CloudWatch 日志

### 我想深入了解配置
👉 **详细文档**：
- [terraform-README.md](terraform-README.md) - 完整的 20K 文档
- 查看各个 .tf 文件中的注释

## 📚 文档清单

### 核心文档（必读）

| 文档 | 大小 | 用途 | 适合人群 |
|------|------|------|---------|
| [TERRAFORM-DEPLOYMENT-SUMMARY.md](TERRAFORM-DEPLOYMENT-SUMMARY.md) | 13K | 部署完成总结 | ✅ 所有人 |
| [TERRAFORM-QUICKSTART.md](TERRAFORM-QUICKSTART.md) | 8K | 快速开始指南 | ✅ 快速上手 |
| [terraform-README.md](terraform-README.md) | 20K | 完整详细文档 | 📖 深入学习 |

### 参考文档

| 文档 | 大小 | 用途 |
|------|------|------|
| [TERRAFORM-FILES-SUMMARY.md](TERRAFORM-FILES-SUMMARY.md) | 9K | 文件清单和说明 |
| [本文档](TERRAFORM-INDEX.md) | 2K | 文档索引 |

### 配置文件

| 文件 | 用途 |
|------|------|
| `terraform.tfvars.example` | 配置模板 |
| `environments/dev.tfvars` | 开发环境配置 |
| `environments/staging.tfvars` | 预发布环境配置 |
| `environments/prod.tfvars` | 生产环境配置 |

### 脚本工具

| 脚本 | 功能 |
|------|------|
| `deploy.sh` | 部署管理（init, plan, apply, status, logs, secrets, restart） |
| `validate-deployment.sh` | 部署验证 |

## 🚀 快速开始（3 步）

```bash
# 1. 初始化
./deploy.sh init

# 2. 部署
./deploy.sh apply -e dev

# 3. 配置密钥并重启
./deploy.sh secrets -e dev
./deploy.sh restart -e dev
```

详细步骤请参考 [TERRAFORM-QUICKSTART.md](TERRAFORM-QUICKSTART.md)

## 📁 项目结构

```
TEN-Agent/
│
├── 📖 文档（你在这里）
│   ├── TERRAFORM-INDEX.md                 ⬅️ 本文档（索引）
│   ├── TERRAFORM-DEPLOYMENT-SUMMARY.md    ⭐ 完成总结
│   ├── TERRAFORM-QUICKSTART.md            ⭐ 快速指南
│   ├── terraform-README.md                📚 完整文档
│   └── TERRAFORM-FILES-SUMMARY.md         📋 文件说明
│
├── 🔧 Terraform 配置
│   ├── main.tf              # Provider 配置
│   ├── variables.tf         # 变量定义
│   ├── outputs.tf           # 输出定义
│   ├── ecs.tf              # ECS 集群
│   ├── tasks.tf            # 任务定义
│   ├── networking.tf       # 网络资源
│   ├── alb.tf              # 负载均衡
│   ├── secrets.tf          # 密钥管理
│   ├── route53.tf          # DNS 配置
│   ├── acm.tf              # SSL 证书
│   └── iam.tf              # IAM 角色
│
├── 🌍 环境配置
│   └── environments/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       ├── prod.tfvars
│       └── terraform.tfvars.example
│
└── 🛠️ 辅助脚本
    ├── deploy.sh
    └── validate-deployment.sh
```

## 💡 常见使用场景

### 场景 1: 首次部署开发环境
```bash
# 阅读文档
cat TERRAFORM-DEPLOYMENT-SUMMARY.md

# 初始化和部署
./deploy.sh init
./deploy.sh apply -e dev

# 配置密钥
# 在 AWS Console 更新 Secrets Manager 密钥

# 重启服务
./deploy.sh restart -e dev

# 验证
./validate-deployment.sh dev
```

### 场景 2: 部署生产环境
```bash
# 阅读生产环境文档
cat terraform-README.md | grep -A 50 "生产环境"

# 准备生产配置
vim environments/prod.tfvars

# 部署
./deploy.sh apply -e prod

# 配置域名和证书
# 参考 terraform-README.md 中的域名配置章节
```

### 场景 3: 查看服务状态
```bash
# 快速检查
./deploy.sh status -e dev

# 详细验证
./validate-deployment.sh dev

# 查看日志
./deploy.sh logs -e dev agents
```

### 场景 4: 更新密钥
```bash
# 方法 1: 批量更新（需要 .env 文件）
./deploy.sh secrets -e dev

# 方法 2: 单个更新
aws secretsmanager put-secret-value \
  --secret-id ten-agent-dev/openai-api-key \
  --secret-string "sk-xxx"

# 重启服务
./deploy.sh restart -e dev
```

### 场景 5: 故障排查
```bash
# 1. 运行验证脚本
./validate-deployment.sh dev

# 2. 查看日志
./deploy.sh logs -e dev agents

# 3. 检查 ECS 服务
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --services ten-agent-dev-agents

# 4. 查看文档
cat terraform-README.md | grep -A 30 "故障排查"
```

## 🔗 外部资源

- **TEN-Agent 项目**: https://github.com/ten-framework/TEN-Agent
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/
- **AWS ECS 文档**: https://docs.aws.amazon.com/ecs/
- **AWS Fargate 定价**: https://aws.amazon.com/fargate/pricing/

## 📞 获取帮助

### 命令行帮助
```bash
# 部署脚本帮助
./deploy.sh -h

# Terraform 帮助
terraform -help
```

### 文档中查找
```bash
# 搜索特定主题
grep -r "关键词" *.md

# 查看特定章节
cat terraform-README.md | grep -A 20 "章节名称"
```

## ✅ 检查清单

### 部署前检查
- [ ] 已安装 Terraform >= 1.5.0
- [ ] 已安装 AWS CLI v2
- [ ] 已配置 AWS 凭证
- [ ] 已准备 API 密钥
- [ ] 已阅读相关文档

### 部署后检查
- [ ] 已更新所有 Secrets Manager 密钥
- [ ] 已重启 ECS 服务
- [ ] 已验证服务可访问
- [ ] 已配置域名（如需要）
- [ ] 已设置监控告警（推荐）

## 🎓 学习路径

### 初级（开始使用）
1. 阅读 TERRAFORM-DEPLOYMENT-SUMMARY.md
2. 跟随 TERRAFORM-QUICKSTART.md 部署
3. 使用 deploy.sh 脚本管理

### 中级（深入理解）
1. 阅读完整的 terraform-README.md
2. 查看各个 .tf 文件和注释
3. 了解不同环境的配置差异
4. 学习故障排查技巧

### 高级（优化和定制）
1. 修改 Terraform 配置以适应需求
2. 优化成本和性能
3. 集成 CI/CD
4. 实现多区域部署

## 🔄 文档更新

**当前版本**: 1.0.0
**最后更新**: 2024-12-16

如需更新文档，请修改相应的 Markdown 文件。

---

**提示**: 从 [TERRAFORM-DEPLOYMENT-SUMMARY.md](TERRAFORM-DEPLOYMENT-SUMMARY.md) 开始阅读，然后根据需要查看其他文档。

祝部署顺利！🚀
