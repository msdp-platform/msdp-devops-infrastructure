#!/bin/bash
set -euo pipefail

# Azure OIDC with AWS IAM Role Setup Script
# This script sets up cross-cloud authentication for Azure AKS to access AWS Route53

echo "🚀 Setting up Azure OIDC with AWS IAM Role for Route53 access"
echo "=============================================================="

# Configuration variables
AZURE_TENANT_ID="${AZURE_TENANT_ID:-}"
AZURE_SUBSCRIPTION_ID="ecd977ed-b8df-4eb6-9cba-98397e1b2491"
AWS_ACCOUNT_ID="319422413814"
AWS_REGION="eu-west-1"
RESOURCE_GROUP="rg-msdp-network-dev"
IDENTITY_NAME="id-aks-route53-access"
ROLE_NAME="AzureRoute53AccessRole"
POLICY_NAME="Route53AccessPolicy"
HOSTED_ZONE_ID="Z0581458B5QGVNLDPESN"
CLUSTER_NAME="aks-msdp-dev-01"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Please install Azure CLI."
        exit 1
    fi
    
    # Check AWS authentication
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI not authenticated. Please run 'aws configure' or set up credentials."
        exit 1
    fi
    
    # Check Azure authentication
    if ! az account show &> /dev/null; then
        log_error "Azure CLI not authenticated. Please run 'az login'."
        exit 1
    fi
    
    # Get Azure Tenant ID if not set
    if [[ -z "$AZURE_TENANT_ID" ]]; then
        AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
        log_info "Using Azure Tenant ID: $AZURE_TENANT_ID"
    fi
    
    log_success "Prerequisites check passed"
}

# Create AWS Route53 access policy
create_aws_policy() {
    log_info "Creating AWS Route53 access policy..."
    
    # Create policy document
    cat > /tmp/route53-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "route53:ListHostedZonesByName",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/${HOSTED_ZONE_ID}",
        "arn:aws:route53:::change/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    }
  ]
}
EOF
    
    # Create or update policy
    if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" &> /dev/null; then
        log_warning "Policy ${POLICY_NAME} already exists, updating..."
        aws iam create-policy-version \
            --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" \
            --policy-document file:///tmp/route53-policy.json \
            --set-as-default
    else
        aws iam create-policy \
            --policy-name "${POLICY_NAME}" \
            --policy-document file:///tmp/route53-policy.json \
            --description "Route53 access policy for Azure AKS External DNS"
    fi
    
    log_success "AWS Route53 policy created/updated"
}

# Create AWS OIDC Identity Provider
create_aws_oidc_provider() {
    log_info "Creating AWS OIDC Identity Provider..."
    
    local oidc_url="https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0"
    
    # Check if OIDC provider already exists
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0" &> /dev/null; then
        log_warning "OIDC provider already exists"
    else
        aws iam create-open-id-connect-provider \
            --url "${oidc_url}" \
            --thumbprint-list "626d44e704d1ceabe3bf0d53397464ac8080142c" \
            --client-id-list "api://AzureADTokenExchange"
        
        log_success "AWS OIDC Identity Provider created"
    fi
}

# Create Azure Managed Identity
create_azure_identity() {
    log_info "Creating Azure User-Assigned Managed Identity..."
    
    # Check if identity already exists
    if az identity show --resource-group "${RESOURCE_GROUP}" --name "${IDENTITY_NAME}" &> /dev/null; then
        log_warning "Azure identity ${IDENTITY_NAME} already exists"
    else
        az identity create \
            --resource-group "${RESOURCE_GROUP}" \
            --name "${IDENTITY_NAME}" \
            --location uksouth
        
        log_success "Azure Managed Identity created"
    fi
    
    # Get identity details
    IDENTITY_CLIENT_ID=$(az identity show \
        --resource-group "${RESOURCE_GROUP}" \
        --name "${IDENTITY_NAME}" \
        --query clientId -o tsv)
    
    IDENTITY_OBJECT_ID=$(az identity show \
        --resource-group "${RESOURCE_GROUP}" \
        --name "${IDENTITY_NAME}" \
        --query principalId -o tsv)
    
    log_info "Identity Client ID: ${IDENTITY_CLIENT_ID}"
    log_info "Identity Object ID: ${IDENTITY_OBJECT_ID}"
}

# Create AWS IAM Role with trust policy
create_aws_role() {
    log_info "Creating AWS IAM Role with trust policy..."
    
    # Create trust policy document
    cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0:sub": "${IDENTITY_OBJECT_ID}",
          "login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0:aud": "api://AzureADTokenExchange"
        }
      }
    }
  ]
}
EOF
    
    # Create or update role
    if aws iam get-role --role-name "${ROLE_NAME}" &> /dev/null; then
        log_warning "Role ${ROLE_NAME} already exists, updating trust policy..."
        aws iam update-assume-role-policy \
            --role-name "${ROLE_NAME}" \
            --policy-document file:///tmp/trust-policy.json
    else
        aws iam create-role \
            --role-name "${ROLE_NAME}" \
            --assume-role-policy-document file:///tmp/trust-policy.json \
            --description "Role for Azure AKS to access AWS Route53"
    fi
    
    # Attach policy to role
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    
    log_success "AWS IAM Role created/updated with Route53 policy attached"
}

