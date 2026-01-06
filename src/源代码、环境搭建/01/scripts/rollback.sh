#!/bin/bash

set -e

NAMESPACE=${NAMESPACE:-default}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-cloud-native-demo}

echo "=== 回滚应用 ==="
echo "命名空间: $NAMESPACE"
echo "部署名称: $DEPLOYMENT_NAME"

echo "可用的历史版本:"
kubectl rollout history deployment/$DEPLOYMENT_NAME -n $NAMESPACE

REVISION=${REVISION:-}
if [ -z "$REVISION" ]; then
  echo "回滚到上一个版本..."
  kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE
else
  echo "回滚到版本 $REVISION..."
  kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE --to-revision=$REVISION
fi

echo "等待回滚完成..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s

echo "✅ 回滚完成"
echo "当前版本:"
kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'