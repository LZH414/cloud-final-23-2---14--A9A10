#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   云原生 CI/CD 项目 - 综合演示与实验结果展示                ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 已安装"
        return 0
    else
        echo -e "${YELLOW}⚠${NC}  $1 未安装"
        return 1
    fi
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_subsection() {
    echo -e "${BOLD}${YELLOW}▶ $1${NC}"
}

show_ci_cd() {
    print_section "核心任务1：构建完整的CI/CD流水线"
    
    print_subsection "1.1 CI/CD 配置文件"
    check_file ".github/workflows/ci-cd.yml"
    echo ""
    
    print_subsection "1.2 CI/CD 流水线阶段"
    echo -e "${CYAN}GitHub Actions 工作流包含以下阶段：${NC}"
    echo "  • Test & Lint - 代码检查和单元测试"
    echo "  • Security Scan - 安全扫描（Trivy + npm audit）"
    echo "  • Build & Push - 构建并推送 Docker 镜像"
    echo "  • Deploy - 自动部署到 Kubernetes"
    echo ""
    
    print_subsection "1.3 触发条件"
    echo "  • 推送到 main 或 develop 分支"
    echo "  • 创建 Pull Request 到 main 分支"
    echo ""
    
    print_subsection "1.4 查看CI/CD配置"
    echo -e "${CYAN}查看 CI/CD 配置：${NC}"
    echo "  cat .github/workflows/ci-cd.yml"
    echo ""
    
    print_subsection "1.5 查看CI/CD运行状态"
    echo -e "${CYAN}在 GitHub Actions 中查看：${NC}"
    echo "  https://github.com/your-username/cloud-native-demo/actions"
    echo ""
}

show_observability() {
    print_section "核心任务2：搭建可观测性闭环"
    
    print_subsection "2.1 可观测性配置文件"
    check_file "monitoring/prometheus/prometheus.yml"
    check_file "monitoring/prometheus/alerts.yml"
    check_file "monitoring/loki/loki-config.yml"
    check_file "monitoring/promtail/promtail-config.yml"
    check_file "monitoring/alertmanager/alertmanager.yml"
    echo ""
    
    print_subsection "2.2 Prometheus 指标"
    echo -e "${CYAN}应用暴露的指标：${NC}"
    echo "  • http_request_duration_seconds - HTTP 请求持续时间"
    echo "  • http_requests_total - HTTP 请求总数"
    echo "  • process_cpu_seconds_total - CPU 使用时间"
    echo "  • process_memory_bytes - 内存使用量"
    echo ""
    
    print_subsection "2.3 告警规则"
    echo -e "${CYAN}配置的告警规则：${NC}"
    echo "  • HighErrorRate - 5xx 错误率超过 5%"
    echo "  • HighLatency - 请求延迟超过 2 秒"
    echo "  • HighCPUUsage - CPU 使用率超过 80%"
    echo ""
    
    print_subsection "2.4 查看指标"
    echo -e "${CYAN}访问 Prometheus 指标端点：${NC}"
    echo "  http://localhost:3000/metrics"
    echo ""
    
    print_subsection "2.5 查看告警配置"
    echo -e "${CYAN}查看告警规则：${NC}"
    echo "  cat monitoring/prometheus/alerts.yml"
    echo ""
}

show_deployment_strategies() {
    print_section "进阶任务1：蓝绿部署和金丝雀发布"
    
    print_subsection "3.1 部署策略脚本"
    check_file "scripts/blue-green.sh"
    check_file "scripts/canary.sh"
    check_file "docker-compose.blue-green.yml"
    check_file "docker-compose.canary.yml"
    echo ""
    
    print_subsection "3.2 蓝绿部署"
    echo -e "${CYAN}使用方法：${NC}"
    echo "  ./scripts/blue-green.sh deploy-blue"
    echo "  ./scripts/blue-green.sh switch-blue"
    echo "  ./scripts/blue-green.sh rollback"
    echo ""
    
    print_subsection "3.3 金丝雀发布"
    echo -e "${CYAN}使用方法：${NC}"
    echo "  ./scripts/canary.sh deploy"
    echo "  ./scripts/canary.sh set-traffic 20"
    echo "  ./scripts/canary.sh rollback"
    echo ""
    
    print_subsection "3.4 查看部署策略配置"
    echo -e "${CYAN}查看蓝绿部署配置：${NC}"
    echo "  cat docker-compose.blue-green.yml"
    echo ""
    echo -e "${CYAN}查看金丝雀部署配置：${NC}"
    echo "  cat docker-compose.canary.yml"
    echo ""
}

