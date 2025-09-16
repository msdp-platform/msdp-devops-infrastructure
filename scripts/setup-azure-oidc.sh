#!/bin/bash
set -euo pipefail

# Azure OIDC Setup Script for GitHub Actions
# This script sets up the Azure App Registration and federated identity credentials

echo "🚀 Setting up Azure OIDC for GitHub Actions"
echo "============================================"

# Configuration
APP_NAME="GitHub-Actions-MSDP-DevOps"
REPO="msdp-platform/msdp-devops-infrastructure"

# Check if user is logged in to Azure
if ! az account show >/dev/null 2>&1; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

# Get current subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "📋 Current Azure Context:"
echo "   Subscription: $SUBSCRIPTION_ID"
echo "   Tenant: $TENANT_ID"
echo ""

# Check if App Registration already exists
echo "🔍 Checking for existing App Registration..."
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
    echo "📝 Creating new App Registration: $APP_NAME"
    APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
    echo "✅ Created App Registration with ID: $APP_ID"
    
    # Create Service Principal
    echo "👤 Creating Service Principal..."
    az ad sp create --id "$APP_ID" >/dev/null
    echo "✅ Created Service Principal"
else
    echo "✅ Found existing App Registration with ID: $APP_ID"
fi

# Get Service Principal Object ID
SP_OBJECT_ID=$(az ad sp list --display-name "$APP_NAME" --query "[0].id" -o tsv)
echo "   Service Principal Object ID: $SP_OBJECT_ID"

# Configure Federated Identity Credentials
echo ""
echo "🔐 Configuring Federated Identity Credentials..."

# For main branch (most common pattern)
echo "   Adding credential for main branch..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"GitHub-Actions-Main-Branch\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:ref:refs/heads/main\",
    \"description\": \"GitHub Actions Main Branch\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" 2>/dev/null || echo "   (Credential may already exist)"

# For pull requests
echo "   Adding credential for pull requests..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"GitHub-Actions-Pull-Requests\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:pull_request\",
    \"description\": \"GitHub Actions Pull Requests\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" 2>/dev/null || echo "   (Credential may already exist)"

# Optional: For specific environments (if you want to use GitHub environments later)
echo "   Adding credential for dev environment (optional)..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"GitHub-Actions-Dev-Environment\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:environment:dev\",
    \"description\": \"GitHub Actions Dev Environment\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" 2>/dev/null || echo "   (Credential may already exist)"

echo "✅ Federated identity credentials configured"

# Assign Azure permissions
echo ""
echo "🔑 Assigning Azure permissions..."
echo "   Assigning Contributor role to subscription..."

# Check if role assignment already exists
EXISTING_ASSIGNMENT=$(az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query "[0].id" -o tsv)

if [ -z "$EXISTING_ASSIGNMENT" ] || [ "$EXISTING_ASSIGNMENT" = "null" ]; then
    az role assignment create \
      --assignee "$SP_OBJECT_ID" \
      --role "Contributor" \
      --scope "/subscriptions/$SUBSCRIPTION_ID" >/dev/null
    echo "✅ Assigned Contributor role"
else
    echo "✅ Contributor role already assigned"
fi

# Display configuration summary
echo ""
echo "📊 Configuration Summary"
echo "========================"
echo "App Registration Name: $APP_NAME"
echo "Application (Client) ID: $APP_ID"
echo "Tenant ID: $TENANT_ID"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Service Principal Object ID: $SP_OBJECT_ID"

# Display GitHub Secrets to configure
echo ""
echo "🔐 GitHub Secrets to Configure"
echo "==============================="
echo "Go to: https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "Add these secrets:"
echo "AZURE_CLIENT_ID = $APP_ID"
echo "AZURE_TENANT_ID = $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"

# Display federated credentials
echo ""
echo "🔍 Configured Federated Identity Credentials:"
az ad app federated-credential list --id "$APP_ID" --query "[].{name:name, subject:subject}" -o table

# Test instructions
echo ""
echo "🧪 Testing Instructions"
echo "======================="
echo "1. Configure the GitHub secrets above"
echo "2. Test the network workflow:"
echo "   gh workflow run azure-network.yml -f action=plan -f environment=dev"
echo ""
echo "3. If you get authentication errors, check:"
echo "   - GitHub secrets are correctly set"
echo "   - Repository name matches: $REPO"
echo "   - Workflow is running from main branch or PR"

echo ""
echo "✅ Azure OIDC setup completed successfully!"