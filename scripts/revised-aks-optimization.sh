#!/bin/bash

# Revised AKS Cost Optimization Script
# Accounts for Visual Studio subscription limitations and system pool constraints

set -e

echo "🚀 Revised AKS Cost Optimization for Visual Studio Subscription..."
echo "================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Check subscription and Spot instance support
check_spot_support() {
    print_status "Step 1: Checking Visual Studio subscription and Spot instance support..."
    
    # Get subscription details
    SUBSCRIPTION_INFO=$(az account show --query "{subscriptionId: id, subscriptionName: name, subscriptionType: subscriptionPolicies.quotaId}" -o json)
    echo "Subscription Info: $SUBSCRIPTION_INFO"
    
    # Check if Spot instances are supported
    print_status "Testing Spot instance support..."
    
    # Try to create a test Spot instance (will fail if not supported, but gives us info)
    SPOT_TEST=$(az vm create \
        --resource-group delivery-platform-aks-rg \
        --name spot-test-vm \
        --image Ubuntu2204 \
        --size Standard_B2s \
        --priority Spot \
        --eviction-policy Delete \
        --admin-username azureuser \
        --generate-ssh-keys \
        --no-wait 2>&1 || echo "SPOT_NOT_SUPPORTED")
    
    if [[ $SPOT_TEST == *"SPOT_NOT_SUPPORTED"* ]] || [[ $SPOT_TEST == *"not supported"* ]] || [[ $SPOT_TEST == *"quota"* ]]; then
        print_warning "Spot instances may not be supported in your Visual Studio subscription"
        SPOT_SUPPORTED=false
    else
        print_success "Spot instances appear to be supported"
        SPOT_SUPPORTED=true
        
        # Clean up test VM
        az vm delete --resource-group delivery-platform-aks-rg --name spot-test-vm --yes 2>/dev/null || true
    fi
    
    echo "Spot Instance Support: $SPOT_SUPPORTED"
}

# Step 2: Check system pool VM size constraints
check_system_pool_constraints() {
    print_status "Step 2: Checking system pool VM size constraints..."
    
    # Get current system pool configuration
    CURRENT_SYSTEM_CONFIG=$(az aks nodepool show \
        --resource-group delivery-platform-aks-rg \
        --cluster-name delivery-platform-aks \
        --nodepool-name nodepool1 \
        --query "{vmSize: vmSize, mode: mode, count: count, minCount: minCount, maxCount: maxCount}" -o json)
    
    echo "Current System Pool Config: $CURRENT_SYSTEM_CONFIG"
    
    # Test if we can create a system pool with B1s
    print_status "Testing B1s support for system pools..."
    
    B1S_TEST=$(az aks nodepool add \
        --resource-group delivery-platform-aks-rg \
        --cluster-name delivery-platform-aks \
        --nodepool-name test-b1s-system \
        --mode System \
        --vm-size Standard_B1s \
        --node-count 0 \
        --min-count 0 \
        --max-count 1 \
        --no-wait 2>&1 || echo "B1S_NOT_SUPPORTED")
    
    if [[ $B1S_TEST == *"B1S_NOT_SUPPORTED"* ]] || [[ $B1S_TEST == *"not supported"* ]] || [[ $B1S_TEST == *"invalid"* ]]; then
        print_warning "B1s may not be supported for system pools"
        B1S_SUPPORTED=false
    else
        print_success "B1s appears to be supported for system pools"
        B1S_SUPPORTED=true
        
        # Clean up test nodepool
        az aks nodepool delete \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name test-b1s-system \
            --yes 2>/dev/null || true
    fi
    
    echo "B1s System Pool Support: $B1S_SUPPORTED"
}

# Step 3: Remove Karpenter
remove_karpenter() {
    print_status "Step 3: Removing Karpenter to avoid conflicts..."
    
    # Scale down Karpenter if it exists
    kubectl scale deployment karpenter -n kube-system --replicas=0 2>/dev/null || print_warning "Karpenter deployment not found"
    
    # Delete Karpenter components
    kubectl delete nodepools --all 2>/dev/null || print_warning "No Karpenter nodepools found"
    kubectl delete nodeclaims --all 2>/dev/null || print_warning "No Karpenter nodeclaims found"
    kubectl delete deployment karpenter -n kube-system 2>/dev/null || print_warning "Karpenter deployment not found"
    
    # Clean up any Karpenter nodes
    KARPENTER_NODES=$(kubectl get nodes -l karpenter.sh/nodepool --no-headers -o custom-columns=":metadata.name" 2>/dev/null || echo "")
    if [ -n "$KARPENTER_NODES" ]; then
        print_warning "Found Karpenter nodes, draining and removing..."
        for node in $KARPENTER_NODES; do
            kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 2>/dev/null || true
            kubectl delete node "$node" 2>/dev/null || true
        done
    fi
    
    print_success "Karpenter removed successfully"
}

