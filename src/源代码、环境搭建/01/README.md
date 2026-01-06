# Cloud Native Demo - CI/CD 项目

一个完整的云原生应用项目，演示从代码到上线的完整 CI/CD 流水线，包括镜像构建、推送、部署、升级回滚和版本追溯。

## 项目特性

### 最低要求（已完成）
- ✅ CI 构建镜像 + 推送
- ✅ 简化测试
- ✅ 打包镜像
- ✅ 部署端演示升级与回滚
- ✅ 版本追溯链路（运行实例 -> 镜像 tag -> commit）

### 加分点（已完成）
- ✅ 安全扫描（Trivy + npm audit）
- ✅ 依赖检查（ESLint + npm audit）
- ✅ 发布策略（蓝绿部署、金丝雀发布）
- ✅ GitOps 工具（Argo CD）

## 项目结构

```
.
├── src/
│   └── app.js              # 主应用
├── tests/
│   └── app.test.js         # 测试文件
├── k8s/
│   ├── namespace.yaml      # 命名空间
│   ├── config.yaml         # 配置和密钥
│   ├── deployment.yaml     # 部署配置
│   ├── service.yaml        # 服务配置
│   └── hpa.yaml            # 自动扩缩容
├── gitops/
│   ├── project.yaml        # Argo CD 项目配置
│   ├── application.yaml    # 应用定义
│   └── values.yaml         # Helm 值文件
├── scripts/
│   ├── deploy.sh           # 部署管理脚本
│   ├── trace.sh            # 版本追溯脚本
│   ├── strategy.sh         # 发布策略脚本
│   ├── security-scan.sh    # 安全扫描脚本
│   ├── install-argocd.sh   # Argo CD 安装脚本
│   └── gitops-deploy.sh    # GitOps 部署脚本
├── .github/
│   └── workflows/
│       └── ci-cd.yml       # GitHub Actions CI/CD 流水线
├── Dockerfile              # Docker 镜像构建文件
├── docker-compose.yml      # Docker Compose 配置
├── package.json            # Node.js 依赖
└── README.md               # 项目文档
```

## 快速开始

### 前置要求

- Node.js 18+
- Docker
- Docker Compose
- Kubernetes 集群（可选，用于生产部署）
- kubectl（可选）

### 本地开发

1. 安装依赖：
```bash
npm install
```

2. 运行应用：
```bash
npm start
```

3. 运行测试：
```bash
npm test
```

4. 代码检查：
```bash
npm run lint
```

### 使用 Docker Compose

1. 构建并启动：
```bash
docker-compose up -d
```

2. 查看日志：
```bash
docker-compose logs -f
```

3. 停止服务：
```bash
docker-compose down
```

### 访问应用

- 主页: http://localhost:3000
- 健康检查: http://localhost:3000/health
- 版本信息: http://localhost:3000/info
- Prometheus 指标: http://localhost:3000/metrics

## CI/CD 流水线

### GitHub Actions 工作流

项目包含完整的 CI/CD 流水线，在 `.github/workflows/ci-cd.yml` 中定义：

#### 流水线阶段

1. **Test & Lint**
   - 运行 ESLint 代码检查
   - 运行 Jest 单元测试
   - 上传测试覆盖率

2. **Security Scan**
   - Trivy 漏洞扫描
   - npm audit 依赖检查
   - 上传扫描结果到 GitHub Security

3. **Build & Push**
   - 构建 Docker 镜像
   - 推送到容器注册表（GitHub Container Registry）
   - 添加版本标签（branch, sha, latest）

4. **Deploy**
   - 更新 Kubernetes Deployment
   - 等待滚动更新完成
   - 验证部署状态

#### 触发条件

- 推送到 `main` 或 `develop` 分支
- 创建 Pull Request 到 `main` 分支

### 配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

- `KUBE_CONFIG`: Kubernetes 配置文件（base64 编码）

## Kubernetes 部署

### 部署到 Kubernetes

1. 创建命名空间：
```bash
kubectl apply -f k8s/namespace.yaml
```

2. 部署应用：
```bash
kubectl apply -f k8s/
```

3. 查看部署状态：
```bash
kubectl get all -n cloud-native-demo
```

### 部署管理脚本

项目提供了便捷的部署管理脚本：

#### deploy.sh - 部署管理

```bash
# 部署新版本
./scripts/deploy.sh deploy cloud-native-demo:v1.0.0

# 回滚到上一版本
./scripts/deploy.sh rollback

# 查看部署状态
./scripts/deploy.sh status

# 查看部署历史
./scripts/deploy.sh history

# 追踪版本信息
./scripts/deploy.sh trace <pod-name>

# 查看应用日志
./scripts/deploy.sh logs
```

#### trace.sh - 版本追溯

```bash
# 完整版本追溯链路
./scripts/trace.sh
```

追溯链路展示：
- 运行实例（Pod）信息
- 镜像 Tag
- ReplicaSet 历史
- 部署版本历史
- 应用版本信息（commit、build time）

#### strategy.sh - 发布策略

```bash
# 滚动更新（默认）
./scripts/strategy.sh rolling cloud-native-demo:v1.0.0

# 蓝绿部署
./scripts/strategy.sh blue-green cloud-native-demo:v1.1.0

# 金丝雀发布（10% 流量）
./scripts/strategy.sh canary cloud-native-demo:v1.2.0
```

### 发布策略说明

#### 1. 滚动更新（Rolling Update）
- 逐个替换 Pod
- 零停机时间
- 适合大多数场景
- 配置：`maxSurge: 1, maxUnavailable: 0`

