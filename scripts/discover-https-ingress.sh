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

# Find all ingress files, excluding example files and chart templates
INGRESS_FILES=$(find . -name "*.yaml" -type f -exec grep -l "kind: Ingress" {} \; | grep -v "/charts/" | grep -v "example" | grep -v "template")

echo "📁 Found ingress files:"
echo "$INGRESS_FILES"

# Process each ingress file and collect unique certificate requirements
declare -A processed_certificates

for ingress_file in $INGRESS_FILES; do
    echo "🔍 Processing: $ingress_file"
    
    # Validate YAML file first
    if ! yq eval '.' "$ingress_file" >/dev/null 2>&1; then
        echo "⚠️ Invalid YAML file, skipping: $ingress_file"
        continue
    fi
    
    # Extract ingress information
    namespace=$(yq eval '.metadata.namespace' "$ingress_file" 2>/dev/null || echo "default")
    name=$(yq eval '.metadata.name' "$ingress_file" 2>/dev/null || echo "unknown")
    
    # Skip if namespace or name is invalid
    if [ "$namespace" = "null" ] || [ "$name" = "null" ] || [ -z "$namespace" ] || [ -z "$name" ]; then
        echo "⚠️ Invalid ingress metadata, skipping: $ingress_file"
        continue
    fi
    
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
done

echo "✅ HTTPS ingress discovery complete"
echo "📁 Certificate management files generated in: $OUTPUT_DIR"
