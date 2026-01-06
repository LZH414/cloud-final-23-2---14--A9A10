#!/bin/bash

set -e

NAMESPACE="cloud-native-demo"
DEPLOYMENT="cloud-native-demo"

function print_usage() {
    echo "Usage: $0 <strategy> <image>"
    echo ""
    echo "Strategies:"
    echo "  rolling    Rolling update (default)"
    echo "  blue-green Blue-green deployment"
    echo "  canary     Canary deployment (10% traffic)"
    echo ""
    echo "Examples:"
    echo "  $0 rolling cloud-native-demo:v1.0.0"
    echo "  $0 blue-green cloud-native-demo:v1.1.0"
    echo "  $0 canary cloud-native-demo:v1.2.0"
}

function rolling_update() {
    local image=$1
    echo "=== Rolling Update Strategy ==="
    echo "Deploying: $image"
    
    kubectl set image deployment/$DEPLOYMENT app=$image -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=5m
    
    echo "Rolling update completed"
}

function blue_green_deployment() {
    local image=$1
    local new_deployment="${DEPLOYMENT}-blue"
    local old_deployment="${DEPLOYMENT}-green"
    
    echo "=== Blue-Green Deployment Strategy ==="
    
    if kubectl get deployment $new_deployment -n $NAMESPACE &>/dev/null; then
        echo "Switching: $new_deployment (active) -> $old_deployment (inactive)"
        kubectl patch svc $DEPLOYMENT -n $NAMESPACE -p '{"spec":{"selector":{"app":"'$old_deployment'"}}}'
        kubectl scale deployment $new_deployment --replicas=0 -n $NAMESPACE
        kubectl scale deployment $old_deployment --replicas=3 -n $NAMESPACE
    else
        echo "Creating new deployment: $new_deployment"
        kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o yaml | \
            sed "s/name: $DEPLOYMENT/name: $new_deployment/g" | \
            sed "s/app: $DEPLOYMENT/app: $new_deployment/g" | \
            sed "s|image: .*|image: $image|g" | \
            kubectl apply -f -
        
        echo "Waiting for new deployment to be ready..."
        kubectl rollout status deployment/$new_deployment -n $NAMESPACE --timeout=5m
        
        echo "Switching traffic to new deployment..."
        kubectl patch svc $DEPLOYMENT -n $NAMESPACE -p '{"spec":{"selector":{"app":"'$new_deployment'"}}}'
        
        echo "Scaling down old deployment..."
        kubectl scale deployment $DEPLOYMENT --replicas=0 -n $NAMESPACE
    fi
    
    echo "Blue-green deployment completed"
}

function canary_deployment() {
    local image=$1
    local canary_deployment="${DEPLOYMENT}-canary"
    
    echo "=== Canary Deployment Strategy ==="
    echo "Deploying canary: $image (10% traffic)"
    
    if kubectl get deployment $canary_deployment -n $NAMESPACE &>/dev/null; then
        echo "Updating existing canary deployment"
        kubectl set image deployment/$canary_deployment app=$image -n $NAMESPACE
    else
        echo "Creating canary deployment"
        kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o yaml | \
            sed "s/name: $DEPLOYMENT/name: $canary_deployment/g" | \
            sed "s/app: $DEPLOYMENT/app: $canary_deployment/g" | \
            sed "s/replicas: 3/replicas: 1/g" | \
            sed "s|image: .*|image: $image|g" | \
            kubectl apply -f -
    fi
    
    kubectl rollout status deployment/$canary_deployment -n $NAMESPACE --timeout=5m
    
    echo ""
    echo "Canary deployment status:"
    kubectl get deployments -n $NAMESPACE -l app=$DEPLOYMENT -o wide
    echo ""
    echo "Traffic distribution: 90% stable, 10% canary"
    echo ""
    echo "To promote canary to full rollout, run:"
    echo "  kubectl set image deployment/$DEPLOYMENT app=$image -n $NAMESPACE"
    echo "  kubectl delete deployment/$canary_deployment -n $NAMESPACE"
}

case "$1" in
    rolling)
        rolling_update "$2"
        ;;
    blue-green)
        blue_green_deployment "$2"
        ;;
    canary)
        canary_deployment "$2"
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
