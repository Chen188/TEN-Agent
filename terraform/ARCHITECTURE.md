# TEN-Agent AWS 架构图

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                   │
│                           Region: us-west-2                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │
                    ┌───────────────┴────────────────┐
                    │   Application Load Balancer    │
                    │       (Public Facing)          │
                    │    DNS: *.elb.amazonaws.com    │
                    └───────────┬────────────────────┘
                                │
                    ┌───────────┴────────────────┐
                    │   Path-Based Routing       │
                    │   /           → astra_agents     │
                    │   /playground → playground       │
                    │   /nova-sonic → nova_sonic       │
                    └───────────┬────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐    ┌────────────────┐    ┌────────────────┐
│  Target Group  │    │  Target Group  │    │  Target Group  │
│ astra_agents   │    │   playground   │    │  nova_sonic    │
└───────┬────────┘    └───────┬────────┘    └───────┬────────┘
        │                     │                      │
        └─────────────────────┼──────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │            VPC: 10.0.0.0/16             │
        │                                         │
        │  ┌────────────────────────────────┐    │
        │  │    Public Subnets (2-3 AZs)   │    │
        │  │  - 10.0.1.0/24                │    │
        │  │  - 10.0.2.0/24                │    │
        │  │  [NAT Gateways]               │    │
        │  └────────────────────────────────┘    │
        │                                         │
        │  ┌────────────────────────────────┐    │
        │  │   Private Subnets (2-3 AZs)   │    │
        │  │  - 10.0.10.0/24               │    │
        │  │  - 10.0.20.0/24               │    │
        │  │                                │    │
        │  │  ┌─────────────────────────┐  │    │
        │  │  │   ECS Cluster (Fargate) │  │    │
        │  │  │                         │  │    │
        │  │  │  ┌──────────────────┐  │  │    │
        │  │  │  │ astra_agents     │  │  │    │
        │  │  │  │ CPU: 2-4 vCPU   │  │  │    │
        │  │  │  │ Mem: 4-8 GB     │  │  │    │
        │  │  │  │ Port: 8080,8001 │  │  │    │
        │  │  │  └──────────────────┘  │  │    │
        │  │  │                         │  │    │
        │  │  │  ┌──────────────────┐  │  │    │
        │  │  │  │ astra_playground │  │  │    │
        │  │  │  │ CPU: 0.5-1 vCPU │  │  │    │
        │  │  │  │ Mem: 1-2 GB     │  │  │    │
        │  │  │  │ Port: 3000      │  │  │    │
        │  │  │  └──────────────────┘  │  │    │
        │  │  │                         │  │    │
        │  │  │  ┌──────────────────┐  │  │    │
        │  │  │  │ nova_sonic       │  │  │    │
        │  │  │  │ CPU: 0.5-2 vCPU │  │  │    │
        │  │  │  │ Mem: 1-4 GB     │  │  │    │
        │  │  │  │ Port: 3333      │  │  │    │
        │  │  │  └──────────────────┘  │  │    │
        │  │  │                         │  │    │
        │  │  └─────────────────────────┘  │    │
        │  │                                │    │
        │  └────────────────────────────────┘    │
        │                                         │
        └─────────────────────────────────────────┘
                              │
                              │ Access
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
        ▼                                           ▼
┌──────────────────┐                    ┌──────────────────┐
│ AWS Secrets      │                    │ CloudWatch Logs  │
│ Manager          │                    │                  │
│                  │                    │ - astra_agents   │
│ - AGORA_APP_ID   │                    │ - playground     │
│ - OPENAI_API_KEY │                    │ - nova_sonic     │
│ - AWS_KEYS       │                    │                  │
│ - AZURE_KEYS     │                    │                  │
│ ... (12 secrets) │                    └──────────────────┘
└──────────────────┘
```

## 📊 组件说明

### 1. 网络层

#### VPC
- **CIDR**: 10.0.0.0/16 (dev) / 10.1.0.0/16 (prod)
- **可用区**: 2-3 个
- **DNS**: 启用

#### 公有子网
- **用途**: NAT Gateway, ALB
- **CIDR**: 10.0.1.0/24, 10.0.2.0/24
- **路由**: 0.0.0.0/0 → Internet Gateway

#### 私有子网
- **用途**: ECS 任务
- **CIDR**: 10.0.10.0/24, 10.0.20.0/24
- **路由**: 0.0.0.0/0 → NAT Gateway

### 2. 负载均衡

#### Application Load Balancer
- **类型**: 面向互联网
- **监听器**: HTTP:80
- **健康检查**: 每30秒

#### 目标组 (3个)
- **astra_agents**: Port 8080
- **astra_playground**: Port 3000
- **nova_sonic**: Port 3333

### 3. 计算层

#### ECS 集群
- **启动类型**: Fargate
- **网络模式**: awsvpc
- **Container Insights**: 启用

#### 服务 (3个)

##### astra_agents
```
镜像: ghcr.io/ten-framework/astra_agents_build:0.3.5
CPU: 1024-4096 (1-4 vCPU)
内存: 2048-8192 MB (2-8 GB)
副本: 1-2 (dev-prod)
端口: 8080, 8001
密钥: 18 个环境变量
```

##### astra_playground
```
镜像: node:20-alpine
CPU: 512-1024 (0.5-1 vCPU)
内存: 1024-2048 MB (1-2 GB)
副本: 1-2 (dev-prod)
端口: 3000
密钥: 无
```

##### nova_sonic
```
镜像: ghcr.io/chen188/nova-sonic-server:latest
CPU: 512-2048 (0.5-2 vCPU)
内存: 1024-4096 MB (1-4 GB)
副本: 1-2 (dev-prod)
端口: 3333
密钥: 3 个环境变量
```

### 4. 安全层

#### Secrets Manager
- **密钥数量**: 12 个
- **存储格式**: JSON
- **访问**: IAM 策略控制

#### 安全组

##### ALB 安全组
```
入站:
- HTTP (80) from 0.0.0.0/0
- HTTPS (443) from 0.0.0.0/0

