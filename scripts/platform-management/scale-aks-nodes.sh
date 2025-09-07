#!/bin/bash

# AKS Node Pool Scaling Script for Cost Optimization
# This script allows you to scale AKS node pools to 0 to reduce costs

set -e

# Configuration
RESOURCE_GROUP="delivery-platform-aks-rg"
CLUSTER_NAME="delivery-platform-aks"
SYSTEM_NODEPOOL="nodepool1"
USER_NODEPOOL="userpool"

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
    echo "  status     - Show current node pool status"
    echo "  scale-up   - Scale user node pool to 1 node"
    echo "  scale-down - Scale user node pool to 0 nodes (cost optimization)"
    echo "  stop       - Scale both node pools to minimum (system: 1, user: 0)"
    echo "  start      - Scale both node pools to normal (system: 1, user: 1)"
    echo "  help       - Show this help message"
    echo ""
    echo "Cost Optimization:"
    echo "  - Use 'scale-down' to reduce costs by scaling user pool to 0"
    echo "  - Use 'stop' to minimize costs (system pool stays at 1 for cluster management)"
    echo "  - Use 'start' to resume normal operations"
}

# Function to show current status
show_status() {
    echo -e "${BLUE}📊 Current AKS Node Pool Status${NC}"
    echo "=================================="
    
    # Show node pools
    echo -e "\n${YELLOW}Node Pools:${NC}"
    az aks nodepool list \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --output table
    
    # Show current nodes
    echo -e "\n${YELLOW}Current Nodes:${NC}"
    kubectl get nodes -o wide
    
    # Show current pods
    echo -e "\n${YELLOW}Current Pods:${NC}"
    kubectl get pods --all-namespaces
}

# Function to scale user node pool up
scale_up() {
    echo -e "${GREEN}🚀 Scaling user node pool up to 1 node${NC}"
    az aks nodepool scale \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name $USER_NODEPOOL \
        --node-count 1
    
    echo -e "${GREEN}✅ User node pool scaled up successfully${NC}"
    echo -e "${YELLOW}⏳ Waiting for nodes to be ready...${NC}"
    
    # Wait for nodes to be ready
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    echo -e "${GREEN}✅ Nodes are ready!${NC}"
    show_status
}

# Function to scale user node pool down
scale_down() {
    echo -e "${YELLOW}⚠️  Scaling user node pool down to 0 nodes${NC}"
    echo -e "${YELLOW}This will reduce costs but may affect running workloads${NC}"
    
    # Check if there are any pods that need user nodes
    echo -e "\n${BLUE}Checking for pods that might be affected...${NC}"
    kubectl get pods --all-namespaces -o wide | grep -v "aks-nodepool1" || true
    
    read -p "Are you sure you want to scale down? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Operation cancelled${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🔄 Scaling down user node pool...${NC}"
    az aks nodepool scale \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name $USER_NODEPOOL \
        --node-count 0
    
    echo -e "${GREEN}✅ User node pool scaled down successfully${NC}"
    echo -e "${BLUE}💰 Cost optimization: User nodes are now at 0, reducing costs${NC}"
    show_status
}

# Function to stop cluster (minimize costs)
stop_cluster() {
    echo -e "${YELLOW}🛑 Stopping cluster to minimize costs${NC}"
    echo -e "${YELLOW}System pool will remain at 1 node for cluster management${NC}"
    
    # Scale user pool to 0
    echo -e "\n${YELLOW}Scaling user pool to 0...${NC}"
    az aks nodepool scale \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name $USER_NODEPOOL \
        --node-count 0
    
    echo -e "${GREEN}✅ Cluster stopped for cost optimization${NC}"
    echo -e "${BLUE}💰 Only system node (1x Standard_B2s) is running${NC}"
    show_status
}

# Function to start cluster (normal operations)
start_cluster() {
    echo -e "${GREEN}🚀 Starting cluster for normal operations${NC}"
    
    # Scale user pool to 1
    echo -e "\n${YELLOW}Scaling user pool to 1...${NC}"
    az aks nodepool scale \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name $USER_NODEPOOL \
        --node-count 1
    
    echo -e "${YELLOW}⏳ Waiting for nodes to be ready...${NC}"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    echo -e "${GREEN}✅ Cluster started successfully${NC}"
    show_status
}

# Main script logic
case "${1:-help}" in
    status)
        show_status
        ;;
    scale-up)
        scale_up
        ;;
    scale-down)
        scale_down
        ;;
    stop)
        stop_cluster
        ;;
    start)
        start_cluster
        ;;
    help|*)
        usage
        ;;
esac
