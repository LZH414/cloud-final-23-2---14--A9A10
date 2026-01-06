#!/bin/bash

set -e

APP_NAME="cloud-native-demo"
STABLE_PORT=3000
CANARY_PORT=3001
NGINX_PORT=8080

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function print_usage() {
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  init              初始化金丝雀部署环境"
    echo "  deploy-canary    部署金丝雀版本"
    echo "  set-traffic       设置金丝雀流量比例 (0-100)"
    echo "  promote           将金丝雀版本提升为稳定版本"
    echo "  rollback          回滚到稳定版本"
    echo "  status            查看当前状态"
    echo "  cleanup           清理环境"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 deploy-canary cloud-native-demo:1.1.0"
    echo "  $0 set-traffic 20"
    echo "  $0 promote"
}

function init() {
    echo -e "${YELLOW}初始化金丝雀部署环境...${NC}"
    
    mkdir -p logs
    
    cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream stable {
        server stable:3000;
    }

    upstream canary {
        server canary:3000;
    }

    split_clients $remote_addr $backend {
        0% canary;
        * stable;
    }

    server {
        listen 8080;
        
        location / {
            proxy_pass http://$backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

    cat > docker-compose.canary.yml << EOF
version: '3.8'

services:
  stable:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${APP_NAME}:stable
    container_name: ${APP_NAME}-stable
    ports:
      - "${STABLE_PORT}:3000"
    environment:
      - NODE_ENV=production
      - APP_VERSION=stable
    volumes:
      - ./logs:/app/logs
    networks:
      - canary

  canary:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${APP_NAME}:canary
    container_name: ${APP_NAME}-canary
    ports:
      - "${CANARY_PORT}:3000"
    environment:
      - NODE_ENV=production
      - APP_VERSION=canary
    volumes:
      - ./logs:/app/logs
    networks:
      - canary

  nginx:
    image: nginx:alpine
    container_name: ${APP_NAME}-nginx
    ports:
      - "${NGINX_PORT}:8080"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - stable
      - canary
    networks:
      - canary

networks:
  canary:
    driver: bridge
EOF

    echo -e "${GREEN}✓${NC} 金丝雀部署环境初始化完成"
}

function deploy_canary() {
    local image=$1
    echo -e "${YELLOW}部署金丝雀版本...${NC}"
    
    if [ -z "$image" ]; then
        image="${APP_NAME}:canary"
    fi
    
    docker-compose -f docker-compose.canary.yml build canary
    docker-compose -f docker-compose.canary.yml up -d canary
    
    echo -e "${GREEN}✓${NC} 金丝雀版本部署完成"
    echo "金丝雀地址: http://localhost:${CANARY_PORT}"
    echo "当前流量比例: 0% 金丝雀, 100% 稳定"
    echo ""
    echo "使用 '$0 set-traffic <percentage>' 设置流量比例"
}

function set_traffic() {
    local percentage=$1
    
    if [ -z "$percentage" ]; then
        echo -e "${RED}错误: 请指定流量比例 (0-100)${NC}"
        exit 1
    fi
    
    if [ "$percentage" -lt 0 ] || [ "$percentage" -gt 100 ]; then
        echo -e "${RED}错误: 流量比例必须在 0-100 之间${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}设置金丝雀流量比例为 ${percentage}%...${NC}"
    
    local stable_percent=$((100 - percentage))
    
    cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream stable {
        server stable:3000;
    }

    upstream canary {
        server canary:3000;
    }

    split_clients \$remote_addr \$backend {
        ${percentage}% canary;
        * stable;
    }

    server {
        listen 8080;
        
        location / {
            proxy_pass http://\$backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

    docker restart ${APP_NAME}-nginx
    
    echo -e "${GREEN}✓${NC} 流量比例已更新"
    echo "当前流量分配: ${percentage}% 金丝雀, ${stable_percent}% 稳定"
}

function promote() {
    echo -e "${YELLOW}将金丝雀版本提升为稳定版本...${NC}"
    
    docker tag ${APP_NAME}:canary ${APP_NAME}:stable
    docker-compose -f docker-compose.canary.yml build stable
    docker-compose -f docker-compose.canary.yml up -d stable
    
    set_traffic 0
    
    echo -e "${GREEN}✓${NC} 金丝雀版本已提升为稳定版本"
    echo "现在可以删除金丝雀容器: docker stop ${APP_NAME}-canary && docker rm ${APP_NAME}-canary"
}

function rollback() {
    echo -e "${YELLOW}回滚到稳定版本...${NC}"
    
    set_traffic 0
    
    echo -e "${GREEN}✓${NC} 已回滚到稳定版本"
    echo "现在可以删除金丝雀容器: docker stop ${APP_NAME}-canary && docker rm ${APP_NAME}-canary"
}

function status() {
    echo -e "${YELLOW}=== 金丝雀部署状态 ===${NC}"
    echo ""
    
    echo "稳定版本:"
    if curl -s -f http://localhost:${STABLE_PORT}/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 运行中 (http://localhost:${STABLE_PORT})"
    else
        echo -e "  ${RED}✗${NC} 未运行"
    fi
    
    echo "金丝雀版本:"
    if curl -s -f http://localhost:${CANARY_PORT}/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 运行中 (http://localhost:${CANARY_PORT})"
    else
        echo -e "  ${RED}✗${NC} 未运行"
    fi
    
    echo ""
    echo "当前流量分配:"
    if grep -q "100% canary" nginx.conf; then
        echo -e "  ${GREEN}100% 金丝雀, 0% 稳定${NC}"
    elif grep -q "0% canary" nginx.conf; then
        echo -e "  ${GREEN}0% 金丝雀, 100% 稳定${NC}"
    else
        local canary_percent=$(grep -o '[0-9]*% canary' nginx.conf | grep -o '[0-9]*')
        local stable_percent=$((100 - canary_percent))
        echo -e "  ${GREEN}${canary_percent}% 金丝雀, ${stable_percent}% 稳定${NC}"
    fi
    
    echo ""
    echo "容器状态:"
    docker-compose -f docker-compose.canary.yml ps
}

function cleanup() {
    echo -e "${YELLOW}清理金丝雀部署环境...${NC}"
    
    docker-compose -f docker-compose.canary.yml down
    rm -f docker-compose.canary.yml nginx.conf nginx.conf.bak
    
    echo -e "${GREEN}✓${NC} 清理完成"
}

case "$1" in
    init)
        init
        ;;
    deploy-canary)
        deploy_canary "$2"
        ;;
    set-traffic)
        set_traffic "$2"
        ;;
    promote)
        promote
        ;;
    rollback)
        rollback
        ;;
    status)
        status
        ;;
    cleanup)
        cleanup
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
