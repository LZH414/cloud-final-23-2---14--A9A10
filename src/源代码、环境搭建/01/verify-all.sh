#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check_item() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    local description="$1"
    local command="$2"
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_item_with_output() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    local description="$1"
    local command="$2"
    
    output=$(eval "$command" 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $description"
        echo -e "    ${CYAN}输出:${NC} $output"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        echo -e "    ${YELLOW}错误:${NC} $output"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
    echo ""
}

print_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║   从代码到上线 + 可观测性闭环 - 完整验证系统                   ║
║                                                                ║
║   Code to Production + Observability Loop Verification        ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

print_summary() {
    echo ""
    echo -e "${BOLD}${CYAN}==========================================${NC}"
    echo -e "${BOLD}${CYAN}  验证总结${NC}"
    echo -e "${BOLD}${CYAN}==========================================${NC}"
    echo ""
    echo -e "总检查项: ${BOLD}$TOTAL_CHECKS${NC}"
    echo -e "通过: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "失败: ${RED}$FAILED_CHECKS${NC}"
    echo ""
    
    local percentage=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        percentage=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi
    
    echo -e "完成度: ${BOLD}${percentage}%${NC}"
    echo ""
    
    if [ $percentage -eq 100 ]; then
        echo -e "${GREEN}${BOLD}🎉 所有验证通过！项目完全符合要求！${NC}"
    elif [ $percentage -ge 80 ]; then
        echo -e "${YELLOW}${BOLD}⚠️  大部分验证通过，有少量问题需要修复${NC}"
    elif [ $percentage -ge 60 ]; then
        echo -e "${YELLOW}${BOLD}⚠️  部分验证通过，需要修复较多问题${NC}"
    else
        echo -e "${RED}${BOLD}❌ 验证失败较多，需要全面检查${NC}"
    fi
    echo ""
}

print_header

print_section "一、构建完整的 CI/CD 流水线（交付链路）"

echo -e "${BOLD}${MAGENTA}1.1 工作流配置验证${NC}"
check_item "GitHub Actions 工作流文件存在" "[ -f '.github/workflows/ci-cd.yml' ]"
check_item "工作流配置有效" "yq eval '.jobs | keys' .github/workflows/ci-cd.yml > /dev/null 2>&1 || grep -q 'jobs:' .github/workflows/ci-cd.yml"

echo ""
echo -e "${BOLD}${MAGENTA}1.2 工作流阶段验证${NC}"
check_item "test 阶段存在" "grep -q '^  test:' .github/workflows/ci-cd.yml"
check_item "security-scan 阶段存在" "grep -q '^  security-scan:' .github/workflows/ci-cd.yml"
check_item "build 阶段存在" "grep -q '^  build:' .github/workflows/ci-cd.yml"
check_item "deploy 阶段存在" "grep -q '^  deploy:' .github/workflows/ci-cd.yml"

echo ""
echo -e "${BOLD}${MAGENTA}1.3 工作流依赖关系验证${NC}"
check_item "security-scan 依赖 test" "grep -A 10 '^  security-scan:' .github/workflows/ci-cd.yml | grep -q 'needs: test'"
check_item "build 依赖 test 和 security-scan" "grep -A 10 '^  build:' .github/workflows/ci-cd.yml | grep -q 'needs: \[test, security-scan\]'"
check_item "deploy 依赖 build" "grep -A 10 '^  deploy:' .github/workflows/ci-cd.yml | grep -q 'needs: build'"

echo ""
echo -e "${BOLD}${MAGENTA}1.4 触发条件验证${NC}"
check_item "配置了 push 触发" "grep -A 5 '^on:' .github/workflows/ci-cd.yml | grep -q 'push:'"
check_item "配置了 pull_request 触发" "grep -A 10 '^on:' .github/workflows/ci-cd.yml | grep -q 'pull_request:'"
check_item "build 仅在 push 时执行" "grep -A 10 '^  build:' .github/workflows/ci-cd.yml | grep -q \"if: github.event_name == 'push'\""
check_item "deploy 仅在 main 分支执行" "grep -A 10 '^  deploy:' .github/workflows/ci-cd.yml | grep -q \"if: github.ref == 'refs/heads/main'\""

echo ""
echo -e "${BOLD}${MAGENTA}1.5 环境变量配置验证${NC}"
check_item "配置了镜像仓库 REGISTRY" "grep -A 5 '^env:' .github/workflows/ci-cd.yml | grep -q 'REGISTRY:'"
check_item "配置了镜像名称 IMAGE_NAME" "grep -A 5 '^env:' .github/workflows/ci-cd.yml | grep -q 'IMAGE_NAME:'"
check_item "REGISTRY 设置为 ghcr.io" "grep -A 5 '^env:' .github/workflows/ci-cd.yml | grep 'REGISTRY:' | grep -q 'ghcr.io'"

