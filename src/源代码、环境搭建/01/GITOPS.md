# GitOps 部署指南

本指南介绍如何使用 Argo CD 实现 GitOps 工作流。

## 什么是 GitOps？

GitOps 是一种使用 Git 作为单一事实来源来管理基础设施和应用程序的运维方法。通过 GitOps，所有的配置变更都通过 Git 提交和 Pull Request 进行，实现：

- **声明式配置**：所有配置以代码形式存储在 Git 中
- **版本控制**：完整的变更历史和审计追踪
- **自动化同步**：自动检测和应用 Git 变更
- **自愈能力**：配置自动修复，确保状态一致

## Argo CD 简介

Argo CD 是一个用于 Kubernetes 的声明式 GitOps 持续交付工具。

### 核心特性

- **可视化部署**：提供 Web UI 查看应用状态
- **自动同步**：自动检测 Git 变更并同步到集群
- **健康检查**：监控应用健康状态
- **回滚支持**：快速回滚到任意版本
- **多集群支持**：管理多个 Kubernetes 集群

## 安装 Argo CD

### 前置要求

- Kubernetes 集群（v1.16+）
- kubectl 已配置
- Helm（可选）

### 安装步骤

1. **运行安装脚本**：
```bash
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

2. **获取初始密码**：
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. **访问 Argo CD UI**：
```
https://argocd.local
```

4. **安装 Argo CD CLI**（可选）：
```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# 验证安装
argocd version
```

5. **登录 Argo CD**：
```bash
argocd login argocd.local --username admin --password <initial-password>
```

## 配置 Git 仓库

### 1. 更新 Application 配置

编辑 `gitops/application.yaml`，修改 Git 仓库地址：

```yaml
source:
  repoURL: https://github.com/your-username/cloud-native-demo.git
  targetRevision: HEAD
  path: k8s
```

### 2. 推送配置到 Git

```bash
git add gitops/
git commit -m "Add Argo CD configuration"
git push origin main
```

## 部署应用

### 使用 GitOps 脚本

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

### 使用 Argo CD CLI

```bash
# 创建应用
argocd app create cloud-native-demo \
  --repo https://github.com/your-username/cloud-native-demo.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace cloud-native-demo \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# 同步应用
argocd app sync cloud-native-demo

# 查看应用状态
argocd app get cloud-native-demo

# 查看应用列表
argocd app list

# 回滚应用
argocd app rollback cloud-native-demo <revision>

# 删除应用
argocd app delete cloud-native-demo
```

### 使用 Argo CD UI

1. 访问 Argo CD UI：`https://argocd.local`
2. 点击 "New App" 创建新应用
3. 填写应用配置：
   - **Application Name**: cloud-native-demo
   - **Project**: cloud-native-demo
   - **Repository**: Git 仓库地址
   - **Path**: k8s
   - **Cluster**: https://kubernetes.default.svc
   - **Namespace**: cloud-native-demo
4. 点击 "Create" 创建应用
5. 点击 "Sync" 同步应用

## GitOps 工作流

### 1. 开发流程

```bash
# 创建特性分支
git checkout -b feature/new-feature

# 修改代码
vim src/app.js

# 提交代码
git add src/app.js
git commit -m "Add new feature"

# 推送到远程仓库
git push origin feature/new-feature
```

### 2. 代码审查

1. 在 GitHub/GitLab 创建 Pull Request
2. 代码审查通过后合并到主分支
3. Argo CD 自动检测到变更并同步

### 3. 自动部署

Argo CD 自动执行以下步骤：

1. 检测 Git 仓库变更
2. 比较期望状态和实际状态
3. 同步差异到 Kubernetes 集群
4. 监控应用健康状态
5. 如果配置了自愈，自动修复异常状态

### 4. 版本管理

```bash
# 查看应用历史
argocd app history cloud-native-demo

# 回滚到指定版本
argocd app rollback cloud-native-demo <revision>

# 查看应用同步状态
argocd app get cloud-native-demo --output json | jq '.status.sync'
```

## 配置自动同步

