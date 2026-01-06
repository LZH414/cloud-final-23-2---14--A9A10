#!/bin/bash

set -e

NAMESPACE="cloud-native-demo"
DEPLOYMENT="cloud-native-demo"

function print_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  deploy <image>        Deploy new image"
    echo "  rollback              Rollback to previous version"
    echo "  status                Show deployment status"
    echo "  history               Show deployment history"
    echo "  trace                 Trace version from pod to commit"
    echo "  logs                  Show application logs"
    echo ""
    echo "Examples:"
    echo "  $0 deploy cloud-native-demo:v1.0.0"
    echo "  $0 rollback"
    echo "  $0 trace pod-name"
}

function deploy() {
    local image=$1
    if [ -z "$image" ]; then
        echo "Error: Image name is required"
        exit 1
    fi
    
    echo "Deploying image: $image"
    kubectl set image deployment/$DEPLOYMENT app=$image -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m
    echo "Deployment completed successfully"
}

function rollback() {
    echo "Rolling back to previous version..."
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m
    echo "Rollback completed successfully"
}

function status() {
    echo "=== Deployment Status ==="
    kubectl get deployment $DEPLOYMENT -n $NAMESPACE
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT
    echo ""
    echo "=== Services ==="
    kubectl get svc -n $NAMESPACE -l app=$DEPLOYMENT
}

function history() {
    echo "=== Deployment History ==="
    kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE
}

function trace() {
    local pod_name=$1
    if [ -z "$pod_name" ]; then
        echo "Getting pods..."
        kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT
        echo ""
        echo "Usage: $0 trace <pod-name>"
        exit 1
    fi
    
    echo "=== Version Trace for Pod: $pod_name ==="
    echo ""
    
    echo "1. Pod Information:"
    kubectl get pod $pod_name -n $NAMESPACE -o wide
    echo ""
    
    echo "2. Container Image:"
    local image=$(kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}')
    echo "   Image: $image"
    echo ""
    
    echo "3. Application Version Info:"
    kubectl exec -n $NAMESPACE $pod_name -- curl -s http://localhost:3000/info | jq '.'
    echo ""
    
    echo "4. Pod Labels:"
    kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.metadata.labels}' | jq '.'
    echo ""
    
    echo "5. Pod Annotations:"
    kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.metadata.annotations}' | jq '.'
}

function logs() {
    kubectl logs -n $NAMESPACE -l app=$DEPLOYMENT --tail=100 -f
}

case "$1" in
    deploy)
        deploy "$2"
        ;;
    rollback)
        rollback
        ;;
    status)
        status
        ;;
    history)
        history
        ;;
    trace)
        trace "$2"
        ;;
    logs)
        logs
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
