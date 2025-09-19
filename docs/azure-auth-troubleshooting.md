# Azure Authentication Troubleshooting

## Current Error
```
AADSTS700213: No matching federated identity record found for presented assertion subject 'repo:msdp-platform/msdp-devops-infrastructure:environment:dev'
```

## Quick Fix

### Option 1: Run the Setup Script (Recommended)
```bash
# Make the script executable
chmod +x scripts/setup-azure-oidc.sh

# Run the setup script
./scripts/setup-azure-oidc.sh
```

This script will:
- Create or find the Azure App Registration
- Configure federated identity credentials for main branch and PRs
- Assign necessary Azure permissions
- Show you the GitHub secrets to configure

### Option 2: Manual Azure CLI Commands

```bash
# 1. Create App Registration (if not exists)
APP_ID=$(az ad app create --display-name "GitHub-Actions-MSDP-DevOps" --query appId -o tsv)
az ad sp create --id $APP_ID

# 2. Add federated credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Main-Branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:ref:refs/heads/main",
    "description": "GitHub Actions Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 3. Assign permissions
SP_OBJECT_ID=$(az ad sp list --display-name "GitHub-Actions-MSDP-DevOps" --query "[0].id" -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# 4. Get values for GitHub secrets
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

### Option 3: Update Workflows (Temporary Fix)

If you want to test immediately without setting up environments, the workflows have been updated to not use GitHub environments. This means the federated credential should match:

```
Subject: repo:msdp-platform/msdp-devops-infrastructure:ref:refs/heads/main
```

Instead of:
```
Subject: repo:msdp-platform/msdp-devops-infrastructure:environment:dev
```

## GitHub Secrets Configuration

After running the setup, add these secrets to your GitHub repository:

1. Go to: https://github.com/msdp-platform/msdp-devops-infrastructure/settings/secrets/actions

2. Add these secrets:
   - `AZURE_CLIENT_ID` = Application ID from Azure App Registration
   - `AZURE_TENANT_ID` = Your Azure Tenant ID  
   - `AZURE_SUBSCRIPTION_ID` = Your Azure Subscription ID
   - `AWS_ROLE_ARN` = Your AWS IAM Role ARN (for S3 backend)
   - `AWS_ACCOUNT_ID` = Your AWS Account ID

## Testing the Fix

After configuring the secrets:

```bash
# Test the network workflow
gh workflow run azure-network.yml -f action=plan -f environment=dev
```

## Common Issues and Solutions

### 1. Wrong Repository Name
**Error**: Subject mismatch
**Solution**: Ensure the repository name in federated credential matches exactly: `msdp-platform/msdp-devops-infrastructure`

### 2. Wrong Branch
**Error**: Subject mismatch for branch
**Solution**: Ensure you're running from `main` branch or add credentials for other branches

### 3. Missing GitHub Secrets
**Error**: Authentication failed
**Solution**: Verify all required secrets are set in GitHub repository settings

### 4. Insufficient Azure Permissions
**Error**: Authorization failed
**Solution**: Ensure the service principal has Contributor role on the subscription or resource group

### 5. Wrong Audience
**Error**: Invalid audience
**Solution**: Ensure audience is set to `["api://AzureADTokenExchange"]`

## Verification Commands

```bash
# Check federated credentials
az ad app federated-credential list --id $APP_ID

# Check role assignments
az role assignment list --assignee $SP_OBJECT_ID

# Check current Azure context
az account show
```

## Alternative: Use Service Principal with Secret

If OIDC continues to cause issues, you can temporarily use a service principal with a client secret:

```bash
# Create client secret
SECRET=$(az ad app credential reset --id $APP_ID --query password -o tsv)

# Add to GitHub secrets
echo "AZURE_CLIENT_SECRET: $SECRET"
```

Then update workflows to use client secret instead of OIDC by removing `ARM_USE_OIDC: "true"` and adding the secret.

## Next Steps

1. Run the setup script: `./scripts/setup-azure-oidc.sh`
2. Configure GitHub secrets as shown in the output
3. Test the workflow: `gh workflow run azure-network.yml -f action=plan`
4. If successful, proceed with infrastructure deployment

The setup script provides the most reliable way to configure everything correctly.