echo ""
echo -e "${BOLD}${MAGENTA}1.6 测试阶段验证${NC}"
check_item "配置了 npm install" "grep -A 50 '^  test:' .github/workflows/ci-cd.yml | grep -q 'npm install'"
check_item "配置了 npm run lint" "grep -A 50 '^  test:' .github/workflows/ci-cd.yml | grep -q 'npm run lint'"
check_item "配置了 npm test" "grep -A 50 '^  test:' .github/workflows/ci-cd.yml | grep -q 'npm test'"
check_item "配置了代码覆盖率上传" "grep -A 50 '^  test:' .github/workflows/ci-cd.yml | grep -q 'codecov'"

echo ""
echo -e "${BOLD}${MAGENTA}1.7 安全扫描验证${NC}"
check_item "配置了 Trivy 漏洞扫描" "grep -A 50 '^  security-scan:' .github/workflows/ci-cd.yml | grep -q 'Trivy'"
check_item "配置了 npm audit" "grep -A 50 '^  security-scan:' .github/workflows/ci-cd.yml | grep -q 'npm audit'"
check_item "配置了 SARIF 格式输出" "grep -A 50 '^  security-scan:' .github/workflows/ci-cd.yml | grep -q 'sarif'"
check_item "配置了安全结果上传" "grep -A 50 '^  security-scan:' .github/workflows/ci-cd.yml | grep -q 'github/codeql-action/upload-sarif'"

echo ""
echo -e "${BOLD}${MAGENTA}1.8 构建阶段验证${NC}"
check_item "配置了 Docker Buildx" "grep -A 50 '^  build:' .github/workflows/ci-cd.yml | grep -q 'docker/setup-buildx-action'"
check_item "配置了容器仓库登录" "grep -A 50 '^  build:' .github/workflows/ci-cd.yml | grep -q 'docker/login-action'"
check_item "配置了镜像元数据提取" "grep -A 50 '^  build:' .github/workflows/ci-cd.yml | grep -q 'docker/metadata-action'"
check_item "配置了镜像构建和推送" "grep -A 50 '^  build:' .github/workflows/ci-cd.yml | grep -q 'docker/build-push-action'"
check_item "配置了构建缓存" "grep -A 50 '^  build:' .github/workflows/ci-cd.yml | grep -q 'cache-from'"
check_item "配置了镜像标签策略" "grep -A 50 '^  build:' .github/workflows/ci-cd.yml | grep -q 'type=ref,event=branch'"

echo ""
echo -e "${BOLD}${MAGENTA}1.9 部署阶段验证${NC}"
check_item "配置了 kubectl 工具" "grep -A 50 '^  deploy:' .github/workflows/ci-cd.yml | grep -q 'azure/setup-kubectl'"
check_item "配置了 kubectl 配置" "grep -A 50 '^  deploy:' .github/workflows/ci-cd.yml | grep -q 'kubectl config'"
check_item "配置了镜像更新命令" "grep -A 50 '^  deploy:' .github/workflows/ci-cd.yml | grep -q 'kubectl set image'"
check_item "配置了滚动更新等待" "grep -A 50 '^  deploy:' .github/workflows/ci-cd.yml | grep -q 'kubectl rollout status'"
check_item "配置了部署验证" "grep -A 50 '^  deploy:' .github/workflows/ci-cd.yml | grep -q 'kubectl get pods'"

echo ""
echo -e "${BOLD}${MAGENTA}1.10 版本追溯链路验证${NC}"
check_item "Dockerfile 存在" "[ -f 'Dockerfile' ]"
check_item "Dockerfile 配置了构建时间参数" "grep -q 'ARG BUILD_TIME' Dockerfile"
check_item "Dockerfile 配置了 Git 提交参数" "grep -q 'ARG GIT_COMMIT' Dockerfile"
check_item "Dockerfile 配置了镜像标签" "grep -q 'org.opencontainers.image' Dockerfile"
check_item "应用代码包含版本信息" "grep -q 'version' package.json"
check_item "应用代码包含 Git 提交信息" "grep -q 'git' src/app.js"