# Get AKS OIDC Issuer URL
get_aks_oidc_issuer() {
    log_info "Getting AKS OIDC Issuer URL..."
    
    AKS_OIDC_ISSUER=$(az aks show \
        --resource-group "${RESOURCE_GROUP}" \
        --name "${CLUSTER_NAME}" \
        --query "oidcIssuerProfile.issuerUrl" -o tsv)
    
    if [[ -z "$AKS_OIDC_ISSUER" ]]; then
        log_error "AKS OIDC Issuer not found. Make sure OIDC is enabled on your AKS cluster."
        log_info "To enable OIDC on AKS cluster, run:"
        log_info "az aks update --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --enable-oidc-issuer"
        exit 1
    fi
    
    log_info "AKS OIDC Issuer: ${AKS_OIDC_ISSUER}"
}

# Create federated credentials
create_federated_credentials() {
    log_info "Creating federated credentials..."
    
    # External DNS federated credential
    if az identity federated-credential show \
        --name "external-dns-federated-credential" \
        --identity-name "${IDENTITY_NAME}" \
        --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
        log_warning "External DNS federated credential already exists"
    else
        az identity federated-credential create \
            --name "external-dns-federated-credential" \
            --identity-name "${IDENTITY_NAME}" \
            --resource-group "${RESOURCE_GROUP}" \
            --issuer "${AKS_OIDC_ISSUER}" \
            --subject "system:serviceaccount:external-dns-system:external-dns" \
            --audience "api://AzureADTokenExchange"
        
        log_success "External DNS federated credential created"
    fi
    
    # Cert-Manager federated credential
    if az identity federated-credential show \
        --name "cert-manager-federated-credential" \
        --identity-name "${IDENTITY_NAME}" \
        --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
        log_warning "Cert-Manager federated credential already exists"
    else
        az identity federated-credential create \
            --name "cert-manager-federated-credential" \
            --identity-name "${IDENTITY_NAME}" \
            --resource-group "${RESOURCE_GROUP}" \
            --issuer "${AKS_OIDC_ISSUER}" \
            --subject "system:serviceaccount:cert-manager:cert-manager" \
            --audience "api://AzureADTokenExchange"
        
        log_success "Cert-Manager federated credential created"
    fi
}

# Generate summary
generate_summary() {
    log_success "Setup completed successfully!"
    echo ""
    echo "📋 Summary of Created Resources:"
    echo "================================"
    echo ""
    echo "🔧 AWS Resources:"
    echo "  • OIDC Provider: arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0"
    echo "  • IAM Role: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
    echo "  • IAM Policy: arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    echo ""
    echo "🔧 Azure Resources:"
    echo "  • Managed Identity: ${IDENTITY_NAME}"
    echo "  • Client ID: ${IDENTITY_CLIENT_ID}"
    echo "  • Object ID: ${IDENTITY_OBJECT_ID}"
    echo "  • Federated Credentials: external-dns, cert-manager"
    echo ""
    echo "📝 Terraform Variables to Update:"
    echo "================================="
    echo ""
    echo "# Add to terraform.tfvars:"
    echo "aws_role_arn_for_azure = \"arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}\""
    echo "azure_workload_identity_client_id = \"${IDENTITY_CLIENT_ID}\""
    echo ""
    echo "📝 GitHub Secrets to Add:"
    echo "========================="
    echo ""
    echo "AWS_ROLE_ARN_FOR_AZURE = arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
    echo "AZURE_WORKLOAD_IDENTITY_CLIENT_ID = ${IDENTITY_CLIENT_ID}"
    echo ""
    echo "🧪 Test Commands:"
    echo "================"
    echo ""
    echo "# Test AWS role assumption (from Azure):"
    echo "aws sts assume-role-with-web-identity \\"
    echo "  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME} \\"
    echo "  --role-session-name test-session \\"
    echo "  --web-identity-token \$(cat /var/run/secrets/azure/tokens/azure-identity-token)"
    echo ""
    echo "🎉 Ready to deploy with Terraform!"
}

# Main execution
main() {
    check_prerequisites
    create_aws_policy
    create_aws_oidc_provider
    create_azure_identity
    create_aws_role
    get_aks_oidc_issuer
    create_federated_credentials
    generate_summary
    
    # Clean up temporary files
    rm -f /tmp/route53-policy.json /tmp/trust-policy.json
}

# Execute main function
main "$@"