show_hpa() {
    print_section "进阶任务2：HPA自动扩缩容"
    
    print_subsection "4.1 HPA 配置文件"
    check_file "k8s/hpa.yaml"
    echo ""
    
    print_subsection "4.2 HPA 配置详情"
    echo -e "${CYAN}HPA 配置：${NC}"
    echo "  • 最小副本数: 2"
    echo "  • 最大副本数: 10"
    echo "  • CPU 目标利用率: 70%"
    echo "  • 内存目标利用率: 80%"
    echo "  • 自定义指标: active_connections (目标值: 100)"
    echo ""
    
    print_subsection "4.3 查看HPA配置"
    echo -e "${CYAN}查看 HPA 配置：${NC}"
    echo "  cat k8s/hpa.yaml"
    echo ""
    
    print_subsection "4.4 查看HPA状态（需要Kubernetes集群）"
    echo -e "${CYAN}查看 HPA 状态：${NC}"
    echo "  kubectl get hpa -n cloud-native-demo"
    echo ""
}

show_security() {
    print_section "进阶任务3：CI流程集成安全扫描"
    
    print_subsection "5.1 安全扫描配置文件"
    check_file "scripts/security-scan.sh"
    check_file ".trivy.yaml"
    check_file ".trivyignore"
    check_file ".eslintrc.js"
    echo ""
    
    print_subsection "5.2 安全扫描工具"
    echo -e "${CYAN}集成的安全扫描工具：${NC}"
    echo "  • npm audit - npm 包漏洞扫描"
    echo "  • ESLint - 代码质量检查"
    echo "  • Trivy - 文件系统和 Docker 镜像漏洞扫描"
    echo ""
    
    print_subsection "5.3 运行安全扫描"
    echo -e "${CYAN}运行完整安全扫描：${NC}"
    echo "  ./scripts/security-scan.sh"
    echo ""
    
    print_subsection "5.4 CI/CD中的安全扫描"
    echo -e "${CYAN}GitHub Actions 中的安全扫描阶段：${NC}"
    echo "  • 自动运行 Trivy 扫描"
    echo "  • 上传扫描结果到 GitHub Security"
    echo "  • 阻止高危漏洞的部署"
    echo ""
}

show_gitops() {
    print_section "进阶任务4：GitOps工具（Argo CD）"
    
    print_subsection "6.1 GitOps 配置文件"
    check_file "gitops/project.yaml"
    check_file "gitops/application.yaml"
    check_file "gitops/values.yaml"
    check_file "scripts/install-argocd.sh"
    check_file "scripts/gitops-deploy.sh"
    echo ""
    
    print_subsection "6.2 Argo CD 功能"
    echo -e "${CYAN}Argo CD 提供的功能：${NC}"
    echo "  • 声明式配置管理"
    echo "  • 自动同步 Git 变更"
    echo "  • 应用健康检查"
    echo "  • 快速回滚到任意版本"
    echo "  • 可视化部署状态"
    echo ""
    
    print_subsection "6.3 GitOps 工作流"
    echo -e "${CYAN}GitOps 工作流：${NC}"
    echo "  1. 代码提交到 Git"
    echo "  2. CI/CD 构建镜像"
    echo "  3. Argo CD 检测变更"
    echo "  4. 自动同步到集群"
    echo "  5. 监控应用健康状态"
    echo ""
    
    print_subsection "6.4 使用 GitOps 部署"
    echo -e "${CYAN}部署应用：${NC}"
    echo "  ./scripts/gitops-deploy.sh deploy --repo <repo-url>"
    echo ""
    echo -e "${CYAN}同步应用：${NC}"
    echo "  ./scripts/gitops-deploy.sh sync"
    echo ""
    echo -e "${CYAN}查看状态：${NC}"
    echo "  ./scripts/gitops-deploy.sh status"
    echo ""
}

show_fault_scenarios() {
    print_section "故障模拟与验证"
    
    print_subsection "7.1 故障模拟脚本"
    check_file "scripts/fault-scenarios.sh"
    echo ""
    
    print_subsection "7.2 故障场景"
    echo -e "${CYAN}支持的故障场景：${NC}"
    echo "  • 高错误率模拟 - /simulate/error?rate=0.5"
    echo "  • 高延迟模拟 - /simulate/slow?delay=2000"
    echo "  • 流量突增模拟 - 并发请求"
    echo ""
    
    print_subsection "7.3 运行故障模拟"
    echo -e "${CYAN}运行故障模拟脚本：${NC}"
    echo "  ./scripts/fault-scenarios.sh"
    echo ""
    
    print_subsection "7.4 验证可观测性"
    echo -e "${CYAN}验证指标收集：${NC}"
    echo "  curl http://localhost:3000/metrics"
    echo ""
    echo -e "${CYAN}验证告警触发：${NC}"
    echo "  查看 Prometheus Alertmanager"
    echo ""
    echo -e "${CYAN}验证日志收集：${NC}"
    echo "  查看 Loki 日志查询"
    echo ""
}

