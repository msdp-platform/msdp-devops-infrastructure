#!/bin/bash

# Laptop Cleanup Script
# This script cleans up local resources after migrating to AKS

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
    echo "  minikube    - Stop and delete Minikube cluster"
    echo "  docker      - Clean up Docker resources"
    echo "  kubectl     - Clean up local kubectl contexts"
    echo "  files       - Clean up local files and binaries"
    echo "  all         - Clean up everything"
    echo "  help        - Show this help message"
}

# Function to clean up Minikube
cleanup_minikube() {
    echo -e "${YELLOW}🛑 Stopping and deleting Minikube cluster${NC}"
    
    # Check if Minikube is running
    if minikube status >/dev/null 2>&1; then
        echo "Stopping Minikube..."
        minikube stop
        echo "Deleting Minikube cluster..."
        minikube delete
        echo -e "${GREEN}✅ Minikube cluster deleted${NC}"
    else
        echo -e "${BLUE}ℹ️  Minikube is not running${NC}"
    fi
    
    # Remove Minikube binary
    if command -v minikube >/dev/null 2>&1; then
        echo "Removing Minikube binary..."
        sudo rm -f /usr/local/bin/minikube
        echo -e "${GREEN}✅ Minikube binary removed${NC}"
    fi
}

# Function to clean up Docker
cleanup_docker() {
    echo -e "${YELLOW}🐳 Cleaning up Docker resources${NC}"
    
    # Stop all containers
    echo "Stopping all containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    # Remove all containers
    echo "Removing all containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    # Remove all images
    echo "Removing all images..."
    docker rmi $(docker images -q) 2>/dev/null || true
    
    # Remove all volumes
    echo "Removing all volumes..."
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    
    # Remove all networks
    echo "Removing all networks..."
    docker network rm $(docker network ls -q) 2>/dev/null || true
    
    # Prune system
    echo "Pruning Docker system..."
    docker system prune -af --volumes
    
    echo -e "${GREEN}✅ Docker resources cleaned up${NC}"
}

# Function to clean up kubectl contexts
cleanup_kubectl() {
    echo -e "${YELLOW}⚙️  Cleaning up kubectl contexts${NC}"
    
    # Remove Minikube context
    if kubectl config get-contexts | grep -q minikube; then
        echo "Removing Minikube context..."
        kubectl config delete-context minikube
        echo -e "${GREEN}✅ Minikube context removed${NC}"
    fi
    
    # Show remaining contexts
    echo -e "\n${BLUE}Remaining kubectl contexts:${NC}"
    kubectl config get-contexts
}

# Function to clean up local files
cleanup_files() {
    echo -e "${YELLOW}📁 Cleaning up local files and binaries${NC}"
    
    # Remove Crossplane CLI
    if [ -f /usr/local/bin/crossplane ]; then
        echo "Removing Crossplane CLI..."
        sudo rm -f /usr/local/bin/crossplane
        echo -e "${GREEN}✅ Crossplane CLI removed${NC}"
    fi
    
    # Remove ArgoCD CLI
    if [ -f /usr/local/bin/argocd ]; then
        echo "Removing ArgoCD CLI..."
        sudo rm -f /usr/local/bin/argocd
        echo -e "${GREEN}✅ ArgoCD CLI removed${NC}"
    fi
    
    # Remove local kubeconfig backup
    if [ -f ~/.kube/config.backup ]; then
        echo "Removing kubeconfig backup..."
        rm -f ~/.kube/config.backup
        echo -e "${GREEN}✅ Kubeconfig backup removed${NC}"
    fi
    
    # Clean up temporary files
    echo "Cleaning up temporary files..."
    rm -rf /tmp/crossplane* 2>/dev/null || true
    rm -rf /tmp/argocd* 2>/dev/null || true
    
    echo -e "${GREEN}✅ Local files cleaned up${NC}"
}

# Function to clean up everything
cleanup_all() {
    echo -e "${RED}🧹 Starting complete laptop cleanup${NC}"
    echo "This will remove all local Kubernetes and Docker resources"
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Cleanup cancelled${NC}"
        exit 1
    fi
    
    cleanup_minikube
    cleanup_docker
    cleanup_kubectl
    cleanup_files
    
    echo -e "\n${GREEN}🎉 Laptop cleanup completed!${NC}"
    echo -e "${BLUE}Your laptop is now clean and ready for AKS-only development${NC}"
}

# Main script logic
case "${1:-help}" in
    minikube)
        cleanup_minikube
        ;;
    docker)
        cleanup_docker
        ;;
    kubectl)
        cleanup_kubectl
        ;;
    files)
        cleanup_files
        ;;
    all)
        cleanup_all
        ;;
    help|*)
        usage
        ;;
esac
