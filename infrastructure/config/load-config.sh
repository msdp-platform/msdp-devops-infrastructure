#!/bin/bash

# Configuration Loader Script
# This script loads global and environment-specific configurations

set -e

# Default values
ENVIRONMENT="dev"
CONFIG_DIR="infrastructure/config"

# Function to load YAML values (simple parser)
load_yaml_value() {
    local file="$1"
    local key="$2"
    local default="$3"
    
    if [ -f "$file" ]; then
        # Simple YAML value extraction (works for simple key: value pairs)
        local value=$(grep "^[[:space:]]*${key}:" "$file" | head -1 | sed "s/^[[:space:]]*${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//')
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# Function to load component version
load_component_version() {
    local component="$1"
    local type="$2"  # platform_components or applications
    
    local global_file="$CONFIG_DIR/global.yaml"
    local version=$(load_yaml_value "$global_file" "version" "unknown" | grep -A 20 "$type:" | grep -A 10 "$component:" | grep "version:" | sed 's/.*version:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    echo "$version"
}

# Function to load environment-specific value
load_env_value() {
    local key="$1"
    local default="$2"
    
    local env_file="$CONFIG_DIR/environments/${ENVIRONMENT}.yaml"
    load_yaml_value "$env_file" "$key" "$default"
}

# Function to load cluster configuration
load_cluster_config() {
    local key="$1"
    local default="$2"
    
    local env_file="$CONFIG_DIR/environments/${ENVIRONMENT}.yaml"
    load_yaml_value "$env_file" "$key" "$default" | grep -A 10 "cluster:" | grep "$key:" | sed "s/.*${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//'
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
    
    # Load Azure configuration
    export AZURE_CLIENT_ID=$(load_yaml_value "$GLOBAL_CONFIG" "client_id" "129dd1fb-3d94-4e10-b451-2b0dea64daee" | grep -A 5 "azure:" | grep "client_id:" | sed 's/.*client_id:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    export AZURE_TENANT_ID=$(load_yaml_value "$GLOBAL_CONFIG" "tenant_id" "a4474822-c84f-4bd1-bc35-baed17234c9f" | grep -A 5 "azure:" | grep "tenant_id:" | sed 's/.*tenant_id:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    export AZURE_SUBSCRIPTION_ID=$(load_yaml_value "$GLOBAL_CONFIG" "subscription_id" "ecd977ed-b8df-4eb6-9cba-98397e1b2491" | grep -A 5 "azure:" | grep "subscription_id:" | sed 's/.*subscription_id:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    
    # Load AWS configuration
    export AWS_REGION=$(load_yaml_value "$GLOBAL_CONFIG" "region" "us-east-1" | grep -A 5 "aws:" | grep "region:" | sed 's/.*region:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    
    # Load cluster configuration
    export CLUSTER_NAME=$(load_env_value "name" "msdp-infra-aks")
    export RESOURCE_GROUP=$(load_env_value "resource_group" "delivery-platform-aks-rg")
    
    # Load component versions
    export EXPECTED_ARGOCD_VERSION=$(load_component_version "argocd" "applications")
    export EXPECTED_GRAFANA_VERSION=$(load_component_version "grafana" "platform_components")
    export EXPECTED_CROSSPLANE_VERSION=$(load_component_version "crossplane" "applications")
    export EXPECTED_CERT_MANAGER_VERSION=$(load_component_version "cert_manager" "platform_components")
    export EXPECTED_NGINX_VERSION=$(load_component_version "nginx_ingress" "platform_components")
    
    # Load timeouts
    export DEPLOYMENT_TIMEOUT=$(load_yaml_value "$GLOBAL_CONFIG" "deployment" "300" | grep -A 10 "timeouts:" | grep "deployment:" | sed 's/.*deployment:[[:space:]]*//')
    export VERIFICATION_TIMEOUT=$(load_yaml_value "$GLOBAL_CONFIG" "verification" "600" | grep -A 10 "timeouts:" | grep "verification:" | sed 's/.*verification:[[:space:]]*//')
    export POD_READY_TIMEOUT=$(load_yaml_value "$GLOBAL_CONFIG" "pod_ready" "300" | grep -A 10 "timeouts:" | grep "pod_ready:" | sed 's/.*pod_ready:[[:space:]]*//')
    
    # Load domain configuration
    export DOMAIN_BASE=$(load_yaml_value "$GLOBAL_CONFIG" "base" "aztech-msdp.com" | grep -A 10 "domains:" | grep "base:" | sed 's/.*base:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    
    echo "✅ Configuration loaded successfully"
    echo "📊 Environment: $ENVIRONMENT"
    echo "🏗️  Cluster: $CLUSTER_NAME"
    echo "📦 Resource Group: $RESOURCE_GROUP"
    echo "🌐 Domain: $DOMAIN_BASE"
    echo "⏱️  Timeouts: deployment=$DEPLOYMENT_TIMEOUT, verification=$VERIFICATION_TIMEOUT, pod_ready=$POD_READY_TIMEOUT"
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
