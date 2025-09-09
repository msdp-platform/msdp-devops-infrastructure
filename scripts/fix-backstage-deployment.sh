#!/bin/bash

# Backstage Deployment Fix Script
# This script fixes common Backstage deployment issues while maintaining architectural principles

set -e

echo "🔧 Fixing Backstage Deployment Issues..."
echo "========================================"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Function to check if namespace exists
check_namespace() {
    if kubectl get namespace backstage &> /dev/null; then
        echo "✅ Backstage namespace exists"
        return 0
    else
        echo "❌ Backstage namespace does not exist"
        return 1
    fi
}

# Function to create namespace if it doesn't exist
create_namespace() {
    echo "📦 Creating backstage namespace..."
    kubectl create namespace backstage --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace backstage app.kubernetes.io/name=backstage app.kubernetes.io/part-of=msdp-platform app.kubernetes.io/managed-by=kustomize
}

# Function to create GitHub token secret
create_github_secret() {
    echo "🔐 Creating GitHub token secret..."
    
    # Check if secret already exists
    if kubectl get secret backstage-github-token -n backstage &> /dev/null; then
        echo "✅ GitHub token secret already exists"
    else
        # Create secret with placeholder token
        kubectl create secret generic backstage-github-token \
            --from-literal=token="placeholder-token" \
            --namespace=backstage \
            --dry-run=client -o yaml | kubectl apply -f -
        echo "⚠️  Created placeholder GitHub token secret. Please update with real token."
    fi
}

# Function to check and fix Backstage deployment
fix_backstage_deployment() {
    echo "🚀 Checking Backstage deployment..."
    
    # Check if deployment exists
    if kubectl get deployment backstage -n backstage &> /dev/null; then
        echo "✅ Backstage deployment exists"
        
        # Check pod status
        POD_STATUS=$(kubectl get pods -n backstage -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
        
        if [ "$POD_STATUS" = "Running" ]; then
            echo "✅ Backstage pod is running"
        elif [ "$POD_STATUS" = "Pending" ]; then
            echo "⏳ Backstage pod is pending, checking events..."
            kubectl describe pod -n backstage -l app.kubernetes.io/name=backstage
        elif [ "$POD_STATUS" = "Failed" ] || [ "$POD_STATUS" = "Error" ]; then
            echo "❌ Backstage pod failed, checking logs..."
            kubectl logs -n backstage -l app.kubernetes.io/name=backstage --tail=50
            echo "🔄 Restarting Backstage deployment..."
            kubectl rollout restart deployment/backstage -n backstage
        else
            echo "⚠️  Backstage pod status: $POD_STATUS"
        fi
    else
        echo "❌ Backstage deployment does not exist, creating..."
        kubectl apply -k infrastructure/applications/backstage/
    fi
}

# Function to check resource constraints
check_resources() {
    echo "📊 Checking resource constraints..."
    
    # Check node resources
    kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server not available"
    
    # Check pod resources
    kubectl top pods -n backstage 2>/dev/null || echo "⚠️  No pods found in backstage namespace"
    
    # Check for resource quotas
    kubectl get resourcequota -n backstage 2>/dev/null || echo "ℹ️  No resource quotas found"
}

# Function to check networking
check_networking() {
    echo "🌐 Checking networking..."
    
    # Check if ingress controller is running
    if kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx &> /dev/null; then
        echo "✅ NGINX Ingress Controller is running"
    else
        echo "❌ NGINX Ingress Controller is not running"
    fi
    
    # Check if cert-manager is running
    if kubectl get pods -n cert-manager -l app.kubernetes.io/name=cert-manager &> /dev/null; then
        echo "✅ Cert-Manager is running"
    else
        echo "❌ Cert-Manager is not running"
    fi
}

# Function to provide troubleshooting steps
provide_troubleshooting() {
    echo "🔍 Troubleshooting Steps:"
    echo "========================"
    echo ""
    echo "1. Check pod logs:"
    echo "   kubectl logs -n backstage -l app.kubernetes.io/name=backstage"
    echo ""
    echo "2. Check pod events:"
    echo "   kubectl describe pod -n backstage -l app.kubernetes.io/name=backstage"
    echo ""
    echo "3. Check deployment status:"
    echo "   kubectl get deployment backstage -n backstage -o wide"
    echo ""
    echo "4. Check service status:"
    echo "   kubectl get svc -n backstage"
    echo ""
    echo "5. Check ingress status:"
    echo "   kubectl get ingress -n backstage"
    echo ""
    echo "6. Restart deployment:"
    echo "   kubectl rollout restart deployment/backstage -n backstage"
    echo ""
    echo "7. Check resource usage:"
    echo "   kubectl top pods -n backstage"
    echo ""
}

# Main execution
main() {
    echo "Starting Backstage deployment fix..."
    
    # Create namespace if it doesn't exist
    if ! check_namespace; then
        create_namespace
    fi
    
    # Create GitHub secret
    create_github_secret
    
    # Fix Backstage deployment
    fix_backstage_deployment
    
    # Check resources
    check_resources
    
    # Check networking
    check_networking
    
    # Wait a moment for deployment to stabilize
    echo "⏳ Waiting for deployment to stabilize..."
    sleep 10
    
    # Final status check
    echo "📊 Final Status Check:"
    kubectl get pods -n backstage
    kubectl get svc -n backstage
    kubectl get ingress -n backstage 2>/dev/null || echo "ℹ️  No ingress found"
    
    # Provide troubleshooting steps
    provide_troubleshooting
    
    echo "✅ Backstage deployment fix completed!"
}

# Run main function
main "$@"
