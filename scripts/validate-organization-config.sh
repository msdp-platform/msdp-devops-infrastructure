#!/bin/bash
set -euo pipefail

# Organization Configuration Validation Script
# This script validates that organization-specific values are properly configured

echo "🔍 Validating Organization Configuration"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file paths
ORG_CONFIG="infrastructure/config/organization.yaml"
GLOBALS_CONFIG="infrastructure/config/globals.yaml"

# Validation results
ERRORS=0
WARNINGS=0

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ((WARNINGS++))
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ((ERRORS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if organization.yaml exists
echo ""
echo "📁 Checking Configuration Files"
echo "--------------------------------"

if [[ -f "$ORG_CONFIG" ]]; then
    print_status "OK" "Organization config found: $ORG_CONFIG"
else
    print_status "ERROR" "Organization config not found: $ORG_CONFIG"
    print_status "INFO" "Create it from: infrastructure/config/organization.yaml.template"
fi

if [[ -f "$GLOBALS_CONFIG" ]]; then
    print_status "OK" "Global config found: $GLOBALS_CONFIG"
else
    print_status "ERROR" "Global config not found: $GLOBALS_CONFIG"
fi

# Check for hardcoded values in critical files
echo ""
echo "🔍 Checking for Hardcoded Values"
echo "--------------------------------"

# Check for hardcoded domain
HARDCODED_DOMAINS=$(grep -r "aztech-msdp\.com" infrastructure/addons/terraform/modules/ --include="*.tf" | wc -l || true)
if [[ $HARDCODED_DOMAINS -gt 0 ]]; then
    print_status "WARN" "Found $HARDCODED_DOMAINS hardcoded domain references in Terraform modules"
    print_status "INFO" "These are now defaults - override with your organization's domain"
else
    print_status "OK" "No hardcoded domains found in Terraform modules"
fi

# Check for hardcoded AWS account ID
HARDCODED_AWS=$(grep -r "319422413814" infrastructure/addons/terraform/modules/ --include="*.tf" | wc -l || true)
if [[ $HARDCODED_AWS -gt 0 ]]; then
    print_status "WARN" "Found $HARDCODED_AWS hardcoded AWS account ID references"
else
    print_status "OK" "No hardcoded AWS account IDs found in modules"
fi

# Check for hardcoded Route53 zone ID
HARDCODED_ZONE=$(grep -r "Z0581458B5QGVNLDPESN" infrastructure/addons/terraform/modules/ --include="*.tf" | wc -l || true)
if [[ $HARDCODED_ZONE -gt 0 ]]; then
    print_status "WARN" "Found $HARDCODED_ZONE hardcoded Route53 zone ID references"
    print_status "INFO" "These are now defaults - override with your zone ID"
else
    print_status "OK" "No hardcoded Route53 zone IDs found in modules"
fi

# Check environment variables
echo ""
echo "🌍 Checking Environment Variables"
echo "--------------------------------"

# List of environment variables that can override defaults
ENV_VARS=(
    "ORG_NAME"
    "ORG_DOMAIN" 
    "ORG_EMAIL"
    "AWS_ACCOUNT_ID"
    "AZURE_SUBSCRIPTION_ID"
    "ROUTE53_ZONE_ID"
    "AWS_DEFAULT_REGION"
    "AZURE_DEFAULT_LOCATION"
)

for var in "${ENV_VARS[@]}"; do
    if [[ -n "${!var:-}" ]]; then
        print_status "OK" "$var is set: ${!var}"
    else
        print_status "INFO" "$var not set (will use default)"
    fi
done

# Check GitHub repository variables (if gh CLI is available)
echo ""
echo "🐙 Checking GitHub Repository Configuration"
echo "------------------------------------------"

if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        # Check repository variables
        REPO_VARS=$(gh variable list --json name,value 2>/dev/null || echo "[]")
        
        if [[ "$REPO_VARS" != "[]" ]]; then
            print_status "OK" "GitHub CLI authenticated and repository variables accessible"
            
            # Check for organization-specific variables
            REQUIRED_VARS=("ORG_DOMAIN" "ORG_EMAIL" "ORG_NAME" "AWS_ACCOUNT_ID" "AZURE_SUBSCRIPTION_ID" "ROUTE53_ZONE_ID")
            
            for var in "${REQUIRED_VARS[@]}"; do
                if echo "$REPO_VARS" | grep -q "$var"; then
                    print_status "OK" "$var repository variable found"
                else
                    print_status "WARN" "$var repository variable not found"
                    case $var in
                        "ORG_DOMAIN")
                            print_status "INFO" "Set with: gh variable set ORG_DOMAIN --body 'your-domain.com'"
                            ;;
                        "ORG_EMAIL")
                            print_status "INFO" "Set with: gh variable set ORG_EMAIL --body 'devops@your-domain.com'"
                            ;;
                        "ORG_NAME")
                            print_status "INFO" "Set with: gh variable set ORG_NAME --body 'your-org'"
                            ;;
                        "AWS_ACCOUNT_ID")
                            print_status "INFO" "Set with: gh variable set AWS_ACCOUNT_ID --body '123456789012'"
                            ;;
                        "AZURE_SUBSCRIPTION_ID")
                            print_status "INFO" "Set with: gh variable set AZURE_SUBSCRIPTION_ID --body 'your-subscription-id'"
                            ;;
                        "ROUTE53_ZONE_ID")
                            print_status "INFO" "Set with: gh variable set ROUTE53_ZONE_ID --body 'Z1234567890ABC'"
                            ;;
                    esac
                fi
            done
            
            # Check repository secrets
            echo ""
            echo "🔐 Checking Repository Secrets"
            REPO_SECRETS=$(gh secret list --json name 2>/dev/null || echo "[]")
            
            REQUIRED_SECRETS=("AZURE_CLIENT_ID" "AZURE_TENANT_ID" "AZURE_SUBSCRIPTION_ID" "AWS_ROLE_ARN_FOR_AZURE")
            
            for secret in "${REQUIRED_SECRETS[@]}"; do
                if echo "$REPO_SECRETS" | grep -q "$secret"; then
                    print_status "OK" "$secret repository secret found"
                else
                    print_status "WARN" "$secret repository secret not found"
                    print_status "INFO" "Add via GitHub repository settings → Secrets and variables → Actions"
                fi
            done
            
        else
            print_status "WARN" "No repository variables found"
        fi
    else
        print_status "WARN" "GitHub CLI not authenticated"
        print_status "INFO" "Run: gh auth login"
    fi
