#!/bin/bash
set -euo pipefail

# NGINX Ingress Controller Plugin Installation Script
PLUGIN_NAME="nginx-ingress"
PLUGIN_DIR="$(dirname "$0")"
NAMESPACE="nginx-ingress"

# Source common functions
source "$PLUGIN_DIR/../../orchestrator/common.sh"

print_plugin_header "$PLUGIN_NAME" "install"

# Validation function
validate_config() {
    log_info "Validating configuration..."
    
    # Check required environment variables
    check_env_var "CLOUD_PROVIDER" || exit 1
    check_env_var "CLUSTER_NAME" || exit 1
    
    # Validate cloud-specific requirements
    if [[ "$CLOUD_PROVIDER" == "aws" ]]; then
        check_env_var "AWS_REGION" || exit 1
    elif [[ "$CLOUD_PROVIDER" == "azure" ]]; then
        check_env_var "AZURE_SUBSCRIPTION_ID" || exit 1
    fi
    
    log_success "Configuration validation passed"
}

# Prepare Helm values
prepare_values() {
    log_info "Preparing Helm values..."
    
    local values_file="$PLUGIN_DIR/values/${CLOUD_PROVIDER}.yaml"
    local temp_values="/tmp/nginx-ingress-values-${CLUSTER_NAME}.yaml"
    
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
    log_info "Installing NGINX Ingress Controller..."
    
    # Add Helm repository
    add_helm_repo "ingress-nginx" "https://kubernetes.github.io/ingress-nginx" || exit 1
    
    # Create namespace with labels
    ensure_namespace "$NAMESPACE" "app.kubernetes.io/managed-by=plugin-manager app.kubernetes.io/name=nginx-ingress" || exit 1
    
    # Install with Helm
    helm_install_or_upgrade "ingress-nginx" "ingress-nginx/ingress-nginx" "$NAMESPACE" "$TEMP_VALUES_FILE" "4.8.3" 600 || exit 1
    
    log_success "NGINX Ingress Controller installed successfully"
}

# Perform health check
health_check() {
    log_info "Performing health check..."
    
    # Wait for deployment to be ready
    wait_for_deployment "ingress-nginx-controller" "$NAMESPACE" 300 || exit 1
    
    # Check if service is ready
    log_info "Checking service status..."
    kubectl get service -n "$NAMESPACE" ingress-nginx-controller
    
    # Get external IP/hostname
    local external_endpoint
    external_endpoint=$(kubectl get service -n "$NAMESPACE" ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    
    if [[ "$external_endpoint" != "pending" && -n "$external_endpoint" ]]; then
        log_success "External endpoint available: $external_endpoint"
    else
        log_warning "External endpoint still pending (this is normal for new deployments)"
    fi
    
    # Check controller health endpoint
    log_info "Checking controller health endpoint..."
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$pod_name" ]]; then
        if kubectl exec -n "$NAMESPACE" "$pod_name" -- wget -q --spider --timeout=10 http://localhost:10254/healthz 2>/dev/null; then
            log_success "Controller health endpoint is responding"
        else
            log_warning "Controller health endpoint not responding (this might be normal during startup)"
        fi
    fi
    
    log_success "Health check completed"
}

# Create test ingress
create_test_ingress() {
    log_info "Creating test ingress..."
    
    local test_ingress_file="/tmp/test-ingress.yaml"
    
    cat > "$test_ingress_file" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: default
  labels:
    app.kubernetes.io/managed-by: plugin-manager
    app.kubernetes.io/part-of: nginx-ingress-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 50m
            memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: test-app-service
  namespace: default
  labels:
    app.kubernetes.io/managed-by: plugin-manager
    app.kubernetes.io/part-of: nginx-ingress-test
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
  labels:
    app.kubernetes.io/managed-by: plugin-manager
    app.kubernetes.io/part-of: nginx-ingress-test
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: test.${DOMAIN_FILTERS:-example.com}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-app-service
            port:
              number: 80
EOF

    # Create test resources
    kubectl apply -f "$test_ingress_file"
    
    # Wait a bit and check status
    sleep 10
    
    # Check ingress status
    kubectl get ingress test-ingress -n default
    
    log_success "Test ingress created (will be cleaned up)"
    
    # Clean up test resources
    kubectl delete -f "$test_ingress_file" --ignore-not-found=true
    
    log_success "Test ingress cleanup completed"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # List all resources in the namespace
    log_info "Resources in namespace $NAMESPACE:"
    kubectl get all -n "$NAMESPACE"
    
    # Check ingress class
    log_info "Ingress classes:"
    kubectl get ingressclass
    
    # Check admission webhooks
    log_info "Validating admission webhooks:"
    kubectl get validatingadmissionwebhooks -l app.kubernetes.io/name=ingress-nginx
    
    log_success "Installation verification completed"
}

# Main installation flow
main() {
    # Set trap for cleanup on failure
    trap 'cleanup_failed_installation "$PLUGIN_NAME" "$NAMESPACE"' ERR
    
    validate_config
    prepare_values
    install_plugin
    health_check
    verify_installation
    
    # Only run ingress test if we have domain filters
    if [[ -n "${DOMAIN_FILTERS:-}" ]]; then
        create_test_ingress
    fi
    
    log_success "Plugin $PLUGIN_NAME installed successfully!"
    echo ""
    echo "📋 Installation Summary:"
    echo "  Namespace: $NAMESPACE"
    echo "  Cloud Provider: $CLOUD_PROVIDER"
    echo "  Service Type: ${SERVICE_TYPE:-LoadBalancer}"
    echo "  Replica Count: ${REPLICA_COUNT:-2}"
    echo "  SSL Redirect: ${ENABLE_SSL_REDIRECT:-true}"
    echo ""
    echo "🔍 To check status:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get service -n $NAMESPACE"
    echo "  kubectl get ingressclass"
    echo ""
    echo "🌐 To get external IP:"
    echo "  kubectl get service -n $NAMESPACE ingress-nginx-controller"
}

# Execute main function
main "$@"