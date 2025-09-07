#!/bin/bash

# AKS Scaling Test Script
# This script tests the autoscaler by creating workloads that trigger scaling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  scale-up   - Create workload to trigger autoscaler"
    echo "  scale-down - Remove workload to trigger scale-down"
    echo "  status     - Show current status"
    echo "  help       - Show this help message"
}

# Function to show current status
show_status() {
    echo -e "${BLUE}📊 Current AKS Status${NC}"
    echo "====================="
    
    echo -e "\n${YELLOW}Nodes:${NC}"
    kubectl get nodes -o wide
    
    echo -e "\n${YELLOW}Pods:${NC}"
    kubectl get pods --all-namespaces
    
    echo -e "\n${YELLOW}Node Pools:${NC}"
    az aks nodepool list \
        --resource-group delivery-platform-aks-rg \
        --cluster-name delivery-platform-aks \
        --output table
}

# Function to trigger scale-up
scale_up() {
    echo -e "${GREEN}🚀 Creating workload to trigger autoscaler${NC}"
    
    # Create a namespace for testing
    kubectl create namespace scaling-test --dry-run=client -o yaml | kubectl apply -f -
    
    # Create a deployment that will trigger scaling
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scaling-test
  namespace: scaling-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: scaling-test
  template:
    metadata:
      labels:
        app: scaling-test
    spec:
      nodeSelector:
        agentpool: userpool
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
EOF
    
    echo -e "${GREEN}✅ Workload created${NC}"
    echo -e "${YELLOW}⏳ Waiting for autoscaler to scale up...${NC}"
    
    # Wait for pods to be scheduled
    kubectl wait --for=condition=Ready pods -l app=scaling-test -n scaling-test --timeout=300s
    
    echo -e "${GREEN}✅ Pods are ready!${NC}"
    show_status
}

# Function to trigger scale-down
scale_down() {
    echo -e "${YELLOW}🔄 Removing workload to trigger scale-down${NC}"
    
    # Delete the deployment
    kubectl delete deployment scaling-test -n scaling-test --ignore-not-found=true
    
    # Delete the namespace
    kubectl delete namespace scaling-test --ignore-not-found=true
    
    echo -e "${GREEN}✅ Workload removed${NC}"
    echo -e "${YELLOW}⏳ Waiting for autoscaler to scale down...${NC}"
    echo -e "${BLUE}Note: Autoscaler will scale down after 10 minutes of inactivity${NC}"
    
    show_status
}

# Main script logic
case "${1:-help}" in
    scale-up)
        scale_up
        ;;
    scale-down)
        scale_down
        ;;
    status)
        show_status
        ;;
    help|*)
        usage
        ;;
esac
