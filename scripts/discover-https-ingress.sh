#!/bin/bash

# Dynamic HTTPS Ingress Discovery Script
# Discovers all ingress rules with HTTPS/TLS and generates certificate management

set -euo pipefail

ENVIRONMENT="${1:-dev}"
BASE_DOMAIN="${2:-aztech-msdp.com}"
OUTPUT_DIR="${3:-/tmp/certificate-management}"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment> [base_domain] [output_dir]"
    echo "Example: $0 dev aztech-msdp.com /tmp/certificate-management"
    exit 1
fi

echo "🔍 Discovering HTTPS ingress rules for environment: $ENVIRONMENT"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Discover actual deployed ingress resources instead of static files
echo "🔍 Discovering deployed ingress resources..."

# Get all deployed ingress resources
DEPLOYED_INGRESS=$(kubectl get ingress -A -o yaml 2>/dev/null || echo "")

if [ -z "$DEPLOYED_INGRESS" ]; then
    echo "❌ No deployed ingress resources found"
    exit 1
fi

echo "📁 Found deployed ingress resources:"
echo "$DEPLOYED_INGRESS" | yq eval '.items[].metadata | "\(.namespace)/\(.name)"' -o json

# Process each deployed ingress resource
declare -A processed_certificates

# Extract ingress information from deployed resources
echo "$DEPLOYED_INGRESS" | yq eval '.items[]' -o json | while read -r ingress_json; do
    if [ -n "$ingress_json" ]; then
        namespace=$(echo "$ingress_json" | yq eval '.metadata.namespace' -o json)
        name=$(echo "$ingress_json" | yq eval '.metadata.name' -o json)
        
        echo "🔍 Processing deployed ingress: $name in namespace $namespace"
        
        # Check if ingress has TLS configuration
        tls_config=$(echo "$ingress_json" | yq eval '.spec.tls[0]' -o json 2>/dev/null || echo "null")
        
        if [ "$tls_config" != "null" ] && [ -n "$tls_config" ]; then
            secret_name=$(echo "$tls_config" | yq eval '.secretName' -o json 2>/dev/null || echo "")
            hosts=$(echo "$tls_config" | yq eval '.hosts[]' -o json 2>/dev/null || echo "")
            
            if [ -n "$secret_name" ] && [ -n "$hosts" ]; then
                echo "🔒 Found HTTPS ingress: $name in namespace $namespace"
                echo "📋 TLS Configuration:"
                echo "  - Secret Name: $secret_name"
                echo "  - Hosts: $hosts"
                
                # Create unique key for this certificate (namespace + secret_name)
                cert_key="${namespace}:${secret_name}"
                
                # Check if we've already processed this certificate
                if [ -n "${processed_certificates[$cert_key]}" ]; then
                    echo "⚠️ Certificate already processed: $cert_key"
                    echo "  - Skipping duplicate certificate generation"
                    continue
                fi
                
                # Mark this certificate as processed
                processed_certificates[$cert_key]="true"
                
                # Convert hosts to space-separated string for the script
                hosts_string=$(echo "$hosts" | tr '\n' ' ' | sed 's/ $//')
                
                # Generate certificate management for this ingress
                ./scripts/generate-certificate-management.sh "$name" "$namespace" "$secret_name" "$hosts_string" "$ENVIRONMENT" "$OUTPUT_DIR"
            fi
        else
            echo "ℹ️ No TLS configuration found in $name"
        fi
    fi
done

echo "✅ HTTPS ingress discovery complete"
echo "📁 Certificate management files generated in: $OUTPUT_DIR"
