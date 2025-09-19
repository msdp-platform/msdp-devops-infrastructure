#!/bin/bash
# Common utility functions for Kubernetes add-ons plugins

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if environment variable is set
check_env_var() {
    local var_name="$1"
    local error_msg="${2:-$var_name is required}"
    
    if [[ -z "${!var_name:-}" ]]; then
        log_error "$error_msg"
        return 1
    fi
    
    log_success "$var_name is set"
    return 0
}

# Check if command exists
check_command() {
    local cmd="$1"
    local error_msg="${2:-$cmd is required but not installed}"
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$error_msg"
        return 1
    fi
    
    log_success "$cmd is available"
    return 0
}

# Check Kubernetes connectivity
check_k8s_connectivity() {
    log_info "Checking Kubernetes connectivity..."
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        return 1
    fi
    
    local context
    context=$(kubectl config current-context)
    log_success "Connected to Kubernetes cluster: $context"
    return 0
}

# Check Helm connectivity
check_helm() {
    log_info "Checking Helm..."
    
    if ! check_command "helm" "Helm is required but not installed"; then
        return 1
    fi
    
    # Check Helm version
    local helm_version
    helm_version=$(helm version --short --client 2>/dev/null || echo "unknown")
    log_success "Helm version: $helm_version"
    
    return 0
}

# Wait for deployment to be ready
wait_for_deployment() {
    local deployment="$1"
    local namespace="$2"
    local timeout="${3:-300}"
    
    log_info "Waiting for deployment $deployment in namespace $namespace to be ready..."
    
    if kubectl wait --for=condition=available deployment/"$deployment" \
        --namespace "$namespace" \
        --timeout="${timeout}s"; then
        log_success "Deployment $deployment is ready"
        return 0
    else
        log_error "Deployment $deployment failed to become ready within ${timeout}s"
        return 1
    fi
}

# Wait for pods to be ready
wait_for_pods() {
    local label_selector="$1"
    local namespace="$2"
    local timeout="${3:-300}"
    
    log_info "Waiting for pods with selector $label_selector in namespace $namespace..."
    
    if kubectl wait --for=condition=ready pod \
        --selector="$label_selector" \
        --namespace "$namespace" \
        --timeout="${timeout}s"; then
        log_success "Pods are ready"
        return 0
    else
        log_error "Pods failed to become ready within ${timeout}s"
        return 1
    fi
}

# Create namespace if it doesn't exist
ensure_namespace() {
    local namespace="$1"
    local labels="${2:-}"
    
    log_info "Ensuring namespace $namespace exists..."
    
    if kubectl get namespace "$namespace" &> /dev/null; then
        log_success "Namespace $namespace already exists"
    else
        log_info "Creating namespace $namespace..."
        kubectl create namespace "$namespace"
        log_success "Namespace $namespace created"
    fi
    
    # Apply labels if provided
    if [[ -n "$labels" ]]; then
        log_info "Applying labels to namespace $namespace..."
        kubectl label namespace "$namespace" $labels --overwrite
        log_success "Labels applied to namespace $namespace"
    fi
    
    return 0
}

# Add Helm repository
add_helm_repo() {
    local repo_name="$1"
    local repo_url="$2"
    
    log_info "Adding Helm repository $repo_name..."
    
    if helm repo add "$repo_name" "$repo_url"; then
        log_success "Helm repository $repo_name added"
        
        log_info "Updating Helm repositories..."
        helm repo update
        log_success "Helm repositories updated"
        return 0
    else
        log_error "Failed to add Helm repository $repo_name"
        return 1
    fi
}

# Install or upgrade Helm chart
helm_install_or_upgrade() {
    local release_name="$1"
    local chart="$2"
    local namespace="$3"
    local values_file="$4"
    local version="${5:-}"
    local timeout="${6:-300}"
    
    log_info "Installing/upgrading Helm chart $chart as release $release_name..."
    
    local helm_cmd="helm upgrade --install $release_name $chart"
    helm_cmd="$helm_cmd --namespace $namespace"
    helm_cmd="$helm_cmd --create-namespace"
    
    if [[ -n "$values_file" && -f "$values_file" ]]; then
        helm_cmd="$helm_cmd --values $values_file"
    fi
    
    if [[ -n "$version" ]]; then
        helm_cmd="$helm_cmd --version $version"
    fi
    
    helm_cmd="$helm_cmd --timeout ${timeout}s"
    helm_cmd="$helm_cmd --wait"
    helm_cmd="$helm_cmd --atomic"
    
    log_info "Executing: $helm_cmd"
    
    if eval "$helm_cmd"; then
        log_success "Helm chart $chart installed/upgraded successfully"
        return 0
    else
        log_error "Failed to install/upgrade Helm chart $chart"
        return 1
    fi
}

