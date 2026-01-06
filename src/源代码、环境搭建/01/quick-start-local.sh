#!/bin/bash

set -e

APP_URL="http://localhost:3000"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== 快速启动云原生演示应用 ===${NC}"
echo ""

echo -e "${YELLOW}1. 检查应用状态${NC}"
if curl -s -f "$APP_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 应用运行中"
else
    echo -e "${RED}✗${NC} 应用未运行，正在启动..."
    npm start &
    sleep 3
fi

echo ""
echo -e "${YELLOW}2. 应用信息${NC}"
curl -s "$APP_URL/" | jq .

echo ""
echo -e "${YELLOW}3. 可用端点${NC}"
echo "  主页:        $APP_URL/"
echo "  健康检查:    $APP_URL/health"
echo "  指标:        $APP_URL/metrics"
echo "  版本信息:    $APP_URL/info"
echo "  API数据:     $APP_URL/api/data"
echo "  API用户:     $APP_URL/api/users"
echo ""

echo -e "${YELLOW}4. 故障模拟端点${NC}"
echo "  模拟错误:    $APP_URL/simulate/error?rate=0.5"
echo "  模拟延迟:    $APP_URL/simulate/slow?delay=2000"
echo "  模拟崩溃:    $APP_URL/simulate/crash"
echo ""

echo -e "${YELLOW}5. 部署策略脚本${NC}"
echo "  蓝绿部署:    ./scripts/blue-green.sh init"
echo "  金丝雀部署:  ./scripts/canary.sh init"
echo "  故障场景:    ./scripts/fault-scenarios.sh"
echo ""

echo -e "${GREEN}=== 应用已就绪 ===${NC}"
echo -e "提示: 使用 'open http://localhost:3000' 在浏览器中打开"
