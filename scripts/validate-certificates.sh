#!/bin/bash

# Certificate Validation Script
# Validates that certificates are properly generated and configured

set -euo pipefail

echo "🔍 Certificate Validation Report"
echo "================================"

# Function to check certificate status
check_certificate() {
    local namespace=$1
    local cert_name=$2
    local secret_name=$3
    
    echo ""
    echo "📋 Checking certificate: $cert_name in namespace: $namespace"
    echo "------------------------------------------------------------"
    
    # Check if certificate resource exists
    if kubectl get certificate -n "$namespace" "$cert_name" >/dev/null 2>&1; then
        echo "✅ Certificate resource exists: $cert_name"
        
        # Get certificate status
        local status=$(kubectl get certificate -n "$namespace" "$cert_name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        local reason=$(kubectl get certificate -n "$namespace" "$cert_name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}' 2>/dev/null || echo "Unknown")
        
        if [ "$status" = "True" ]; then
            echo "✅ Certificate is Ready"
        else
            echo "❌ Certificate is not ready. Status: $status, Reason: $reason"
        fi
        
        # Check certificate details
        local not_after=$(kubectl get certificate -n "$namespace" "$cert_name" -o jsonpath='{.status.notAfter}' 2>/dev/null || echo "Unknown")
        local not_before=$(kubectl get certificate -n "$namespace" "$cert_name" -o jsonpath='{.status.notBefore}' 2>/dev/null || echo "Unknown")
        
        echo "📅 Valid from: $not_before"
        echo "📅 Valid until: $not_after"
        
    else
        echo "❌ Certificate resource not found: $cert_name"
    fi
    
    # Check if TLS secret exists
    if kubectl get secret -n "$namespace" "$secret_name" >/dev/null 2>&1; then
        echo "✅ TLS secret exists: $secret_name"
        
        # Check if secret has certificate data
        local cert_data=$(kubectl get secret -n "$namespace" "$secret_name" -o jsonpath='{.data.tls\.crt}' 2>/dev/null || echo "")
        if [ -n "$cert_data" ]; then
            echo "✅ Secret contains certificate data"
            
            # Decode and check certificate validity
            echo "$cert_data" | base64 -d | openssl x509 -text -noout 2>/dev/null | grep -E "(Subject:|Issuer:|Not Before|Not After)" || echo "⚠️ Could not parse certificate"
        else
            echo "❌ Secret missing certificate data"
        fi
    else
        echo "❌ TLS secret not found: $secret_name"
    fi
}

# Function to check External Secrets status
check_external_secrets() {
    echo ""
    echo "🔐 External Secrets Status"
    echo "-------------------------"
    
    # Check External Secrets operator
    if kubectl get deployment -n external-secrets external-secrets >/dev/null 2>&1; then
        echo "✅ External Secrets operator is running"
        
        # Check External Secrets resources
        kubectl get externalsecrets -A 2>/dev/null || echo "⚠️ No External Secrets found"
        
        # Check cluster secret store
        if kubectl get clustersecretstore azure-keyvault-store >/dev/null 2>&1; then
            echo "✅ Azure Key Vault store is configured"
            
            local store_status=$(kubectl get clustersecretstore azure-keyvault-store -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
            if [ "$store_status" = "True" ]; then
                echo "✅ Key Vault store is ready"
            else
                echo "❌ Key Vault store is not ready. Status: $store_status"
            fi
        else
            echo "❌ Azure Key Vault store not found"
        fi
    else
        echo "❌ External Secrets operator not found"
    fi
}

# Function to check cert-manager status
check_cert_manager() {
    echo ""
    echo "🔧 Cert-Manager Status"
    echo "---------------------"
    
    # Check cert-manager pods
    if kubectl get pods -n cert-manager >/dev/null 2>&1; then
        echo "✅ Cert-manager namespace exists"
        
        # Check cert-manager deployment
        kubectl get pods -n cert-manager -l app.kubernetes.io/name=cert-manager
        
        # Check cert-manager webhook
        kubectl get pods -n cert-manager -l app.kubernetes.io/name=webhook
        
        # Check cert-manager cainjector
        kubectl get pods -n cert-manager -l app.kubernetes.io/name=cainjector
        
    else
        echo "❌ Cert-manager namespace not found"
    fi
}

# Main validation
echo "Starting certificate validation..."
echo ""

# Check cert-manager
check_cert_manager

# Check External Secrets
check_external_secrets

# Check specific certificates
check_certificate "argocd" "aztech-msdp-tls" "aztech-msdp-tls"
check_certificate "monitoring" "grafana-tls" "grafana-tls"

# Check for any other certificates
echo ""
echo "📊 All Certificates Summary"
echo "--------------------------"
kubectl get certificates -A 2>/dev/null || echo "No certificates found"

echo ""
echo "📊 All TLS Secrets Summary"
echo "-------------------------"
kubectl get secrets -A | grep tls || echo "No TLS secrets found"

echo ""
echo "✅ Certificate validation complete!"
