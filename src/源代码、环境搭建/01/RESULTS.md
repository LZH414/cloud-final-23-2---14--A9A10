# 实验结果展示指南

本指南详细说明如何查看和验证每个任务的实验结果。

## 快速查看所有结果

运行综合演示脚本查看所有任务的完成情况：

```bash
./show-results.sh
```

---

## 核心任务1：构建完整的CI/CD流水线

### 1.1 查看CI/CD配置

```bash
# 查看 GitHub Actions 工作流配置
cat .github/workflows/ci-cd.yml
```

**预期结果：**
- 包含 Test & Lint、Security Scan、Build & Push、Deploy 四个阶段
- 配置了自动触发条件（push 到 main/develop 分支、Pull Request）

### 1.2 查看CI/CD运行状态

访问 GitHub Actions 页面：
```
https://github.com/your-username/cloud-native-demo/actions
```

**预期结果：**
- 显示所有工作流运行历史
- 每个阶段显示成功/失败状态
- 可以查看详细的日志输出

### 1.3 本地测试CI/CD流程

```bash
# 运行测试
npm test

# 运行代码检查
npm run lint

# 运行安全扫描
./scripts/security-scan.sh
```

**预期结果：**
- 测试全部通过
- 代码检查无错误
- 安全扫描报告显示漏洞情况

### 1.4 查看Docker镜像构建

```bash
# 查看本地镜像
docker images | grep cloud-native-demo

# 查看镜像详情
docker inspect cloud-native-demo:latest
```

**预期结果：**
- 显示构建的镜像列表
- 镜像标签包含版本信息
- 镜像包含应用的完整依赖

---

## 核心任务2：搭建可观测性闭环

### 2.1 启动应用并查看指标

```bash
# 启动应用
npm start

# 在另一个终端查看指标
curl http://localhost:3000/metrics
```

**预期结果：**
- 显示 Prometheus 格式的指标
- 包含 http_request_duration_seconds、http_requests_total 等指标
- 指标带有标签（method、route、code 等）

### 2.2 查看告警规则配置

```bash
# 查看告警规则
cat monitoring/prometheus/alerts.yml
```

**预期结果：**
- 定义了 HighErrorRate、HighLatency、HighCPUUsage 等告警规则
- 每个规则包含触发条件、持续时间、严重级别

### 2.3 触发告警并验证

```bash
# 运行故障模拟脚本
./scripts/fault-scenarios.sh

# 查看指标变化
curl http://localhost:3000/metrics | grep http_requests_total
```

**预期结果：**
- 高错误率场景触发 5xx 错误
- 高延迟场景增加请求持续时间
- 指标数据实时更新

### 2.4 查看日志

```bash
# 查看应用日志
tail -f logs/app.log

# 或使用 Docker Compose
docker-compose logs -f app
```

**预期结果：**
- 日志包含请求信息、错误信息、性能数据
- 日志格式为 JSON，便于解析
- 包含时间戳、级别、消息等字段

### 2.5 查看可观测性配置

```bash
# 查看 Prometheus 配置
cat monitoring/prometheus/prometheus.yml

# 查看 Loki 配置
cat monitoring/loki/loki-config.yml

# 查看 Promtail 配置
cat monitoring/promtail/promtail-config.yml
```

**预期结果：**
- Prometheus 配置了抓取目标
- Loki 配置了日志存储和查询
- Promtail 配置了日志采集规则

---

## 进阶任务1：蓝绿部署和金丝雀发布

### 3.1 蓝绿部署演示

```bash
# 部署到 blue 环境
./scripts/blue-green.sh deploy-blue

# 切换流量到 blue
./scripts/blue-green.sh switch-blue

# 回滚到 green
./scripts/blue-green.sh rollback
```

**预期结果：**
- Blue 环境部署成功
- 流量切换瞬间完成
- 回滚操作快速恢复

### 3.2 金丝雀发布演示

```bash
# 部署金丝雀版本
./scripts/canary.sh deploy

# 设置 20% 流量到金丝雀
./scripts/canary.sh set-traffic 20

# 逐步增加流量
./scripts/canary.sh set-traffic 50
./scripts/canary.sh set-traffic 100

# 回滚
./scripts/canary.sh rollback
```

**预期结果：**
- 金丝雀版本部署成功
- 流量按比例分配
- 可以逐步验证新版本

### 3.3 查看部署配置

```bash
# 查看蓝绿部署配置
cat docker-compose.blue-green.yml

# 查看金丝雀部署配置
cat docker-compose.canary.yml

# 查看 Nginx 配置
cat nginx.conf
```