出站:
- All traffic to 0.0.0.0/0
```

##### ECS 任务安全组
```
入站:
- All TCP from ALB Security Group
- All TCP from VPC CIDR

出站:
- All traffic to 0.0.0.0/0
```

### 5. 监控层

#### CloudWatch Logs
- **日志组**: 4 个（每服务一个）
- **保留期**: 3-30 天 (dev-prod)
- **流前缀**: ecs

#### Container Insights
- **指标**: CPU, Memory, Network
- **告警**: 可配置

### 6. IAM 角色

#### ECS 任务执行角色
```
权限:
- 拉取镜像 (ECR)
- 写入日志 (CloudWatch)
- 读取密钥 (Secrets Manager)
```

#### ECS 任务角色
```
权限:
- S3 访问
- 日志写入
- 应用特定权限
```

## 🔄 数据流

### 1. 用户请求流程
```
用户 → Internet → ALB (公有子网)
    → 路由规则 → 目标组
    → ECS 任务 (私有子网)
    → 响应返回
```

### 2. 容器启动流程
```
ECS 服务 → 任务定义
    → 从 Container Registry 拉取镜像
    → 从 Secrets Manager 读取密钥
    → 在私有子网启动容器
    → 注册到目标组
    → 健康检查通过
    → 开始接收流量
```

### 3. 日志流程
```
容器 → CloudWatch Logs
    → 日志组
    → 保留策略
    → 可查询和分析
```

### 4. 出站流量
```
ECS 任务 (私有子网)
    → NAT Gateway (公有子网)
    → Internet Gateway
    → 外部 API (OpenAI, Azure, etc.)
```

## 🔒 安全架构

### 网络隔离
```
┌──────────────────────────────┐
│      Internet Gateway        │
└──────────┬───────────────────┘
           │
    ┌──────┴──────┐
    │     ALB     │ (公有子网)
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │ NAT Gateway │ (公有子网)
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │ ECS Tasks   │ (私有子网)
    └─────────────┘
```

### 密钥管理
```
Environment Variables
        ↓
    Terraform
        ↓
  Secrets Manager
        ↓
  ECS Task Definition
        ↓
   Container Runtime
```

## 📈 扩展架构

### 自动扩展
```
CloudWatch Metrics
    │
    ├─→ CPU > 75% ──→ Scale Out
    ├─→ Memory > 75% ──→ Scale Out
    ├─→ CPU < 25% ──→ Scale In
    └─→ Memory < 25% ──→ Scale In
```

### 高可用
```
Multiple AZs
    │
    ├─→ AZ 1: Subnet + Tasks
    ├─→ AZ 2: Subnet + Tasks
    └─→ AZ 3: Subnet + Tasks (prod)
```

## 🌍 环境对比

### 开发环境
```
┌─────────────────┐
│   2 AZs         │
│   Single NAT    │
│   1 Task/Svc    │
│   Lower CPU/Mem │
│   No AutoScale  │
└─────────────────┘
```

### 生产环境
```
┌─────────────────┐
│   3 AZs         │
│   Multi NAT     │
│   2+ Tasks/Svc  │
│   Higher CPU/Mem│
│   AutoScale On  │
└─────────────────┘
```

## 💰 成本组件

```
┌──────────────────────┐
│ ECS Fargate Tasks    │ $$$ (最大成本)
├──────────────────────┤
│ NAT Gateway          │ $$ (固定成本)
├──────────────────────┤
│ Application LB       │ $ (固定成本)
├──────────────────────┤
│ CloudWatch Logs      │ $ (使用量)
├──────────────────────┤
│ Secrets Manager      │ $ (很少)
├──────────────────────┤
│ Data Transfer        │ $ (使用量)
└──────────────────────┘
```

## 🔄 更新流程

```
代码更新
    ↓
构建新镜像
    ↓
推送到 Container Registry
    ↓
更新 Terraform 变量
    ↓
terraform apply
    ↓
ECS 滚动更新
    ↓
健康检查
    ↓
完成部署
```

## 📊 监控视图

```
┌─────────────────────────────┐
│   CloudWatch Dashboard      │
├─────────────────────────────┤
│ - ECS Service Status        │
│ - Task Count                │
│ - CPU/Memory Usage          │
│ - ALB Request Count         │
│ - Target Health             │
│ - Log Insights              │
└─────────────────────────────┘
```

## 🎯 设计原则

1. **高可用性**: 多 AZ 部署
2. **安全性**: 私有子网 + 密钥管理
3. **可扩展性**: Auto Scaling + Fargate
4. **可观测性**: CloudWatch 集成
5. **成本优化**: 环境差异化配置

---

此架构提供了生产就绪的基础设施，支持 TEN-Agent 应用的可靠运行和扩展。
