#!/bin/bash
set -euo pipefail

# External DNS Plugin Uninstallation Script
PLUGIN_NAME="external-dns"
NAMESPACE="external-dns-system"

echo "🗑️ Uninstalling plugin: $PLUGIN_NAME"
echo "Environment: $ENVIRONMENT"
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Cluster: $CLUSTER_NAME"

# Uninstall function
uninstall_plugin() {
    echo "📦 Uninstalling External DNS..."
    
    # Check if Helm release exists
    if helm list -n "$NAMESPACE" | grep -q external-dns; then
        echo "Removing Helm release..."
        helm uninstall external-dns --namespace "$NAMESPACE" --timeout 300s
        echo "✅ Helm release removed"
    else
        echo "ℹ️ Helm release not found, skipping..."
    fi
    
    # Clean up any remaining resources
    echo "Cleaning up remaining resources..."
    
    # Remove any finalizers that might prevent deletion
    kubectl patch crd -p '{"metadata":{"finalizers":[]}}' --type=merge \
        $(kubectl get crd -o name | grep external-dns) 2>/dev/null || true
    
    # Remove ClusterRole and ClusterRoleBinding
    kubectl delete clusterrole external-dns --ignore-not-found=true
    kubectl delete clusterrolebinding external-dns --ignore-not-found=true
    
    # Remove namespace if it exists and is empty
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        echo "Checking if namespace can be removed..."
        
        # Check if namespace has any resources left
        resource_count=$(kubectl get all -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
        
        if [[ $resource_count -eq 0 ]]; then
            echo "Removing empty namespace..."
            kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
            echo "✅ Namespace removed"
        else
            echo "⚠️ Namespace contains other resources, keeping it"
            kubectl get all -n "$NAMESPACE"
        fi
    else
        echo "ℹ️ Namespace not found, skipping..."
    fi
    
    echo "✅ External DNS uninstalled successfully"
}

# Verify uninstallation
verify_uninstallation() {
    echo "🔍 Verifying uninstallation..."
    
    # Check if Helm release is gone
    if helm list -n "$NAMESPACE" | grep -q external-dns; then
        echo "⚠️ Helm release still exists"
        return 1
    fi
    
    # Check if pods are gone
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns --no-headers 2>/dev/null | grep -q external-dns; then
        echo "⚠️ Pods still exist"
        return 1
    fi
    
    # Check if ClusterRole is gone
    if kubectl get clusterrole external-dns >/dev/null 2>&1; then
        echo "⚠️ ClusterRole still exists"
        return 1
    fi
    
    echo "✅ Uninstallation verification passed"
    return 0
}

# Main uninstallation flow
main() {
    uninstall_plugin
    
    # Wait a bit for resources to be cleaned up
    sleep 5
    
    verify_uninstallation
    
    echo "🎉 Plugin $PLUGIN_NAME uninstalled successfully!"
    echo ""
    echo "📋 Uninstallation Summary:"
    echo "  Plugin: $PLUGIN_NAME"
    echo "  Namespace: $NAMESPACE (removed if empty)"
    echo "  Cloud Provider: $CLOUD_PROVIDER"
}

# Execute main function
main "$@"