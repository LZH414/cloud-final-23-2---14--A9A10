#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME="cloud-native-demo"
NAMESPACE="argocd"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<EOF
GitOps 部署管理脚本

用法: $0 [命令] [选项]

命令:
  deploy      部署应用到集群
  sync        同步应用状态
  status      查看应用状态
  rollback    回滚到上一个版本
  delete      删除应用
  logs        查看应用日志
  help        显示帮助信息

选项:
  --repo      Git仓库地址
  --revision  Git分支或commit (默认: HEAD)
  --app       应用名称 (默认: cloud-native-demo)

示例:
  $0 deploy --repo https://github.com/user/repo.git
  $0 sync
  $0 status
  $0 rollback
EOF
}

check_argocd_cli() {
    if ! command -v argocd &> /dev/null; then
        echo -e "${RED}错误: argocd CLI 未安装${NC}"
        echo "请先安装 Argo CD CLI"
        exit 1
    fi
    
    if ! argocd cluster list &> /dev/null; then
        echo -e "${YELLOW}警告: 未连接到 Argo CD 服务器${NC}"
        echo "请先登录: argocd login <server-address>"
        exit 1
    fi
}

create_project() {
    echo -e "${YELLOW}创建 Argo CD Project...${NC}"
    
    argocd proj create ${APP_NAME} \
        --src https://github.com/your-username/cloud-native-demo.git \
        --dest https://kubernetes.default.svc,${APP_NAME} \
        -d https://kubernetes.default.svc,argocd \
        --allow-cluster-resource Namespace \
        --description "Cloud Native Demo Project" 2>/dev/null || \
        echo -e "${BLUE}Project 已存在${NC}"
    
    echo -e "${GREEN}✓${NC} Project 创建完成"
}

deploy_app() {
    local repo=$1
    local revision=${2:-HEAD}
    
    echo -e "${YELLOW}部署应用: ${APP_NAME}${NC}"
    
    create_project
    
    if [ -z "$repo" ]; then
        echo -e "${RED}错误: 请提供 Git 仓库地址${NC}"
        echo "使用: $0 deploy --repo <repo-url>"
        exit 1
    fi
    
    argocd app create ${APP_NAME} \
        --repo ${repo} \
        --path k8s \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace ${APP_NAME} \
        --revision ${revision} \
        --sync-policy automated \
        --auto-prune \
        --self-heal \
        --upsert 2>/dev/null || \
        argocd app get ${APP_NAME} > /dev/null 2>&1 && \
        argocd app set ${APP_NAME} \
            --repo ${repo} \
            --revision ${revision} \
            --sync-policy automated \
            --auto-prune \
            --self-heal
    
    echo -e "${GREEN}✓${NC} 应用部署完成"
    echo ""
    echo "访问应用: argocd app get ${APP_NAME}"
}

sync_app() {
    echo -e "${YELLOW}同步应用: ${APP_NAME}${NC}"
    
    argocd app sync ${APP_NAME} \
        --force \
        --prune
    
    echo -e "${GREEN}✓${NC} 应用同步完成"
}

show_status() {
    echo -e "${YELLOW}应用状态: ${APP_NAME}${NC}"
    echo ""
    
    argocd app get ${APP_NAME} --output wide
    
    echo ""
    echo -e "${BLUE}资源状态:${NC}"
    argocd app resources ${APP_NAME}
    
    echo ""
    echo -e "${BLUE}同步历史:${NC}"
    argocd app history ${APP_NAME}
}

rollback_app() {
    echo -e "${YELLOW}回滚应用: ${APP_NAME}${NC}"
    
    local history=$(argocd app history ${APP_NAME} --output json)
    local deploy_count=$(echo "$history" | jq '.deployedAtHistory | length')
    
    if [ "$deploy_count" -lt 2 ]; then
        echo -e "${RED}错误: 没有可回滚的版本${NC}"
        exit 1
    fi
    
    local previous_revision=$(echo "$history" | jq -r '.deployedAtHistory[1].revision')
    
    echo "回滚到版本: ${previous_revision}"
    argocd app set ${APP_NAME} --revision ${previous_revision}
    argocd app sync ${APP_NAME} --force
    
    echo -e "${GREEN}✓${NC} 应用回滚完成"
}

delete_app() {
    echo -e "${YELLOW}删除应用: ${APP_NAME}${NC}"
    
    read -p "确认删除应用? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        argocd app delete ${APP_NAME} --cascade
        echo -e "${GREEN}✓${NC} 应用已删除"
    else
        echo "取消删除"
    fi
}

show_logs() {
    echo -e "${YELLOW}应用日志: ${APP_NAME}${NC}"
    
    local pod=$(kubectl get pods -n ${APP_NAME} -l app=${APP_NAME} -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$pod" ]; then
        echo -e "${RED}错误: 未找到运行中的 Pod${NC}"
        exit 1
    fi
    
    kubectl logs -n ${APP_NAME} -f ${pod}
}

main() {
    local command=${1:-help}
    shift || true
    
    local repo=""
    local revision="HEAD"
    local app="${APP_NAME}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo)
                repo="$2"
                shift 2
                ;;
            --revision)
                revision="$2"
                shift 2
                ;;
            --app)
                app="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                usage
                exit 1
                ;;
        esac
    done
    
    case $command in
        deploy)
            check_argocd_cli
            deploy_app "$repo" "$revision"
            ;;
        sync)
            check_argocd_cli
            sync_app
            ;;
        status)
            check_argocd_cli
            show_status
            ;;
        rollback)
            check_argocd_cli
            rollback_app
            ;;
        delete)
            check_argocd_cli
            delete_app
            ;;
        logs)
            show_logs
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}未知命令: $command${NC}"
            usage
            exit 1
            ;;
    esac
}

main "$@"
