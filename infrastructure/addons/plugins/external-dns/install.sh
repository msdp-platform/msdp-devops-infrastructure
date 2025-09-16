#!/bin/bash
set -euo pipefail

# External DNS Plugin Installation Script
PLUGIN_NAME="external-dns"
PLUGIN_DIR="$(dirname "$0")"
NAMESPACE="external-dns-system"

echo "🚀 Installing plugin: $PLUGIN_NAME"
echo "Environment: $ENVIRONMENT"
echo "Cloud Provider: $CLOUD_PROVIDER"
echo "Cluster: $CLUSTER_NAME"

# Source common functions
if [[ -f "$PLUGIN_DIR/../../orchestrator/common.sh" ]]; then
    source "$PLUGIN_DIR/../../orchestrator/common.sh"
fi

# Validation function
validate_config() {
    echo "📋 Validating configuration..."
    
    # Check required environment variables
    check_env_var "CLOUD_PROVIDER" "Cloud provider must be specified"
    check_env_var "CLUSTER_NAME" "Cluster name must be specified"
    check_env_var "DOMAIN_FILTERS" "Domain filters must be specified"
    check_env_var "TXT_OWNER_ID" "TXT owner ID must be specified"
    
    # Validate cloud-specific requirements
    if [[ "$CLOUD_PROVIDER" == "aws" ]]; then
        check_env_var "AWS_REGION" "AWS region must be specified"
        echo "✅ AWS configuration validated"
    elif [[ "$CLOUD_PROVIDER" == "azure" ]]; then
        check_env_var "AZURE_SUBSCRIPTION_ID" "Azure subscription ID must be specified"
        check_env_var "AZURE_RESOURCE_GROUP" "Azure resource group must be specified"
        echo "✅ Azure configuration validated"
    else
        echo "❌ Unsupported cloud provider: $CLOUD_PROVIDER"
        exit 1
    fi
    
    echo "✅ Configuration validation passed"
}

# Check environment variable helper
check_env_var() {
    local var_name="$1"
    local error_msg="${2:-$var_name is required}"
    
    if [[ -z "${!var_name:-}" ]]; then
        echo "❌ $error_msg"
        exit 1
    fi
}

# Prepare Helm values
prepare_values() {
    echo "📦 Preparing Helm values..."
    
    # Select the appropriate values file based on cloud provider
    local values_file="$PLUGIN_DIR/values/${CLOUD_PROVIDER}.yaml"
    local temp_values="/tmp/external-dns-values-${CLUSTER_NAME}.yaml"
    
    if [[ ! -f "$values_file" ]]; then
        echo "❌ Values file not found: $values_file"
        exit 1
    fi
    
    # Process template variables
    envsubst < "$values_file" > "$temp_values"
    
    echo "✅ Values file prepared: $temp_values"
    echo "Values content:"
    cat "$temp_values"
    
    export TEMP_VALUES_FILE="$temp_values"
}

# Install the plugin
install_plugin() {
    echo "📦 Installing External DNS..."
    
    # Add Helm repository
    echo "Adding Helm repository..."
    helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
    helm repo update
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace for management
    kubectl label namespace "$NAMESPACE" app.kubernetes.io/managed-by=plugin-manager --overwrite
    kubectl label namespace "$NAMESPACE" app.kubernetes.io/name=external-dns --overwrite
    
    # Install with Helm
    echo "Installing External DNS with Helm..."
    helm upgrade --install external-dns external-dns/external-dns \
        --namespace "$NAMESPACE" \
        --values "$TEMP_VALUES_FILE" \
        --version "${PLUGIN_VERSION:-1.13.1}" \
        --timeout 300s \
        --wait \
        --atomic
    
    echo "✅ External DNS installed successfully"
}

# Perform health check
health_check() {
    echo "🔍 Performing health check..."
    
    # Wait for deployment to be ready
    echo "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available deployment/external-dns \
        --namespace "$NAMESPACE" \
        --timeout=300s
    
    # Check if pods are running
    echo "Checking pod status..."
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns
    
    # Verify the service is responding
    echo "Checking service health..."
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -n "$pod_name" ]]; then
        # Check if the health endpoint is responding
        if kubectl exec -n "$NAMESPACE" "$pod_name" -- wget -q --spider http://localhost:7979/healthz; then
            echo "✅ Health endpoint is responding"
        else
            echo "⚠️ Health endpoint not responding, but pod is running"
        fi
        
        # Check logs for any errors
        echo "Recent logs:"
        kubectl logs -n "$NAMESPACE" "$pod_name" --tail=10
    fi
    
    echo "✅ Health check completed"
}

# Verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    
    # Check if CRDs are installed (if any)
    echo "Checking resources..."
    
    # List all resources in the namespace
    kubectl get all -n "$NAMESPACE"
    
    # Check service account and RBAC
    kubectl get serviceaccount -n "$NAMESPACE"
    kubectl get clusterrole -l app.kubernetes.io/name=external-dns
    kubectl get clusterrolebinding -l app.kubernetes.io/name=external-dns
    
    echo "✅ Installation verification completed"
}

# Cleanup function for failed installations
cleanup_on_failure() {
    echo "🧹 Cleaning up failed installation..."
    
    # Remove Helm release
    helm uninstall external-dns --namespace "$NAMESPACE" 2>/dev/null || true
    
    # Remove namespace if empty
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    
    echo "✅ Cleanup completed"
}

# Main installation flow
main() {
    # Set trap for cleanup on failure
    trap cleanup_on_failure ERR
    
    validate_config
    prepare_values
    install_plugin
    health_check
    verify_installation
    
    echo "🎉 Plugin $PLUGIN_NAME installed successfully!"
    echo ""
    echo "📋 Installation Summary:"
    echo "  Namespace: $NAMESPACE"
    echo "  Cloud Provider: $CLOUD_PROVIDER"
    echo "  Domain Filters: $DOMAIN_FILTERS"
    echo "  TXT Owner ID: $TXT_OWNER_ID"
    echo ""
    echo "🔍 To check status:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=external-dns"
}

# Execute main function
main "$@"