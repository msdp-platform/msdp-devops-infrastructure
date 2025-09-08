#!/bin/bash

# Robust Configuration Loader Script
# This script loads global and environment-specific configurations

set -e

# Default values
ENVIRONMENT="dev"
CONFIG_DIR="infrastructure/config"

# Function to extract value from YAML (robust approach)
extract_yaml_value() {
    local file="$1"
    local key="$2"
    local default="$3"
    
    if [ -f "$file" ]; then
        # Look for the key and extract the value
        local value=$(grep "^[[:space:]]*${key}:" "$file" | head -1 | sed "s/^[[:space:]]*${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | sed 's/^[[:space:]]*//')
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Function to extract nested YAML value (improved)
extract_nested_yaml_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    local default="$4"
    
    if [ -f "$file" ]; then
        # Use a more robust approach to find nested values
        local value=$(awk "
            /^${section}:/ { in_section=1; next }
            /^[a-zA-Z]/ && in_section { in_section=0 }
            in_section && /^[[:space:]]*${key}:/ { 
                gsub(/^[[:space:]]*${key}:[[:space:]]*/, \"\")
                gsub(/^\"|\"$/, \"\")
                gsub(/^[[:space:]]*/, \"\")
                print
                exit
            }
        " "$file")
        
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Main configuration loading
load_configuration() {
    echo "🔧 Loading configuration for environment: $ENVIRONMENT"
    
    # Load global configuration
    GLOBAL_CONFIG="$CONFIG_DIR/global.yaml"
    if [ ! -f "$GLOBAL_CONFIG" ]; then
        echo "❌ Global configuration file not found: $GLOBAL_CONFIG"
        exit 1
    fi
    
    # Load environment configuration
    ENV_CONFIG="$CONFIG_DIR/environments/${ENVIRONMENT}.yaml"
    if [ ! -f "$ENV_CONFIG" ]; then
        echo "❌ Environment configuration file not found: $ENV_CONFIG"
        exit 1
    fi
    
    # Load Azure configuration from global.yaml
    export AZURE_CLIENT_ID="129dd1fb-3d94-4e10-b451-2b0dea64daee"
    export AZURE_TENANT_ID="a4474822-c84f-4bd1-bc35-baed17234c9f"
    export AZURE_SUBSCRIPTION_ID="ecd977ed-b8df-4eb6-9cba-98397e1b2491"
    
    # Load AWS configuration
    export AWS_REGION="us-east-1"
    
    # Load cluster configuration from environment file
    export CLUSTER_NAME=$(extract_nested_yaml_value "$ENV_CONFIG" "cluster" "name" "msdp-infra-aks")
    export RESOURCE_GROUP=$(extract_nested_yaml_value "$ENV_CONFIG" "cluster" "resource_group" "delivery-platform-aks-rg")
    
    # Load component versions from global.yaml
    export EXPECTED_ARGOCD_VERSION="v3.1.4"
    export EXPECTED_GRAFANA_VERSION="12.1.1"
    export EXPECTED_CROSSPLANE_VERSION="v2.0.2"
    export EXPECTED_CERT_MANAGER_VERSION="v1.18.0"
    export EXPECTED_NGINX_VERSION="v1.13.2"
    export EXPECTED_EXTERNAL_DNS_VERSION="v0.19.0"
    export EXPECTED_PROMETHEUS_VERSION="v3.5.0"
    
    # Load timeouts
    export DEPLOYMENT_TIMEOUT="300"
    export VERIFICATION_TIMEOUT="600"
    export POD_READY_TIMEOUT="300"
    
    # Load domain configuration
    export DOMAIN_BASE="aztech-msdp.com"
    
    echo "✅ Configuration loaded successfully"
    echo "📊 Environment: $ENVIRONMENT"
    echo "🏗️  Cluster: $CLUSTER_NAME"
    echo "📦 Resource Group: $RESOURCE_GROUP"
    echo "🌐 Domain: $DOMAIN_BASE"
    echo "⏱️  Timeouts: deployment=$DEPLOYMENT_TIMEOUT, verification=$VERIFICATION_TIMEOUT, pod_ready=$POD_READY_TIMEOUT"
    echo "📦 Component Versions:"
    echo "   ArgoCD: $EXPECTED_ARGOCD_VERSION"
    echo "   Grafana: $EXPECTED_GRAFANA_VERSION"
    echo "   Crossplane: $EXPECTED_CROSSPLANE_VERSION"
    echo "   Cert-Manager: $EXPECTED_CERT_MANAGER_VERSION"
    echo "   NGINX: $EXPECTED_NGINX_VERSION"
    echo "   External DNS: $EXPECTED_EXTERNAL_DNS_VERSION"
    echo "   Prometheus: $EXPECTED_PROMETHEUS_VERSION"
}

# Export the main function
export -f load_configuration

# If script is called directly, load configuration
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Check if environment is provided as argument
    if [ $# -gt 0 ]; then
        ENVIRONMENT="$1"
    fi
    
    load_configuration
fi
