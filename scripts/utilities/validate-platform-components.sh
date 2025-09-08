#!/bin/bash

# MSDP Platform Components Validation Script
# This script validates all platform component configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate YAML files
validate_yaml() {
    local file="$1"
    print_status "Validating YAML: $file"
    
    if command_exists yamllint; then
        if yamllint "$file"; then
            print_success "YAML validation passed: $file"
        else
            print_error "YAML validation failed: $file"
            return 1
        fi
    else
        print_warning "yamllint not found, skipping YAML validation for: $file"
    fi
}

# Function to validate Kustomize
validate_kustomize() {
    local dir="$1"
    print_status "Validating Kustomize: $dir"
    
    if command_exists kustomize; then
        if kustomize build "$dir" >/dev/null 2>&1; then
            print_success "Kustomize validation passed: $dir"
        else
            print_error "Kustomize validation failed: $dir"
            return 1
        fi
    else
        print_warning "kustomize not found, skipping Kustomize validation for: $dir"
    fi
}

# Function to validate Helm values
validate_helm_values() {
    local file="$1"
    print_status "Validating Helm values: $file"
    
    if command_exists helm; then
        # Check if this is a Helm values file (contains common Helm keys)
        if grep -q "replicaCount\|image:\|service:" "$file" 2>/dev/null; then
            # Create a temporary Chart.yaml for validation
            local temp_dir=$(mktemp -d)
            cat > "$temp_dir/Chart.yaml" << EOF
apiVersion: v2
name: temp-chart
description: Temporary chart for validation
type: application
version: 0.1.0
EOF
            
            if helm template test "$temp_dir" -f "$file" >/dev/null 2>&1; then
                print_success "Helm values validation passed: $file"
                rm -rf "$temp_dir"
            else
                print_error "Helm values validation failed: $file"
                rm -rf "$temp_dir"
                return 1
            fi
        else
            print_warning "File doesn't appear to be a Helm values file: $file"
        fi
    else
        print_warning "helm not found, skipping Helm validation for: $file"
    fi
}

# Main validation function
main() {
    print_status "Starting MSDP Platform Components Validation"
    
    local validation_errors=0
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    if ! command_exists kubectl; then
        print_warning "kubectl not found - some validations will be skipped"
    fi
    
    # Validate networking platform components
    print_status "Validating networking platform components..."
    
    # NGINX Ingress Controller
    if [ -d "infrastructure/platforms/networking/nginx-ingress" ]; then
        validate_yaml "infrastructure/platforms/networking/nginx-ingress/namespace.yaml"
        validate_helm_values "infrastructure/platforms/networking/nginx-ingress/helm-values.yaml"
        validate_kustomize "infrastructure/platforms/networking/nginx-ingress"
    else
        print_error "NGINX Ingress Controller directory not found"
        ((validation_errors++))
    fi
    
    # Cert-Manager
    if [ -d "infrastructure/platforms/networking/cert-manager" ]; then
        validate_yaml "infrastructure/platforms/networking/cert-manager/namespace.yaml"
        validate_yaml "infrastructure/platforms/networking/cert-manager/letsencrypt-issuer.yaml"
        validate_helm_values "infrastructure/platforms/networking/cert-manager/helm-values.yaml"
        validate_kustomize "infrastructure/platforms/networking/cert-manager"
    else
        print_error "Cert-Manager directory not found"
        ((validation_errors++))
    fi
    
    # External DNS
    if [ -d "infrastructure/platforms/networking/external-dns" ]; then
        validate_yaml "infrastructure/platforms/networking/external-dns/namespace.yaml"
        validate_yaml "infrastructure/platforms/networking/external-dns/rbac.yaml"
        validate_yaml "infrastructure/platforms/networking/external-dns/deployment.yaml"
        validate_yaml "infrastructure/platforms/networking/external-dns/service.yaml"
        validate_yaml "infrastructure/platforms/networking/external-dns/servicemonitor.yaml"
        validate_kustomize "infrastructure/platforms/networking/external-dns"
    else
        print_error "External DNS directory not found"
        ((validation_errors++))
    fi
    
    # Validate application components
    print_status "Validating application components..."
    
    # ArgoCD
    if [ -d "infrastructure/applications/argocd" ]; then
        if [ -d "infrastructure/applications/argocd/ingress" ]; then
            for yaml_file in infrastructure/applications/argocd/ingress/*.yaml; do
                if [ -f "$yaml_file" ]; then
                    validate_yaml "$yaml_file"
                fi
            done
            validate_kustomize "infrastructure/applications/argocd/ingress"
        fi
        
        if [ -d "infrastructure/applications/argocd/certificates" ]; then
            for yaml_file in infrastructure/applications/argocd/certificates/*.yaml; do
                if [ -f "$yaml_file" ]; then
                    validate_yaml "$yaml_file"
                fi
            done
            validate_kustomize "infrastructure/applications/argocd/certificates"
        fi
    else
        print_error "ArgoCD application directory not found"
        ((validation_errors++))
    fi
    
    # Backstage
    if [ -d "infrastructure/applications/backstage" ]; then
        validate_yaml "infrastructure/applications/backstage/Chart.yaml"
        validate_yaml "infrastructure/applications/backstage/values.yaml"
        validate_yaml "infrastructure/applications/backstage/values-dev.yaml"
        validate_yaml "infrastructure/applications/backstage/values-test.yaml"
        validate_yaml "infrastructure/applications/backstage/values-prod.yaml"
        
        if [ -d "infrastructure/applications/backstage/templates" ]; then
            for yaml_file in infrastructure/applications/backstage/templates/*.yaml; do
                if [ -f "$yaml_file" ]; then
                    validate_yaml "$yaml_file"
                fi
            done
        fi
    else
        print_error "Backstage application directory not found"
        ((validation_errors++))
    fi
    
    # Validate GitHub Actions workflow
    print_status "Validating GitHub Actions workflow..."
    if [ -f "ci-cd/workflows/deploy-platform-components.yml" ]; then
        validate_yaml "ci-cd/workflows/deploy-platform-components.yml"
    else
        print_error "Platform components deployment workflow not found"
        ((validation_errors++))
    fi
    
    # Summary
    print_status "Validation completed"
    
    if [ $validation_errors -eq 0 ]; then
        print_success "All platform components validation passed! ✅"
        exit 0
    else
        print_error "Validation failed with $validation_errors errors ❌"
        exit 1
    fi
}

# Run main function
main "$@"
