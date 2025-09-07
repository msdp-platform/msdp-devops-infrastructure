#!/bin/bash

# Setup script for Minikube + Crossplane + ArgoCD integration
# Multi-Service Delivery Platform

set -e

echo "🚀 Setting up Minikube + Crossplane + ArgoCD for Multi-Service Delivery Platform"
echo "=================================================================================="

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

# Check if Minikube is running
print_status "Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    print_error "Minikube is not running. Please start Minikube first:"
    echo "  minikube start --memory=7000 --cpus=4 --disk-size=20g"
    exit 1
fi
print_success "Minikube is running"

# Check if required addons are enabled
print_status "Checking Minikube addons..."
if ! minikube addons list | grep -q "ingress.*enabled"; then
    print_warning "Enabling ingress addon..."
    minikube addons enable ingress
fi

if ! minikube addons list | grep -q "metrics-server.*enabled"; then
    print_warning "Enabling metrics-server addon..."
    minikube addons enable metrics-server
fi
print_success "Required addons are enabled"

# Check Crossplane installation
print_status "Checking Crossplane installation..."
if ! kubectl get pods -n crossplane-system > /dev/null 2>&1; then
    print_error "Crossplane is not installed. Please install Crossplane first:"
    echo "  kubectl create namespace crossplane-system"
    echo "  helm repo add crossplane-stable https://charts.crossplane.io/stable"
    echo "  helm repo update"
    echo "  helm install crossplane crossplane-stable/crossplane --version 2.0.2 -n crossplane-system"
    exit 1
fi

# Check if Crossplane pods are running
if ! kubectl get pods -n crossplane-system | grep -q "Running"; then
    print_warning "Crossplane pods are not running. Waiting for them to start..."
    kubectl wait --for=condition=Ready pod -l app=crossplane -n crossplane-system --timeout=300s
fi
print_success "Crossplane is running"

# Check Azure provider
print_status "Checking Azure provider..."
if ! kubectl get providers | grep -q "crossplane-contrib-provider-azure"; then
    print_warning "Azure provider not found. Installing..."
    crossplane xpkg install provider xpkg.upbound.io/crossplane-contrib/provider-azure:v0.32.0
fi
print_success "Azure provider is installed"

# Check ArgoCD installation
print_status "Checking ArgoCD installation..."
if ! kubectl get pods -n argocd > /dev/null 2>&1; then
    print_error "ArgoCD is not installed. Please install ArgoCD first:"
    echo "  kubectl create namespace argocd"
    echo "  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi

# Check if ArgoCD pods are running
if ! kubectl get pods -n argocd | grep -q "Running"; then
    print_warning "ArgoCD pods are not running. Waiting for them to start..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
fi
print_success "ArgoCD is running"

# Apply ArgoCD applications
print_status "Applying ArgoCD applications..."
if kubectl apply -f infrastructure/argocd/applications/delivery-platform-applications.yaml; then
    print_success "ArgoCD applications applied successfully"
else
    print_error "Failed to apply ArgoCD applications"
    exit 1
fi

# Get ArgoCD admin password
print_status "Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Password not available yet")

# Display access information
echo ""
echo "🎉 Setup completed successfully!"
echo "================================"
echo ""
echo "📊 Access Information:"
echo "  ArgoCD UI: https://localhost:8080 (use port-forward)"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "🔧 Useful Commands:"
echo "  # Port-forward ArgoCD UI"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "  # Check Crossplane status"
echo "  kubectl get pods -n crossplane-system"
echo "  kubectl get providers"
echo ""
echo "  # Check ArgoCD status"
echo "  kubectl get pods -n argocd"
echo "  kubectl get applications -n argocd"
echo ""
echo "  # Check ArgoCD admin password"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "📁 Repository Integration:"
echo "  Repository: https://github.com/santanubiswas2k1/multi-service-delivery-platform"
echo "  ArgoCD will automatically sync from this repository"
echo ""
echo "🚀 Next Steps:"
echo "  1. Access ArgoCD UI at https://localhost:8080"
echo "  2. Login with admin/$ARGOCD_PASSWORD"
echo "  3. Check application sync status"
echo "  4. Configure Azure credentials for Crossplane"
echo "  5. Create database claims to test infrastructure provisioning"
echo ""
