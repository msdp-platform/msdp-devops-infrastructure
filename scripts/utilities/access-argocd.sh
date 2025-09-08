#!/bin/bash

# ArgoCD Access Script - Smart Deployment System
# This script provides access to ArgoCD in the smart deployment system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to detect environment
detect_environment() {
    # Try to detect environment from current context
    if kubectl get namespace argocd-dev &>/dev/null; then
        echo "dev"
    elif kubectl get namespace argocd-test &>/dev/null; then
        echo "test"
    elif kubectl get namespace argocd-prod &>/dev/null; then
        echo "prod"
    else
        echo "argocd"
    fi
}

ENVIRONMENT=$(detect_environment)
ARGOCD_NAMESPACE="argocd-${ENVIRONMENT}"

echo -e "${BLUE}🚀 ArgoCD Access - Smart Deployment System${NC}"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $ARGOCD_NAMESPACE"
echo ""

# Check if ArgoCD is running
if ! kubectl get pods -n "$ARGOCD_NAMESPACE" &>/dev/null; then
    echo -e "${RED}❌ ArgoCD not found in namespace: $ARGOCD_NAMESPACE${NC}"
    echo "Available namespaces:"
    kubectl get namespaces | grep argocd || echo "No ArgoCD namespaces found"
    exit 1
fi

# Get ArgoCD service info
ARGOCD_SERVICE=$(kubectl get svc -n "$ARGOCD_NAMESPACE" | grep argocd-server | awk '{print $1}' || echo "")
if [ -z "$ARGOCD_SERVICE" ]; then
    echo -e "${RED}❌ ArgoCD server service not found${NC}"
    exit 1
fi

# Get public IP or use port-forward
PUBLIC_IP=$(kubectl get svc -n "$ARGOCD_NAMESPACE" "$ARGOCD_SERVICE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

echo -e "${GREEN}Method 1: Through Ingress (Recommended)${NC}"
echo "====================================="
if [ -n "$PUBLIC_IP" ]; then
    echo "1. Add to /etc/hosts:"
    echo "   echo \"$PUBLIC_IP argocd.$ENVIRONMENT.aztech-msdp.com\" | sudo tee -a /etc/hosts"
    echo ""
    echo "2. Access ArgoCD:"
    echo "   URL: https://argocd.$ENVIRONMENT.aztech-msdp.com"
    echo "   Username: admin"
    echo "   Password: (check secrets in namespace $ARGOCD_NAMESPACE)"
    echo ""
else
    echo "No public IP available. Use port-forward method below."
    echo ""
fi

echo -e "${BLUE}Method 2: Port Forward (Temporary)${NC}"
echo "=================================="
echo "1. Start port forward:"
echo "   kubectl port-forward svc/$ARGOCD_SERVICE -n $ARGOCD_NAMESPACE 8080:443 &"
echo ""
echo "2. Access ArgoCD:"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: (check secrets in namespace $ARGOCD_NAMESPACE)"
echo ""

echo -e "${GREEN}🎯 Quick Setup Commands:${NC}"
echo "========================"
if [ -n "$PUBLIC_IP" ]; then
    echo "# Add to hosts file"
    echo "echo \"$PUBLIC_IP argocd.$ENVIRONMENT.aztech-msdp.com\" | sudo tee -a /etc/hosts"
    echo ""
fi
echo "# Start port forward"
echo "kubectl port-forward svc/$ARGOCD_SERVICE -n $ARGOCD_NAMESPACE 8080:443 &"
echo ""

echo -e "${YELLOW}💡 Troubleshooting:${NC}"
echo "=================="
echo "If access doesn't work:"
echo "1. Check ArgoCD status: kubectl get pods -n $ARGOCD_NAMESPACE"
echo "2. Check service: kubectl get svc -n $ARGOCD_NAMESPACE"
echo "3. Check ingress: kubectl get ingress -n $ARGOCD_NAMESPACE"
echo "4. Use port forward as backup: kubectl port-forward svc/$ARGOCD_SERVICE -n $ARGOCD_NAMESPACE 8080:443"
