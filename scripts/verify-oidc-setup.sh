#!/bin/bash
set -euo pipefail

# Verification Script for Azure OIDC with AWS IAM Role Setup
# This script verifies that the cross-cloud authentication is working correctly

echo "🔍 Verifying Azure OIDC with AWS IAM Role Setup"
echo "==============================================="

# Configuration variables
AZURE_TENANT_ID="${AZURE_TENANT_ID:-$(az account show --query tenantId -o tsv)}"
AZURE_SUBSCRIPTION_ID="ecd977ed-b8df-4eb6-9cba-98397e1b2491"
AWS_ACCOUNT_ID="319422413814"
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

# Verify AWS resources
verify_aws_resources() {
    log_info "Verifying AWS resources..."
    
    # Check OIDC Provider
    if aws iam get-open-id-connect-provider \
        --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0" &> /dev/null; then
        log_success "AWS OIDC Provider exists"
    else
        log_error "AWS OIDC Provider not found"
        return 1
    fi
    
    # Check IAM Role
    if aws iam get-role --role-name "${ROLE_NAME}" &> /dev/null; then
        log_success "AWS IAM Role exists"
        
        # Check trust policy
        TRUST_POLICY=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.AssumeRolePolicyDocument')
        if echo "$TRUST_POLICY" | grep -q "login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0"; then
            log_success "Trust policy correctly configured for Azure"
        else
            log_error "Trust policy not configured for Azure"
            return 1
        fi
    else
        log_error "AWS IAM Role not found"
        return 1
    fi
    
    # Check IAM Policy
    if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}" &> /dev/null; then
        log_success "AWS IAM Policy exists"
        
        # Check if policy is attached to role
        if aws iam list-attached-role-policies --role-name "${ROLE_NAME}" | grep -q "${POLICY_NAME}"; then
            log_success "Policy attached to role"
        else
            log_error "Policy not attached to role"
            return 1
        fi
    else
        log_error "AWS IAM Policy not found"
        return 1
    fi
    
    # Check Route53 hosted zone
    if aws route53 get-hosted-zone --id "${HOSTED_ZONE_ID}" &> /dev/null; then
        log_success "Route53 hosted zone accessible"
    else
        log_error "Route53 hosted zone not accessible"
        return 1
    fi
}

# Verify Azure resources
verify_azure_resources() {
    log_info "Verifying Azure resources..."
    
    # Check Managed Identity
    if az identity show --resource-group "${RESOURCE_GROUP}" --name "${IDENTITY_NAME}" &> /dev/null; then
        log_success "Azure Managed Identity exists"
        
        # Get identity details
        IDENTITY_CLIENT_ID=$(az identity show \
            --resource-group "${RESOURCE_GROUP}" \
            --name "${IDENTITY_NAME}" \
            --query clientId -o tsv)
        
        log_info "Identity Client ID: ${IDENTITY_CLIENT_ID}"
    else
        log_error "Azure Managed Identity not found"
        return 1
    fi
    
    # Check AKS cluster OIDC
    AKS_OIDC_ISSUER=$(az aks show \
        --resource-group "${RESOURCE_GROUP}" \
        --name "${CLUSTER_NAME}" \
        --query "oidcIssuerProfile.issuerUrl" -o tsv)
    
    if [[ -n "$AKS_OIDC_ISSUER" ]]; then
        log_success "AKS OIDC Issuer configured: ${AKS_OIDC_ISSUER}"
    else
        log_error "AKS OIDC Issuer not configured"
        log_info "Run: az aks update --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --enable-oidc-issuer"
        return 1
    fi
    
    # Check federated credentials
    if az identity federated-credential show \
        --name "external-dns-federated-credential" \
        --identity-name "${IDENTITY_NAME}" \
        --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
        log_success "External DNS federated credential exists"
    else
        log_error "External DNS federated credential not found"
        return 1
    fi
    
    if az identity federated-credential show \
        --name "cert-manager-federated-credential" \
        --identity-name "${IDENTITY_NAME}" \
        --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
        log_success "Cert-Manager federated credential exists"
    else
        log_error "Cert-Manager federated credential not found"
        return 1
    fi
}

# Test OIDC connectivity
test_oidc_connectivity() {
    log_info "Testing OIDC connectivity..."
    
    # Test Azure AD OIDC endpoint
    OIDC_URL="https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0/.well-known/openid_configuration"
    
    if curl -s --fail "${OIDC_URL}" > /dev/null; then
        log_success "Azure AD OIDC endpoint accessible"
    else
        log_error "Azure AD OIDC endpoint not accessible"
        return 1
    fi
    
    # Test AKS OIDC endpoint
    if [[ -n "${AKS_OIDC_ISSUER:-}" ]]; then
        AKS_OIDC_CONFIG="${AKS_OIDC_ISSUER}/.well-known/openid_configuration"
        
        if curl -s --fail "${AKS_OIDC_CONFIG}" > /dev/null; then
            log_success "AKS OIDC endpoint accessible"
        else
            log_error "AKS OIDC endpoint not accessible"
            return 1
        fi
    fi
}

