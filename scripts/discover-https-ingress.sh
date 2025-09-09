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

# Find all ingress files
INGRESS_FILES=$(find . -name "*.yaml" -type f -exec grep -l "kind: Ingress" {} \;)

echo "📁 Found ingress files:"
echo "$INGRESS_FILES"

# Process each ingress file
for ingress_file in $INGRESS_FILES; do
    echo "🔍 Processing: $ingress_file"
    
    # Extract ingress information
    namespace=$(yq eval '.metadata.namespace' "$ingress_file" 2>/dev/null || echo "default")
    name=$(yq eval '.metadata.name' "$ingress_file" 2>/dev/null || echo "unknown")
    
    # Check if ingress has TLS configuration
    tls_hosts=$(yq eval '.spec.tls[].hosts[]' "$ingress_file" 2>/dev/null || echo "")
    
    if [ -n "$tls_hosts" ]; then
        echo "🔒 Found HTTPS ingress: $name in namespace $namespace"
        
        # Extract TLS configuration
        secret_name=$(yq eval '.spec.tls[0].secretName' "$ingress_file" 2>/dev/null || echo "")
        hosts=$(yq eval '.spec.tls[0].hosts[]' "$ingress_file" 2>/dev/null || echo "")
        
        if [ -n "$secret_name" ] && [ -n "$hosts" ]; then
            echo "📋 TLS Configuration:"
            echo "  - Secret Name: $secret_name"
            echo "  - Hosts: $hosts"
            
            # Convert hosts to space-separated string for the script
            hosts_string=$(echo "$hosts" | tr '\n' ' ' | sed 's/ $//')
            
            # Generate certificate management for this ingress
            ./scripts/generate-certificate-management.sh "$name" "$namespace" "$secret_name" "$hosts_string" "$ENVIRONMENT" "$OUTPUT_DIR"
        fi
    else
        echo "ℹ️ No TLS configuration found in $name"
    fi
done

echo "✅ HTTPS ingress discovery complete"
echo "📁 Certificate management files generated in: $OUTPUT_DIR"
