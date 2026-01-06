#!/bin/bash

set -e

NAMESPACE=${NAMESPACE:-default}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-cloud-native-demo}
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "=== 升级应用 ==="
echo "命名空间: $NAMESPACE"
echo "部署名称: $DEPLOYMENT_NAME"
echo "镜像标签: $IMAGE_TAG"

kubectl set image deployment/$DEPLOYMENT_NAME app=$IMAGE_TAG -n $NAMESPACE

echo "等待部署完成..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s

echo "✅ 升级完成"
echo "当前版本:"
kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'