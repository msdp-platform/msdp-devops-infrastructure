#!/bin/bash
set -euo pipefail

# Add Dev Branch OIDC Support
# This script adds federated identity credential for the dev branch to existing Azure OIDC setup

echo "🔐 Adding OIDC support for dev branch"
echo "===================================="

# Configuration
APP_NAME="GitHub-Actions-MSDP-DevOps"
REPO="msdp-platform/msdp-devops-infrastructure"

# Check if user is logged in to Azure
if ! az account show >/dev/null 2>&1; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

# Get App Registration ID
echo "🔍 Finding existing App Registration..."
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
    echo "❌ App Registration '$APP_NAME' not found!"
    echo "   Please run setup-azure-oidc.sh first to create the initial setup."
    exit 1
fi

echo "✅ Found App Registration: $APP_ID"

# Add federated identity credential for dev branch
echo "🔐 Adding federated identity credential for dev branch..."

az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"GitHub-Actions-Dev-Branch\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:ref:refs/heads/dev\",
    \"description\": \"GitHub Actions Dev Branch\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" 2>/dev/null && echo "✅ Dev branch credential added successfully!" || echo "⚠️  Credential may already exist"

# List all federated credentials to verify
echo ""
echo "📋 Current federated identity credentials:"
az ad app federated-credential list --id "$APP_ID" --query "[].{Name:name, Subject:subject}" -o table

echo ""
echo "🎉 Dev branch OIDC setup complete!"
echo "   You can now run GitHub Actions workflows on the dev branch."
