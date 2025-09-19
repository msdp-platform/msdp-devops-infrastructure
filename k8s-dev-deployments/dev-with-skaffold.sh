#!/bin/bash

# MSDP Skaffold Development Script
# Fast development workflow without rebuilding Docker images every time

set -e

echo "🚀 MSDP Skaffold Development Environment"
echo "======================================="

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

# Check if skaffold is installed
if ! command -v skaffold &> /dev/null; then
    print_error "Skaffold is not installed. Please install it first:"
    echo "  brew install skaffold"
    exit 1
fi

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

# Function to start development mode
start_dev() {
    local profile=${1:-dev}
    
    print_status "Starting Skaffold development mode with profile: $profile"
    print_status "This will:"
    echo "  ✅ Build and deploy your services automatically"
    echo "  ✅ Watch for file changes and sync them instantly"
    echo "  ✅ Set up port forwarding for all services"
    echo "  ✅ Stream logs from all services"
    echo ""
    print_warning "Press Ctrl+C to stop development mode"
    echo ""
    
    # Start skaffold dev with the specified profile
    skaffold dev --profile="$profile" --port-forward --cleanup=false
}

# Function to run once (build and deploy without watching)
run_once() {
    local profile=${1:-dev}
    
    print_status "Running Skaffold once with profile: $profile"
    print_status "This will build and deploy your services without file watching"
    
    skaffold run --profile="$profile"
    
    print_success "Deployment completed!"
    print_status "Services are running in the msdp-dev namespace"
    print_status "Use 'kubectl get pods -n msdp-dev' to check status"
}

# Function to debug mode
debug_mode() {
    print_status "Starting Skaffold in debug mode"
    print_status "This enables debug logging and development optimizations"
    
    skaffold dev --profile=debug --port-forward --verbosity=debug
}

# Function to delete deployed resources
cleanup() {
    print_warning "This will delete all resources deployed by Skaffold"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up Skaffold resources..."
        skaffold delete
        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to build images only
build_only() {
    local profile=${1:-dev}
    
    print_status "Building images with Skaffold (profile: $profile)"
    
    skaffold build --profile="$profile"
    
    print_success "Build completed!"
}

# Function to render manifests
render_manifests() {
    local profile=${1:-dev}
    
    print_status "Rendering Kubernetes manifests with Skaffold (profile: $profile)"
    
    skaffold render --profile="$profile"
}

# Function to check configuration
check_config() {
    print_status "Validating Skaffold configuration..."
    
    if skaffold diagnose; then
        print_success "Skaffold configuration is valid!"
    else
        print_error "Skaffold configuration has issues"
        exit 1
    fi
}

# Function to show service status
show_status() {
    print_status "MSDP Services Status:"
    echo ""
    
    print_status "Pods:"
    kubectl get pods -n msdp-dev
    echo ""
    
    print_status "Services:"
    kubectl get services -n msdp-dev
    echo ""
    
    print_status "Port Forwards (if running):"
    echo "  API Gateway:      http://localhost:3000"
    echo "  Location Service: http://localhost:3001"
    echo "  Merchant Service: http://localhost:3002"
    echo "  User Service:     http://localhost:3003"
    echo "  Order Service:    http://localhost:3006"
    echo "  Payment Service:  http://localhost:3007"
}

# Function to show logs
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        print_status "Showing logs for all MSDP services..."
        kubectl logs -n msdp-dev -l app.kubernetes.io/part-of=msdp --tail=50 -f
    else
        print_status "Showing logs for $service..."
        kubectl logs -n msdp-dev -l app=msdp-$service --tail=50 -f
    fi
}

# Function to show help
show_help() {
    echo "MSDP Skaffold Development Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  dev [profile]       Start development mode with file watching (default: dev)"
    echo "  run [profile]       Build and deploy once without watching (default: dev)"
    echo "  debug               Start in debug mode with verbose logging"
    echo "  build [profile]     Build images only (default: dev)"
    echo "  render [profile]    Render Kubernetes manifests (default: dev)"
    echo "  cleanup             Delete all deployed resources"
    echo "  status              Show service status and access URLs"
    echo "  logs [service]      Show logs (all services or specific service)"
    echo "  check               Validate Skaffold configuration"
    echo "  help                Show this help message"
    echo ""
    echo "Profiles:"
    echo "  dev                 Development profile (default)"
    echo "  debug               Debug profile with extra logging"
    echo ""
    echo "Examples:"
    echo "  $0 dev              # Start development mode"
    echo "  $0 run              # Deploy once"
    echo "  $0 debug            # Start in debug mode"
    echo "  $0 logs api-gateway # Show API Gateway logs"
    echo "  $0 status           # Check service status"
    echo ""
    echo "Development Workflow:"
    echo "  1. Run '$0 dev' to start development mode"
    echo "  2. Edit your code - changes will sync automatically"
    echo "  3. Access services at http://localhost:300X"
    echo "  4. Press Ctrl+C to stop"
    echo ""
    echo "🚀 Fast Development Features:"
    echo "  ✅ No Docker build/push cycle for code changes"
    echo "  ✅ Automatic file sync to running containers"
    echo "  ✅ Instant port forwarding to all services"
    echo "  ✅ Real-time log streaming"
    echo "  ✅ Hot reload for Node.js applications"
}

# Main script logic
case "${1:-help}" in
    dev)
        start_dev "$2"
        ;;
    run)
        run_once "$2"
        ;;
    debug)
        debug_mode
        ;;
    build)
        build_only "$2"
        ;;
    render)
        render_manifests "$2"
        ;;
    cleanup)
        cleanup
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    check)
        check_config
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
