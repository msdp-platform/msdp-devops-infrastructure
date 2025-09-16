#!/bin/bash
set -euo pipefail

# NGINX Ingress Controller Plugin Health Check Script
PLUGIN_NAME="nginx-ingress"
NAMESPACE="nginx-ingress"

echo "🔍 Performing health check for plugin: $PLUGIN_NAME"

# Health check function
health_check() {
    local exit_code=0
    
    echo "📋 Checking NGINX Ingress Controller health..."
    
    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        echo "❌ Namespace $NAMESPACE does not exist"
        return 1
    fi
    
    # Check if deployment exists and is ready
    echo "Checking deployment status..."
    if ! kubectl get deployment ingress-nginx-controller -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "❌ Deployment ingress-nginx-controller not found in namespace $NAMESPACE"
        return 1
    fi
    
    # Check deployment readiness
    local ready_replicas
    ready_replicas=$(kubectl get deployment ingress-nginx-controller -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired_replicas
    desired_replicas=$(kubectl get deployment ingress-nginx-controller -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [[ "$ready_replicas" != "$desired_replicas" ]]; then
        echo "❌ Deployment not ready: $ready_replicas/$desired_replicas replicas ready"
        kubectl get deployment ingress-nginx-controller -n "$NAMESPACE"
        exit_code=1
    else
        echo "✅ Deployment is ready: $ready_replicas/$desired_replicas replicas"
    fi
    
    # Check pod status
    echo "Checking pod status..."
    local pod_status
    pod_status=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")
    
    if [[ -z "$pod_status" ]]; then
        echo "❌ No pods found for ingress-nginx"
        return 1
    fi
    
    for status in $pod_status; do
        if [[ "$status" != "Running" ]]; then
            echo "❌ Pod not running: $status"
            kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=ingress-nginx
            exit_code=1
        fi
    done
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ All pods are running"
    fi
    
    # Check service
    echo "Checking service..."
    if kubectl get service ingress-nginx-controller -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "✅ Service exists"
        
        # Check if external IP is assigned (for LoadBalancer type)
        local service_type
        service_type=$(kubectl get service ingress-nginx-controller -n "$NAMESPACE" -o jsonpath='{.spec.type}')
        
        if [[ "$service_type" == "LoadBalancer" ]]; then
            local external_ip
            external_ip=$(kubectl get service ingress-nginx-controller -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
            
            if [[ -n "$external_ip" ]]; then
                echo "✅ External endpoint available: $external_ip"
            else
                echo "⚠️ External IP still pending (this is normal for new deployments)"
            fi
        fi
    else
        echo "❌ Service not found"
        exit_code=1
    fi
    
    # Check ingress class
    echo "Checking ingress class..."
    if kubectl get ingressclass nginx >/dev/null 2>&1; then
        echo "✅ Ingress class 'nginx' exists"
        
        # Check if it's the default
        local is_default
        is_default=$(kubectl get ingressclass nginx -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}' 2>/dev/null || echo "false")
        
        if [[ "$is_default" == "true" ]]; then
            echo "✅ Ingress class 'nginx' is set as default"
        else
            echo "ℹ️ Ingress class 'nginx' is not set as default"
        fi
    else
        echo "❌ Ingress class 'nginx' not found"
        exit_code=1
    fi
    
    # Check health endpoint if pods are running
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$pod_name" ]]; then
        echo "Checking health endpoint..."
        
        # Try to access the health endpoint
        if kubectl exec -n "$NAMESPACE" "$pod_name" -- wget -q --spider --timeout=10 http://localhost:10254/healthz 2>/dev/null; then
            echo "✅ Health endpoint is responding"
        else
            echo "⚠️ Health endpoint not responding (this might be normal during startup)"
            # Don't fail the health check for this, as it might be starting up
        fi
        
        # Check metrics endpoint
        if kubectl exec -n "$NAMESPACE" "$pod_name" -- wget -q --spider --timeout=10 http://localhost:10254/metrics 2>/dev/null; then
            echo "✅ Metrics endpoint is responding"
        else
            echo "⚠️ Metrics endpoint not responding"
        fi
        
        # Check recent logs for errors
        echo "Checking recent logs for errors..."
        local error_count
        error_count=$(kubectl logs -n "$NAMESPACE" "$pod_name" --tail=50 2>/dev/null | grep -i "error\|failed\|panic" | wc -l || echo "0")
        
        if [[ $error_count -gt 0 ]]; then
            echo "⚠️ Found $error_count error messages in recent logs:"
            kubectl logs -n "$NAMESPACE" "$pod_name" --tail=20 | grep -i "error\|failed\|panic" || true
            # Don't fail for log errors, just warn
        else
            echo "✅ No errors found in recent logs"
        fi
    fi
    
    # Check RBAC
    echo "Checking RBAC..."
    if kubectl get clusterrole ingress-nginx >/dev/null 2>&1; then
        echo "✅ ClusterRole exists"
    else
        echo "❌ ClusterRole not found"
        exit_code=1
    fi
    
    if kubectl get clusterrolebinding ingress-nginx >/dev/null 2>&1; then
        echo "✅ ClusterRoleBinding exists"
    else
        echo "❌ ClusterRoleBinding not found"
        exit_code=1
    fi
    
    # Check ServiceAccount
    if kubectl get serviceaccount ingress-nginx -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "✅ ServiceAccount exists"
    else
        echo "❌ ServiceAccount not found"
        exit_code=1
    fi
    
    # Check admission webhooks
    echo "Checking admission webhooks..."
    local webhook_count
    webhook_count=$(kubectl get validatingadmissionwebhooks -l app.kubernetes.io/name=ingress-nginx --no-headers 2>/dev/null | wc -l || echo "0")
    
    if [[ $webhook_count -gt 0 ]]; then
        echo "✅ Admission webhooks configured ($webhook_count found)"
    else
        echo "⚠️ No admission webhooks found (this might be normal depending on configuration)"
    fi
    
    return $exit_code
}

# Detailed status report
status_report() {
    echo ""
    echo "📊 Detailed Status Report:"
    echo "=========================="
    
    # Deployment status
    echo ""
    echo "Deployment Status:"
    kubectl get deployment ingress-nginx-controller -n "$NAMESPACE" -o wide 2>/dev/null || echo "Deployment not found"
    
    # Pod status
    echo ""
    echo "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=ingress-nginx -o wide 2>/dev/null || echo "No pods found"
    
    # Service status
    echo ""
    echo "Service Status:"
    kubectl get service ingress-nginx-controller -n "$NAMESPACE" -o wide 2>/dev/null || echo "Service not found"
    
    # Ingress class status
    echo ""
    echo "Ingress Class Status:"
    kubectl get ingressclass 2>/dev/null || echo "No ingress classes found"
    
    # Recent events
    echo ""
    echo "Recent Events:"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' --field-selector involvedObject.name=ingress-nginx-controller 2>/dev/null | tail -5 || echo "No recent events"
    
    # Configuration
    echo ""
    echo "Configuration:"
    kubectl get configmap -n "$NAMESPACE" -l app.kubernetes.io/name=ingress-nginx 2>/dev/null || echo "No configmaps found"
}

# Main health check flow
main() {
    if health_check; then
        echo ""
        echo "🎉 Health check passed for plugin: $PLUGIN_NAME"
        status_report
        exit 0
    else
        echo ""
        echo "❌ Health check failed for plugin: $PLUGIN_NAME"
        status_report
        exit 1
    fi
}

# Execute main function
main "$@"