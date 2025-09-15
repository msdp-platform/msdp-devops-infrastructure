# Azure OIDC Setup Guide

## Issue
The GitHub Actions workflow is failing with:
```
AADSTS700213: No matching federated identity record found for presented assertion subject 'repo:msdp-platform/msdp-devops-infrastructure:environment:dev'
```

This means the Azure App Registration doesn't have the correct federated identity credential configured.

## Solution

### Step 1: Create Azure App Registration (if not exists)

```bash
# Create App Registration
az ad app create --display-name "GitHub-Actions-MSDP-DevOps"

# Get the Application (Client) ID
APP_ID=$(az ad app list --display-name "GitHub-Actions-MSDP-DevOps" --query "[0].appId" -o tsv)
echo "Application ID: $APP_ID"

# Create Service Principal
az ad sp create --id $APP_ID

# Get Service Principal Object ID
SP_OBJECT_ID=$(az ad sp list --display-name "GitHub-Actions-MSDP-DevOps" --query "[0].id" -o tsv)
echo "Service Principal Object ID: $SP_OBJECT_ID"
```

### Step 2: Configure Federated Identity Credentials

You need to add federated identity credentials for each environment and workflow pattern.

#### For Environment-based Workflows (Current Issue)

```bash
# For 'dev' environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Dev-Environment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:environment:dev",
    "description": "GitHub Actions Dev Environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For 'staging' environment (future)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Staging-Environment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:environment:staging",
    "description": "GitHub Actions Staging Environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For 'prod' environment (future)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Prod-Environment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:environment:prod",
    "description": "GitHub Actions Prod Environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### For Branch-based Workflows (Alternative)

If you prefer branch-based authentication instead of environment-based:

```bash
# For main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Main-Branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:ref:refs/heads/main",
    "description": "GitHub Actions Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Pull-Requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:pull_request",
    "description": "GitHub Actions Pull Requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 3: Assign Azure Permissions

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Assign Contributor role to the Service Principal
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Optional: Assign specific resource group permissions instead
# az role assignment create \
#   --assignee $SP_OBJECT_ID \
#   --role "Contributor" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-msdp-network-dev"
```

### Step 4: Update GitHub Secrets

Add these secrets to your GitHub repository:

1. Go to: `https://github.com/msdp-platform/msdp-devops-infrastructure/settings/secrets/actions`

2. Add the following secrets:

```
AZURE_CLIENT_ID = <Application ID from Step 1>
AZURE_TENANT_ID = <Your Azure Tenant ID>
AZURE_SUBSCRIPTION_ID = <Your Azure Subscription ID>
```

To get these values:
```bash
# Get Tenant ID
az account show --query tenantId -o tsv

# Get Subscription ID
az account show --query id -o tsv

# Application ID (from Step 1)
echo $APP_ID
```

### Step 5: Verify Configuration

```bash
# List all federated credentials
az ad app federated-credential list --id $APP_ID --query "[].{name:name, subject:subject}" -o table

# Verify role assignments
az role assignment list --assignee $SP_OBJECT_ID --query "[].{role:roleDefinitionName, scope:scope}" -o table
```

## Alternative: Update Workflows to Not Use Environments

If you prefer not to use GitHub environments, update your workflows:

### Option 1: Remove Environment from Workflows

```yaml
# In .github/workflows/azure-network.yml
jobs:
  network:
    runs-on: ubuntu-latest
    # Remove this line: environment: ${{ github.event.inputs.environment || 'dev' }}
    
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_USE_OIDC: "true"
```

Then add a branch-based federated credential:
```bash
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHub-Actions-Main-Branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:ref:refs/heads/main",
    "description": "GitHub Actions Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Option 2: Create GitHub Environments

1. Go to: `https://github.com/msdp-platform/msdp-devops-infrastructure/settings/environments`
2. Click "New environment"
3. Create environments: `dev`, `staging`, `prod`
4. Configure protection rules as needed

## Testing the Fix

After configuring the federated identity credentials:

```bash
# Test the workflow
gh workflow run azure-network.yml -f action=plan -f environment=dev
```

## Troubleshooting

### Check Current Configuration
```bash
# List federated credentials
az ad app federated-credential list --id $APP_ID

# Check role assignments
az role assignment list --assignee $SP_OBJECT_ID
```

### Common Issues

1. **Wrong Subject Format**: Ensure the subject matches exactly:
   - Environment: `repo:ORG/REPO:environment:ENV_NAME`
   - Branch: `repo:ORG/REPO:ref:refs/heads/BRANCH_NAME`
   - PR: `repo:ORG/REPO:pull_request`

2. **Missing Audience**: Must be `["api://AzureADTokenExchange"]`

3. **Wrong Issuer**: Must be `https://token.actions.githubusercontent.com`

4. **Insufficient Permissions**: Service Principal needs appropriate Azure permissions

### Verify Token Claims

You can check what GitHub is sending by adding this to your workflow:
```yaml
- name: Debug OIDC Token
  run: |
    echo "GitHub Token Claims:"
    echo "Repository: ${{ github.repository }}"
    echo "Ref: ${{ github.ref }}"
    echo "Environment: ${{ github.environment }}"
    echo "Actor: ${{ github.actor }}"
```

## Security Best Practices

1. **Use Environments**: Protect production environments with required reviewers
2. **Least Privilege**: Grant minimal required permissions
3. **Separate Service Principals**: Consider separate SPs for different environments
4. **Regular Rotation**: Regularly review and rotate credentials
5. **Audit Logs**: Monitor Azure AD sign-in logs for the service principal

## Next Steps

1. Run the Azure CLI commands above to configure federated identity
2. Update GitHub secrets
3. Test the workflow: `gh workflow run azure-network.yml -f action=plan -f environment=dev`
4. If successful, proceed with infrastructure deployment