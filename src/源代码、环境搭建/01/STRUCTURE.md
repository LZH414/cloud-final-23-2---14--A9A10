# 项目结构说明

## 目录结构

```
cloud-native-demo/
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions CI/CD 流水线
├── k8s/                        # Kubernetes 配置文件
│   ├── namespace.yaml          # 命名空间定义
│   ├── config.yaml             # ConfigMap 和 Secret
│   ├── deployment.yaml         # Deployment 配置
│   ├── service.yaml            # Service 配置
│   └── hpa.yaml                # Horizontal Pod Autoscaler
├── scripts/                    # 管理脚本
│   ├── deploy.sh               # 部署管理（部署/回滚/状态/日志）
│   ├── trace.sh                # 版本追溯
│   ├── strategy.sh             # 发布策略（滚动/蓝绿/金丝雀）
│   └── security-scan.sh        # 安全扫描
├── src/                        # 源代码
│   └── app.js                  # Express 应用主文件
├── tests/                      # 测试文件
│   └── app.test.js             # Jest 单元测试
├── .dockerignore               # Docker 忽略文件
├── .eslintrc.js                # ESLint 配置
├── .gitignore                  # Git 忽略文件
├── .npmrc                      # npm 配置
├── .trivy.yaml                 # Trivy 安全扫描配置
├── .trivyignore                # Trivy 忽略规则
├── Dockerfile                  # Docker 镜像构建文件
├── docker-compose.yml          # Docker Compose 配置
├── INSTALL.md                  # 环境安装指南
├── Makefile                    # Make 命令快捷方式
├── package.json                # Node.js 依赖和脚本
├── quick-start.sh              # 快速启动脚本
└── README.md                   # 项目文档
```

## 核心文件说明

### 应用代码

#### [src/app.js](src/app.js)
- Express.js Web 应用
- 提供 REST API 端点
- Prometheus 指标收集
- 健康检查端点
- 版本信息追踪

#### [tests/app.test.js](tests/app.test.js)
- Jest 单元测试
- API 端点测试
- 健康检查测试

### CI/CD

#### [.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml)
GitHub Actions 工作流，包含：
- **Test & Lint**: 代码检查和测试
- **Security Scan**: 安全扫描（Trivy + npm audit）
- **Build & Push**: Docker 镜像构建和推送
- **Deploy**: Kubernetes 部署

### 容器化

#### [Dockerfile](Dockerfile)
- 多阶段构建
- 基于 Node.js 18 Alpine
- 非 root 用户运行
- 健康检查配置

#### [docker-compose.yml](docker-compose.yml)
- 本地开发环境
- 服务编排
- 环境变量配置
- 健康检查

### Kubernetes

#### [k8s/namespace.yaml](k8s/namespace.yaml)
- 定义命名空间 `cloud-native-demo`

#### [k8s/config.yaml](k8s/config.yaml)
- ConfigMap: 环境变量配置
- Secret: 敏感信息配置

#### [k8s/deployment.yaml](k8s/deployment.yaml)
- Deployment 配置
- 3 个副本
- 滚动更新策略
- 资源限制
- 健康检查探针

#### [k8s/service.yaml](k8s/service.yaml)
- LoadBalancer Service
- 端口映射 80 -> 3000

#### [k8s/hpa.yaml](k8s/hpa.yaml)
- 自动扩缩容配置
- CPU 和内存指标

### 管理脚本

#### [scripts/deploy.sh](scripts/deploy.sh)
部署管理工具：
```bash
./scripts/deploy.sh deploy <image>   # 部署新版本
./scripts/deploy.sh rollback         # 回滚
./scripts/deploy.sh status           # 查看状态
./scripts/deploy.sh history          # 查看历史
./scripts/deploy.sh trace <pod>      # 追踪版本
./scripts/deploy.sh logs             # 查看日志
```

#### [scripts/trace.sh](scripts/trace.sh)
完整的版本追溯链路：
- Pod 信息
- 镜像 Tag
- ReplicaSet 历史
- 部署版本历史
- 应用版本信息

#### [scripts/strategy.sh](scripts/strategy.sh)
发布策略实现：
```bash
./scripts/strategy.sh rolling <image>      # 滚动更新
./scripts/strategy.sh blue-green <image>   # 蓝绿部署
./scripts/strategy.sh canary <image>       # 金丝雀发布
```

#### [scripts/security-scan.sh](scripts/security-scan.sh)
本地安全扫描：
- npm audit
- ESLint
- Trivy 文件系统扫描
- Trivy Docker 镜像扫描

### 配置文件

#### [.eslintrc.js](.eslintrc.js)
ESLint 代码检查规则

#### [.trivy.yaml](.trivy.yaml)
Trivy 安全扫描配置

#### [.trivyignore](.trivyignore)
Trivy 忽略的漏洞

#### [Makefile](Makefile)
快捷命令：
```bash
make install        # 安装依赖
make test           # 运行测试
make lint           # 代码检查
make build          # 构建镜像
make run            # 运行应用
make docker-up      # 启动 Docker Compose
make docker-down    # 停止 Docker Compose
make deploy         # 部署
make rollback       # 回滚
make trace          # 版本追溯
make security       # 安全扫描
```

## 数据流

### CI/CD 流程

```
代码提交
    ↓
GitHub Actions 触发
    ↓
Test & Lint (测试和代码检查)
    ↓
Security Scan (安全扫描)
    ↓
Build & Push (构建和推送镜像)
    ↓
Deploy (部署到 Kubernetes)
    ↓
应用运行
```

### 版本追溯链路

```
运行实例 (Pod)
    ↓
镜像 Tag (cloud-native-demo:v1.0.0)
    ↓
Commit SHA (abc123def456)
    ↓
代码仓库 (GitHub)
```

### 发布策略

#### 滚动更新
```
旧版本 Pod 1 → 新版本 Pod 1
旧版本 Pod 2 → 新版本 Pod 2
旧版本 Pod 3 → 新版本 Pod 3
```

#### 蓝绿部署
```
环境 A (旧版本) ← 流量
环境 B (新版本) ← 流量切换
```

#### 金丝雀发布
```
稳定版本 (90% 流量)
金丝雀版本 (10% 流量)
```

## 环境变量

| 变量 | 说明 | 默认值 | 位置 |
|------|------|--------|------|
| NODE_ENV | 运行环境 | production | ConfigMap |
| PORT | 服务端口 | 3000 | ConfigMap |
| APP_VERSION | 应用版本 | 1.0.0 | Secret |
| GIT_COMMIT | Git 提交 SHA | unknown | 构建时注入 |
| BUILD_TIME | 构建时间 | unknown | 构建时注入 |

## API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| / | GET | 欢迎页面 |
| /health | GET | 健康检查 |
| /info | GET | 版本信息 |
| /metrics | GET | Prometheus 指标 |

## 监控指标

应用暴露以下 Prometheus 指标：
- `http_request_duration_seconds`: HTTP 请求持续时间
- `process_cpu_seconds_total`: CPU 使用时间
- `process_resident_memory_bytes`: 内存使用量
- `nodejs_eventloop_lag_seconds`: 事件循环延迟