#### 2. 蓝绿部署（Blue-Green）
- 维护两套完整环境
- 瞬间切换流量
- 快速回滚
- 需要双倍资源

#### 3. 金丝雀发布（Canary）
- 小部分流量验证新版本
- 逐步扩大流量
- 降低风险
- 支持流量比例控制

## GitOps 部署

项目使用 Argo CD 实现 GitOps 工作流，通过 Git 仓库管理应用部署状态。

### 安装 Argo CD

1. 运行安装脚本：
```bash
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

2. 获取初始密码：
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. 访问 Argo CD UI：
```
https://argocd.local
```

4. 安装 Argo CD CLI（可选）：
```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
```

### GitOps 部署管理

使用 GitOps 部署脚本管理应用：

```bash
# 部署应用
./scripts/gitops-deploy.sh deploy --repo https://github.com/your-username/cloud-native-demo.git

# 同步应用状态
./scripts/gitops-deploy.sh sync

# 查看应用状态
./scripts/gitops-deploy.sh status

# 回滚到上一个版本
./scripts/gitops-deploy.sh rollback

# 查看应用日志
./scripts/gitops-deploy.sh logs

# 删除应用
./scripts/gitops-deploy.sh delete
```

### GitOps 配置文件

GitOps 配置文件位于 `gitops/` 目录：

- `project.yaml` - Argo CD 项目配置
- `application.yaml` - 应用定义
- `values.yaml` - Helm 值文件

### GitOps 工作流

1. **代码提交**：将代码推送到 Git 仓库
2. **自动构建**：CI/CD 流水线构建 Docker 镜像
3. **自动同步**：Argo CD 检测到 Git 变化，自动同步到集群
4. **健康检查**：Argo CD 监控应用健康状态
5. **自动修复**：配置自愈策略，自动恢复异常状态

### GitOps 优势

- **声明式管理**：所有配置存储在 Git 中
- **版本控制**：完整的变更历史和审计追踪
- **自动化同步**：自动检测和应用 Git 变更
- **自愈能力**：配置自动修复，确保状态一致
- **回滚简单**：通过 Git 回滚即可恢复应用

## 安全扫描

### 本地安全扫描

```bash
# 运行完整安全扫描
./scripts/security-scan.sh
```

扫描内容包括：
- npm audit（依赖漏洞）
- ESLint（代码质量）
- Trivy（文件系统漏洞）
- Trivy（Docker 镜像漏洞）

### CI/CD 安全扫描

GitHub Actions 自动执行安全扫描：
- Trivy 扫描代码和依赖
- npm audit 检查 npm 包漏洞
- 扫描结果上传到 GitHub Security

## 版本追溯

### 完整追溯链路

项目实现了从运行实例到代码提交的完整追溯链路：

```
运行实例 (Pod)
    ↓
镜像 Tag
    ↓
Commit SHA
    ↓
代码仓库
```

### 查看版本信息

```bash
# 通过 API 查看版本信息
curl http://localhost:3000/info

# 返回示例：
{
  "version": "1.0.0",
  "commit": "abc123def456",
  "buildTime": "2024-01-01T00:00:00Z",
  "environment": "production"
}
```

## 监控和可观测性

### Prometheus 指标

应用暴露 Prometheus 指标：
- HTTP 请求持续时间
- 请求计数
- 默认 Node.js 指标

访问：`http://localhost:3000/metrics`

### 健康检查

- Liveness Probe: `/health`
- Readiness Probe: `/health`
- 检查间隔：5-10 秒
- 超时：3 秒

### 日志

查看应用日志：
```bash
# Docker Compose
docker-compose logs -f app

# Kubernetes
kubectl logs -f -n cloud-native-demo -l app=cloud-native-demo
```

## 自动扩缩容

配置了 Horizontal Pod Autoscaler (HPA)：

- 最小副本：2
- 最大副本：10
- CPU 目标利用率：70%
- 内存目标利用率：80%

## 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| NODE_ENV | 运行环境 | production |
| PORT | 服务端口 | 3000 |
| APP_VERSION | 应用版本 | 1.0.0 |
| GIT_COMMIT | Git 提交 SHA | unknown |
| BUILD_TIME | 构建时间 | unknown |

## 故障排查

### Pod 启动失败

```bash
# 查看 Pod 状态
kubectl get pods -n cloud-native-demo

# 查看 Pod 日志
kubectl logs <pod-name> -n cloud-native-demo

# 查看 Pod 事件
kubectl describe pod <pod-name> -n cloud-native-demo
```

### 镜像拉取失败

```bash
# 检查镜像是否存在
docker images | grep cloud-native-demo

# 检查镜像拉取策略
kubectl describe deployment cloud-native-demo -n cloud-native-demo
```

### 健康检查失败

```bash
# 检查健康检查端点
kubectl exec <pod-name> -n cloud-native-demo -- curl http://localhost:3000/health

# 查看健康检查配置
kubectl describe pod <pod-name> -n cloud-native-demo
```

## 最佳实践

1. **版本管理**
   - 使用语义化版本号
   - 每次发布打 Git tag
   - 镜像 tag 与 Git commit 关联

2. **安全**
   - 定期运行安全扫描
   - 及时更新依赖
   - 使用非 root 用户运行容器

3. **部署**
   - 使用滚动更新减少停机
   - 配置健康检查确保可用性
   - 保留历史版本便于回滚

4. **监控**
   - 收集 Prometheus 指标
   - 配置告警规则
   - 定期检查日志

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

如有问题或建议，请提交 Issue。
