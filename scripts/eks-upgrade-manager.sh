#!/bin/bash

# EKS Upgrade Manager Script
# This script automatically determines the deployment strategy and manages EKS upgrades

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLUSTER_NAME=""
TARGET_VERSION="1.32"
AUTO_UPGRADE=false
AWS_REGION="us-west-2"
ENVIRONMENT="dev"
ACTION="plan"

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

# Function to show usage
show_usage() {
    cat << EOF
EKS Upgrade Manager Script

Usage: $0 [OPTIONS]

OPTIONS:
    -c, --cluster-name NAME     Name of the existing EKS cluster (optional)
    -t, --target-version VER    Target Kubernetes version (default: 1.32)
    -a, --auto-upgrade          Automatically proceed with multi-version upgrades
    -r, --region REGION         AWS region (default: us-west-2)
    -e, --environment ENV       Environment (default: dev)
    -x, --action ACTION         Action: plan, apply, destroy (default: plan)
    -h, --help                  Show this help message

EXAMPLES:
    # Check upgrade plan for existing cluster
    $0 -c msdp-eks-dev -t 1.32

    # Fresh deployment with latest version
    $0 -t 1.32

    # Auto-upgrade existing cluster
    $0 -c msdp-eks-dev -t 1.32 -a

    # Apply the upgrade plan
    $0 -c msdp-eks-dev -t 1.32 -x apply

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -t|--target-version)
            TARGET_VERSION="$2"
            shift 2
            ;;
        -a|--auto-upgrade)
            AUTO_UPGRADE=true
            shift
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -x|--action)
            ACTION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION. Must be one of: plan, apply, destroy"
    exit 1
fi

# Function to check if cluster exists
check_cluster_exists() {
    if [[ -n "$CLUSTER_NAME" ]]; then
        print_status "Checking if cluster '$CLUSTER_NAME' exists..."
        if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
            print_success "Cluster '$CLUSTER_NAME' exists"
            return 0
        else
            print_warning "Cluster '$CLUSTER_NAME' does not exist"
            return 1
        fi
    else
        print_status "No cluster name provided - will perform fresh deployment"
        return 1
    fi
}

# Function to get current cluster version
get_current_version() {
    if [[ -n "$CLUSTER_NAME" ]]; then
        aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.version' --output text 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Function to determine deployment strategy
determine_strategy() {
    local current_version="$1"
    
    if [[ -z "$current_version" ]]; then
        echo "fresh"
    else
        # Convert versions to comparable format (e.g., 1.28 -> 128)
        local current_num=$(echo "$current_version" | tr -d '.')
        local target_num=$(echo "$TARGET_VERSION" | tr -d '.')
        
        if [[ $current_num -eq $target_num ]]; then
            echo "no_change"
        elif [[ $current_num -gt $target_num ]]; then
            echo "downgrade"
        elif [[ $((target_num - current_num)) -eq 1 ]]; then
            echo "single_upgrade"
        else
            echo "multi_upgrade"
        fi
    fi
}

# Function to get component versions for a given Kubernetes version
get_component_versions() {
    local k8s_version="$1"
    
    case "$k8s_version" in
        "1.28")
            echo "karpenter=0.37.0 aws_load_balancer_controller=1.6.2 cert_manager=v1.13.2 external_dns=1.13.1 prometheus=55.4.0 argocd=5.51.6 crossplane=1.14.1"
            ;;
        "1.29")
            echo "karpenter=0.38.0 aws_load_balancer_controller=1.7.0 cert_manager=v1.14.0 external_dns=1.14.0 prometheus=56.0.0 argocd=5.52.0 crossplane=1.15.0"
            ;;
        "1.30")
            echo "karpenter=0.39.0 aws_load_balancer_controller=1.7.1 cert_manager=v1.15.0 external_dns=1.15.0 prometheus=57.0.0 argocd=5.53.0 crossplane=1.16.0"
            ;;
        "1.31")
            echo "karpenter=0.40.0 aws_load_balancer_controller=1.8.0 cert_manager=v1.16.0 external_dns=1.16.0 prometheus=58.0.0 argocd=5.54.0 crossplane=1.17.0"
            ;;
        "1.32")
            echo "karpenter=0.41.0 aws_load_balancer_controller=1.8.1 cert_manager=v1.17.0 external_dns=1.17.0 prometheus=59.0.0 argocd=5.55.0 crossplane=1.18.0"
            ;;
        *)
            print_warning "Unknown Kubernetes version: $k8s_version, using default versions"
            echo "karpenter=0.37.0 aws_load_balancer_controller=1.6.2 cert_manager=v1.13.2 external_dns=1.13.1 prometheus=55.4.0 argocd=5.51.6 crossplane=1.14.1"
            ;;
    esac
}