# Generate test deployment
generate_test_deployment() {
    log_info "Generating test deployment manifest..."
    
    cat > /tmp/test-external-dns.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns-test
  namespace: default
  annotations:
    azure.workload.identity/client-id: "${IDENTITY_CLIENT_ID}"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns-test
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: external-dns-test
  template:
    metadata:
      labels:
        app: external-dns-test
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: external-dns-test
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.14.0
        args:
        - --source=service
        - --provider=aws
        - --aws-zone-type=public
        - --domain-filter=aztech-msdp.com
        - --txt-owner-id=test-external-dns
        - --policy=sync
        - --registry=txt
        - --log-level=debug
        env:
        - name: AWS_ROLE_ARN
          value: "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
        - name: AWS_WEB_IDENTITY_TOKEN_FILE
          value: "/var/run/secrets/azure/tokens/azure-identity-token"
        - name: AWS_REGION
          value: "eu-west-1"
        volumeMounts:
        - name: azure-identity-token
          mountPath: /var/run/secrets/azure/tokens
          readOnly: true
      volumes:
      - name: azure-identity-token
        projected:
          sources:
          - serviceAccountToken:
              path: azure-identity-token
              audience: api://AzureADTokenExchange
              expirationSeconds: 3600
EOF
    
    log_success "Test deployment manifest created at /tmp/test-external-dns.yaml"
    log_info "To test, run: kubectl apply -f /tmp/test-external-dns.yaml"
    log_info "Then check logs: kubectl logs -l app=external-dns-test"
}

# Check Terraform configuration
check_terraform_config() {
    log_info "Checking Terraform configuration..."
    
    TERRAFORM_FILE="infrastructure/addons/terraform/environments/azure-dev/terraform.tfvars"
    
    if [[ -f "$TERRAFORM_FILE" ]]; then
        if grep -q "aws_role_arn_for_azure" "$TERRAFORM_FILE"; then
            log_success "Terraform configuration has aws_role_arn_for_azure"
        else
            log_warning "Terraform configuration missing aws_role_arn_for_azure"
            log_info "Add: aws_role_arn_for_azure = \"arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}\""
        fi
    else
        log_warning "Terraform configuration file not found: $TERRAFORM_FILE"
    fi
}

# Generate final report
generate_report() {
    echo ""
    log_success "Verification completed!"
    echo ""
    echo "📋 Setup Summary:"
    echo "================="
    echo ""
    echo "🔧 AWS Resources:"
    echo "  • OIDC Provider: ✅ Configured"
    echo "  • IAM Role: ✅ ${ROLE_NAME}"
    echo "  • IAM Policy: ✅ ${POLICY_NAME}"
    echo "  • Route53 Zone: ✅ ${HOSTED_ZONE_ID}"
    echo ""
    echo "🔧 Azure Resources:"
    echo "  • Managed Identity: ✅ ${IDENTITY_NAME}"
    echo "  • Client ID: ${IDENTITY_CLIENT_ID}"
    echo "  • AKS OIDC: ✅ Enabled"
    echo "  • Federated Credentials: ✅ Configured"
    echo ""
    echo "🚀 Next Steps:"
    echo "=============="
    echo ""
    echo "1. Update GitHub Secrets:"
    echo "   AWS_ROLE_ARN_FOR_AZURE = arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
    echo "   AZURE_WORKLOAD_IDENTITY_CLIENT_ID = ${IDENTITY_CLIENT_ID}"
    echo ""
    echo "2. Update Terraform variables:"
    echo "   aws_role_arn_for_azure = \"arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}\""
    echo ""
    echo "3. Deploy with Terraform:"
    echo "   GitHub Actions → k8s-addons-terraform.yml"
    echo "   cloud_provider: azure"
    echo "   action: plan"
    echo ""
    echo "4. Test deployment available at: /tmp/test-external-dns.yaml"
    echo ""
    echo "🎉 Azure OIDC with AWS IAM Role setup is ready!"
}

# Main execution
main() {
    local exit_code=0
    
    verify_aws_resources || exit_code=1
    verify_azure_resources || exit_code=1
    test_oidc_connectivity || exit_code=1
    generate_test_deployment
    check_terraform_config
    
    if [[ $exit_code -eq 0 ]]; then
        generate_report
    else
        log_error "Verification failed. Please check the errors above."
        exit 1
    fi
}

# Execute main function
main "$@"