else
    print_status "INFO" "GitHub CLI not available - skipping repository variable check"
fi

# DNS Resolution Check
echo ""
echo "🌐 DNS Resolution Check"
echo "----------------------"

if [[ -n "${ORG_DOMAIN:-}" ]]; then
    if nslookup "$ORG_DOMAIN" &> /dev/null; then
        print_status "OK" "Domain $ORG_DOMAIN resolves correctly"
    else
        print_status "WARN" "Domain $ORG_DOMAIN does not resolve"
        print_status "INFO" "Check DNS configuration and nameservers"
    fi
else
    print_status "INFO" "ORG_DOMAIN not set - skipping DNS resolution check"
fi

# Cloud CLI Authentication Check
echo ""
echo "☁️  Cloud CLI Authentication"
echo "---------------------------"

# AWS CLI check
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        print_status "OK" "AWS CLI authenticated (Account: $AWS_ACCOUNT)"
        
        # Check Route53 access
        if aws route53 list-hosted-zones &> /dev/null; then
            print_status "OK" "AWS Route53 access confirmed"
        else
            print_status "WARN" "AWS Route53 access failed"
            print_status "INFO" "Check IAM permissions for Route53"
        fi
    else
        print_status "WARN" "AWS CLI not authenticated"
        print_status "INFO" "Run: aws configure"
    fi
else
    print_status "INFO" "AWS CLI not available"
fi

# Azure CLI check
if command -v az &> /dev/null; then
    if az account show &> /dev/null; then
        AZURE_SUBSCRIPTION=$(az account show --query name --output tsv 2>/dev/null)
        print_status "OK" "Azure CLI authenticated (Subscription: $AZURE_SUBSCRIPTION)"
        
        # Check resource group access
        if az group list &> /dev/null; then
            print_status "OK" "Azure resource group access confirmed"
        else
            print_status "WARN" "Azure resource group access failed"
            print_status "INFO" "Check Azure permissions"
        fi
    else
        print_status "WARN" "Azure CLI not authenticated"
        print_status "INFO" "Run: az login"
    fi
else
    print_status "INFO" "Azure CLI not available"
fi

# Terraform validation
echo ""
echo "🏗️  Terraform Validation"
echo "----------------------"

if command -v terraform &> /dev/null; then
    # Check Azure dev environment
    if [[ -d "infrastructure/addons/terraform/environments/azure-dev" ]]; then
        cd infrastructure/addons/terraform/environments/azure-dev
        if terraform fmt -check . &> /dev/null; then
            print_status "OK" "Azure dev Terraform formatting is correct"
        else
            print_status "WARN" "Azure dev Terraform needs formatting"
            print_status "INFO" "Run: terraform fmt"
        fi
        cd - > /dev/null
    fi
    
    # Check AWS dev environment
    if [[ -d "infrastructure/addons/terraform/environments/aws-dev" ]]; then
        cd infrastructure/addons/terraform/environments/aws-dev
        if terraform fmt -check . &> /dev/null; then
            print_status "OK" "AWS dev Terraform formatting is correct"
        else
            print_status "WARN" "AWS dev Terraform needs formatting"
            print_status "INFO" "Run: terraform fmt"
        fi
        cd - > /dev/null
    fi
else
    print_status "INFO" "Terraform not available - skipping validation"
fi

# Summary
echo ""
echo "📊 Validation Summary"
echo "===================="

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    print_status "OK" "All validations passed! Your configuration is ready for shipment."
elif [[ $ERRORS -eq 0 ]]; then
    print_status "WARN" "Validation completed with $WARNINGS warnings"
    echo ""
    echo "Your configuration is functional but could be improved."
    echo "Address the warnings above for optimal setup."
else
    print_status "ERROR" "Validation failed with $ERRORS errors and $WARNINGS warnings"
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi

echo ""
echo "🚀 Next Steps:"
echo "1. Review any warnings above"
echo "2. Set repository variables in GitHub (if using GitHub Actions)"
echo "3. Test with a dry-run deployment"
echo "4. Update documentation with your organization's values"

exit 0
