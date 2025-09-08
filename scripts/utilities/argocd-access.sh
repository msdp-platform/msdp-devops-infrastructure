#!/bin/bash

# ArgoCD Access Management Script - Smart Deployment System
# This script provides easy access to ArgoCD in the smart deployment system

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
    echo ""
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $ARGOCD_NAMESPACE"
}

# Function to show ArgoCD status
show_status() {
    echo -e "${BLUE}📊 ArgoCD Status - Smart Deployment System${NC}"
    echo "=============================================="
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $ARGOCD_NAMESPACE"
    echo ""
    
    # Check if ArgoCD is running
    if ! kubectl get pods -n "$ARGOCD_NAMESPACE" &>/dev/null; then
        echo -e "${RED}❌ ArgoCD not found in namespace: $ARGOCD_NAMESPACE${NC}"
        echo "Available namespaces:"
        kubectl get namespaces | grep argocd || echo "No ArgoCD namespaces found"
        return 1
    fi
    
    # Show ArgoCD pods
    echo -e "${YELLOW}ArgoCD Pods:${NC}"
    kubectl get pods -n "$ARGOCD_NAMESPACE"
    
    # Show ArgoCD service
    echo -e "\n${YELLOW}ArgoCD Service:${NC}"
    kubectl get svc -n "$ARGOCD_NAMESPACE" | grep argocd-server || echo "ArgoCD server service not found"
    
    # Show ArgoCD URL and credentials
    echo -e "\n${YELLOW}Access Information:${NC}"
    ARGOCD_URL=$(kubectl get svc -n "$ARGOCD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$ARGOCD_URL" ]; then
        echo "  URL: https://$ARGOCD_URL"
        echo "  Ingress URL: https://argocd.$ENVIRONMENT.aztech-msdp.com"
    else
        echo "  URL: Use port-forward (see login command)"
        echo "  Ingress URL: https://argocd.$ENVIRONMENT.aztech-msdp.com"
    fi
    echo "  Username: admin"
    echo "  Password: (check secrets in namespace $ARGOCD_NAMESPACE)"
    
    echo -e "\n${GREEN}🌐 Access Methods:${NC}"
    if [ -n "$ARGOCD_URL" ]; then
        echo "  Direct: https://$ARGOCD_URL"
    fi
    echo "  Ingress: https://argocd.$ENVIRONMENT.aztech-msdp.com"
    echo "  Port-forward: kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
}

# Function to show admin password
show_password() {
    echo -e "${BLUE}🔑 ArgoCD Admin Password${NC}"
    echo "========================"
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $ARGOCD_NAMESPACE"
    echo ""
    
    # Try to get password from secret
    PASSWORD=$(kubectl get secret -n "$ARGOCD_NAMESPACE" argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
    
    if [ -n "$PASSWORD" ]; then
        echo "Password: $PASSWORD"
    else
        echo "Password not found in secret. Check namespace $ARGOCD_NAMESPACE"
        echo "Available secrets:"
        kubectl get secrets -n "$ARGOCD_NAMESPACE" | grep argocd || echo "No ArgoCD secrets found"
    fi
    echo ""
}

# Function to show ArgoCD URL
show_url() {
    echo -e "${BLUE}🌐 ArgoCD URL${NC}"
    echo "============="
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $ARGOCD_NAMESPACE"
    echo ""
    
    ARGOCD_URL=$(kubectl get svc -n "$ARGOCD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$ARGOCD_URL" ]; then
        echo "Direct URL: https://$ARGOCD_URL"
    fi
    echo "Ingress URL: https://argocd.$ENVIRONMENT.aztech-msdp.com"
    echo "Port-forward: kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
}

# Function to login to ArgoCD CLI
login_cli() {
    echo -e "${GREEN}🔐 Logging into ArgoCD CLI${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Namespace: $ARGOCD_NAMESPACE"
    echo ""
    
    # Get ArgoCD URL
    ARGOCD_URL=$(kubectl get svc -n "$ARGOCD_NAMESPACE" -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$ARGOCD_URL" ]; then
        echo -e "${YELLOW}No public IP found. Starting port-forward...${NC}"
        kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" 8080:443 &
        PORT_FORWARD_PID=$!
        sleep 3
        ARGOCD_URL="localhost:8080"
        echo "Port-forward started (PID: $PORT_FORWARD_PID)"
    fi
    
    # Get password from secret
    ARGOCD_PASSWORD=$(kubectl get secret -n "$ARGOCD_NAMESPACE" argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "admin123")
    
    echo "URL: https://$ARGOCD_URL"
    echo "Username: admin"
    echo "Password: $ARGOCD_PASSWORD"
    echo ""
    
    # Login to ArgoCD CLI
    if argocd login "$ARGOCD_URL" --username admin --password "$ARGOCD_PASSWORD" --insecure; then
        echo -e "${GREEN}✅ Successfully logged into ArgoCD CLI${NC}"
    else
        echo -e "${RED}❌ Failed to login to ArgoCD CLI${NC}"
        echo "Try using port-forward: kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
    fi
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
