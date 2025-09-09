#!/bin/bash

# Connect to AKS with environment-specific kubeconfig
# Usage: ./scripts/utilities/connect-aks.sh [dev|test|prod]

set -e

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

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Environment not specified"
    echo "Usage: $0 [dev|test|prod]"
    echo ""
    echo "Examples:"
    echo "  $0 dev    # Connect to dev environment"
    echo "  $0 test   # Connect to test environment"
    echo "  $0 prod   # Connect to prod environment"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
case $ENVIRONMENT in
    dev|test|prod)
        print_status "Connecting to $ENVIRONMENT environment..."
        ;;
    *)
        print_error "Invalid environment: $ENVIRONMENT"
        echo "Valid environments: dev, test, prod"
        exit 1
        ;;
esac

# Set environment-specific values
case $ENVIRONMENT in
    dev)
        RESOURCE_GROUP="delivery-platform-aks-rg"
        CLUSTER_NAME="msdp-infra-aks"
        ;;
    test)
        RESOURCE_GROUP="delivery-platform-aks-rg-test"
        CLUSTER_NAME="msdp-infra-aks-test"
        ;;
    prod)
        RESOURCE_GROUP="delivery-platform-aks-rg-prod"
        CLUSTER_NAME="msdp-infra-aks-prod"
        ;;
esac

# Create kubeconfig directory if it doesn't exist
mkdir -p ~/.kube

# Option 1: Separate kubeconfig files
KUBECONFIG_FILE="$HOME/.kube/config-msdp-$ENVIRONMENT"

print_status "Getting AKS credentials..."
print_status "Resource Group: $RESOURCE_GROUP"
print_status "Cluster Name: $CLUSTER_NAME"
print_status "Kubeconfig File: $KUBECONFIG_FILE"

# Get AKS credentials
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --file "$KUBECONFIG_FILE" \
    --overwrite-existing

print_success "AKS credentials saved to: $KUBECONFIG_FILE"

# Set KUBECONFIG environment variable
export KUBECONFIG="$KUBECONFIG_FILE"

print_status "Testing connection..."
if kubectl cluster-info >/dev/null 2>&1; then
    print_success "Successfully connected to $ENVIRONMENT cluster!"
    
    # Show cluster info
    echo ""
    print_status "Cluster Information:"
    kubectl cluster-info
    
    echo ""
    print_status "Current Context:"
    kubectl config current-context
    
    echo ""
    print_status "Available Nodes:"
    kubectl get nodes
    
else
    print_error "Failed to connect to cluster"
    exit 1
fi

echo ""
print_success "Setup complete!"
print_warning "To use this kubeconfig in your current session, run:"
echo "export KUBECONFIG=\"$KUBECONFIG_FILE\""
echo ""
print_warning "Or add this to your ~/.bashrc or ~/.zshrc:"
echo "alias kubectl-$ENVIRONMENT='KUBECONFIG=\"$KUBECONFIG_FILE\" kubectl'"
echo ""
print_status "Then you can use: kubectl-$ENVIRONMENT get pods"
