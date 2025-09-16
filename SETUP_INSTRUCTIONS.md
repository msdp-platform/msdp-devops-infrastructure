# Azure OIDC with AWS IAM Role - Setup Instructions

## 🚀 **Ready to Set Up Cross-Cloud Authentication**

I've created comprehensive scripts to set up Azure OIDC with AWS IAM Role authentication. Here's how to run them on your local machine.

## 📋 **Prerequisites Check**

Before running the setup, make sure you have:

### **1. CLI Tools Installed**
```bash
# Check AWS CLI
aws --version

# Check Azure CLI  
az --version

# If not installed:
# AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
```

### **2. Authentication**
```bash
# Login to AWS (if not already)
aws configure
# OR use existing credentials/profiles

# Login to Azure (if not already)
az login

# Verify authentication
aws sts get-caller-identity
az account show
```

### **3. Permissions Required**

**AWS Permissions:**
- `iam:CreateOpenIDConnectProvider`
- `iam:CreateRole`
- `iam:CreatePolicy`
- `iam:AttachRolePolicy`
- `route53:GetHostedZone`

**Azure Permissions:**
- `Microsoft.ManagedIdentity/userAssignedIdentities/*`
- `Microsoft.ContainerService/managedClusters/read`
- Contributor or Owner on resource group `rg-msdp-network-dev`

## 🔧 **Step 1: Make Scripts Executable**

```bash
cd /Users/santanu/github/msdp-devops-infrastructure

# Make scripts executable
chmod +x scripts/setup-azure-oidc-aws-role.sh
chmod +x scripts/verify-oidc-setup.sh
```

## 🚀 **Step 2: Run Setup Script**

```bash
# Run the main setup script
./scripts/setup-azure-oidc-aws-role.sh
```

**What this script does:**
- ✅ Creates AWS OIDC Identity Provider
- ✅ Creates AWS IAM Role with trust policy for Azure
- ✅ Creates AWS IAM Policy for Route53 access
- ✅ Creates Azure User-Assigned Managed Identity
- ✅ Sets up federated credentials for service accounts
- ✅ Configures cross-cloud authentication

## 🔍 **Step 3: Verify Setup**

```bash
# Run verification script
./scripts/verify-oidc-setup.sh
```

**What this script does:**
- ✅ Verifies all AWS resources are created correctly
- ✅ Verifies all Azure resources are configured
- ✅ Tests OIDC connectivity
- ✅ Generates test deployment manifest
- ✅ Provides summary and next steps

## 📝 **Step 4: Update Configuration**

After successful setup, you'll get output like this:

```bash
📝 Terraform Variables to Update:
=================================

# Add to terraform.tfvars:
aws_role_arn_for_azure = "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
azure_workload_identity_client_id = "12345678-1234-1234-1234-123456789abc"

📝 GitHub Secrets to Add:
=========================

AWS_ROLE_ARN_FOR_AZURE = arn:aws:iam::319422413814:role/AzureRoute53AccessRole
AZURE_WORKLOAD_IDENTITY_CLIENT_ID = 12345678-1234-1234-1234-123456789abc
```

### **Update Terraform Configuration**

Add these lines to `infrastructure/addons/terraform/environments/azure-dev/terraform.tfvars`:

```hcl
# AWS OIDC Configuration
aws_role_arn_for_azure = "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
```

### **Update GitHub Secrets**

Add these secrets to your GitHub repository:
1. Go to GitHub → Settings → Secrets and variables → Actions
2. Add new repository secrets:
   - `AWS_ROLE_ARN_FOR_AZURE`
   - `AZURE_WORKLOAD_IDENTITY_CLIENT_ID`

## 🧪 **Step 5: Test the Setup**

### **Option 1: Test with Kubernetes Deployment**
```bash
# Apply the generated test deployment
kubectl apply -f /tmp/test-external-dns.yaml

# Check logs
kubectl logs -l app=external-dns-test

# Clean up test
kubectl delete -f /tmp/test-external-dns.yaml
```

### **Option 2: Test with Terraform**
```bash
# Run Terraform plan
GitHub Actions → k8s-addons-terraform.yml
  cluster_name: aks-msdp-dev-01
  environment: dev
  cloud_provider: azure
  action: plan
```

## 🔧 **Troubleshooting**

### **Common Issues:**

**1. AWS OIDC Provider Already Exists**
```bash
# This is normal if you've run the script before
# The script will skip creation and continue
```

**2. AKS OIDC Not Enabled**
```bash
# Enable OIDC on your AKS cluster
az aks update \
  --resource-group rg-msdp-network-dev \
  --name aks-msdp-dev-01 \
  --enable-oidc-issuer
```

**3. Permission Denied**
```bash
# Make sure you have the required permissions
# Check AWS: aws sts get-caller-identity
# Check Azure: az account show
```

**4. Resource Already Exists**
```bash
# The scripts handle existing resources gracefully
# They will update existing resources instead of failing
```

## 📊 **What Gets Created**

### **AWS Resources:**
- **OIDC Provider**: `arn:aws:iam::319422413814:oidc-provider/login.microsoftonline.com/TENANT_ID/v2.0`
- **IAM Role**: `AzureRoute53AccessRole`
- **IAM Policy**: `Route53AccessPolicy`

### **Azure Resources:**
- **Managed Identity**: `id-aks-route53-access`
- **Federated Credentials**: For external-dns and cert-manager service accounts

## 🎯 **Expected Output**

When successful, you'll see:

```bash
✅ Prerequisites check passed
✅ AWS Route53 policy created/updated
✅ AWS OIDC Identity Provider created
✅ Azure Managed Identity created
✅ AWS IAM Role created/updated with Route53 policy attached
✅ External DNS federated credential created
✅ Cert-Manager federated credential created
🎉 Setup completed successfully!
```

## 🚀 **Next Steps After Setup**

1. **Update GitHub Secrets** with the provided values
2. **Update Terraform variables** in `terraform.tfvars`
3. **Test with Terraform plan** to verify configuration
4. **Deploy add-ons** using the Terraform workflow

## 📞 **Need Help?**

If you encounter any issues:

1. **Check the logs** - Scripts provide detailed output
2. **Run verification script** - `./scripts/verify-oidc-setup.sh`
3. **Check prerequisites** - Ensure AWS/Azure CLI are authenticated
4. **Review permissions** - Make sure you have required IAM/RBAC permissions

**Ready to run? Execute the commands above and let me know if you need any help!** 🎯