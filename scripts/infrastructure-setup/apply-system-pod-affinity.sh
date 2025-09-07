#!/bin/bash

# Apply System Pod Affinity Configuration
# Ensures all system pods run only on system nodes

set -e

echo "🔧 Applying System Pod Affinity Configuration..."
echo "=============================================="

# Function to apply and wait for rollout
apply_and_wait() {
    local file=$1
    local namespace=$2
    local resource_type=$3
    local resource_name=$4
    
    echo "📝 Applying $file..."
    kubectl apply -f "$file"
    
    if [ -n "$resource_name" ]; then
        echo "⏳ Waiting for $resource_type/$resource_name rollout in namespace $namespace..."
        kubectl rollout status "$resource_type/$resource_name" -n "$namespace" --timeout=300s
        echo "✅ $resource_type/$resource_name is ready"
    fi
}

# Apply ArgoCD system affinity
echo ""
echo "🎯 Configuring ArgoCD System Pod Affinity..."
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "deployment" "argocd-server"
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "statefulset" "argocd-application-controller"
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "deployment" "argocd-applicationset-controller"
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "deployment" "argocd-dex-server"
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "deployment" "argocd-notifications-controller"
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "deployment" "argocd-redis"
apply_and_wait "infrastructure/system-pod-affinity/argocd-system-affinity.yaml" "argocd" "deployment" "argocd-repo-server"

# Apply cert-manager system affinity
echo ""
echo "🔐 Configuring cert-manager System Pod Affinity..."
apply_and_wait "infrastructure/system-pod-affinity/cert-manager-system-affinity.yaml" "cert-manager" "deployment" "cert-manager"
apply_and_wait "infrastructure/system-pod-affinity/cert-manager-system-affinity.yaml" "cert-manager" "deployment" "cert-manager-cainjector"
apply_and_wait "infrastructure/system-pod-affinity/cert-manager-system-affinity.yaml" "cert-manager" "deployment" "cert-manager-webhook"

# Apply NGINX Ingress system affinity
echo ""
echo "🌐 Configuring NGINX Ingress System Pod Affinity..."
apply_and_wait "infrastructure/system-pod-affinity/nginx-ingress-system-affinity.yaml" "ingress-nginx" "deployment" "ingress-nginx-controller"

# Apply Crossplane system affinity
echo ""
echo "☁️  Configuring Crossplane System Pod Affinity..."
apply_and_wait "infrastructure/system-pod-affinity/crossplane-system-affinity.yaml" "crossplane-system" "deployment" "crossplane"
apply_and_wait "infrastructure/system-pod-affinity/crossplane-system-affinity.yaml" "crossplane-system" "deployment" "crossplane-rbac-manager"
apply_and_wait "infrastructure/system-pod-affinity/crossplane-system-affinity.yaml" "crossplane-system" "deployment" "crossplane-contrib-provider-aws-1a98473eeed4"
apply_and_wait "infrastructure/system-pod-affinity/crossplane-system-affinity.yaml" "crossplane-system" "deployment" "upbound-provider-family-azure-8c7042ba2f4e"
apply_and_wait "infrastructure/system-pod-affinity/crossplane-system-affinity.yaml" "crossplane-system" "deployment" "upbound-provider-family-gcp-2718ef31e45f"

echo ""
echo "🎉 System Pod Affinity Configuration Complete!"
echo "=============================================="
echo ""
echo "✅ All system pods are now configured to run only on system nodes"
echo "✅ User workloads will be scheduled on user nodes when available"
echo "✅ System components remain isolated and always available"
echo ""
echo "🔍 Verification:"
echo "kubectl get pods --all-namespaces -o wide | grep -E '(argocd|cert-manager|ingress-nginx|crossplane)'"
echo ""
echo "📊 Node Distribution:"
echo "kubectl get nodes --show-labels | grep 'kubernetes.azure.com/mode'"
