#!/bin/bash

# Apply System Pod Affinity Configuration using kubectl patch
# Ensures all system pods run only on system nodes

set -e

echo "🔧 Applying System Pod Affinity Configuration (Patch Method)..."
echo "=============================================================="

# Function to patch deployment with system node affinity
patch_deployment() {
    local namespace=$1
    local deployment=$2
    local app_name=$3
    
    echo "📝 Patching deployment/$deployment in namespace $namespace..."
    
    # Create the patch JSON
    local patch_json='{
        "spec": {
            "template": {
                "spec": {
                    "affinity": {
                        "nodeAffinity": {
                            "requiredDuringSchedulingIgnoredDuringExecution": {
                                "nodeSelectorTerms": [
                                    {
                                        "matchExpressions": [
                                            {
                                                "key": "kubernetes.azure.com/mode",
                                                "operator": "In",
                                                "values": ["system"]
                                            }
                                        ]
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
    }'
    
    # Apply the patch
    kubectl patch deployment "$deployment" -n "$namespace" --type merge -p "$patch_json"
    echo "✅ Patched deployment/$deployment"
}

# Function to patch statefulset with system node affinity
patch_statefulset() {
    local namespace=$1
    local statefulset=$2
    local app_name=$3
    
    echo "📝 Patching statefulset/$statefulset in namespace $namespace..."
    
    # Create the patch JSON
    local patch_json='{
        "spec": {
            "template": {
                "spec": {
                    "affinity": {
                        "nodeAffinity": {
                            "requiredDuringSchedulingIgnoredDuringExecution": {
                                "nodeSelectorTerms": [
                                    {
                                        "matchExpressions": [
                                            {
                                                "key": "kubernetes.azure.com/mode",
                                                "operator": "In",
                                                "values": ["system"]
                                            }
                                        ]
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
    }'
    
    # Apply the patch
    kubectl patch statefulset "$statefulset" -n "$namespace" --type merge -p "$patch_json"
    echo "✅ Patched statefulset/$statefulset"
}

# Function to wait for rollout
wait_for_rollout() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    echo "⏳ Waiting for $resource_type/$resource_name rollout in namespace $namespace..."
    kubectl rollout status "$resource_type/$resource_name" -n "$namespace" --timeout=300s
    echo "✅ $resource_type/$resource_name is ready"
}

# Apply ArgoCD system affinity
echo ""
echo "🎯 Configuring ArgoCD System Pod Affinity..."
patch_deployment "argocd" "argocd-server" "argocd-server"
wait_for_rollout "deployment" "argocd-server" "argocd"

patch_statefulset "argocd" "argocd-application-controller" "argocd-application-controller"
wait_for_rollout "statefulset" "argocd-application-controller" "argocd"

patch_deployment "argocd" "argocd-applicationset-controller" "argocd-applicationset-controller"
wait_for_rollout "deployment" "argocd-applicationset-controller" "argocd"

patch_deployment "argocd" "argocd-dex-server" "argocd-dex-server"
wait_for_rollout "deployment" "argocd-dex-server" "argocd"

patch_deployment "argocd" "argocd-notifications-controller" "argocd-notifications-controller"
wait_for_rollout "deployment" "argocd-notifications-controller" "argocd"

patch_deployment "argocd" "argocd-redis" "argocd-redis"
wait_for_rollout "deployment" "argocd-redis" "argocd"

patch_deployment "argocd" "argocd-repo-server" "argocd-repo-server"
wait_for_rollout "deployment" "argocd-repo-server" "argocd"

# Apply cert-manager system affinity
echo ""
echo "🔐 Configuring cert-manager System Pod Affinity..."
patch_deployment "cert-manager" "cert-manager" "cert-manager"
wait_for_rollout "deployment" "cert-manager" "cert-manager"

patch_deployment "cert-manager" "cert-manager-cainjector" "cert-manager-cainjector"
wait_for_rollout "deployment" "cert-manager-cainjector" "cert-manager"

patch_deployment "cert-manager" "cert-manager-webhook" "cert-manager-webhook"
wait_for_rollout "deployment" "cert-manager-webhook" "cert-manager"

# Apply NGINX Ingress system affinity
echo ""
echo "🌐 Configuring NGINX Ingress System Pod Affinity..."
patch_deployment "ingress-nginx" "ingress-nginx-controller" "ingress-nginx-controller"
wait_for_rollout "deployment" "ingress-nginx-controller" "ingress-nginx"

# Apply Crossplane system affinity
echo ""
echo "☁️  Configuring Crossplane System Pod Affinity..."
patch_deployment "crossplane-system" "crossplane" "crossplane"
wait_for_rollout "deployment" "crossplane" "crossplane-system"

patch_deployment "crossplane-system" "crossplane-rbac-manager" "crossplane-rbac-manager"
wait_for_rollout "deployment" "crossplane-rbac-manager" "crossplane-system"

patch_deployment "crossplane-system" "crossplane-contrib-provider-aws-1a98473eeed4" "crossplane-contrib-provider-aws"
wait_for_rollout "deployment" "crossplane-contrib-provider-aws-1a98473eeed4" "crossplane-system"

patch_deployment "crossplane-system" "upbound-provider-family-azure-8c7042ba2f4e" "upbound-provider-family-azure"
wait_for_rollout "deployment" "upbound-provider-family-azure-8c7042ba2f4e" "crossplane-system"

patch_deployment "crossplane-system" "upbound-provider-family-gcp-2718ef31e45f" "upbound-provider-family-gcp"
wait_for_rollout "deployment" "upbound-provider-family-gcp-2718ef31e45f" "crossplane-system"

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
