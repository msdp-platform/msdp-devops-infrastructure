#!/bin/bash

# Complete AKS Cleanup and Fresh Setup Script
# This script completely removes the existing AKS cluster and sets up a clean, cost-optimized cluster

set -e

echo "🧹 Complete AKS Cleanup and Fresh Setup"
echo "======================================"

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

# Step 1: Complete AKS Cluster Deletion
delete_aks_cluster() {
    print_status "Step 1: Deleting AKS cluster completely..."
    
    echo "This will delete the entire AKS cluster and all associated resources."
    echo "Resource Group: delivery-platform-aks-rg"
    echo "Cluster Name: delivery-platform-aks"
    echo ""
    read -p "Are you sure you want to delete everything? (yes/NO): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_warning "Deletion cancelled"
        exit 1
    fi
    
    print_status "Deleting AKS cluster..."
    az aks delete \
        --resource-group delivery-platform-aks-rg \
        --name delivery-platform-aks \
        --yes \
        --no-wait
    
    print_success "AKS cluster deletion initiated"
}

# Step 2: Clean up Resource Group
cleanup_resource_group() {
    print_status "Step 2: Cleaning up resource group and all resources..."
    
    print_warning "This will delete ALL resources in the resource group!"
    read -p "Continue with resource group cleanup? (yes/NO): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_warning "Resource group cleanup cancelled"
        return
    fi
    
    print_status "Deleting resource group: delivery-platform-aks-rg"
    az group delete \
        --name delivery-platform-aks-rg \
        --yes \
        --no-wait
    
    print_success "Resource group deletion initiated"
}

# Step 3: Wait for cleanup to complete
wait_for_cleanup() {
    print_status "Step 3: Waiting for cleanup to complete..."
    
    print_status "Waiting for AKS cluster deletion..."
    while az aks show --resource-group delivery-platform-aks-rg --name delivery-platform-aks &>/dev/null; do
        echo -n "."
        sleep 10
    done
    echo ""
    print_success "AKS cluster deleted"
    
    print_status "Waiting for resource group deletion..."
    while az group show --name delivery-platform-aks-rg &>/dev/null; do
        echo -n "."
        sleep 10
    done
    echo ""
    print_success "Resource group deleted"
}

# Step 4: Create fresh resource group
create_fresh_resource_group() {
    print_status "Step 4: Creating fresh resource group..."
    
    az group create \
        --name delivery-platform-aks-rg \
        --location eastus \
        --tags "Environment=Dev" "Project=MSDP" "ManagedBy=Script"
    
    print_success "Fresh resource group created"
}

# Step 5: Create clean AKS cluster
create_clean_aks_cluster() {
    print_status "Step 5: Creating clean AKS cluster with cost optimization..."
    
    # Create AKS cluster with proper configuration
    az aks create \
        --resource-group delivery-platform-aks-rg \
        --name delivery-platform-aks \
        --location eastus \
        --kubernetes-version 1.32 \
        --node-count 1 \
        --node-vm-size Standard_B2s \
        --min-count 1 \
        --max-count 2 \
        --enable-cluster-autoscaler \
        --enable-addons monitoring \
        --enable-managed-identity \
        --network-plugin azure \
        --network-policy azure \
        --generate-ssh-keys \
        --tags "Environment=Dev" "Project=MSDP" "CostOptimized=true"
    
    print_success "Clean AKS cluster created"
}

# Step 6: Create optimized user node pool
create_user_node_pool() {
    print_status "Step 6: Creating optimized user node pool..."
    
    # Test Spot instance support first
    print_status "Testing Spot instance support..."
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
        print_warning "Spot instances not supported, creating on-demand user pool"
        
        # Create user pool with on-demand instances
        az aks nodepool add \
            --resource-group delivery-platform-aks-rg \
            --cluster-name delivery-platform-aks \
            --nodepool-name userpool \
            --mode User \
            --vm-size Standard_B2s \
            --node-count 0 \
            --min-count 0 \
            --max-count 3 \
            --enable-cluster-autoscaler \
            --labels "cost-optimized=true" "scale-to-zero=true"
        
        print_success "User pool created with on-demand instances and scale-to-zero"
    else
        print_success "Spot instances supported, creating Spot user pool"
        
        # Clean up test VM
        az vm delete --resource-group delivery-platform-aks-rg --name spot-test-vm --yes 2>/dev/null || true
        
        # Create user pool with Spot instances
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
            --labels "cost-optimized=true" "spot-instance=true"
        
        print_success "User pool created with Spot instances (90% cost savings)"
    fi
}

# Step 7: Get cluster credentials and verify
verify_cluster() {
    print_status "Step 7: Getting cluster credentials and verifying setup..."
    
    # Get AKS credentials
    az aks get-credentials \
        --resource-group delivery-platform-aks-rg \
        --name delivery-platform-aks \
        --overwrite-existing
    
    # Verify cluster
    print_status "Verifying cluster setup..."
    kubectl get nodes
    kubectl get pods --all-namespaces
    
    print_success "Cluster verification completed"
}

# Step 8: Deploy infrastructure components
deploy_infrastructure() {
    print_status "Step 8: Deploying infrastructure components..."
    
    # Deploy ArgoCD
    print_status "Deploying ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Deploy Crossplane
    print_status "Deploying Crossplane..."
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace
    
    # Wait for Crossplane to be ready
    print_status "Waiting for Crossplane to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/crossplane -n crossplane-system
    
    print_success "Infrastructure components deployed"
}

# Step 9: Final verification and cost summary
final_verification() {
    print_status "Step 9: Final verification and cost summary..."
    
    echo ""
    echo "🎉 Clean AKS Setup Completed!"
    echo "=============================="
    echo ""
    echo "Cluster Information:"
    echo "- Name: delivery-platform-aks"
    echo "- Resource Group: delivery-platform-aks-rg"
    echo "- Location: eastus"
    echo "- Kubernetes Version: 1.32"
    echo ""
    echo "Node Pools:"
    az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table
    echo ""
    echo "Current Nodes:"
    kubectl get nodes -o wide
    echo ""
    echo "Infrastructure Components:"
    kubectl get pods --all-namespaces | grep -E "(argocd|crossplane)"
    echo ""
    echo "Cost Optimization:"
    echo "- System Pool: Standard_B2s (1-2 nodes, auto-scaling)"
    echo "- User Pool: Standard_B2s (0-3 nodes, scale-to-zero)"
    echo "- Spot Instances: $(if kubectl get nodes -l spot-instance=true --no-headers 2>/dev/null | wc -l | grep -q "0"; then echo "Not supported"; else echo "Enabled"; fi)"
    echo ""
    echo "Access Information:"
    echo "- ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "- ArgoCD Admin Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo ""
    print_success "Setup completed successfully!"
}

# Main execution
main() {
    echo "This script will:"
    echo "1. Delete the entire AKS cluster and resource group"
    echo "2. Create a fresh, clean AKS cluster"
    echo "3. Set up cost-optimized node pools"
    echo "4. Deploy infrastructure components (ArgoCD, Crossplane)"
    echo "5. Verify everything is working"
    echo ""
    echo "⚠️  WARNING: This will delete ALL existing resources!"
    echo ""
    read -p "Continue with complete cleanup and fresh setup? (yes/NO): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_warning "Setup cancelled"
        exit 1
    fi
    
    delete_aks_cluster
    cleanup_resource_group
    wait_for_cleanup
    create_fresh_resource_group
    create_clean_aks_cluster
    create_user_node_pool
    verify_cluster
    deploy_infrastructure
    final_verification
}

# Run main function
main "$@"
