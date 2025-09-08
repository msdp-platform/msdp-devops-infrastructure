#!/bin/bash

# MSDP Platform Components Deployment Script
# This script deploys platform components manually as an alternative to GitHub Actions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
COMPONENT="all"
DRY_RUN=false
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

Deploy MSDP Platform Components

OPTIONS:
    -e, --environment ENV     Environment (dev, test, prod) [default: dev]
    -c, --component COMP      Component (all, networking, monitoring) [default: all]
    -d, --dry-run            Perform dry run [default: false]
    -v, --verbose            Verbose output [default: false]
    -h, --help               Show this help message

EXAMPLES:
    $0                                    # Deploy all components to dev
    $0 -e test -c networking             # Deploy networking to test
    $0 -e prod -d                        # Dry run for prod
    $0 -e dev -c monitoring -v           # Deploy monitoring to dev with verbose output

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -c|--component)
            COMPONENT="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
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

# Validate component
if [[ ! "$COMPONENT" =~ ^(all|networking|monitoring)$ ]]; then
    print_error "Invalid component: $COMPONENT. Must be all, networking, or monitoring."
    exit 1
fi

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check kustomize
    if ! command -v kustomize &> /dev/null; then
        print_error "kustomize is not installed or not in PATH"
        exit 1
    fi
    
    print_success "All prerequisites are available"
}

# Function to get AKS credentials
get_aks_credentials() {
    print_status "Getting AKS credentials for $ENVIRONMENT environment..."
    
    RESOURCE_GROUP="msdp-${ENVIRONMENT}-rg"
    CLUSTER_NAME="msdp-${ENVIRONMENT}-aks"
    
    if ! az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing; then
        print_error "Failed to get AKS credentials for $CLUSTER_NAME"
        exit 1
    fi
    
    print_success "Successfully connected to $CLUSTER_NAME"
}

# Function to deploy networking components
deploy_networking() {
    print_status "Deploying networking components..."
    
    # Deploy NGINX Ingress Controller
    print_status "Deploying NGINX Ingress Controller..."
    if [ "$DRY_RUN" = "true" ]; then
        kustomize build infrastructure/platforms/networking/nginx-ingress/ | kubectl apply --dry-run=client -f -
    else
        kubectl apply -k infrastructure/platforms/networking/nginx-ingress/
    fi
    
    # Wait for NGINX Ingress Controller
    if [ "$DRY_RUN" = "false" ]; then
        print_status "Waiting for NGINX Ingress Controller to be ready..."
        kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=300s
    fi
    
    # Deploy Cert-Manager
    print_status "Deploying Cert-Manager..."
    if [ "$DRY_RUN" = "true" ]; then
        kustomize build infrastructure/platforms/networking/cert-manager/ | kubectl apply --dry-run=client -f -
    else
        kubectl apply -k infrastructure/platforms/networking/cert-manager/
    fi
    
    # Wait for Cert-Manager
    if [ "$DRY_RUN" = "false" ]; then
        print_status "Waiting for Cert-Manager to be ready..."
        kubectl wait --namespace cert-manager \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=300s
    fi
    
    # Deploy External DNS
    print_status "Deploying External DNS..."
    if [ "$DRY_RUN" = "true" ]; then
        kustomize build infrastructure/platforms/networking/external-dns/ | kubectl apply --dry-run=client -f -
    else
        kubectl apply -k infrastructure/platforms/networking/external-dns/
    fi
    
    # Wait for External DNS
    if [ "$DRY_RUN" = "false" ]; then
        print_status "Waiting for External DNS to be ready..."
        kubectl wait --namespace external-dns \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/name=external-dns \
            --timeout=300s
    fi
    
    print_success "Networking components deployed successfully"
}

# Function to deploy monitoring components
deploy_monitoring() {
    print_status "Deploying monitoring components..."
    
    if [ "$DRY_RUN" = "true" ]; then
        print_warning "Dry run mode - monitoring components would be deployed"
    else
        print_warning "Monitoring components deployment not yet implemented"
        # TODO: Add monitoring components deployment when available
    fi
    
    print_success "Monitoring components deployment completed"
}

# Function to verify deployment
verify_deployment() {
    if [ "$DRY_RUN" = "true" ]; then
        print_warning "Dry run mode - skipping verification"
        return
    fi
    
    print_status "Verifying platform components..."
    
    # Check NGINX Ingress Controller
    print_status "Checking NGINX Ingress Controller..."
    kubectl get pods -n ingress-nginx
    
    # Check Cert-Manager
    print_status "Checking Cert-Manager..."
    kubectl get pods -n cert-manager
    kubectl get clusterissuer
    
    # Check External DNS
    print_status "Checking External DNS..."
    kubectl get pods -n external-dns
    
    print_success "Platform components verification completed"
}

# Main execution
main() {
    print_status "Starting MSDP Platform Components Deployment"
    print_status "Environment: $ENVIRONMENT"
    print_status "Component: $COMPONENT"
    print_status "Dry Run: $DRY_RUN"
    print_status "Verbose: $VERBOSE"
    
    # Check prerequisites
    check_prerequisites
    
    # Get AKS credentials
    get_aks_credentials
    
    # Deploy components based on selection
    case $COMPONENT in
        "all")
            deploy_networking
            deploy_monitoring
            ;;
        "networking")
            deploy_networking
            ;;
        "monitoring")
            deploy_monitoring
            ;;
    esac
    
    # Verify deployment
    verify_deployment
    
    print_success "Platform components deployment completed successfully!"
}

# Run main function
main "$@"
