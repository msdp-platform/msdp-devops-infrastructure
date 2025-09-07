#!/bin/bash

# ArgoCD Access Script
# This script provides multiple ways to access ArgoCD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get current public IP
PUBLIC_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not available")

echo -e "${BLUE}🚀 ArgoCD Access Methods${NC}"
echo "========================="
echo ""

echo -e "${GREEN}Method 1: Through Ingress (Recommended)${NC}"
echo "====================================="
echo "1. Add to /etc/hosts:"
echo "   echo \"$PUBLIC_IP argocd.delivery-platform.local\" | sudo tee -a /etc/hosts"
echo ""
echo "2. Access ArgoCD:"
echo "   URL: http://argocd.delivery-platform.local"
echo "   Username: admin"
echo "   Password: admin123"
echo ""

echo -e "${YELLOW}Method 2: Direct Public IP${NC}"
echo "=========================="
echo "URL: http://$PUBLIC_IP"
echo "Username: admin"
echo "Password: admin123"
echo ""

echo -e "${BLUE}Method 3: Port Forward (Temporary)${NC}"
echo "=================================="
echo "1. Start port forward:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo ""
echo "2. Access ArgoCD:"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: admin123"
echo ""

echo -e "${GREEN}🎯 Quick Setup Commands:${NC}"
echo "========================"
echo "# Add to hosts file"
echo "echo \"$PUBLIC_IP argocd.delivery-platform.local\" | sudo tee -a /etc/hosts"
echo ""
echo "# Start port forward (if needed)"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo ""

echo -e "${YELLOW}💡 Troubleshooting:${NC}"
echo "=================="
echo "If ingress doesn't work:"
echo "1. Check ingress status: kubectl get ingress -n argocd"
echo "2. Check ingress logs: kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx"
echo "3. Use port forward as backup: kubectl port-forward svc/argocd-server -n argocd 8080:443"
