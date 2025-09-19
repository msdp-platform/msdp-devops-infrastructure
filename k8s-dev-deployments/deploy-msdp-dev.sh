#!/bin/bash

# MSDP Development Deployment Script
# Deploy your Docker containers to AKS for individual development

set -e

echo "🚀 MSDP Development Deployment Script"
echo "======================================"

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig"
    exit 1
fi

print_status "Connected to cluster: $(kubectl config current-context)"

# Function to deploy services
deploy_services() {
    print_status "Deploying MSDP services to msdp-dev namespace..."
    
    if kubectl apply -f msdp-dev-services.yaml; then
        print_success "Services deployed successfully!"
    else
        print_error "Failed to deploy services"
        exit 1
    fi
}

# Function to check service status
check_status() {
    print_status "Checking service status..."
    echo ""
    
    print_status "Namespace status:"
    kubectl get namespace msdp-dev
    echo ""
    
    print_status "Pod status:"
    kubectl get pods -n msdp-dev
    echo ""
    
    print_status "Service status:"
    kubectl get services -n msdp-dev
    echo ""
    
    print_status "Ingress status:"
    kubectl get ingress -n msdp-dev
}

# Function to get service logs
get_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service name"
        print_status "Available services:"
        kubectl get pods -n msdp-dev --no-headers | awk '{print $1}' | sed 's/-.*//' | sort -u
        return 1
    fi
    
    print_status "Getting logs for $service..."
    kubectl logs -n msdp-dev -l app=msdp-$service --tail=50 -f
}

# Function to port-forward to a service
port_forward() {
    local service=$1
    local port=$2
    
    if [ -z "$service" ] || [ -z "$port" ]; then
        print_error "Usage: port_forward <service> <port>"
        print_status "Examples:"
        print_status "  port_forward api-gateway 3000"
        print_status "  port_forward location-service 3001"
        return 1
    fi
    
    print_status "Port forwarding $service to localhost:$port..."
    kubectl port-forward -n msdp-dev svc/msdp-$service $port:$port
}

# Function to update a specific service
update_service() {
    local service=$1
    local image=$2
    
    if [ -z "$service" ] || [ -z "$image" ]; then
        print_error "Usage: update_service <service> <image>"
        print_status "Example: update_service api-gateway your-registry/msdp-api-gateway:v1.2.3"
        return 1
    fi
    
    print_status "Updating $service with image $image..."
    kubectl set image deployment/msdp-$service -n msdp-dev $service=$image
    
    print_status "Waiting for rollout to complete..."
    kubectl rollout status deployment/msdp-$service -n msdp-dev
    
    print_success "Service $service updated successfully!"
}

# Function to scale a service
scale_service() {
    local service=$1
    local replicas=$2
    
    if [ -z "$service" ] || [ -z "$replicas" ]; then
        print_error "Usage: scale_service <service> <replicas>"
        print_status "Example: scale_service api-gateway 2"
        return 1
    fi
    
    print_status "Scaling $service to $replicas replicas..."
    kubectl scale deployment msdp-$service -n msdp-dev --replicas=$replicas
    
    print_success "Service $service scaled to $replicas replicas!"
}

# Function to delete all services
cleanup() {
    print_warning "This will delete all MSDP services from the msdp-dev namespace!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up MSDP services..."
        kubectl delete -f msdp-dev-services.yaml || true
        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to show help
show_help() {
    echo "MSDP Development Deployment Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  deploy              Deploy all MSDP services"
    echo "  status              Check status of all services"
    echo "  logs <service>      Get logs for a specific service"
    echo "  port-forward <service> <port>  Port forward to a service"
    echo "  update <service> <image>       Update a service with new image"
    echo "  scale <service> <replicas>     Scale a service"
    echo "  cleanup             Delete all services"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 status"
    echo "  $0 logs api-gateway"
    echo "  $0 port-forward api-gateway 3000"
    echo "  $0 update api-gateway your-registry/msdp-api-gateway:latest"
    echo "  $0 scale api-gateway 2"
    echo ""
    echo "Services:"
    echo "  - api-gateway (port 3000)"
    echo "  - location-service (port 3001)"
    echo "  - merchant-service (port 3002)"
    echo "  - user-service (port 3003)"
    echo "  - order-service (port 3006)"
    echo "  - payment-service (port 3007)"
}

# Main script logic
case "${1:-help}" in
    deploy)
        deploy_services
        echo ""
        check_status
        ;;
    status)
        check_status
        ;;
    logs)
        get_logs "$2"
        ;;
    port-forward)
        port_forward "$2" "$3"
        ;;
    update)
        update_service "$2" "$3"
        ;;
    scale)
        scale_service "$2" "$3"
        ;;
    cleanup)
        cleanup
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