### 自动同步策略

在 `gitops/application.yaml` 中配置：

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
    allowEmpty: false
  syncOptions:
  - CreateNamespace=true
  - PrunePropagationPolicy=foreground
  - PruneLast=true
```

### 同步选项说明

- **prune**: 自动删除 Git 中不存在的资源
- **selfHeal**: 自动修复与期望状态不一致的资源
- **allowEmpty**: 允许空目录同步
- **CreateNamespace**: 自动创建命名空间
- **PrunePropagationPolicy**: 删除策略（foreground/background）

## 配置健康检查

### 应用健康检查

Argo CD 内置健康检查，支持：

- **Deployment**: 检查副本数和可用性
- **Service**: 检查服务端点
- **Ingress**: 检查 Ingress 状态
- **Pod**: 检查 Pod 状态和就绪状态

### 自定义健康检查

在 `gitops/application.yaml` 中添加：

```yaml
healthCheck:
  namespace: cloud-native-demo
  resources:
    - kind: Deployment
      name: cloud-native-demo
      checkInterval: 30s
      timeout: 5m
```

## 配置通知

### Argo CD Notifications

安装 Argo CD Notifications：

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/notifications-install.yaml
```

配置通知服务：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  triggers.on-sync-status-unknown: |
    - description: Application syncing has failed
      send: [slack]
```

## 最佳实践

### 1. 分支策略

- **main**: 生产环境，自动部署
- **develop**: 开发环境，手动同步
- **feature/**: 功能分支，不部署

### 2. 版本管理

- 使用语义化版本号
- 每次发布打 Git tag
- 镜像 tag 与 Git commit 关联

### 3. 安全

- 使用私有 Git 仓库
- 配置 RBAC 权限控制
- 定期更新 Argo CD 版本
- 启用审计日志

### 4. 监控

- 配置 Prometheus 监控 Argo CD
- 设置告警规则
- 定期检查应用健康状态

## 故障排查

### 应用同步失败

```bash
# 查看同步状态
argocd app get cloud-native-demo

# 查看同步日志
argocd app logs cloud-native-demo

# 强制同步
argocd app sync cloud-native-demo --force
```

### 应用健康检查失败

```bash
# 查看应用状态
argocd app get cloud-native-demo --output json | jq '.status.health'

# 查看资源状态
argocd app resources cloud-native-demo

# 查看事件
kubectl get events -n cloud-native-demo
```

### 权限问题

```bash
# 检查 RBAC 权限
kubectl auth can-i get deployments -n cloud-native-demo

# 查看角色绑定
kubectl get rolebindings -n cloud-native-demo
```

## 高级功能

### 多集群管理

```bash
# 添加集群
argocd cluster add <context-name>

# 查看集群列表
argocd cluster list

# 在指定集群部署应用
argocd app create cloud-native-demo \
  --dest-server https://<cluster-api-server> \
  --dest-namespace cloud-native-demo
```

### 应用分组

使用 AppSet 管理多个应用：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cloud-native-demo-set
spec:
  generators:
  - list:
      elements:
      - cluster: dev
        url: https://kubernetes.default.svc
      - cluster: prod
        url: https://kubernetes.default.svc
  template:
    metadata:
      name: 'cloud-native-demo-{{cluster}}'
    spec:
      project: cloud-native-demo
      source:
        repoURL: https://github.com/your-username/cloud-native-demo.git
        targetRevision: HEAD
        path: k8s
      destination:
        server: '{{url}}'
        namespace: cloud-native-demo
```

### 密钥管理

使用 Sealed Secrets 管理敏感信息：

```bash
# 安装 Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# 加密密钥
kubeseal --scope strict < secret.yaml > sealed-secret.yaml

# 部署加密的密钥
kubectl apply -f sealed-secret.yaml
```

## 参考资料

- [Argo CD 官方文档](https://argoproj.github.io/argo-cd/)
- [GitOps 最佳实践](https://www.weave.works/technologies/gitops/)
- [Argo CD 示例](https://argoproj.github.io/argo-cd/examples/)
