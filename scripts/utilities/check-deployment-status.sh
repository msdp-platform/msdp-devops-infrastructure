#!/bin/bash

# MSDP Platform Components Deployment Status Checker
# This script checks the status of platform components deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
VERBOSE=false

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

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Check MSDP Platform Components Deployment Status

OPTIONS:
    -e, --environment ENV     Environment (dev, test, prod) [default: dev]
    -v, --verbose            Verbose output [default: false]
    -h, --help               Show this help message

EXAMPLES:
    $0                       # Check dev environment
    $0 -e test              # Check test environment
    $0 -e prod -v           # Check prod environment with verbose output

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, test, or prod."
    exit 1
fi

# Function to check AKS cluster connectivity
check_aks_connectivity() {
    print_status "Checking AKS cluster connectivity for $ENVIRONMENT environment..."
    
    RESOURCE_GROUP="msdp-${ENVIRONMENT}-rg"
    CLUSTER_NAME="msdp-${ENVIRONMENT}-aks"
    
    if az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing >/dev/null 2>&1; then
        print_success "Successfully connected to $CLUSTER_NAME"
        return 0
    else
        print_error "Failed to connect to $CLUSTER_NAME"
        return 1
    fi
}

# Function to check platform components
check_platform_components() {
    print_status "Checking platform components status..."
    
    local all_healthy=true
    
    # Check NGINX Ingress Controller
    print_status "Checking NGINX Ingress Controller..."
    if kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep -q "Running"; then
        print_success "NGINX Ingress Controller is running"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get pods -n ingress-nginx
            kubectl get svc -n ingress-nginx
        fi
    else
        print_error "NGINX Ingress Controller is not running"
        all_healthy=false
    fi
    
    # Check Cert-Manager
    print_status "Checking Cert-Manager..."
    if kubectl get pods -n cert-manager --no-headers 2>/dev/null | grep -q "Running"; then
        print_success "Cert-Manager is running"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get pods -n cert-manager
            kubectl get clusterissuer
        fi
    else
        print_error "Cert-Manager is not running"
        all_healthy=false
    fi
    
    # Check External DNS
    print_status "Checking External DNS..."
    if kubectl get pods -n external-dns --no-headers 2>/dev/null | grep -q "Running"; then
        print_success "External DNS is running"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get pods -n external-dns
            kubectl get svc -n external-dns
        fi
    else
        print_error "External DNS is not running"
        all_healthy=false
    fi
    
    return $([ "$all_healthy" = "true" ] && echo 0 || echo 1)
}

# Function to check applications
check_applications() {
    print_status "Checking applications status..."
    
    local all_healthy=true
    
    # Check ArgoCD
    print_status "Checking ArgoCD..."
    if kubectl get pods -n argocd --no-headers 2>/dev/null | grep -q "Running"; then
        print_success "ArgoCD is running"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get pods -n argocd
        fi
    else
        print_warning "ArgoCD is not running (may not be deployed yet)"
    fi
    
    # Check Backstage
    print_status "Checking Backstage..."
    if kubectl get pods -n backstage --no-headers 2>/dev/null | grep -q "Running"; then
        print_success "Backstage is running"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get pods -n backstage
        fi
    else
        print_warning "Backstage is not running (may not be deployed yet)"
    fi
    
    # Check Crossplane
    print_status "Checking Crossplane..."
    if kubectl get pods -n crossplane-system --no-headers 2>/dev/null | grep -q "Running"; then
        print_success "Crossplane is running"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get pods -n crossplane-system
        fi
    else
        print_warning "Crossplane is not running (may not be deployed yet)"
    fi
    
    return 0
}

# Function to check ingress and certificates
check_ingress_certificates() {
    print_status "Checking ingress and certificates..."
    
    # Check ingress
    print_status "Checking ingress resources..."
    if kubectl get ingress -A --no-headers 2>/dev/null | grep -q "argocd\|backstage"; then
        print_success "Application ingress resources found"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get ingress -A
        fi
    else
        print_warning "No application ingress resources found"
    fi
    
    # Check certificates
    print_status "Checking certificates..."
    if kubectl get certificates -A --no-headers 2>/dev/null | grep -q "argocd\|backstage"; then
        print_success "Application certificates found"
        if [ "$VERBOSE" = "true" ]; then
            kubectl get certificates -A
        fi
    else
        print_warning "No application certificates found"
    fi
}

# Function to check DNS resolution
check_dns_resolution() {
    print_status "Checking DNS resolution..."
    
    local dns_working=true
    
    # Test DNS resolution
    if nslookup argocd.dev.aztech-msdp.com >/dev/null 2>&1; then
        print_success "DNS resolution working for argocd.dev.aztech-msdp.com"
    else
        print_warning "DNS resolution not working for argocd.dev.aztech-msdp.com"
        dns_working=false
    fi
    
    if nslookup backstage.dev.aztech-msdp.com >/dev/null 2>&1; then
        print_success "DNS resolution working for backstage.dev.aztech-msdp.com"
    else
        print_warning "DNS resolution not working for backstage.dev.aztech-msdp.com"
        dns_working=false
    fi
    
    return $([ "$dns_working" = "true" ] && echo 0 || echo 1)
}

# Main function
main() {
    print_status "Starting MSDP Platform Components Deployment Status Check"
    print_status "Environment: $ENVIRONMENT"
    print_status "Verbose: $VERBOSE"
    
    local overall_status=0
    
    # Check AKS connectivity
    if ! check_aks_connectivity; then
        print_error "Cannot connect to AKS cluster. Please check your Azure credentials and cluster configuration."
        exit 1
    fi
    
    # Check platform components
    if ! check_platform_components; then
        print_error "Platform components are not healthy"
        overall_status=1
    fi
    
    # Check applications
    check_applications
    
    # Check ingress and certificates
    check_ingress_certificates
    
    # Check DNS resolution
    if ! check_dns_resolution; then
        print_warning "DNS resolution issues detected"
    fi
    
    # Summary
    print_status "Deployment status check completed"
    
    if [ $overall_status -eq 0 ]; then
        print_success "Platform components are healthy! ✅"
        print_status "You can proceed with application deployment"
    else
        print_error "Platform components have issues ❌"
        print_status "Please check the GitHub Actions workflow logs and troubleshoot"
    fi
    
    exit $overall_status
}

# Run main function
main "$@"
