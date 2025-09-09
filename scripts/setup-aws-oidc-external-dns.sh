#!/bin/bash

# Setup AWS OIDC Provider and IAM Role for External DNS
# This script sets up the necessary AWS resources for External DNS to manage Route53

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
OIDC_PROVIDER_URL="eastus.oic.prod-aks.azure.com/a4474822-c84f-4bd1-bc35-baed17234c9f/e7abd138-540d-4eea-9d06-5b4a88562748"
ROLE_NAME="external-dns-role"
POLICY_NAME="external-dns-policy"

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

# Check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        print_status "Using AWS Account ID: $AWS_ACCOUNT_ID"
    fi
}

# Create OIDC Provider
create_oidc_provider() {
    print_status "Creating OIDC Provider..."
    
    # Check if OIDC provider already exists
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER_URL}" &> /dev/null; then
        print_warning "OIDC Provider already exists"
        return 0
    fi
    
    # Get the OIDC provider's thumbprint
    print_status "Getting OIDC provider thumbprint..."
    THUMBPRINT=$(echo | openssl s_client -servername ${OIDC_PROVIDER_URL} -showcerts -connect ${OIDC_PROVIDER_URL}:443 2>/dev/null | openssl x509 -fingerprint -noout | sed 's/://g' | cut -d= -f2)
    
    # Create the OIDC provider
    aws iam create-open-id-connect-provider \
        --url "https://${OIDC_PROVIDER_URL}" \
        --thumbprint-list "$THUMBPRINT" \
        --client-id-list "sts.amazonaws.com"
    
    print_success "OIDC Provider created successfully"
}

# Create IAM Policy
create_iam_policy() {
    print_status "Creating IAM Policy for External DNS..."
    
    # Check if policy already exists
    if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" &> /dev/null; then
        print_warning "IAM Policy already exists"
        return 0
    fi
    
    # Create the policy
    aws iam create-policy \
        --policy-name "$POLICY_NAME" \
        --policy-document file://external-dns-policy.json \
        --description "Policy for External DNS to manage Route53 records"
    
    print_success "IAM Policy created successfully"
}

# Create IAM Role
create_iam_role() {
    print_status "Creating IAM Role for External DNS..."
    
    # Update trust policy with actual AWS account ID
    sed "s/YOUR_AWS_ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" external-dns-trust-policy.json > external-dns-trust-policy-updated.json
    
    # Check if role already exists
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        print_warning "IAM Role already exists"
    else
        # Create the role
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://external-dns-trust-policy-updated.json \
            --description "Role for External DNS to manage Route53 records"
        
        print_success "IAM Role created successfully"
    fi
    
    # Attach the policy to the role
    print_status "Attaching policy to role..."
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    
    print_success "Policy attached to role successfully"
}

# Update External DNS service account
update_service_account() {
    print_status "Updating External DNS service account with IAM role annotation..."
    
    # Update the service account with the IAM role ARN
    kubectl annotate serviceaccount external-dns \
        -n external-dns \
        eks.amazonaws.com/role-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}" \
        --overwrite
    
    print_success "Service account updated with IAM role annotation"
}

# Restart External DNS
restart_external_dns() {
    print_status "Restarting External DNS to pick up new IAM role..."
    
    kubectl rollout restart deployment external-dns -n external-dns
    
    print_status "Waiting for External DNS to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/external-dns -n external-dns
    
    print_success "External DNS restarted successfully"
}

# Main execution
main() {
    print_status "Setting up AWS OIDC Provider and IAM Role for External DNS..."
    
    check_aws_cli
    create_oidc_provider
    create_iam_policy
    create_iam_role
    update_service_account
    restart_external_dns
    
    print_success "Setup completed successfully!"
    print_status "External DNS should now be able to manage Route53 records"
    
    # Clean up temporary files
    rm -f external-dns-trust-policy-updated.json
    
    print_status "You can now check External DNS logs with:"
    print_status "kubectl logs -f deployment/external-dns -n external-dns"
}

# Run main function
main "$@"