# Function to create terraform.tfvars with upgrade plan
create_tfvars() {
    local strategy="$1"
    local current_version="$2"
    local target_version="$3"
    
    local tfvars_file="infrastructure/terraform/environments/$ENVIRONMENT/terraform.tfvars"
    
    print_status "Creating terraform.tfvars with upgrade plan..."
    
    # Get component versions for target version
    local component_versions=$(get_component_versions "$target_version")
    
    cat > "$tfvars_file" << EOF
# Terraform variables for $ENVIRONMENT environment
# Generated by EKS Upgrade Manager

# Cluster Configuration
cluster_name = "msdp-eks-$ENVIRONMENT"
aws_region   = "$AWS_REGION"
vpc_cidr     = "10.0.0.0/16"

# Kubernetes Configuration
kubernetes_version = "$target_version"
karpenter_version  = "$(echo $component_versions | grep -o 'karpenter=[^ ]*' | cut -d'=' -f2)"

# Component Versions (compatible with Kubernetes $target_version)
aws_load_balancer_controller_version = "$(echo $component_versions | grep -o 'aws_load_balancer_controller=[^ ]*' | cut -d'=' -f2)"
external_dns_version = "$(echo $component_versions | grep -o 'external_dns=[^ ]*' | cut -d'=' -f2)"
cert_manager_version = "$(echo $component_versions | grep -o 'cert_manager=[^ ]*' | cut -d'=' -f2)"
secrets_store_csi_version = "1.3.4"
secrets_store_csi_aws_provider_version = "0.3.4"
nginx_ingress_version = "4.8.3"
prometheus_version = "$(echo $component_versions | grep -o 'prometheus=[^ ]*' | cut -d'=' -f2)"
argocd_version = "$(echo $component_versions | grep -o 'argocd=[^ ]*' | cut -d'=' -f2)"
crossplane_version = "$(echo $component_versions | grep -o 'crossplane=[^ ]*' | cut -d'=' -f2)"
ack_s3_version = "1.1.0"
ack_rds_version = "1.1.0"
backstage_version = "0.1.0"

# Instance Types for Karpenter - Cost-optimized mixed architecture (ARM + x86)
karpenter_instance_types = [
  # ARM-based instances (Graviton) - Up to 40% better price/performance
  "t4g.medium", "t4g.large", "t4g.xlarge", "t4g.2xlarge", "t4g.4xlarge",
  "r6g.medium", "r6g.large", "r6g.xlarge", "r6g.2xlarge", "r6g.4xlarge",
  "m6g.medium", "m6g.large", "m6g.xlarge", "m6g.2xlarge", "m6g.4xlarge",
  "c6g.medium", "c6g.large", "c6g.xlarge", "c6g.2xlarge", "c6g.4xlarge",
  
  # x86-based instances - For cost comparison and availability
  "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge",
  "t3a.medium", "t3a.large", "t3a.xlarge", "t3a.2xlarge",
  "m5.medium", "m5.large", "m5.xlarge", "m5.2xlarge", "m5.4xlarge",
  "m5a.medium", "m5a.large", "m5a.xlarge", "m5a.2xlarge", "m5a.4xlarge",
  "r5.medium", "r5.large", "r5.xlarge", "r5.2xlarge", "r5.4xlarge",
  "r5a.medium", "r5a.large", "r5a.xlarge", "r5a.2xlarge", "r5a.4xlarge",
  "c5.medium", "c5.large", "c5.xlarge", "c5.2xlarge", "c5.4xlarge",
  "c5a.medium", "c5a.large", "c5a.xlarge", "c5a.2xlarge", "c5a.4xlarge"
]

# DNS and Certificate Configuration
domain_name            = "aztech-msdp.com"
create_route53_zone    = false
route53_zone_id        = "Z1234567890ABC"
create_acm_certificate = false
letsencrypt_email      = "admin@aztech-msdp.com"

# Upgrade Strategy Information
# Strategy: $strategy
# Current Version: $current_version
# Target Version: $target_version
# Generated: $(date)
EOF

    print_success "Created terraform.tfvars with upgrade plan"
}

# Function to run terraform
run_terraform() {
    local action="$1"
    local terraform_dir="infrastructure/terraform/environments/$ENVIRONMENT"
    
    print_status "Running terraform $action in $terraform_dir..."
    
    cd "$terraform_dir"
    
    case "$action" in
        "plan")
            terraform init
            terraform plan
            ;;
        "apply")
            terraform init
            terraform apply -auto-approve
            ;;
        "destroy")
            terraform init
            terraform destroy -auto-approve
            ;;
    esac
    
    cd - > /dev/null
}

# Main execution
main() {
    print_status "EKS Upgrade Manager starting..."
    print_status "Cluster: ${CLUSTER_NAME:-"<fresh deployment>"}"
    print_status "Target Version: $TARGET_VERSION"
    print_status "Auto Upgrade: $AUTO_UPGRADE"
    print_status "Action: $ACTION"
    
    # Check if cluster exists
    if check_cluster_exists; then
        current_version=$(get_current_version)
        print_status "Current version: $current_version"
    else
        current_version=""
        print_status "Fresh deployment"
    fi
    
    # Determine strategy
    strategy=$(determine_strategy "$current_version")
    print_status "Deployment strategy: $strategy"
    
    # Handle different strategies
    case "$strategy" in
        "fresh")
            print_success "Fresh deployment with Kubernetes $TARGET_VERSION"
            create_tfvars "$strategy" "" "$TARGET_VERSION"
            ;;
        "no_change")
            print_warning "Cluster is already at target version $TARGET_VERSION"
            exit 0
            ;;
        "downgrade")
            print_error "Downgrades are not supported. Current: $current_version, Target: $TARGET_VERSION"
            exit 1
            ;;
        "single_upgrade")
            print_success "Single version upgrade: $current_version -> $TARGET_VERSION"
            create_tfvars "$strategy" "$current_version" "$TARGET_VERSION"
            ;;
        "multi_upgrade")
            if [[ "$AUTO_UPGRADE" == "true" ]]; then
                print_warning "Multi-version upgrade: $current_version -> $TARGET_VERSION"
                print_warning "This will require multiple upgrade steps"
                create_tfvars "$strategy" "$current_version" "$TARGET_VERSION"
            else
                print_error "Multi-version upgrade requires --auto-upgrade flag"
                print_error "Upgrade path: $current_version -> $TARGET_VERSION"
                exit 1
            fi
            ;;
    esac
    
    # Run terraform
    if [[ "$ACTION" != "plan" ]] || [[ "$strategy" != "no_change" ]]; then
        run_terraform "$ACTION"
    fi
    
    print_success "EKS Upgrade Manager completed successfully!"
}

# Run main function
main "$@"