echo ""
echo -e "${BOLD}${MAGENTA}1.11 Docker 配置验证${NC}"
check_item "docker-compose.yml 存在" "[ -f 'docker-compose.yml' ]"
check_item "docker-compose.yml 包含应用服务" "grep -q 'app:' docker-compose.yml"
check_item "docker-compose.yml 包含 Prometheus 服务" "grep -q 'prometheus:' docker-compose.yml"
check_item "docker-compose.yml 包含 Grafana 服务" "grep -q 'grafana:' docker-compose.yml"
check_item "docker-compose.yml 包含 Loki 服务" "grep -q 'loki:' docker-compose.yml"

echo ""
echo -e "${BOLD}${MAGENTA}1.12 Kubernetes 配置验证${NC}"
check_item "K8s 配置目录存在" "[ -d 'k8s' ]"
check_item "namespace.yaml 存在" "[ -f 'k8s/namespace.yaml' ]"
check_item "deployment.yaml 存在" "[ -f 'k8s/deployment.yaml' ]"
check_item "service.yaml 存在" "[ -f 'k8s/service.yaml' ]"
check_item "hpa.yaml 存在" "[ -f 'k8s/hpa.yaml' ]"
check_item "Deployment 配置了健康检查" "grep -q 'livenessProbe\|readinessProbe' k8s/deployment.yaml"
check_item "Deployment 配置了资源限制" "grep -q 'resources:' k8s/deployment.yaml"

print_section "二、搭建可观测性闭环（稳定性保障）"

echo -e "${BOLD}${MAGENTA}2.1 Prometheus 配置验证${NC}"
check_item "Prometheus 配置文件存在" "[ -f 'monitoring/prometheus/prometheus.yml' ]"
check_item "Prometheus 配置了应用抓取" "grep -q 'job_name.*app' monitoring/prometheus/prometheus.yml"
check_item "Prometheus 配置了告警规则" "grep -q 'alerting:' monitoring/prometheus/prometheus.yml"
check_item "Prometheus 告警规则文件存在" "[ -f 'monitoring/prometheus/alerts.yml' ]"
check_item "配置了高错误率告警" "grep -q 'HighErrorRate' monitoring/prometheus/alerts.yml"
check_item "配置了高延迟告警" "grep -q 'HighLatency' monitoring/prometheus/alerts.yml"
check_item "配置了高CPU使用率告警" "grep -q 'HighCPUUsage' monitoring/prometheus/alerts.yml"

echo ""
echo -e "${BOLD}${MAGENTA}2.2 应用指标验证${NC}"
check_item "应用代码引入了 prom-client" "grep -q 'prom-client' package.json"
check_item "应用配置了 HTTP 请求计数器" "grep -q 'http_requests_total' src/app.js"
check_item "应用配置了请求延迟直方图" "grep -q 'http_request_duration_seconds' src/app.js"
check_item "应用配置了活跃连接数" "grep -q 'active_connections' src/app.js"
check_item "应用暴露了 /metrics 端点" "grep -q '/metrics' src/app.js"
check_item "应用指标包含状态码标签" "grep -q 'code' src/app.js | grep -q 'labelNames'"

echo ""
echo -e "${BOLD}${MAGENTA}2.3 Grafana 配置验证${NC}"
check_item "Grafana 配置文件存在" "[ -f 'monitoring/grafana/grafana.ini' ]"
check_item "Grafana 数据源配置存在" "[ -f 'monitoring/grafana/provisioning/datasources/prometheus.yml' ]"
check_item "Grafana 仪表板配置存在" "[ -f 'monitoring/grafana/provisioning/dashboards/dashboard.yml' ]"
check_item "Grafana 配置了 Prometheus 数据源" "grep -q 'prometheus' monitoring/grafana/provisioning/datasources/prometheus.yml"

echo ""
echo -e "${BOLD}${MAGENTA}2.4 Loki 配置验证${NC}"
check_item "Loki 配置文件存在" "[ -f 'monitoring/loki/loki-config.yml' ]"
check_item "Loki 配置了存储" "grep -q 'storage:' monitoring/loki/loki-config.yml"
check_item "Loki 配置了 API" "grep -q 'http_server_config:' monitoring/loki/loki-config.yml"

echo ""
echo -e "${BOLD}${MAGENTA}2.5 Promtail 配置验证${NC}"
check_item "Promtail 配置文件存在" "[ -f 'monitoring/promtail/promtail-config.yml' ]"
check_item "Promtail 配置了应用日志采集" "grep -q 'job_name.*app' monitoring/promtail/promtail-config.yml"
check_item "Promtail 配置了 Loki 输出" "grep -q 'loki' monitoring/promtail/promtail-config.yml"

