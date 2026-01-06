#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="argocd"

echo -e "${YELLOW}=== Argo CD 安装脚本 ===${NC}"
echo ""

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}错误: kubectl 未安装${NC}"
        echo "请先安装 kubectl: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}错误: 无法连接到 Kubernetes 集群${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC} Kubernetes 集群连接正常"
}

install_argocd() {
    echo -e "${YELLOW}正在安装 Argo CD...${NC}"
    
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -n ${NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo -e "${GREEN}✓${NC} Argo CD 安装完成"
}

wait_for_argocd() {
    echo -e "${YELLOW}等待 Argo CD Pods 就绪...${NC}"
    
    kubectl wait \
        --for=condition=ready pod \
        -l app.kubernetes.io/name=argocd-server \
        -n ${NAMESPACE} \
        --timeout=300s
    
    echo -e "${GREEN}✓${NC} Argo CD Pods 已就绪"
}

create_ingress() {
    echo -e "${YELLOW}创建 Argo CD Ingress...${NC}"
    
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: ${NAMESPACE}
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF
    
    echo -e "${GREEN}✓${NC} Argo CD Ingress 创建完成"
    echo "访问地址: https://argocd.local"
}

get_password() {
    echo -e "${YELLOW}获取 Argo CD 初始密码...${NC}"
    
    INITIAL_PASSWORD=$(kubectl -n ${NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo -e "${GREEN}初始用户名: admin${NC}"
    echo -e "${GREEN}初始密码: ${INITIAL_PASSWORD}${NC}"
    echo ""
    echo "首次登录后请修改密码"
}

install_cli() {
    echo -e "${YELLOW}检查 Argo CD CLI...${NC}"
    
    if ! command -v argocd &> /dev/null; then
        echo "Argo CD CLI 未安装"
        echo "安装命令:"
        echo "  macOS: brew install argocd"
        echo "  Linux: curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
        echo "         sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
    else
        echo -e "${GREEN}✓${NC} Argo CD CLI 已安装"
    fi
}

main() {
    check_kubectl
    install_argocd
    wait_for_argocd
    create_ingress
    get_password
    install_cli
    
    echo ""
    echo -e "${GREEN}=== Argo CD 安装完成 ===${NC}"
    echo ""
    echo "下一步操作:"
    echo "1. 访问 Argo CD UI: https://argocd.local"
    echo "2. 使用初始密码登录"
    echo "3. 运行 ./scripts/gitops-deploy.sh 部署应用"
}

main "$@"
