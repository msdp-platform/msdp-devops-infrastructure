#!/bin/bash
set -euo pipefail

# New Organization Setup Automation Script
# This script helps new organizations set up the infrastructure quickly

echo "🚀 MSDP DevOps Infrastructure - New Organization Setup"
echo "====================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Function to prompt for input
prompt_input() {
    local prompt=$1
    local default=$2
    local var_name=$3
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " input
        input=${input:-$default}
    else
        read -p "$prompt: " input
    fi
    
    eval "$var_name='$input'"
}

# Function to validate input
validate_input() {
    local value=$1
    local type=$2
    
    case $type in
        "domain")
            if [[ ! "$value" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
                return 1
            fi
            ;;
        "email")
            if [[ ! "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                return 1
            fi
            ;;
        "aws_account")
            if [[ ! "$value" =~ ^[0-9]{12}$ ]]; then
                return 1
            fi
            ;;
    esac
    return 0
}

echo ""
echo "📋 Organization Information"
echo "========================="

# Collect organization information
prompt_input "Organization name (lowercase, no spaces)" "" ORG_NAME
prompt_input "Organization domain" "" ORG_DOMAIN
prompt_input "DevOps team email" "" ORG_EMAIL
prompt_input "GitHub organization" "" ORG_GITHUB

# Validate inputs
if ! validate_input "$ORG_DOMAIN" "domain"; then
    print_status "ERROR" "Invalid domain format"
    exit 1
fi

if ! validate_input "$ORG_EMAIL" "email"; then
    print_status "ERROR" "Invalid email format"
    exit 1
fi

echo ""
echo "☁️  Cloud Account Information"
echo "============================"

# Cloud provider selection
echo "Which cloud providers will you use?"
echo "1) AWS only"
echo "2) Azure only"
echo "3) Both AWS and Azure"
read -p "Select option [1-3]: " cloud_choice

case $cloud_choice in
    1)
        USE_AWS=true
        USE_AZURE=false
        ;;
    2)
        USE_AWS=false
        USE_AZURE=true
        ;;
    3)
        USE_AWS=true
        USE_AZURE=true
        ;;
    *)
        print_status "ERROR" "Invalid selection"
        exit 1
        ;;
esac

# AWS configuration
if [[ "$USE_AWS" == "true" ]]; then
    prompt_input "AWS Account ID (12 digits)" "" AWS_ACCOUNT_ID
    prompt_input "AWS Default Region" "us-east-1" AWS_REGION
    
    if ! validate_input "$AWS_ACCOUNT_ID" "aws_account"; then
        print_status "ERROR" "Invalid AWS Account ID format"
        exit 1
    fi
fi

# Azure configuration
if [[ "$USE_AZURE" == "true" ]]; then
    prompt_input "Azure Subscription ID" "" AZURE_SUBSCRIPTION_ID
    prompt_input "Azure Default Location" "eastus" AZURE_LOCATION
fi

# DNS configuration
prompt_input "Route53 Hosted Zone ID (if using Route53)" "" HOSTED_ZONE_ID

echo ""
echo "🏗️  Organization Type"
echo "==================="

echo "What type of organization are you?"
echo "1) Startup (cost-optimized, simple setup)"
echo "2) Enterprise (multi-cloud, compliance-focused)"
echo "3) SaaS Company (scalable, multi-region)"
echo "4) Custom (manual configuration)"
read -p "Select option [1-4]: " org_type

case $org_type in
    1)
        TEMPLATE="startup-example"
        ;;
    2)
        TEMPLATE="enterprise-example"
        ;;
    3)
        TEMPLATE="saas-example"
        ;;
    4)
        TEMPLATE="custom"
        ;;
    *)
        print_status "ERROR" "Invalid selection"
        exit 1
        ;;
esac

echo ""
echo "📝 Configuration Summary"
echo "======================="
echo "Organization: $ORG_NAME"
echo "Domain: $ORG_DOMAIN"
echo "Email: $ORG_EMAIL"
echo "GitHub Org: $ORG_GITHUB"
if [[ "$USE_AWS" == "true" ]]; then
    echo "AWS Account: $AWS_ACCOUNT_ID"
    echo "AWS Region: $AWS_REGION"
fi
if [[ "$USE_AZURE" == "true" ]]; then
    echo "Azure Subscription: $AZURE_SUBSCRIPTION_ID"
    echo "Azure Location: $AZURE_LOCATION"
fi
echo "Template: $TEMPLATE"

echo ""
read -p "Continue with this configuration? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    print_status "INFO" "Setup cancelled"
    exit 0
fi

echo ""
echo "🔧 Setting up configuration..."
echo "============================="

# Create organization.yaml
print_status "INFO" "Creating organization.yaml..."

cat > infrastructure/config/organization.yaml << EOF
# $ORG_NAME Organization Configuration
# Generated by setup-new-organization.sh