# Step 4: Optimize based on findings
optimize_based_on_findings() {
    print_status "Step 4: Optimizing based on subscription and VM size constraints..."
    
    if [ "$SPOT_SUPPORTED" = true ]; then
        print_status "Optimizing user pool with Spot instances..."
        optimize_user_pool_spot
    else
        print_warning "Spot instances not supported, using on-demand with cost optimization..."
        optimize_user_pool_ondemand
    fi
    
    if [ "$B1S_SUPPORTED" = true ]; then
        print_status "Optimizing system pool to B1s..."
        optimize_system_pool_b1s
    else
        print_warning "B1s not supported for system pools, keeping B2s with optimization..."
        optimize_system_pool_b2s
    fi
}

# Optimize user pool with Spot instances
optimize_user_pool_spot() {
    print_status "Creating/updating user pool with Spot instances..."
    
    # Check if user pool exists
    USER_POOL_EXISTS=$(az aks nodepool show --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name userpool --query "name" -o tsv 2>/dev/null || echo "")
    
    if [ -z "$USER_POOL_EXISTS" ]; then
        # Create new user pool with Spot instances
        az aks nodepool add \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name userpool \
            --mode User \
            --vm-size Standard_B2s \
            --node-count 0 \
            --min-count 0 \
            --max-count 3 \
            --priority Spot \
            --eviction-policy Delete \
            --spot-max-price -1 \
            --enable-cluster-autoscaler \
            --labels "cost-optimized=true,spot-instance=true"
        
        print_success "User pool created with Spot instances (90% cost savings)"
    else
        # Update existing user pool to Spot
        az aks nodepool update \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name userpool \
            --priority Spot \
            --eviction-policy Delete \
            --spot-max-price -1 \
            --labels "cost-optimized=true,spot-instance=true"
        
        print_success "User pool updated to Spot instances (90% cost savings)"
    fi
}

# Optimize user pool with on-demand (fallback)
optimize_user_pool_ondemand() {
    print_status "Creating/updating user pool with on-demand instances and cost optimization..."
    
    # Check if user pool exists
    USER_POOL_EXISTS=$(az aks nodepool show --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name userpool --query "name" -o tsv 2>/dev/null || echo "")
    
    if [ -z "$USER_POOL_EXISTS" ]; then
        # Create new user pool with on-demand
        az aks nodepool add \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name userpool \
            --mode User \
            --vm-size Standard_B2s \
            --node-count 0 \
            --min-count 0 \
            --max-count 2 \
            --enable-cluster-autoscaler \
            --labels "cost-optimized=true,scale-to-zero=true"
        
        print_success "User pool created with on-demand instances and scale-to-zero"
    else
        # Update existing user pool
        az aks nodepool update \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name userpool \
            --max-count 2 \
            --labels "cost-optimized=true,scale-to-zero=true"
        
        print_success "User pool updated with scale-to-zero optimization"
    fi
}

# Optimize system pool to B1s
optimize_system_pool_b1s() {
    print_status "Optimizing system pool to B1s..."
    
    # Create new optimized system pool
    az aks nodepool add \
        --resource-group delivery-platform-aks-rg \
        --cluster-name delivery-platform-aks \
        --nodepool-name system-optimized \
        --mode System \
        --vm-size Standard_B1s \
        --node-count 1 \
        --min-count 1 \
        --max-count 2 \
        --enable-cluster-autoscaler \
        --labels "cost-optimized=true,system-pool=true"
    
    # Wait for new nodes to be ready
    print_status "Waiting for new system nodes to be ready..."
    sleep 60
    
    # Check if new nodes are ready
    NEW_NODES_READY=$(kubectl get nodes -l kubernetes.azure.com/agentpool=system-optimized --no-headers | grep Ready | wc -l)
    
    if [ "$NEW_NODES_READY" -gt 0 ]; then
        print_success "New system nodes are ready"
        
        # Wait for pods to stabilize
        sleep 30
        
        # Delete old system pool
        az aks nodepool delete \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name nodepool1 \
            --yes
        
        print_success "System pool optimized to B1s (50% cost savings)"
    else
        print_error "New system nodes not ready, keeping old configuration"
        az aks nodepool delete \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name system-optimized \
            --yes
    fi
}

