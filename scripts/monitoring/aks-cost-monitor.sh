#!/bin/bash

# AKS Cost Monitoring Script
# This script monitors AKS costs and provides cost optimization recommendations

set -e

# Configuration
RESOURCE_GROUP="delivery-platform-aks-rg"
CLUSTER_NAME="delivery-platform-aks"
SUBSCRIPTION_ID="ecd977ed-b8df-4eb6-9cba-98397e1b2491"

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
    echo "  status     - Show current AKS status and costs"
    echo "  estimate   - Estimate monthly costs"
    echo "  optimize   - Show cost optimization recommendations"
    echo "  help       - Show this help message"
}

# Function to show current status
show_status() {
    echo -e "${BLUE}📊 AKS Cluster Status & Cost Analysis${NC}"
    echo "=============================================="
    
    # Show node pools
    echo -e "\n${YELLOW}Node Pools:${NC}"
    az aks nodepool list \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --output table
    
    # Show current nodes
    echo -e "\n${YELLOW}Current Nodes:${NC}"
    kubectl get nodes -o wide
    
    # Show resource usage
    echo -e "\n${YELLOW}Resource Usage:${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    
    # Show current costs
    echo -e "\n${YELLOW}Current Configuration Costs:${NC}"
    estimate_costs
}

# Function to estimate costs
estimate_costs() {
    echo -e "\n${BLUE}💰 Cost Estimation${NC}"
    echo "=================="
    
    # Get current node counts
    SYSTEM_NODES=$(az aks nodepool show \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name nodepool1 \
        --query count -o tsv)
    
    USER_NODES=$(az aks nodepool show \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name userpool \
        --query count -o tsv)
    
    # Cost per Standard_B2s node (approximate)
    NODE_COST_PER_HOUR=0.042  # $0.042/hour for Standard_B2s
    NODE_COST_PER_DAY=$(echo "$NODE_COST_PER_HOUR * 24" | bc -l)
    NODE_COST_PER_MONTH=$(echo "$NODE_COST_PER_DAY * 30" | bc -l)
    
    # Calculate costs
    TOTAL_NODES=$((SYSTEM_NODES + USER_NODES))
    DAILY_COST=$(echo "$TOTAL_NODES * $NODE_COST_PER_DAY" | bc -l)
    MONTHLY_COST=$(echo "$TOTAL_NODES * $NODE_COST_PER_MONTH" | bc -l)
    
    echo "Current Configuration:"
    echo "  System Nodes: $SYSTEM_NODES"
    echo "  User Nodes: $USER_NODES"
    echo "  Total Nodes: $TOTAL_NODES"
    echo ""
    echo "Cost Breakdown:"
    echo "  Per Node: \$${NODE_COST_PER_HOUR}/hour"
    echo "  Daily Cost: \$$(printf "%.2f" $DAILY_COST)"
    echo "  Monthly Cost: \$$(printf "%.2f" $MONTHLY_COST)"
    
    # Show cost optimization scenarios
    echo -e "\n${GREEN}Cost Optimization Scenarios:${NC}"
    
    # Scenario 1: Scale user pool to 0
    OPTIMIZED_NODES=$SYSTEM_NODES
    OPTIMIZED_DAILY=$(echo "$OPTIMIZED_NODES * $NODE_COST_PER_DAY" | bc -l)
    OPTIMIZED_MONTHLY=$(echo "$OPTIMIZED_NODES * $NODE_COST_PER_MONTH" | bc -l)
    SAVINGS_DAILY=$(echo "$DAILY_COST - $OPTIMIZED_DAILY" | bc -l)
    SAVINGS_MONTHLY=$(echo "$MONTHLY_COST - $OPTIMIZED_MONTHLY" | bc -l)
    
    echo "  Scale User Pool to 0:"
    echo "    Daily Cost: \$$(printf "%.2f" $OPTIMIZED_DAILY)"
    echo "    Monthly Cost: \$$(printf "%.2f" $OPTIMIZED_MONTHLY)"
    echo "    Daily Savings: \$$(printf "%.2f" $SAVINGS_DAILY)"
    echo "    Monthly Savings: \$$(printf "%.2f" $SAVINGS_MONTHLY)"
}

# Function to show optimization recommendations
show_optimizations() {
    echo -e "${GREEN}🎯 Cost Optimization Recommendations${NC}"
    echo "======================================"
    
    # Get current node counts
    USER_NODES=$(az aks nodepool show \
        --resource-group $RESOURCE_GROUP \
        --cluster-name $CLUSTER_NAME \
        --name userpool \
        --query count -o tsv)
    
    if [ "$USER_NODES" -gt 0 ]; then
        echo -e "\n${YELLOW}1. Scale User Pool to 0 (Immediate Savings)${NC}"
        echo "   Command: ./scripts/scale-aks-nodes.sh scale-down"
        echo "   Impact: Reduces costs by ~\$1.26/day per user node"
        echo "   Use Case: When not actively developing/testing"
        
        echo -e "\n${YELLOW}2. Use Spot Instances (Future Enhancement)${NC}"
        echo "   Command: az aks nodepool add --priority Spot"
        echo "   Impact: Up to 90% cost reduction"
        echo "   Use Case: For non-critical workloads"
        
        echo -e "\n${YELLOW}3. Schedule Scaling (Future Enhancement)${NC}"
        echo "   Command: Set up cron jobs to scale during off-hours"
        echo "   Impact: Automatic cost optimization"
        echo "   Use Case: Regular development schedule"
    else
        echo -e "\n${GREEN}✅ User pool is already at 0 - Cost optimized!${NC}"
        echo "   To resume work: ./scripts/scale-aks-nodes.sh scale-up"
    fi
    
    echo -e "\n${BLUE}4. Monitor Usage Patterns${NC}"
    echo "   Command: ./scripts/aks-cost-monitor.sh status"
    echo "   Impact: Better understanding of usage"
    echo "   Use Case: Regular monitoring"
    
    echo -e "\n${BLUE}5. Use Azure Cost Management${NC}"
    echo "   Portal: https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/Overview"
    echo "   Impact: Detailed cost analysis and budgets"
    echo "   Use Case: Long-term cost management"
}

# Main script logic
case "${1:-help}" in
    status)
        show_status
        ;;
    estimate)
        estimate_costs
        ;;
    optimize)
        show_optimizations
        ;;
    help|*)
        usage
        ;;
esac
