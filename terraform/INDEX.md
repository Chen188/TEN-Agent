# TEN-Agent Terraform 配置 - 文档索引

## 📚 文档导航

### 🚀 快速开始
- **[QUICK_START.md](./QUICK_START.md)** - 5 分钟快速部署指南
  - 环境变量设置
  - 一键部署命令
  - 常用运维命令
  - 故障排查指南

### 📖 完整文档
- **[README.md](./README.md)** - 完整的部署文档（449 行）
  - 架构概述
  - 前置要求
  - 详细配置说明
  - 部署步骤
  - 管理和运维
  - 成本估算
  - 安全最佳实践

### 🏗️ 架构设计
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - 系统架构设计文档
  - 整体架构图
  - 网络架构
  - 服务架构
  - 安全架构
  - 数据流向

### 📝 部署指南
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - 详细部署指南
  - 环境准备
  - 分步部署流程
  - 验证方法
  - 回滚策略

### ⚡ 快速参考
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - 快速参考手册
  - 常用命令速查
  - 配置参数说明
  - 故障排查速查
  - API 端点列表

### ✅ 检查清单
- **[CHECKLIST.md](./CHECKLIST.md)** - 部署检查清单
  - 部署前检查
  - 部署中验证
  - 部署后确认
  - 安全检查

### 📊 项目总结
- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - 项目总结
  - 项目概述
  - 技术栈
  - 资源清单
  - 团队信息

### ✅ 验证结果
- **[VALIDATION_RESULTS.md](./VALIDATION_RESULTS.md)** - Terraform 配置验证结果
  - 代码格式化
  - 配置验证
  - 资源完整性检查
  - 最佳实践遵循

---

## 📁 配置文件

### 核心配置
- **[main.tf](./main.tf)** - 主配置文件（156 行）
  - Terraform 提供者配置
  - 数据源定义
  - 本地变量定义
  - 服务配置映射

- **[variables.tf](./variables.tf)** - 变量定义（390 行）
  - 通用变量
  - 网络变量
  - ECS 变量
  - 镜像变量
  - 端口变量
  - 密钥变量
  - 自动扩展变量

### 资源配置
- **[ecs.tf](./ecs.tf)** - ECS 配置（624 行）
  - ECS 集群
  - 任务定义（4 个服务）
  - ECS 服务（4 个服务）
  - IAM 角色和策略
  - CloudWatch 日志组
  - 自动扩展配置

- **[networking.tf](./networking.tf)** - 网络配置（452 行）
  - VPC 配置
  - 子网配置
  - Internet Gateway
  - NAT Gateway
  - 路由表
  - 安全组
  - Application Load Balancer
  - 目标组
  - 监听器和路由规则
  - VPC Endpoints

- **[secrets.tf](./secrets.tf)** - 密钥管理（79 行）
  - AWS Secrets Manager 配置
  - 密钥版本管理
  - IAM 策略

- **[outputs.tf](./outputs.tf)** - 输出定义（276 行）
  - 网络输出
  - ECS 输出
  - 负载均衡器输出
  - 服务端点
  - 管理命令

### 环境配置
- **[dev.tfvars](./dev.tfvars)** - 开发环境配置
  - 较低的资源配置
  - 单实例部署
  - 较短的日志保留
  - 禁用自动扩展

- **[prod.tfvars](./prod.tfvars)** - 生产环境配置
  - 较高的资源配置
  - 多实例高可用部署
  - 较长的日志保留
  - 启用自动扩展

- **[terraform.tfvars.example](./terraform.tfvars.example)** - 配置示例
  - 所有变量的示例值
  - 密钥配置说明
  - 注释和提示

### 自动化脚本
- **[deploy.sh](./deploy.sh)** - 自动化部署脚本（417 行）
  - 环境检查
  - Terraform 操作封装
  - 服务管理命令
  - 日志查看
  - 状态查询

---

## 🔍 按任务查找

### 第一次部署
1. 阅读 [QUICK_START.md](./QUICK_START.md)
2. 参考 [CHECKLIST.md](./CHECKLIST.md)
3. 查看 [terraform.tfvars.example](./terraform.tfvars.example)