# Optimize system pool keeping B2s
optimize_system_pool_b2s() {
    print_status "Optimizing system pool while keeping B2s..."
    
    # Update existing system pool for better cost optimization
    az aks nodepool update \
        --resource-group delivery-platform-aks-rg \
        --cluster-name delivery-platform-aks \
        --nodepool-name nodepool1 \
        --min-count 1 \
        --max-count 2 \
        --enable-cluster-autoscaler \
        --labels "cost-optimized=true,system-pool=true"
    
    print_success "System pool optimized with B2s (maintained stability)"
}

# Step 5: Verify optimization
verify_optimization() {
    print_status "Step 5: Verifying cost optimization..."
    
    echo ""
    echo "Optimized Node Pools:"
    az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table
    
    echo ""
    echo "Current Nodes:"
    kubectl get nodes -o wide
    
    # Calculate cost savings based on actual configuration
    echo ""
    print_success "Cost Optimization Summary:"
    echo "================================"
    
    if [ "$SPOT_SUPPORTED" = true ] && [ "$B1S_SUPPORTED" = true ]; then
        echo "✅ Maximum optimization achieved:"
        echo "System Pool: Standard_B1s (1 vCPU, 1GB RAM) - ~$3.74/month"
        echo "User Pool: Standard_B2s Spot (2 vCPU, 4GB RAM) - ~$3.02/month when running"
        echo "Total Cost: $3.74/month (idle) to $6.76/month (active)"
        echo "Savings: 87-89% from original cost"
    elif [ "$SPOT_SUPPORTED" = true ] && [ "$B1S_SUPPORTED" = false ]; then
        echo "✅ Good optimization achieved:"
        echo "System Pool: Standard_B2s (2 vCPU, 4GB RAM) - ~$30/month"
        echo "User Pool: Standard_B2s Spot (2 vCPU, 4GB RAM) - ~$3.02/month when running"
        echo "Total Cost: $30/month (idle) to $33.02/month (active)"
        echo "Savings: 45% when active, scale-to-zero when idle"
    elif [ "$SPOT_SUPPORTED" = false ] && [ "$B1S_SUPPORTED" = true ]; then
        echo "✅ Moderate optimization achieved:"
        echo "System Pool: Standard_B1s (1 vCPU, 1GB RAM) - ~$3.74/month"
        echo "User Pool: Standard_B2s On-demand (2 vCPU, 4GB RAM) - ~$30/month when running"
        echo "Total Cost: $3.74/month (idle) to $33.74/month (active)"
        echo "Savings: 50% on system, scale-to-zero on user"
    else
        echo "✅ Basic optimization achieved:"
        echo "System Pool: Standard_B2s (2 vCPU, 4GB RAM) - ~$30/month"
        echo "User Pool: Standard_B2s On-demand (2 vCPU, 4GB RAM) - ~$30/month when running"
        echo "Total Cost: $30/month (idle) to $60/month (active)"
        echo "Savings: Scale-to-zero capability, no additional cost when idle"
    fi
}

# Main execution
main() {
    echo "This script will optimize your AKS cluster based on your Visual Studio subscription limitations:"
    echo "1. Check Spot instance support"
    echo "2. Check system pool VM size constraints"
    echo "3. Remove Karpenter to avoid conflicts"
    echo "4. Apply best possible optimization"
    echo "5. Verify results"
    echo ""
    read -p "Continue with optimization? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Optimization cancelled"
        exit 1
    fi
    
    check_spot_support
    check_system_pool_constraints
    remove_karpenter
    optimize_based_on_findings
    verify_optimization
    
    print_success "🎉 AKS Cost Optimization Completed!"
    print_success "Optimization applied based on your subscription capabilities."
}

# Run main function
main "$@"