**预期结果：**
- 蓝绿配置包含 blue 和 green 两个服务
- 金丝雀配置包含 stable 和 canary 两个服务
- Nginx 配置了流量分配规则

---

## 进阶任务2：HPA自动扩缩容

### 4.1 查看HPA配置

```bash
# 查看 HPA 配置文件
cat k8s/hpa.yaml
```

**预期结果：**
- 最小副本数：2
- 最大副本数：10
- CPU 目标利用率：70%
- 内存目标利用率：80%
- 自定义指标：active_connections

### 4.2 部署到Kubernetes并查看HPA状态

```bash
# 部署到 Kubernetes
kubectl apply -f k8s/

# 查看 HPA 状态
kubectl get hpa -n cloud-native-demo

# 查看 Pod 状态
kubectl get pods -n cloud-native-demo
```

**预期结果：**
- HPA 创建成功
- 显示当前副本数、目标副本数
- 显示 CPU/内存使用率

### 4.3 触发自动扩缩容

```bash
# 生成负载触发扩容
for i in {1..100}; do
  curl http://<service-url>/api/data?size=100 &
done
wait

# 查看 HPA 状态变化
kubectl get hpa -n cloud-native-demo -w
```

**预期结果：**
- CPU 使用率上升
- HPA 自动增加副本数
- 负载下降后自动减少副本数

---

## 进阶任务3：CI流程集成安全扫描

### 3.1 运行本地安全扫描

```bash
# 运行完整安全扫描
./scripts/security-scan.sh
```

**预期结果：**
- 显示 npm audit 结果
- 显示 ESLint 检查结果
- 显示 Trivy 扫描结果
- 显示 Docker 镜像扫描结果

### 3.2 查看安全扫描配置

```bash
# 查看 Trivy 配置
cat .trivy.yaml

# 查看 Trivy 忽略规则
cat .trivyignore

# 查看 ESLint 配置
cat .eslintrc.js
```

**预期结果：**
- Trivy 配置了扫描严重级别
- Trivyignore 定义了忽略的漏洞
- ESLint 配置了代码规则

### 3.3 查看CI/CD中的安全扫描

访问 GitHub Actions 工作流页面，查看 Security Scan 阶段：
```
https://github.com/your-username/cloud-native-demo/actions
```

**预期结果：**
- Security Scan 阶段自动运行
- 显示扫描结果摘要
- 上传 SARIF 格式的报告到 GitHub Security

### 3.4 查看GitHub Security

访问 GitHub Security 页面：
```
https://github.com/your-username/cloud-native-demo/security
```

**预期结果：**
- 显示依赖漏洞
- 显示代码漏洞
- 显示安全建议

---

## 进阶任务4：GitOps工具（Argo CD）

### 4.1 安装Argo CD

```bash
# 运行安装脚本
./scripts/install-argocd.sh
```

**预期结果：**
- Argo CD 安装到 argocd 命名空间
- 创建 Ingress 访问 Argo CD UI
- 显示初始密码

### 4.2 访问Argo CD UI

打开浏览器访问：
```
https://argocd.local
```

**预期结果：**
- 显示 Argo CD 登录页面
- 使用 admin 和初始密码登录
- 显示应用列表和状态

### 4.3 部署应用到Argo CD

```bash
# 部署应用
./scripts/gitops-deploy.sh deploy --repo https://github.com/your-username/cloud-native-demo.git

# 同步应用
./scripts/gitops-deploy.sh sync

# 查看状态
./scripts/gitops-deploy.sh status
```

**预期结果：**
- 应用创建成功
- 自动同步到 Kubernetes
- 显示应用健康状态

### 4.4 验证GitOps工作流

```bash
# 修改代码
echo "test" >> src/app.js

# 提交到 Git
git add src/app.js
git commit -m "Test GitOps"
git push origin main

# 观察自动同步
./scripts/gitops-deploy.sh status
```

**预期结果：**
- Argo CD 检测到 Git 变更
- 自动同步到集群
- 应用状态更新

### 4.5 查看GitOps配置

```bash
# 查看 Argo CD 项目配置
cat gitops/project.yaml

# 查看应用配置
cat gitops/application.yaml

# 查看值文件
cat gitops/values.yaml
```

**预期结果：**
- 项目配置定义了源仓库和目标集群
- 应用配置定义了同步策略
- 值文件定义了应用参数

---

## 故障模拟与验证

### 运行故障模拟脚本