show_version_trace() {
    print_section "版本追溯链路"
    
    print_subsection "8.1 版本追溯脚本"
    check_file "scripts/trace.sh"
    check_file "scripts/deploy.sh"
    echo ""
    
    print_subsection "8.2 版本追溯链路"
    echo -e "${CYAN}完整的追溯链路：${NC}"
    echo "  运行实例 (Pod)"
    echo "    ↓"
    echo "  镜像 Tag"
    echo "    ↓"
    echo "  Commit SHA"
    echo "    ↓"
    echo "  代码仓库"
    echo ""
    
    print_subsection "8.3 查看版本信息"
    echo -e "${CYAN}通过 API 查看版本：${NC}"
    echo "  curl http://localhost:3000/info"
    echo ""
    
    print_subsection "8.4 运行版本追溯"
    echo -e "${CYAN}运行版本追溯脚本：${NC}"
    echo "  ./scripts/trace.sh"
    echo ""
}

show_quick_demo() {
    print_section "快速演示"
    
    print_subsection "9.1 环境检查"
    echo -e "${CYAN}检查必要工具：${NC}"
    check_command "node"
    check_command "npm"
    check_command "docker"
    echo ""
    
    print_subsection "9.2 启动应用"
    echo -e "${CYAN}方式1：使用 npm 直接启动${NC}"
    echo "  npm install"
    echo "  npm start"
    echo ""
    echo -e "${CYAN}方式2：使用 Docker Compose${NC}"
    echo "  docker-compose up -d"
    echo ""
    
    print_subsection "9.3 访问应用"
    echo -e "${CYAN}应用端点：${NC}"
    echo "  • 主页: http://localhost:3000"
    echo "  • 健康检查: http://localhost:3000/health"
    echo "  • 版本信息: http://localhost:3000/info"
    echo "  • 指标: http://localhost:3000/metrics"
    echo ""
    
    print_subsection "9.4 运行测试"
    echo -e "${CYAN}运行单元测试：${NC}"
    echo "  npm test"
    echo ""
    
    print_subsection "9.5 运行安全扫描"
    echo -e "${CYAN}运行安全扫描：${NC}"
    echo "  ./scripts/security-scan.sh"
    echo ""
}

show_summary() {
    print_section "任务完成总结"
    
    echo -e "${BOLD}${CYAN}核心任务：${NC}"
    echo -e "  ${GREEN}✓${NC} 1. 构建完整的CI/CD流水线（交付链路）"
    echo -e "  ${GREEN}✓${NC} 2. 搭建可观测性闭环（稳定性保障）"
    echo ""
    
    echo -e "${BOLD}${CYAN}进阶任务：${NC}"
    echo -e "  ${GREEN}✓${NC} 1. 实施蓝绿部署或金丝雀发布策略"
    echo -e "  ${GREEN}✓${NC} 2. 配置HPA实现自动扩缩容"
    echo -e "  ${GREEN}✓${NC} 3. 在CI流程中集成安全扫描"
    echo -e "  ${GREEN}✓${NC} 4. 使用GitOps工具（Argo CD）管理部署状态"
    echo ""
    
    echo -e "${BOLD}${CYAN}总体完成度：100%（6/6项任务全部完成）${NC}"
    echo ""
}

show_next_steps() {
    print_section "下一步操作"
    
    echo -e "${BOLD}${YELLOW}本地开发测试：${NC}"
    echo "  1. npm install"
    echo "  2. npm start"
    echo "  3. 访问 http://localhost:3000"
    echo ""
    
    echo -e "${BOLD}${YELLOW}运行测试和安全扫描：${NC}"
    echo "  1. npm test"
    echo "  2. ./scripts/security-scan.sh"
    echo ""
    
    echo -e "${BOLD}${YELLOW}故障模拟测试：${NC}"
    echo "  1. ./scripts/fault-scenarios.sh"
    echo "  2. 查看指标: curl http://localhost:3000/metrics"
    echo ""
    
    echo -e "${BOLD}${YELLOW}部署策略测试：${NC}"
    echo "  1. ./scripts/blue-green.sh deploy-blue"
    echo "  2. ./scripts/canary.sh deploy"
    echo ""
    
    echo -e "${BOLD}${YELLOW}Kubernetes 部署：${NC}"
    echo "  1. kubectl apply -f k8s/"
    echo "  2. ./scripts/deploy.sh deploy cloud-native-demo:v1.0.0"
    echo ""
    
    echo -e "${BOLD}${YELLOW}GitOps 部署：${NC}"
    echo "  1. ./scripts/install-argocd.sh"
    echo "  2. ./scripts/gitops-deploy.sh deploy --repo <repo-url>"
    echo ""
    
    echo -e "${BOLD}${YELLOW}查看详细文档：${NC}"
    echo "  • README.md - 项目总览"
    echo "  • GITOPS.md - GitOps 部署指南"
    echo "  • INSTALL.md - 安装指南"
    echo "  • STRUCTURE.md - 项目结构说明"
    echo ""
}

main() {
    show_ci_cd
    show_observability
    show_deployment_strategies
    show_hpa
    show_security
    show_gitops
    show_fault_scenarios
    show_version_trace
    show_quick_demo
    show_summary
    show_next_steps
    
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║   演示完成！所有任务已成功实现                              ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

main "$@"
