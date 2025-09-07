#!/bin/bash

# Deploy Multi-Environment ArgoCD Setup
echo "🚀 Deploying Multi-Environment ArgoCD Setup..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured or cluster is not accessible"
    exit 1
fi

echo "✅ kubectl is configured and cluster is accessible"

# Deploy ArgoCD instances
echo "📦 Deploying ArgoCD instances..."

# Deploy Dev ArgoCD
echo "🔧 Deploying ArgoCD Dev Environment..."
kubectl apply -f infrastructure/argocd/dev/argocd-dev-install.yaml

# Deploy Test ArgoCD
echo "🧪 Deploying ArgoCD Test Environment..."
kubectl apply -f infrastructure/argocd/test/argocd-test-install.yaml

# Deploy Prod ArgoCD
echo "🏭 Deploying ArgoCD Production Environment..."
kubectl apply -f infrastructure/argocd/prod/argocd-prod-install.yaml

echo "⏳ Waiting for ArgoCD instances to be ready..."

# Wait for ArgoCD instances to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd-dev
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd-test
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd-prod

echo "✅ ArgoCD instances are ready!"

# Deploy MSDP applications
echo "📱 Deploying MSDP applications..."

# Deploy Dev Applications
echo "🔧 Deploying Dev Applications..."
kubectl apply -f infrastructure/argocd/dev/msdp-dev-applications.yaml

# Deploy Test Applications
echo "🧪 Deploying Test Applications..."
kubectl apply -f infrastructure/argocd/test/msdp-test-applications.yaml

# Deploy Prod Applications
echo "🏭 Deploying Production Applications..."
kubectl apply -f infrastructure/argocd/prod/msdp-prod-applications.yaml

echo "🎉 Multi-Environment ArgoCD Setup Complete!"

# Display access information
echo ""
echo "📋 ArgoCD Access Information:"
echo "================================"
echo "🔧 Development:  https://argocd-dev.aztech-msdp.com"
echo "🧪 Test:         https://argocd-test.aztech-msdp.com"
echo "🏭 Production:   https://argocd.aztech-msdp.com"
echo ""
echo "🔑 Default Admin Password:"
echo "   Dev:  admin123"
echo "   Test: admin123"
echo "   Prod: admin123"
echo ""
echo "📊 Check Status:"
echo "   kubectl get applications -n argocd-dev"
echo "   kubectl get applications -n argocd-test"
echo "   kubectl get applications -n argocd-prod"
echo ""
echo "🔗 Organization: https://github.com/msdp-platform"
echo "📚 Documentation: See infrastructure/argocd/README.md"