```bash
# 启动应用
npm start

# 在另一个终端运行故障模拟
./scripts/fault-scenarios.sh
```

**预期结果：**

1. **高错误率场景**
   - 50% 的请求返回 500 错误
   - Prometheus 指标显示错误率上升
   - 触发 HighErrorRate 告警

2. **高延迟场景**
   - 请求延迟增加到 2 秒
   - Prometheus 指标显示延迟上升
   - 触发 HighLatency 告警

3. **流量突增场景**
   - 200 个并发请求
   - CPU 使用率上升
   - 触发自动扩缩容（如果配置了 HPA）

### 验证可观测性

```bash
# 查看指标
curl http://localhost:3000/metrics | grep http_request_duration_seconds

# 查看错误率
curl http://localhost:3000/metrics | grep 'http_requests_total{code="5"'

# 查看日志
tail -f logs/app.log
```

**预期结果：**
- 指标实时更新
- 错误率明显上升
- 日志记录故障信息

---

## 版本追溯链路

### 查看版本信息

```bash
# 通过 API 查看版本
curl http://localhost:3000/info
```

**预期结果：**
```json
{
  "version": "1.0.0",
  "commit": "abc123def456",
  "buildTime": "2024-01-01T00:00:00Z",
  "environment": "production"
}
```

### 运行版本追溯脚本

```bash
# 运行版本追溯
./scripts/trace.sh
```

**预期结果：**
- 显示运行中的 Pod 信息
- 显示使用的镜像 Tag
- 显示对应的 Git Commit SHA
- 显示部署历史

### 验证追溯链路

```bash
# 查看 Pod 信息
kubectl get pods -n cloud-native-demo

# 查看 Pod 使用的镜像
kubectl describe pod <pod-name> -n cloud-native-demo | grep Image

# 查看部署历史
kubectl rollout history deployment/cloud-native-demo -n cloud-native-demo
```

**预期结果：**
- Pod 信息完整
- 镜像 Tag 与 Commit 关联
- 部署历史清晰

---

## 综合测试流程

### 完整测试步骤

```bash
# 1. 环境准备
npm install

# 2. 运行测试
npm test

# 3. 运行安全扫描
./scripts/security-scan.sh

# 4. 启动应用
npm start

# 5. 验证应用功能
curl http://localhost:3000/health
curl http://localhost:3000/info
curl http://localhost:3000/metrics

# 6. 运行故障模拟
./scripts/fault-scenarios.sh

# 7. 验证指标和日志
curl http://localhost:3000/metrics
tail -f logs/app.log

# 8. 测试部署策略
./scripts/blue-green.sh deploy-blue
./scripts/canary.sh deploy

# 9. 停止应用
Ctrl+C
```

### 验证清单

- [ ] CI/CD 流水线配置正确
- [ ] 测试全部通过
- [ ] 安全扫描完成
- [ ] 应用正常启动
- [ ] 健康检查通过
- [ ] 指标正常采集
- [ ] 日志正常记录
- [ ] 故障模拟触发告警
- [ ] 蓝绿部署成功
- [ ] 金丝雀发布成功
- [ ] 版本追溯完整

---

## 常见问题

### Q: 如何查看CI/CD运行日志？

A: 访问 GitHub Actions 页面，点击具体的工作流运行，查看每个阶段的详细日志。

### Q: 如何查看Prometheus指标？

A: 访问 `http://localhost:3000/metrics` 查看 Prometheus 格式的指标。

### Q: 如何触发自动扩缩容？

A: 生成高负载，例如使用 `ab` 或 `wrk` 工具进行压力测试。

### Q: 如何查看Argo CD应用状态？

A: 访问 Argo CD UI `https://argocd.local`，或使用命令 `./scripts/gitops-deploy.sh status`。

### Q: 如何验证GitOps自动同步？

A: 修改代码并推送到 Git，观察 Argo CD 自动同步到集群。

---

## 总结

通过以上步骤，您可以完整地验证所有任务的实验结果：

1. **CI/CD 流水线** - GitHub Actions 自动化构建、测试、部署
2. **可观测性闭环** - Prometheus 指标、Loki 日志、Alertmanager 告警
3. **蓝绿部署** - 零停机切换流量
4. **金丝雀发布** - 逐步验证新版本
5. **HPA 自动扩缩容** - 根据负载自动调整副本数
6. **安全扫描** - CI 流程集成漏洞扫描
7. **GitOps** - 通过 Git 管理部署状态

所有任务已 100% 完成！
