#!/bin/bash
set -euo pipefail

# Cert-Manager Plugin Installation Script
PLUGIN_NAME="cert-manager"
PLUGIN_DIR="$(dirname "$0")"
NAMESPACE="cert-manager"

# Source common functions
source "$PLUGIN_DIR/../../orchestrator/common.sh"

print_plugin_header "$PLUGIN_NAME" "install"

# Validation function
validate_config() {
    log_info "Validating configuration..."
    
    # Check required environment variables
    check_env_var "CLOUD_PROVIDER" || exit 1
    check_env_var "CLUSTER_NAME" || exit 1
    check_env_var "EMAIL" || exit 1
    check_env_var "CLUSTER_ISSUER" || exit 1
    
    # Validate cloud-specific requirements
    if [[ "$CLOUD_PROVIDER" == "aws" ]]; then
        check_env_var "AWS_REGION" || exit 1
        if [[ "${DNS_CHALLENGE:-true}" == "true" ]]; then
            check_env_var "DNS_PROVIDER" || exit 1
        fi
    elif [[ "$CLOUD_PROVIDER" == "azure" ]]; then
        check_env_var "AZURE_SUBSCRIPTION_ID" || exit 1
        if [[ "${DNS_CHALLENGE:-true}" == "true" ]]; then
            check_env_var "DNS_PROVIDER" || exit 1
        fi
    fi
    
    log_success "Configuration validation passed"
}

# Install CRDs first
install_crds() {
    log_info "Installing Cert-Manager CRDs..."
    
    # Install CRDs using kubectl (recommended approach)
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml
    
    log_success "Cert-Manager CRDs installed"
}

# Prepare Helm values
prepare_values() {
    log_info "Preparing Helm values..."
    
    local values_file="$PLUGIN_DIR/values/${CLOUD_PROVIDER}.yaml"
    local temp_values="/tmp/cert-manager-values-${CLUSTER_NAME}.yaml"
    
    if [[ ! -f "$values_file" ]]; then
        log_error "Values file not found: $values_file"
        exit 1
    fi
    
    # Process template variables
    process_template "$values_file" "$temp_values" || exit 1
    
    log_success "Values file prepared: $temp_values"
    export TEMP_VALUES_FILE="$temp_values"
}

# Install the plugin
install_plugin() {
    log_info "Installing Cert-Manager..."
    
    # Add Helm repository
    add_helm_repo "jetstack" "https://charts.jetstack.io" || exit 1
    
    # Create namespace with labels
    ensure_namespace "$NAMESPACE" "app.kubernetes.io/managed-by=plugin-manager app.kubernetes.io/name=cert-manager" || exit 1
    
    # Install with Helm
    helm_install_or_upgrade "cert-manager" "jetstack/cert-manager" "$NAMESPACE" "$TEMP_VALUES_FILE" "v1.13.2" 600 || exit 1
    
    log_success "Cert-Manager installed successfully"
}

# Create cluster issuer
create_cluster_issuer() {
    log_info "Creating cluster issuer..."
    
    local issuer_file="/tmp/cluster-issuer-${CLUSTER_ISSUER}.yaml"
    
    # Generate cluster issuer manifest
    cat > "$issuer_file" << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${CLUSTER_ISSUER}
  labels:
    app.kubernetes.io/managed-by: plugin-manager
    app.kubernetes.io/part-of: cert-manager
spec:
  acme:
    server: $(get_acme_server)
    email: ${EMAIL}
    privateKeySecretRef:
      name: ${CLUSTER_ISSUER}-private-key
    solvers:
$(get_acme_solvers)
EOF

    # Apply the cluster issuer
    kubectl apply -f "$issuer_file"
    
    log_success "Cluster issuer ${CLUSTER_ISSUER} created"
}

# Get ACME server URL
get_acme_server() {
    if [[ "$CLUSTER_ISSUER" == "letsencrypt-prod" ]]; then
        echo "https://acme-staging-v02.api.letsencrypt.org/directory"
    else
        echo "https://acme-v02.api.letsencrypt.org/directory"
    fi
}

# Get ACME solvers configuration
get_acme_solvers() {
    if [[ "${DNS_CHALLENGE:-true}" == "true" ]]; then
        case "$DNS_PROVIDER" in
            "route53")
                cat << EOF
    - dns01:
        route53:
          region: ${AWS_REGION}