echo ""
echo -e "${BOLD}${MAGENTA}2.6 应用日志验证${NC}"
check_item "应用代码引入了 winston" "grep -q 'winston' package.json"
check_item "应用配置了日志格式" "grep -q 'format' src/app.js | grep -q 'winston'"
check_item "应用配置了日志级别" "grep -q 'level' src/app.js | grep -q 'winston'"
check_item "应用配置了日志传输" "grep -q 'transports' src/app.js | grep -q 'winston'"

echo ""
echo -e "${BOLD}${MAGENTA}2.7 Alertmanager 配置验证${NC}"
check_item "Alertmanager 配置文件存在" "[ -f 'monitoring/alertmanager/alertmanager.yml' ]"
check_item "Alertmanager 配置了路由" "grep -q 'route:' monitoring/alertmanager/alertmanager.yml"
check_item "Alertmanager 配置了接收器" "grep -q 'receivers:' monitoring/alertmanager/alertmanager.yml"
check_item "Alertmanager 配置了告警分组" "grep -q 'group_by' monitoring/alertmanager/alertmanager.yml"

echo ""
echo -e "${BOLD}${MAGENTA}2.8 故障模拟验证${NC}"
check_item "故障模拟脚本存在" "[ -f 'scripts/fault-scenarios.sh' ]"
check_item "应用配置了故障模拟端点" "grep -q '/simulate-error' src/app.js || grep -q '/fault' src/app.js"
check_item "应用配置了高延迟模拟" "grep -q 'delay' src/app.js | grep -q 'simulate'"
check_item "应用配置了错误率模拟" "grep -q 'error' src/app.js | grep -q 'simulate'"

print_section "三、进阶任务验证"

echo -e "${BOLD}${MAGENTA}3.1 蓝绿部署验证${NC}"
check_item "蓝绿部署脚本存在" "[ -f 'scripts/blue-green.sh' ]"
check_item "蓝绿配置文件存在" "[ -f 'k8s/blue-green.yaml' ] || [ -f 'k8s/blue-green-deployment.yaml' ]"
check_item "蓝绿部署脚本包含切换逻辑" "grep -q 'switch\|traffic' scripts/blue-green.sh"

echo ""
echo -e "${BOLD}${MAGENTA}3.2 金丝雀发布验证${NC}"
check_item "金丝雀发布脚本存在" "[ -f 'scripts/canary.sh' ]"
check_item "金丝雀配置文件存在" "[ -f 'k8s/canary.yaml' ] || [ -f 'k8s/canary-deployment.yaml' ]"
check_item "金丝雀发布脚本包含流量控制" "grep -q 'traffic\|weight' scripts/canary.sh"

echo ""
echo -e "${BOLD}${MAGENTA}3.3 HPA 自动扩缩容验证${NC}"
check_item "HPA 配置文件存在" "[ -f 'k8s/hpa.yaml' ]"
check_item "HPA 配置了 CPU 指标" "grep -q 'cpu' k8s/hpa.yaml"
check_item "HPA 配置了自定义指标" "grep -q 'custom\|metrics' k8s/hpa.yaml"
check_item "HPA 配置了最小副本数" "grep -q 'minReplicas' k8s/hpa.yaml"
check_item "HPA 配置了最大副本数" "grep -q 'maxReplicas' k8s/hpa.yaml"

echo ""
echo -e "${BOLD}${MAGENTA}3.4 安全扫描验证${NC}"
check_item "Trivy 配置文件存在" "[ -f '.trivy.yaml' ]"
check_item "Trivy 忽略文件存在" "[ -f '.trivyignore' ]"
check_item "ESLint 配置文件存在" "[ -f '.eslintrc.js' ] || [ -f '.eslintrc.json' ]"
check_item "npm 配置文件存在" "[ -f '.npmrc' ]"
check_item "npm 配置了审计级别" "grep -q 'audit-level' .npmrc"
check_item "安全扫描脚本存在" "[ -f 'scripts/security-scan.sh' ]"

echo ""
echo -e "${BOLD}${MAGENTA}3.5 GitOps 验证${NC}"
check_item "GitOps 目录存在" "[ -d 'gitops' ]"
check_item "Argo CD 应用配置存在" "[ -f 'gitops/application.yaml' ]"
check_item "Argo CD 项目配置存在" "[ -f 'gitops/project.yaml' ]"
check_item "Argo CD 安装脚本存在" "[ -f 'scripts/install-argocd.sh' ]"
check_item "GitOps 部署脚本存在" "[ -f 'scripts/gitops-deploy.sh' ]"
check_item "Argo CD 配置了自动同步" "grep -q 'syncPolicy' gitops/application.yaml"
check_item "Argo CD 配置了自愈" "grep -q 'selfHeal' gitops/application.yaml"