### 了解架构
1. 阅读 [ARCHITECTURE.md](./ARCHITECTURE.md)
2. 查看 [README.md](./README.md) 的架构部分
3. 检查配置文件注释

### 日常运维
1. 使用 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
2. 运行 [deploy.sh](./deploy.sh) 脚本
3. 参考 [README.md](./README.md) 的管理部分

### 故障排查
1. 查看 [QUICK_START.md](./QUICK_START.md) 的故障排查部分
2. 参考 [README.md](./README.md) 的故障排查章节
3. 检查 [VALIDATION_RESULTS.md](./VALIDATION_RESULTS.md)

### 生产部署
1. 阅读 [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
2. 遵循 [CHECKLIST.md](./CHECKLIST.md)
3. 使用 [prod.tfvars](./prod.tfvars)
4. 参考 [README.md](./README.md) 的安全最佳实践

---

## 📊 配置统计

### 代码行数
| 文件 | 行数 | 说明 |
|------|------|------|
| main.tf | 156 | 主配置 |
| variables.tf | 390 | 变量定义 |
| ecs.tf | 624 | ECS 配置 |
| secrets.tf | 79 | 密钥管理 |
| networking.tf | 452 | 网络配置 |
| outputs.tf | 276 | 输出定义 |
| deploy.sh | 417 | 部署脚本 |
| **配置总计** | **2,394** | **所有配置** |

### 文档行数
| 文件 | 行数 | 类型 |
|------|------|------|
| README.md | 449 | 完整文档 |
| ARCHITECTURE.md | ~400 | 架构设计 |
| DEPLOYMENT_GUIDE.md | ~300 | 部署指南 |
| QUICK_REFERENCE.md | ~200 | 快速参考 |
| QUICK_START.md | ~150 | 快速开始 |
| CHECKLIST.md | ~250 | 检查清单 |
| VALIDATION_RESULTS.md | ~300 | 验证结果 |
| **文档总计** | **~2,049** | **所有文档** |

---

## 🎯 服务配置

### 4 个微服务
1. **astra-agents** - 主服务
   - 镜像: ghcr.io/ten-framework/astra_agents_build:0.3.5
   - 端口: 8001, 8080
   - 密钥: 18 个

2. **astra-playground** - Web UI
   - 镜像: node:20-alpine
   - 端口: 3000
   - 密钥: 无

3. **nova-sonic-server** - Nova Sonic 服务
   - 镜像: ghcr.io/chen188/nova-sonic-server:latest
   - 端口: 3333
   - 密钥: 3 个

4. **graph-designer** - 图形设计器
   - 镜像: agoraio/astra_graph_designer:0.1.0
   - 端口: 3000
   - 密钥: 无

---

## 🔐 安全配置

### AWS Secrets Manager
- 18 个敏感配置项
- JSON 格式存储
- ECS 任务运行时注入
- IAM 策略保护

### 网络安全
- 私有子网部署容器
- NAT Gateway 访问互联网
- 安全组限制流量
- ALB 作为公开入口

---

## 💰 成本估算

### 开发环境
- ~$155-195/月
- 2.5 vCPU, 5 GB 内存
- 4 个服务，各 1 实例

### 生产环境
- ~$481-681/月
- 16 vCPU, 32 GB 内存（最小）
- 4 个服务，各 2 实例
- 自动扩展至 10 实例

---

## 📞 获取帮助

### 快速问题
- 查看 [QUICK_START.md](./QUICK_START.md)
- 查看 [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

### 深入了解
- 阅读 [README.md](./README.md)
- 阅读 [ARCHITECTURE.md](./ARCHITECTURE.md)

### 部署问题
- 查看 [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- 查看 [CHECKLIST.md](./CHECKLIST.md)

### 配置问题
- 查看 [VALIDATION_RESULTS.md](./VALIDATION_RESULTS.md)
- 检查 [terraform.tfvars.example](./terraform.tfvars.example)

---

## ✅ 验证状态

- ✅ Terraform 配置验证通过
- ✅ 代码格式化完成
- ✅ 所有文档齐全
- ✅ 生产就绪

**配置位置**: `/projects/sandbox/TEN-Agent/terraform/`  
**最后更新**: 2025-12-16  
**配置状态**: ✅ 生产就绪
