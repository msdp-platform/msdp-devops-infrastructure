# Comprehensive Setup Guide 🚀

## 🎯 **Overview**

This guide provides complete setup instructions for the MSDP DevOps Infrastructure platform, including Azure OIDC authentication, AWS integration, and GitHub secrets configuration.

## 🔐 **Azure OIDC Setup**

### **1. Create Azure App Registration**

```bash
# Create App Registration
az ad app create \
  --display-name "GitHub-Actions-MSDP-DevOps" \
  --sign-in-audience AzureADMyOrg

# Get Application ID
APP_ID=$(az ad app list --display-name "GitHub-Actions-MSDP-DevOps" --query "[0].appId" -o tsv)
echo "Application ID: $APP_ID"
```

### **2. Create Service Principal**

```bash
# Create Service Principal
az ad sp create --id $APP_ID

# Get Object ID
OBJECT_ID=$(az ad sp list --display-name "GitHub-Actions-MSDP-DevOps" --query "[0].id" -o tsv)
echo "Service Principal Object ID: $OBJECT_ID"
```

### **3. Configure Federated Identity Credentials**

```bash
# For main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHubActions-Main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHubActions-PR",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For dev environment
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "GitHubActions-Dev-Environment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:msdp-platform/msdp-devops-infrastructure:environment:dev",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### **4. Assign Azure Permissions**

```bash
# Get Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign Contributor role
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

echo "✅ Azure OIDC setup complete!"
echo "Application ID: $APP_ID"
echo "Tenant ID: $(az account show --query tenantId -o tsv)"
echo "Subscription ID: $SUBSCRIPTION_ID"
```

## 🔑 **GitHub Secrets Configuration**

### **Required Secrets**

Configure these secrets in your GitHub repository:

```bash
# Azure OIDC Secrets
gh secret set AZURE_CLIENT_ID --body "$APP_ID"
gh secret set AZURE_TENANT_ID --body "$(az account show --query tenantId -o tsv)"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"

# AWS Secrets (for Route53 DNS)
gh secret set AWS_ACCESS_KEY_ID --body "your-aws-access-key-id"
gh secret set AWS_SECRET_ACCESS_KEY --body "your-aws-secret-access-key"
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::your-account:role/your-role"

# Optional: Azure Workload Identity (if using)
gh secret set AZURE_WORKLOAD_IDENTITY_CLIENT_ID --body "$APP_ID"
```

### **Verification**

```bash
# Verify secrets are set
gh secret list

# Expected output:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY  
# AWS_ROLE_ARN
# AZURE_CLIENT_ID
# AZURE_SUBSCRIPTION_ID
# AZURE_TENANT_ID
```

## 🧪 **Testing Setup**

### **1. Test Network Infrastructure**

```bash
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=plan \
  --field environment=dev
```

### **2. Test Kubernetes Clusters**

```bash
gh workflow run "Kubernetes Clusters" \
  --field cloud_provider=azure \
  --field action=plan \
  --field environment=dev \
  --field cluster_name=aks-msdp-dev-01
```

### **3. Test Kubernetes Add-ons**

```bash
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field cluster_name=aks-msdp-dev-01 \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=plan \
  --field auto_approve=false
```

## 🚀 **Production Deployment**

### **1. Deploy Infrastructure in Order**

```bash
# 1. Network Infrastructure
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=apply \
  --field environment=dev

# 2. Kubernetes Clusters (wait for network to complete)
gh workflow run "Kubernetes Clusters" \
  --field cloud_provider=azure \
  --field action=apply \
  --field environment=dev \
  --field cluster_name=aks-msdp-dev-01

# 3. Kubernetes Add-ons (wait for clusters to complete)
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field cluster_name=aks-msdp-dev-01 \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=apply \
  --field auto_approve=true

# 4. Platform Engineering (wait for add-ons to complete)
gh workflow run "Platform Engineering Stack (Backstage + Crossplane)" \
  --field action=apply \
  --field environment=dev \
  --field component=all \
  --field cluster_name=aks-msdp-dev-01
```

### **2. Use Infrastructure Orchestrator (Recommended)**

```bash
# Deploy all components with dependency resolution
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components=network,clusters,addons,platform \
  --field action=apply \
  --field cloud_provider=azure \
  --field force_sequential=false
```

## 🔧 **Troubleshooting**

### **Common Issues**

1. **Authentication Failures**
   - Verify Azure OIDC setup
   - Check GitHub secrets are set correctly
   - Ensure federated identity credentials are configured

2. **Terraform Provider Issues**
   - All providers use consistent versions (Helm ~> 2.15, Kubernetes ~> 2.24)
   - Backend configuration is properly set up

3. **DNS/Route53 Issues**
   - Verify AWS credentials are set
   - Check Route53 hosted zone exists
   - Ensure external-dns has proper permissions

### **Getting Help**

- Check workflow logs in GitHub Actions
- Review troubleshooting guides in `docs/troubleshooting/`
- Check implementation notes in `docs/implementation-notes/`

## ✅ **Success Criteria**

Your setup is successful when:

1. ✅ All workflows authenticate successfully with Azure
2. ✅ Terraform plans execute without errors
3. ✅ Infrastructure deploys successfully
4. ✅ Kubernetes clusters are accessible
5. ✅ Add-ons deploy and function correctly

---

**Setup Status**: Follow this guide for complete platform setup  
**Support**: Check docs/ directory for additional troubleshooting guides
