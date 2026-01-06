#!/bin/bash

set -e

APP_URL="http://localhost:3000"
PROMETHEUS_URL="http://localhost:9090"
GRAFANA_URL="http://localhost:3001"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== 故障场景验证脚本 ===${NC}"
echo ""

check_service() {
    local name=$1
    local url=$2
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name 可用"
        return 0
    else
        echo -e "${RED}✗${NC} $name 不可用"
        return 1
    fi
}

echo -e "${YELLOW}1. 检查所有服务状态${NC}"
check_service "应用" "$APP_URL/health"
check_service "Prometheus" "$PROMETHEUS_URL/-/healthy"
check_service "Grafana" "$GRAFANA_URL/api/health"
echo ""

echo -e "${YELLOW}2. 场景1: 模拟高错误率${NC}"
echo "发送100个请求，其中50%会失败..."
for i in {1..100}; do
    curl -s "$APP_URL/simulate/error?rate=0.5" > /dev/null &
done
wait
echo -e "${GREEN}✓${NC} 高错误率场景已触发"
echo "请访问 $GRAFANA_URL 查看告警"
sleep 5
echo ""

echo -e "${YELLOW}3. 场景2: 模拟高延迟${NC}"
echo "发送50个慢请求（延迟2秒）..."
for i in {1..50}; do
    curl -s "$APP_URL/simulate/slow?delay=2000" > /dev/null &
done
wait
echo -e "${GREEN}✓${NC} 高延迟场景已触发"
echo "请访问 $GRAFANA_URL 查看延迟指标"
sleep 5
echo ""

echo -e "${YELLOW}4. 场景3: 模拟流量突增${NC}"
echo "发送200个并发请求..."
for i in {1..200}; do
    curl -s "$APP_URL/api/data?size=50" > /dev/null &
done
wait
echo -e "${GREEN}✓${NC} 流量突增场景已触发"
echo "请访问 $GRAFANA_URL 查看请求速率和活跃连接数"
sleep 5
echo ""

echo -e "${YELLOW}5. 场景4: 检查告警状态${NC}"
echo "查询Prometheus告警..."
curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | "\(.labels.alertname): \(.state)"' || echo "需要jq工具解析"
echo ""

echo -e "${YELLOW}6. 场景5: 查看日志${NC}"
echo "应用日志位置: ./logs/app.log"
if [ -f "./logs/app.log" ]; then
    echo "最近的日志:"
    tail -n 10 ./logs/app.log
fi
echo ""

echo -e "${YELLOW}7. 场景6: 查看指标${NC}"
echo "应用指标: $APP_URL/metrics"
echo "Prometheus目标: $PROMETHEUS_URL/targets"
echo "Grafana仪表板: $GRAFANA_URL/d/cloud-native-app"
echo ""

echo -e "${GREEN}=== 故障场景验证完成 ===${NC}"
echo ""
echo "提示："
echo "- 访问 $GRAFANA_URL 查看可视化仪表板（用户名/密码: admin/admin）"
echo "- 访问 $PROMETHEUS_URL 查看Prometheus界面"
echo "- 查看 ./logs/app.log 了解应用日志"
echo "- 等待5-10分钟后，告警规则将被触发"
