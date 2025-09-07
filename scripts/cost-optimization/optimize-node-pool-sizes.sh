#!/bin/bash

# Optimize Node Pool Sizes for Maximum Cost Efficiency
# System Pool: B1s (smaller, cheaper for always-on components)
# User Pool: B2s Spot (larger, much cheaper for user workloads)

set -e

echo "🔧 Optimizing Node Pool Sizes for Maximum Cost Efficiency"
echo "========================================================"

# Function to check if Azure CLI is logged in
check_azure_login() {
    echo "🔐 Checking Azure CLI login..."
    if ! az account show >/dev/null 2>&1; then
        echo "❌ Not logged into Azure CLI"
        echo "Please run: az login"
        exit 1
    fi
    echo "✅ Azure CLI logged in"
}

# Function to connect to AKS
connect_aks() {
    echo "🔗 Connecting to AKS cluster..."
    if ! az aks get-credentials --resource-group delivery-platform-aks-rg --name delivery-platform-aks --overwrite-existing >/dev/null 2>&1; then
        echo "❌ Failed to connect to AKS cluster"
        exit 1
    fi
    echo "✅ Connected to AKS cluster"
}

# Function to update system node pool to B1s
update_system_node_pool() {
    echo ""
    echo "🔧 Updating System Node Pool to B1s..."
    echo "====================================="
    
    # Check current configuration
    echo "Current system node pool configuration:"
    az aks nodepool show --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --query '{name: name, vmSize: vmSize, mode: mode, count: count, minCount: minCount, maxCount: maxCount}' -o table
    
    echo ""
    echo "⚠️  This will update the system node pool to use B1s instances"
    echo "Benefits:"
    echo "  - Smaller, cheaper instances for system components"
    echo "  - 1 vCPU, 1 GB RAM (sufficient for system daemon pods)"
    echo "  - ~50% cost reduction for system nodes"
    echo ""
    read -p "Continue with system node pool update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ System node pool update cancelled"
        return 1
    fi
    
    # Disable autoscaling temporarily
    echo "📉 Disabling autoscaling for system node pool..."
    az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --disable-cluster-autoscaler
    
    # Scale down to 0 to allow VM size change
    echo "📉 Scaling system node pool to 0..."
    az aks nodepool scale --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --node-count 0
    
    # Wait for scale down
    echo "⏳ Waiting for system nodes to scale down..."
    sleep 30
    
    # Update VM size to B1s
    echo "🔧 Updating system node pool VM size to Standard_B1s..."
    az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --vm-size Standard_B1s
    
    # Scale back up to 1
    echo "📈 Scaling system node pool back to 1..."
    az aks nodepool scale --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --node-count 1
    
    # Re-enable autoscaling
    echo "📈 Re-enabling autoscaling for system node pool..."
    az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --enable-cluster-autoscaler --min-count 1 --max-count 2
    
    echo "✅ System node pool updated to B1s"
}

# Function to update user node pool to B2s Spot
update_user_node_pool() {
    echo ""
    echo "🔧 Updating User Node Pool to B2s Spot..."
    echo "========================================"
    
    # Check current configuration
    echo "Current user node pool configuration:"
    az aks nodepool show --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name userpool --query '{name: name, vmSize: vmSize, mode: mode, count: count, minCount: minCount, maxCount: maxCount}' -o table
    
    echo ""
    echo "⚠️  This will update the user node pool to use B2s Spot instances"
    echo "Benefits:"
    echo "  - Same size as current (2 vCPU, 4 GB RAM)"
    echo "  - Up to 90% cost reduction with Spot pricing"
    echo "  - Perfect for user workloads that can tolerate interruptions"
    echo "  - Automatic scaling to 0 when not needed"
    echo ""
    read -p "Continue with user node pool update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ User node pool update cancelled"
        return 1
    fi
    
    # Update VM size to B2s Spot
    echo "🔧 Updating user node pool VM size to Standard_B2s with Spot pricing..."
    az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name userpool --vm-size Standard_B2s --priority Spot --eviction-policy Delete --spot-max-price -1
    
    echo "✅ User node pool updated to B2s Spot"
}

# Function to show final configuration
show_final_configuration() {
    echo ""
    echo "🎉 Node Pool Optimization Complete!"
    echo "=================================="
    
    echo ""
    echo "📊 Final Node Pool Configuration:"
    az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table
    
    echo ""
    echo "💰 Cost Optimization Benefits:"
    echo "=============================="
    echo "✅ System Node Pool (B1s):"
    echo "  - 1 vCPU, 1 GB RAM"
    echo "  - ~50% cost reduction vs B2s"
    echo "  - Perfect for system daemon pods"
    echo ""
    echo "✅ User Node Pool (B2s Spot):"
    echo "  - 2 vCPU, 4 GB RAM"
    echo "  - Up to 90% cost reduction with Spot pricing"
    echo "  - Scales to 0 when not needed"
    echo "  - Perfect for user workloads"
    echo ""
    echo "🎯 Total Cost Reduction:"
    echo "  - System nodes: ~50% reduction"
    echo "  - User nodes: Up to 90% reduction (when running)"
    echo "  - Combined: Significant overall cost savings"
    echo ""
    echo "💡 Next Steps:"
    echo "  - Monitor costs with: python3 scripts/platform-manager.py status"
    echo "  - Test platform functionality"
    echo "  - Enjoy significant cost savings!"
}

# Main execution
main() {
    check_azure_login
    connect_aks
    
    echo ""
    echo "🎯 Node Pool Optimization Strategy:"
    echo "=================================="
    echo "System Pool: B1s (smaller, cheaper for always-on components)"
    echo "User Pool: B2s Spot (larger, much cheaper for user workloads)"
    echo ""
    
    update_system_node_pool
    update_user_node_pool
    show_final_configuration
}

# Run main function
main "$@"
