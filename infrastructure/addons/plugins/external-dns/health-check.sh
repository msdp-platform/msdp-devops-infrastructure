#!/bin/bash
set -euo pipefail

# External DNS Plugin Health Check Script
PLUGIN_NAME="external-dns"
NAMESPACE="external-dns-system"

echo "🔍 Performing health check for plugin: $PLUGIN_NAME"

# Health check function
health_check() {
    local exit_code=0
    
    echo "📋 Checking External DNS health..."
    
    # Check if namespace exists
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        echo "❌ Namespace $NAMESPACE does not exist"
        return 1
    fi
    
    # Check if deployment exists and is ready
    echo "Checking deployment status..."
    if ! kubectl get deployment external-dns -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "❌ Deployment external-dns not found in namespace $NAMESPACE"
        return 1
    fi
    
    # Check deployment readiness
    local ready_replicas
    ready_replicas=$(kubectl get deployment external-dns -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired_replicas
    desired_replicas=$(kubectl get deployment external-dns -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [[ "$ready_replicas" != "$desired_replicas" ]]; then
        echo "❌ Deployment not ready: $ready_replicas/$desired_replicas replicas ready"
        kubectl get deployment external-dns -n "$NAMESPACE"
        exit_code=1
    else
        echo "✅ Deployment is ready: $ready_replicas/$desired_replicas replicas"
    fi
    
    # Check pod status
    echo "Checking pod status..."
    local pod_status
    pod_status=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")
    
    if [[ -z "$pod_status" ]]; then
        echo "❌ No pods found for external-dns"
        return 1
    fi
    
    for status in $pod_status; do
        if [[ "$status" != "Running" ]]; then
            echo "❌ Pod not running: $status"
            kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns
            exit_code=1
        fi
    done
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ All pods are running"
    fi
    
    # Check service
    echo "Checking service..."
    if kubectl get service external-dns -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "✅ Service exists"
    else
        echo "⚠️ Service not found (this might be normal depending on configuration)"
    fi
    
    # Check health endpoint if pods are running
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$pod_name" ]]; then
        echo "Checking health endpoint..."
        
        # Try to access the health endpoint
        if kubectl exec -n "$NAMESPACE" "$pod_name" -- wget -q --spider --timeout=10 http://localhost:7979/healthz 2>/dev/null; then
            echo "✅ Health endpoint is responding"
        else
            echo "⚠️ Health endpoint not responding (this might be normal during startup)"
            # Don't fail the health check for this, as it might be starting up
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
    if kubectl get clusterrole external-dns >/dev/null 2>&1; then
        echo "✅ ClusterRole exists"
    else
        echo "❌ ClusterRole not found"
        exit_code=1
    fi
    
    if kubectl get clusterrolebinding external-dns >/dev/null 2>&1; then
        echo "✅ ClusterRoleBinding exists"
    else
        echo "❌ ClusterRoleBinding not found"
        exit_code=1
    fi
    
    # Check ServiceAccount
    if kubectl get serviceaccount external-dns -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "✅ ServiceAccount exists"
    else
        echo "❌ ServiceAccount not found"
        exit_code=1
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
    kubectl get deployment external-dns -n "$NAMESPACE" -o wide 2>/dev/null || echo "Deployment not found"
    
    # Pod status
    echo ""
    echo "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns -o wide 2>/dev/null || echo "No pods found"
    
    # Service status
    echo ""
    echo "Service Status:"
    kubectl get service -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns 2>/dev/null || echo "No services found"
    
    # Recent events
    echo ""
    echo "Recent Events:"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' --field-selector involvedObject.name=external-dns 2>/dev/null | tail -5 || echo "No recent events"
    
    # Configuration
    echo ""
    echo "Configuration:"
    kubectl get configmap -n "$NAMESPACE" -l app.kubernetes.io/name=external-dns 2>/dev/null || echo "No configmaps found"
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