print_section "四、文档和脚本验证"

echo -e "${BOLD}${MAGENTA}4.1 文档验证${NC}"
check_item "README.md 存在" "[ -f 'README.md' ]"
check_item "README 包含 CI/CD 说明" "grep -q 'CI/CD\|GitHub Actions' README.md"
check_item "README 包含可观测性说明" "grep -q 'Prometheus\|Grafana\|Loki' README.md"
check_item "INSTALL.md 存在" "[ -f 'INSTALL.md' ]"
check_item "STRUCTURE.md 存在" "[ -f 'STRUCTURE.md' ]"
check_item "RESULTS.md 存在" "[ -f 'RESULTS.md' ]"
check_item "GITOPS.md 存在" "[ -f 'GITOPS.md' ]"

echo ""
echo -e "${BOLD}${MAGENTA}4.2 脚本验证${NC}"
check_item "快速启动脚本存在" "[ -f 'quick-start.sh' ]"
check_item "结果展示脚本存在" "[ -f 'show-results.sh' ]"
check_item "部署脚本存在" "[ -f 'scripts/deploy.sh' ]"
check_item "版本追溯脚本存在" "[ -f 'scripts/trace.sh' ]"
check_item "部署策略脚本存在" "[ -f 'scripts/strategy.sh' ]"

print_section "五、应用功能验证"

echo -e "${BOLD}${MAGENTA}5.1 基础功能验证${NC}"
check_item "应用入口文件存在" "[ -f 'src/app.js' ]"
check_item "package.json 存在" "[ -f 'package.json' ]"
check_item "配置了启动脚本" "grep -q '\"start\"' package.json"
check_item "配置了测试脚本" "grep -q '\"test\"' package.json"
check_item "配置了 lint 脚本" "grep -q '\"lint\"' package.json"
check_item "应用配置了健康检查端点" "grep -q '/health\|/ping' src/app.js"
check_item "应用配置了根路由" "grep -q "app.get.*'/'" src/app.js || grep -q 'app.get.*"/"' src/app.js"

echo ""
echo -e "${BOLD}${MAGENTA}5.2 依赖验证${NC}"
check_item "安装了 express" "grep -q '\"express\"' package.json"
check_item "安装了 prom-client" "grep -q '\"prom-client\"' package.json"
check_item "安装了 winston" "grep -q '\"winston\"' package.json"
check_item "安装了 jest" "grep -q '\"jest\"' package.json"
check_item "安装了 eslint" "grep -q '\"eslint\"' package.json"

print_section "六、运行时验证（可选）"

echo -e "${BOLD}${YELLOW}注意：以下验证需要应用正在运行${NC}"
echo ""

echo -e "${BOLD}${MAGENTA}6.1 应用运行状态${NC}"
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    check_item "应用健康检查端点可访问" "curl -s http://localhost:3000/health > /dev/null 2>&1"
else
    echo -e "  ${YELLOW}⊘${NC} 应用未运行，跳过运行时验证"
fi

if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo ""
    echo -e "${BOLD}${MAGENTA}6.2 指标端点验证${NC}"
    check_item "Prometheus 指标端点可访问" "curl -s http://localhost:3000/metrics | grep -q 'http_requests_total'"
    check_item "指标包含状态码标签" "curl -s http://localhost:3000/metrics | grep -q 'code=\"200\"'"
    
    echo ""
    echo -e "${BOLD}${MAGENTA}6.3 应用端点验证${NC}"
    check_item "根路由可访问" "curl -s http://localhost:3000/ | grep -q 'Hello'"
    check_item "版本端点可访问" "curl -s http://localhost:3000/version > /dev/null 2>&1"
    
    echo ""
    echo -e "${BOLD}${MAGENTA}6.4 故障模拟端点验证${NC}"
    check_item "错误模拟端点存在" "curl -s http://localhost:3000/simulate-error 2>&1 | head -1"
fi

print_summary

echo -e "${BOLD}${CYAN}==========================================${NC}"
echo -e "${BOLD}${CYAN}  详细报告已生成${NC}"
echo -e "${BOLD}${CYAN}==========================================${NC}"
echo ""
echo -e "如需查看特定部分的详细信息，请运行："
echo -e "  ${GREEN}./verify-cicd.sh${NC}           - CI/CD 流水线验证"
echo -e "  ${GREEN}./verify-observability.sh${NC} - 可观测性验证"
echo -e "  ${GREEN}./verify-gitops.sh${NC}         - GitOps 验证"
echo ""
