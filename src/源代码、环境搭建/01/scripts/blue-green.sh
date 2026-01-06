#!/bin/bash

set -e

APP_NAME="cloud-native-demo"
BLUE_PORT=3000
GREEN_PORT=3001
NGINX_PORT=8080

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function print_usage() {
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  init              初始化蓝绿部署环境"
    echo "  deploy-blue       部署到蓝环境"
    echo "  deploy-green      部署到绿环境"
    echo "  switch-blue       切换流量到蓝环境"
    echo "  switch-green      切换流量到绿环境"
    echo "  status            查看当前状态"
    echo "  cleanup           清理环境"
    echo ""
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 deploy-blue cloud-native-demo:1.0.0"
    echo "  $0 switch-blue"
}

function init() {
    echo -e "${YELLOW}初始化蓝绿部署环境...${NC}"
    
    mkdir -p logs
    
    cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server blue:3000;
    }

    server {
        listen 8080;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF

    cat > docker-compose.blue-green.yml << EOF
version: '3.8'

services:
  blue:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${APP_NAME}:blue
    container_name: ${APP_NAME}-blue
    ports:
      - "${BLUE_PORT}:3000"
    environment:
      - NODE_ENV=production
      - APP_VERSION=blue
    volumes:
      - ./logs:/app/logs
    networks:
      - blue-green

  green:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${APP_NAME}:green
    container_name: ${APP_NAME}-green
    ports:
      - "${GREEN_PORT}:3000"
    environment:
      - NODE_ENV=production
      - APP_VERSION=green
    volumes:
      - ./logs:/app/logs
    networks:
      - blue-green

  nginx:
    image: nginx:alpine
    container_name: ${APP_NAME}-nginx
    ports:
      - "${NGINX_PORT}:8080"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - blue
      - green
    networks:
      - blue-green

networks:
  blue-green:
    driver: bridge
EOF

    echo -e "${GREEN}✓${NC} 蓝绿部署环境初始化完成"
}

function deploy_blue() {
    local image=$1
    echo -e "${YELLOW}部署到蓝环境...${NC}"
    
    if [ -z "$image" ]; then
        image="${APP_NAME}:blue"
    fi
    
    docker-compose -f docker-compose.blue-green.yml build blue
    docker-compose -f docker-compose.blue-green.yml up -d blue
    
    echo -e "${GREEN}✓${NC} 蓝环境部署完成"
    echo "蓝环境地址: http://localhost:${BLUE_PORT}"
}

function deploy_green() {
    local image=$1
    echo -e "${YELLOW}部署到绿环境...${NC}"
    
    if [ -z "$image" ]; then
        image="${APP_NAME}:green"
    fi
    
    docker-compose -f docker-compose.blue-green.yml build green
    docker-compose -f docker-compose.blue-green.yml up -d green
    
    echo -e "${GREEN}✓${NC} 绿环境部署完成"
    echo "绿环境地址: http://localhost:${GREEN_PORT}"
}

function switch_blue() {
    echo -e "${YELLOW}切换流量到蓝环境...${NC}"
    
    sed -i.bak 's/server green:3000;/server blue:3000;/' nginx.conf
    docker restart ${APP_NAME}-nginx
    
    echo -e "${GREEN}✓${NC} 流量已切换到蓝环境"
    echo "访问地址: http://localhost:${NGINX_PORT}"
}

function switch_green() {
    echo -e "${YELLOW}切换流量到绿环境...${NC}"
    
    sed -i.bak 's/server blue:3000;/server green:3000;/' nginx.conf
    docker restart ${APP_NAME}-nginx
    
    echo -e "${GREEN}✓${NC} 流量已切换到绿环境"
    echo "访问地址: http://localhost:${NGINX_PORT}"
}

function status() {
    echo -e "${YELLOW}=== 蓝绿部署状态 ===${NC}"
    echo ""
    
    echo "蓝环境:"
    if curl -s -f http://localhost:${BLUE_PORT}/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 运行中 (http://localhost:${BLUE_PORT})"
    else
        echo -e "  ${RED}✗${NC} 未运行"
    fi
    
    echo "绿环境:"
    if curl -s -f http://localhost:${GREEN_PORT}/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 运行中 (http://localhost:${GREEN_PORT})"
    else
        echo -e "  ${RED}✗${NC} 未运行"
    fi
    
    echo ""
    echo "当前流量指向:"
    if grep -q "blue:3000" nginx.conf; then
        echo -e "  ${GREEN}蓝环境${NC}"
    else
        echo -e "  ${GREEN}绿环境${NC}"
    fi
    
    echo ""
    echo "容器状态:"
    docker-compose -f docker-compose.blue-green.yml ps
}

function cleanup() {
    echo -e "${YELLOW}清理蓝绿部署环境...${NC}"
    
    docker-compose -f docker-compose.blue-green.yml down
    rm -f docker-compose.blue-green.yml nginx.conf nginx.conf.bak
    
    echo -e "${GREEN}✓${NC} 清理完成"
}

case "$1" in
    init)
        init
        ;;
    deploy-blue)
        deploy_blue "$2"
        ;;
    deploy-green)
        deploy_green "$2"
        ;;
    switch-blue)
        switch_blue
        ;;
    switch-green)
        switch_green
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
