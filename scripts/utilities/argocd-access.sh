#!/bin/bash

# ArgoCD Access Management Script for AKS
# This script provides easy access to ArgoCD running on AKS

set -e

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
    echo "  status     - Show ArgoCD status and access info"
    echo "  login      - Login to ArgoCD CLI"
    echo "  password   - Show admin password"
    echo "  url        - Show ArgoCD URL"
    echo "  help       - Show this help message"
}

# Function to show ArgoCD status
show_status() {
    echo -e "${BLUE}📊 ArgoCD Status on AKS${NC}"
    echo "========================="
    
    # Show ArgoCD pods
    echo -e "\n${YELLOW}ArgoCD Pods:${NC}"
    kubectl get pods -n argocd
    
    # Show ArgoCD service
    echo -e "\n${YELLOW}ArgoCD Service:${NC}"
    kubectl get svc argocd-server -n argocd
    
    # Show ArgoCD URL and credentials
    echo -e "\n${YELLOW}Access Information:${NC}"
    ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "  URL: https://$ARGOCD_URL"
    echo "  Username: admin"
    echo "  Password: admin123"
    
    echo -e "\n${GREEN}🌐 Open ArgoCD UI:${NC}"
    echo "  https://$ARGOCD_URL"
}

# Function to show admin password
show_password() {
    echo -e "${BLUE}🔑 ArgoCD Admin Password${NC}"
    echo "========================"
    echo "admin123"
    echo ""
}

# Function to show ArgoCD URL
show_url() {
    echo -e "${BLUE}🌐 ArgoCD URL${NC}"
    echo "============="
    ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "https://$ARGOCD_URL"
}

# Function to login to ArgoCD CLI
login_cli() {
    echo -e "${GREEN}🔐 Logging into ArgoCD CLI${NC}"
    
    ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    ARGOCD_PASSWORD="admin123"
    
    echo "URL: https://$ARGOCD_URL"
    echo "Username: admin"
    echo "Password: $ARGOCD_PASSWORD"
    
    # Login to ArgoCD CLI
    argocd login $ARGOCD_URL --username admin --password "$ARGOCD_PASSWORD" --insecure
    
    echo -e "${GREEN}✅ Successfully logged into ArgoCD CLI${NC}"
}

# Main script logic
case "${1:-help}" in
    status)
        show_status
        ;;
    login)
        login_cli
        ;;
    password)
        show_password
        ;;
    url)
        show_url
        ;;
    help|*)
        usage
        ;;
esac