# Uninstall Helm chart
helm_uninstall() {
    local release_name="$1"
    local namespace="$2"
    local timeout="${3:-300}"
    
    log_info "Uninstalling Helm release $release_name from namespace $namespace..."
    
    if helm list -n "$namespace" | grep -q "$release_name"; then
        if helm uninstall "$release_name" --namespace "$namespace" --timeout "${timeout}s"; then
            log_success "Helm release $release_name uninstalled successfully"
            return 0
        else
            log_error "Failed to uninstall Helm release $release_name"
            return 1
        fi
    else
        log_warning "Helm release $release_name not found in namespace $namespace"
        return 0
    fi
}

# Check if Helm release exists
helm_release_exists() {
    local release_name="$1"
    local namespace="$2"
    
    if helm list -n "$namespace" | grep -q "$release_name"; then
        return 0
    else
        return 1
    fi
}

# Get Helm release status
helm_release_status() {
    local release_name="$1"
    local namespace="$2"
    
    helm status "$release_name" --namespace "$namespace" 2>/dev/null || echo "not-found"
}

# Validate YAML file
validate_yaml() {
    local yaml_file="$1"
    
    if [[ ! -f "$yaml_file" ]]; then
        log_error "YAML file not found: $yaml_file"
        return 1
    fi
    
    if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
        log_success "YAML file is valid: $yaml_file"
        return 0
    else
        log_error "YAML file is invalid: $yaml_file"
        return 1
    fi
}

# Process template variables in file
process_template() {
    local input_file="$1"
    local output_file="$2"
    
    log_info "Processing template: $input_file -> $output_file"
    
    if [[ ! -f "$input_file" ]]; then
        log_error "Template file not found: $input_file"
        return 1
    fi
    
    if envsubst < "$input_file" > "$output_file"; then
        log_success "Template processed successfully"
        return 0
    else
        log_error "Failed to process template"
        return 1
    fi
}

# Check AWS permissions (basic check)
check_aws_permissions() {
    log_info "Checking AWS permissions..."
    
    if ! check_command "aws" "AWS CLI is required"; then
        return 1
    fi
    
    # Try to get caller identity
    if aws sts get-caller-identity &> /dev/null; then
        local account_id
        account_id=$(aws sts get-caller-identity --query Account --output text)
        log_success "AWS permissions OK - Account: $account_id"
        return 0
    else
        log_error "AWS permissions check failed"
        return 1
    fi
}

# Check Azure permissions (basic check)
check_azure_permissions() {
    log_info "Checking Azure permissions..."
    
    if ! check_command "az" "Azure CLI is required"; then
        return 1
    fi
    
    # Try to get account info
    if az account show &> /dev/null; then
        local subscription_id
        subscription_id=$(az account show --query id --output tsv)
        log_success "Azure permissions OK - Subscription: $subscription_id"
        return 0
    else
        log_error "Azure permissions check failed"
        return 1
    fi
}

# Cleanup function for failed installations
cleanup_failed_installation() {
    local plugin_name="$1"
    local namespace="$2"
    
    log_warning "Cleaning up failed installation for $plugin_name..."
    
    # Remove Helm release if it exists
    helm_uninstall "$plugin_name" "$namespace" 2>/dev/null || true
    
    # Remove namespace if it's empty
    local resource_count
    resource_count=$(kubectl get all -n "$namespace" --no-headers 2>/dev/null | wc -l || echo "0")
    
    if [[ $resource_count -eq 0 ]]; then
        kubectl delete namespace "$namespace" --ignore-not-found=true
        log_success "Empty namespace $namespace removed"
    else
        log_warning "Namespace $namespace contains resources, keeping it"
    fi
}

# Print separator
print_separator() {
    echo "=============================================="
}

# Print plugin header
print_plugin_header() {
    local plugin_name="$1"
    local action="$2"
    
    print_separator
    echo "🔌 Plugin: $plugin_name"
    echo "🎯 Action: $action"
    echo "🌍 Environment: ${ENVIRONMENT:-unknown}"
    echo "☁️  Cloud: ${CLOUD_PROVIDER:-unknown}"
    echo "🎪 Cluster: ${CLUSTER_NAME:-unknown}"
    print_separator
}