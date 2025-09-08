#!/bin/bash

# Robust Configuration Loading Script
# This script loads configuration from YAML files using yq

# Global configuration variables
GLOBAL_CONFIG_FILE="infrastructure/config/global.yaml"
ENVIRONMENT_CONFIG_FILE=""
COMPONENT_CONFIG_FILE=""

# Function to check if yq is available
check_yq() {
    if ! command -v yq &> /dev/null; then
        echo "❌ yq is not installed. Installing yq..."
        # Install yq
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            chmod +x /usr/local/bin/yq
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install yq
            else
                echo "❌ Please install yq manually on macOS"
                exit 1
            fi
        else
            echo "❌ Unsupported OS. Please install yq manually."
            exit 1
        fi
    fi
}

# Function to load global configuration
load_global_config() {
    if [[ ! -f "$GLOBAL_CONFIG_FILE" ]]; then
        echo "❌ Global configuration file not found: $GLOBAL_CONFIG_FILE"
        exit 1
    fi
    
    echo "📋 Loading global configuration from: $GLOBAL_CONFIG_FILE"
    check_yq
}

# Function to get configuration value
get_config_value() {
    local key="$1"
    local value
    
    if [[ -z "$key" ]]; then
        echo "❌ Configuration key is required"
        return 1
    fi
    
    # Try to get value from global config
    if [[ -f "$GLOBAL_CONFIG_FILE" ]]; then
        value=$(yq eval ".$key" "$GLOBAL_CONFIG_FILE" 2>/dev/null)
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Try to get value from environment config
    if [[ -n "$ENVIRONMENT_CONFIG_FILE" && -f "$ENVIRONMENT_CONFIG_FILE" ]]; then
        value=$(yq eval ".$key" "$ENVIRONMENT_CONFIG_FILE" 2>/dev/null)
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    # Try to get value from component config
    if [[ -n "$COMPONENT_CONFIG_FILE" && -f "$COMPONENT_CONFIG_FILE" ]]; then
        value=$(yq eval ".$key" "$COMPONENT_CONFIG_FILE" 2>/dev/null)
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi
    
    echo "❌ Configuration key not found: $key"
    return 1
}

# Function to set environment config file
set_environment_config() {
    local env="$1"
    if [[ -n "$env" ]]; then
        ENVIRONMENT_CONFIG_FILE="infrastructure/config/environments/${env}.yaml"
        if [[ -f "$ENVIRONMENT_CONFIG_FILE" ]]; then
            echo "📋 Environment configuration loaded: $ENVIRONMENT_CONFIG_FILE"
        else
            echo "⚠️  Environment configuration file not found: $ENVIRONMENT_CONFIG_FILE"
            ENVIRONMENT_CONFIG_FILE=""
        fi
    fi
}

# Function to set component config file
set_component_config() {
    local component="$1"
    if [[ -n "$component" ]]; then
        COMPONENT_CONFIG_FILE="infrastructure/config/components/${component}.yaml"
        if [[ -f "$COMPONENT_CONFIG_FILE" ]]; then
            echo "📋 Component configuration loaded: $COMPONENT_CONFIG_FILE"
        else
            echo "⚠️  Component configuration file not found: $COMPONENT_CONFIG_FILE"
            COMPONENT_CONFIG_FILE=""
        fi
    fi
}

# Function to validate configuration
validate_config() {
    local required_keys=(
        "platform_components.nginx_ingress.version"
        "platform_components.cert_manager.version"
        "platform_components.external_dns.version"
        "platform_components.prometheus.version"
        "platform_components.grafana.version"
        "applications.argocd.version"
        "applications.backstage.version"
        "applications.crossplane.version"
    )
    
    echo "🔍 Validating configuration..."
    
    for key in "${required_keys[@]}"; do
        if ! get_config_value "$key" >/dev/null 2>&1; then
            echo "❌ Missing required configuration key: $key"
            return 1
        fi
    done
    
    echo "✅ Configuration validation passed"
    return 0
}

# Function to display configuration summary
display_config_summary() {
    echo "📊 Configuration Summary:"
    echo "  Global Config: $GLOBAL_CONFIG_FILE"
    echo "  Environment Config: ${ENVIRONMENT_CONFIG_FILE:-"Not set"}"
    echo "  Component Config: ${COMPONENT_CONFIG_FILE:-"Not set"}"
    echo ""
    echo "🔧 Component Versions:"
    echo "  NGINX Ingress: $(get_config_value "platform_components.nginx_ingress.version" 2>/dev/null || echo "Not found")"
    echo "  Cert-Manager: $(get_config_value "platform_components.cert_manager.version" 2>/dev/null || echo "Not found")"
    echo "  External DNS: $(get_config_value "platform_components.external_dns.version" 2>/dev/null || echo "Not found")"
    echo "  Prometheus: $(get_config_value "platform_components.prometheus.version" 2>/dev/null || echo "Not found")"
    echo "  Grafana: $(get_config_value "platform_components.grafana.version" 2>/dev/null || echo "Not found")"
    echo "  ArgoCD: $(get_config_value "applications.argocd.version" 2>/dev/null || echo "Not found")"
    echo "  Backstage: $(get_config_value "applications.backstage.version" 2>/dev/null || echo "Not found")"
    echo "  Crossplane: $(get_config_value "applications.crossplane.version" 2>/dev/null || echo "Not found")"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    load_global_config
    validate_config
    display_config_summary
fi