organization:
  name: "$ORG_NAME"
  domain: "$ORG_DOMAIN"
  email: "$ORG_EMAIL"
  github_org: "$ORG_GITHUB"

cloud_accounts:
EOF

if [[ "$USE_AWS" == "true" ]]; then
    cat >> infrastructure/config/organization.yaml << EOF
  aws:
    account_id: "$AWS_ACCOUNT_ID"
    default_region: "$AWS_REGION"
    regions:
      primary: "$AWS_REGION"
EOF
else
    cat >> infrastructure/config/organization.yaml << EOF
  aws:
    account_id: ""
    default_region: ""
EOF
fi

if [[ "$USE_AZURE" == "true" ]]; then
    cat >> infrastructure/config/organization.yaml << EOF
  
  azure:
    subscription_id: "$AZURE_SUBSCRIPTION_ID"
    default_location: "$AZURE_LOCATION"
    locations:
      primary: "$AZURE_LOCATION"
EOF
else
    cat >> infrastructure/config/organization.yaml << EOF
  
  azure:
    subscription_id: ""
    default_location: ""
EOF
fi

cat >> infrastructure/config/organization.yaml << EOF

dns:
  provider: "route53"
  route53:
    zone_id: "$HOSTED_ZONE_ID"

registries:
  ghcr: "ghcr.io/$ORG_GITHUB"
  default: "ghcr"

naming:
  prefix: "$ORG_NAME"
  environments:
    - "dev"
    - "prod"
  cluster_pattern: "{prefix}-{cloud}-{env}"

defaults:
  kubernetes_version: "1.31.2"
  vm_sizes:
    aws:
      small: "t3.medium"
      medium: "t3.large"
      large: "m5.large"
    azure:
      small: "Standard_D2s_v3"
      medium: "Standard_D4s_v3"
      large: "Standard_D8s_v3"

security:
  sign_images: false
  vulnerability_scanning: true
  network_policies: true
EOF

print_status "OK" "organization.yaml created"

# Generate GitHub setup commands
print_status "INFO" "Generating GitHub setup commands..."

cat > setup-github-vars.sh << EOF
#!/bin/bash
# GitHub Repository Setup Commands
# Run these commands to set up your GitHub repository

echo "Setting up GitHub repository variables..."

gh variable set ORG_NAME --body "$ORG_NAME"
gh variable set ORG_DOMAIN --body "$ORG_DOMAIN"
gh variable set ORG_EMAIL --body "$ORG_EMAIL"
gh variable set ORG_GITHUB --body "$ORG_GITHUB"
EOF

if [[ "$USE_AWS" == "true" ]]; then
    cat >> setup-github-vars.sh << EOF
gh variable set AWS_ACCOUNT_ID --body "$AWS_ACCOUNT_ID"
gh variable set AWS_DEFAULT_REGION --body "$AWS_REGION"
EOF
fi

if [[ "$USE_AZURE" == "true" ]]; then
    cat >> setup-github-vars.sh << EOF
gh variable set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID"
gh variable set AZURE_DEFAULT_LOCATION --body "$AZURE_LOCATION"
EOF
fi

if [[ -n "$HOSTED_ZONE_ID" ]]; then
    cat >> setup-github-vars.sh << EOF
gh variable set ROUTE53_ZONE_ID --body "$HOSTED_ZONE_ID"
EOF
fi

cat >> setup-github-vars.sh << EOF

echo "✅ GitHub variables set successfully!"
echo ""
echo "⚠️  Don't forget to add these secrets manually:"
EOF

if [[ "$USE_AWS" == "true" ]]; then
    cat >> setup-github-vars.sh << EOF
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
EOF
fi

if [[ "$USE_AZURE" == "true" ]]; then
    cat >> setup-github-vars.sh << EOF
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_CLIENT_SECRET"
echo "   - AZURE_TENANT_ID"
echo "   - AZURE_SUBSCRIPTION_ID"
EOF
fi

cat >> setup-github-vars.sh << EOF
echo ""
echo "Add secrets at: https://github.com/$ORG_GITHUB/$(basename $(pwd))/settings/secrets/actions"
EOF

chmod +x setup-github-vars.sh
print_status "OK" "setup-github-vars.sh created"

echo ""
echo "🎉 Setup Complete!"
echo "================="
print_status "OK" "Configuration files created successfully"
print_status "INFO" "Next steps:"
echo "   1. Run: ./setup-github-vars.sh"
echo "   2. Add secrets to GitHub repository"
echo "   3. Run: ./scripts/validate-organization-config.sh"
echo "   4. Follow the deployment guide for your organization type"

if [[ "$TEMPLATE" != "custom" ]]; then
    print_status "INFO" "Check examples/$TEMPLATE/ for specific guidance"
fi

echo ""
print_status "INFO" "Happy deploying! 🚀"
