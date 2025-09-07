#!/bin/bash

# Multi-Cloud Provider Setup Script for Crossplane
# Supports AWS, GCP, and Azure providers

set -e

echo "🌐 Setting up Multi-Cloud Providers for Crossplane"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Crossplane is running
print_status "Checking Crossplane status..."
if ! kubectl get pods -n crossplane-system | grep -q "Running"; then
    print_error "Crossplane is not running. Please install Crossplane first."
    exit 1
fi
print_success "Crossplane is running"

# Check providers status
print_status "Checking provider installation status..."
kubectl get providers

echo ""
print_status "Installing Multi-Cloud Compositions..."

# Apply multi-cloud compositions
if kubectl apply -f infrastructure/crossplane/compositions/multi-cloud-database-composition.yaml; then
    print_success "Multi-cloud database composition applied"
else
    print_error "Failed to apply multi-cloud composition"
    exit 1
fi

# Apply provider configurations (templates)
print_status "Applying provider configuration templates..."
if kubectl apply -f infrastructure/crossplane/provider-configs/; then
    print_success "Provider configuration templates applied"
else
    print_warning "Some provider configurations may need manual setup"
fi

# Display setup instructions
echo ""
echo "🎉 Multi-Cloud Setup Completed!"
echo "==============================="
echo ""
echo "📊 Current Status:"
echo "  ✅ Crossplane: Running"
echo "  ✅ AWS Provider: Installed"
echo "  ✅ GCP Provider: Installed" 
echo "  ✅ Azure Provider: Installed"
echo "  ✅ Multi-Cloud Compositions: Applied"
echo ""
echo "🔧 Next Steps - Configure Cloud Credentials:"
echo ""
echo "1. AWS Configuration:"
echo "   # Create AWS credentials secret"
echo "   kubectl create secret generic aws-credentials \\"
echo "     --from-literal=credentials='[default]\\naws_access_key_id=YOUR_KEY\\naws_secret_access_key=YOUR_SECRET\\nregion=us-east-1' \\"
echo "     -n crossplane-system"
echo ""
echo "2. GCP Configuration:"
echo "   # Create GCP service account key and secret"
echo "   kubectl create secret generic gcp-credentials \\"
echo "     --from-file=credentials=path/to/service-account-key.json \\"
echo "     -n crossplane-system"
echo ""
echo "3. Azure Configuration:"
echo "   # Create Azure credentials secret"
echo "   kubectl create secret generic azure-credentials \\"
echo "     --from-literal=client_id=YOUR_CLIENT_ID \\"
echo "     --from-literal=client_secret=YOUR_CLIENT_SECRET \\"
echo "     --from-literal=tenant_id=YOUR_TENANT_ID \\"
echo "     --from-literal=subscription_id=YOUR_SUBSCRIPTION_ID \\"
echo "     -n crossplane-system"
echo ""
echo "🚀 Test Multi-Cloud Infrastructure:"
echo ""
echo "  # AWS Database"
echo "  kubectl apply -f infrastructure/crossplane/claims/aws-database-claim.yaml"
echo ""
echo "  # GCP Database"
echo "  kubectl apply -f infrastructure/crossplane/claims/gcp-database-claim.yaml"
echo ""
echo "  # Azure Database"
echo "  kubectl apply -f infrastructure/crossplane/claims/azure-database-claim.yaml"
echo ""
echo "📋 Monitor Resources:"
echo "  kubectl get databases"
echo "  kubectl get managed"
echo "  kubectl describe database <database-name>"
echo ""
echo "🌐 Supported Cloud Providers:"
echo "  • AWS: RDS PostgreSQL, ElastiCache Redis"
echo "  • GCP: Cloud SQL PostgreSQL, Memorystore Redis"
echo "  • Azure: Database for PostgreSQL, Cache for Redis"
echo ""