EOF
                ;;
            "azuredns")
                cat << EOF
    - dns01:
        azureDNS:
          subscriptionID: ${AZURE_SUBSCRIPTION_ID}
          resourceGroupName: ${AZURE_RESOURCE_GROUP}
          hostedZoneName: ${AZURE_HOSTED_ZONE_NAME}
          environment: AzurePublicCloud
EOF
                ;;
            *)
                log_error "Unsupported DNS provider: $DNS_PROVIDER"
                exit 1
                ;;
        esac
    else
        # HTTP-01 challenge
        cat << EOF
    - http01:
        ingress:
          class: nginx
EOF
    fi
}

# Perform health check
health_check() {
    log_info "Performing health check..."
    
    # Wait for deployments to be ready
    local deployments=("cert-manager" "cert-manager-cainjector" "cert-manager-webhook")
    
    for deployment in "${deployments[@]}"; do
        wait_for_deployment "$deployment" "$NAMESPACE" 300 || exit 1
    done
    
    # Check if cluster issuer is ready
    log_info "Checking cluster issuer status..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if kubectl get clusterissuer "$CLUSTER_ISSUER" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
            log_success "Cluster issuer ${CLUSTER_ISSUER} is ready"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "Cluster issuer ${CLUSTER_ISSUER} not ready after ${max_attempts} attempts"
            kubectl describe clusterissuer "$CLUSTER_ISSUER"
            exit 1
        fi
        
        log_info "Waiting for cluster issuer to be ready (attempt $attempt/$max_attempts)..."
        sleep 10
        ((attempt++))
    done
    
    log_success "Health check completed"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check CRDs
    log_info "Checking CRDs..."
    local crds=("certificates.cert-manager.io" "certificaterequests.cert-manager.io" "issuers.cert-manager.io" "clusterissuers.cert-manager.io")
    
    for crd in "${crds[@]}"; do
        if kubectl get crd "$crd" >/dev/null 2>&1; then
            log_success "CRD $crd exists"
        else
            log_error "CRD $crd not found"
            exit 1
        fi
    done
    
    # List all resources in the namespace
    log_info "Resources in namespace $NAMESPACE:"
    kubectl get all -n "$NAMESPACE"
    
    # Check cluster issuer
    log_info "Cluster issuers:"
    kubectl get clusterissuers
    
    log_success "Installation verification completed"
}

# Test certificate creation
test_certificate() {
    log_info "Testing certificate creation..."
    
    local test_cert_file="/tmp/test-certificate.yaml"
    
    cat > "$test_cert_file" << EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-certificate
  namespace: default
  labels:
    app.kubernetes.io/managed-by: plugin-manager
    app.kubernetes.io/part-of: cert-manager-test
spec:
  secretName: test-certificate-tls
  issuerRef:
    name: ${CLUSTER_ISSUER}
    kind: ClusterIssuer
  dnsNames:
  - test.${DOMAIN_FILTERS:-example.com}
EOF

    # Create test certificate
    kubectl apply -f "$test_cert_file"
    
    # Wait a bit and check status
    sleep 10
    
    local cert_status
    cert_status=$(kubectl get certificate test-certificate -n default -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    
    if [[ "$cert_status" == "True" ]]; then
        log_success "Test certificate created successfully"
    else
        log_warning "Test certificate not ready yet (this is normal for DNS challenges)"
        kubectl describe certificate test-certificate -n default
    fi
    
    # Clean up test certificate
    kubectl delete -f "$test_cert_file" --ignore-not-found=true
    
    log_success "Certificate test completed"
}

# Main installation flow
main() {
    # Set trap for cleanup on failure
    trap 'cleanup_failed_installation "$PLUGIN_NAME" "$NAMESPACE"' ERR
    
    validate_config
    install_crds
    prepare_values
    install_plugin
    health_check
    create_cluster_issuer
    verify_installation
    
    # Only run certificate test if we have domain filters
    if [[ -n "${DOMAIN_FILTERS:-}" ]]; then
        test_certificate
    fi
    
    log_success "Plugin $PLUGIN_NAME installed successfully!"
    echo ""
    echo "📋 Installation Summary:"
    echo "  Namespace: $NAMESPACE"
    echo "  Cloud Provider: $CLOUD_PROVIDER"
    echo "  Cluster Issuer: $CLUSTER_ISSUER"
    echo "  Email: $EMAIL"
    echo "  DNS Challenge: ${DNS_CHALLENGE:-true}"
    echo ""
    echo "🔍 To check status:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get clusterissuers"
    echo "  kubectl describe clusterissuer $CLUSTER_ISSUER"
}

# Execute main function
main "$@"