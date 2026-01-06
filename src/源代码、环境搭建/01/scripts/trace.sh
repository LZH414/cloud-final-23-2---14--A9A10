#!/bin/bash

set -e

NAMESPACE="cloud-native-demo"
DEPLOYMENT="cloud-native-demo"

echo "=== Complete Version Trace Chain ==="
echo ""

echo "1. Running Pods:"
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o wide
echo ""

echo "2. Deployment Image:"
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo ""

echo "3. ReplicaSet History:"
kubectl get rs -n $NAMESPACE -l app=$DEPLOYMENT
echo ""

echo "4. Deployment Revision History:"
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE
echo ""

echo "5. Detailed Pod Information (first pod):"
POD=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD" ]; then
    echo "Pod: $POD"
    echo ""
    echo "Container Image:"
    kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}'
    echo ""
    echo ""
    echo "Application Info:"
    kubectl exec -n $NAMESPACE $POD -- curl -s http://localhost:3000/info 2>/dev/null || echo "Unable to fetch app info"
    echo ""
    echo ""
    echo "Pod Labels:"
    kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.metadata.labels}' | jq '.'
    echo ""
    echo "Pod Annotations:"
    kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.metadata.annotations}' | jq '.'
fi

echo ""
echo "=== Trace Chain Summary ==="
echo "Running Instance (Pod) -> Image Tag -> Commit/Version"
echo "Current Image: $(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')"
