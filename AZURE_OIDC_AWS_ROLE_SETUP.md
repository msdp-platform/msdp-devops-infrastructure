# Azure OIDC with AWS IAM Role Setup Guide

## 🎯 **Overview**

You want to use a **predefined AWS IAM role** with **Azure OIDC federation** instead of static AWS credentials. This is much more secure and follows best practices for cross-cloud authentication.

## 🏗️ **Architecture**

```
Azure AKS Cluster → Azure Workload Identity → AWS OIDC Provider → AWS IAM Role → Route53 Access
```

## 🔧 **Implementation Steps**

### **Step 1: Create AWS OIDC Identity Provider**

First, create an OIDC identity provider in AWS that trusts Azure AD:

```bash
# Create OIDC Identity Provider in AWS
aws iam create-open-id-connect-provider \
  --url "https://login.microsoftonline.com/YOUR_AZURE_TENANT_ID/v2.0" \
  --thumbprint-list "626d44e704d1ceabe3bf0d53397464ac8080142c" \
  --client-id-list "api://AzureADTokenExchange"
```

### **Step 2: Create AWS IAM Role for Azure**

Create the AWS IAM role that Azure will assume:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::319422413814:oidc-provider/login.microsoftonline.com/YOUR_AZURE_TENANT_ID/v2.0"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "login.microsoftonline.com/YOUR_AZURE_TENANT_ID/v2.0:sub": "YOUR_AZURE_SERVICE_PRINCIPAL_OBJECT_ID",
          "login.microsoftonline.com/YOUR_AZURE_TENANT_ID/v2.0:aud": "api://AzureADTokenExchange"
        }
      }
    }
  ]
}
```

### **Step 3: Create Route53 Access Policy**

Create the policy for Route53 access:

```json
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
        "arn:aws:route53:::hostedzone/Z0581458B5QGVNLDPESN",
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
```

### **Step 4: Create Azure Workload Identity**

Create Azure Workload Identity for the AKS cluster:

```bash
# Create Azure User-Assigned Managed Identity
az identity create \
  --resource-group rg-msdp-network-dev \
  --name id-aks-route53-access \
  --location uksouth

# Get the identity details
IDENTITY_CLIENT_ID=$(az identity show \
  --resource-group rg-msdp-network-dev \
  --name id-aks-route53-access \
  --query clientId -o tsv)

IDENTITY_OBJECT_ID=$(az identity show \
  --resource-group rg-msdp-network-dev \
  --name id-aks-route53-access \
  --query principalId -o tsv)
```

### **Step 5: Configure Federated Credentials**

Set up federated credentials for the Azure identity:

```bash
# Create federated credential for External DNS
az identity federated-credential create \
  --name external-dns-federated-credential \
  --identity-name id-aks-route53-access \
  --resource-group rg-msdp-network-dev \
  --issuer "https://oidc.prod-aks.azure.com/YOUR_TENANT_ID/YOUR_AKS_OIDC_ISSUER_ID/" \
  --subject "system:serviceaccount:external-dns-system:external-dns" \
  --audience api://AzureADTokenExchange

# Create federated credential for Cert-Manager
az identity federated-credential create \
  --name cert-manager-federated-credential \
  --identity-name id-aks-route53-access \
  --resource-group rg-msdp-network-dev \
  --issuer "https://oidc.prod-aks.azure.com/YOUR_TENANT_ID/YOUR_AKS_OIDC_ISSUER_ID/" \
  --subject "system:serviceaccount:cert-manager:cert-manager" \
  --audience api://AzureADTokenExchange
```

## 🔄 **Updated Terraform Configuration**

### **External DNS Module Call**
```hcl
module "external_dns" {
  source = "../../modules/external-dns"
  
  enabled = true
  
  # DNS configuration
  domain_filters = ["aztech-msdp.com"]
  hosted_zone_id = "Z0581458B5QGVNLDPESN"
  
  # OIDC configuration
  cloud_provider              = "azure"
  aws_region                 = "eu-west-1"
  aws_role_arn               = "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
  aws_web_identity_token_file = "/var/run/secrets/azure/tokens/azure-identity-token"
  use_oidc                   = true
}
```

### **Service Account Annotations**
```hcl
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "external-dns-system"
    
    annotations = {
      "azure.workload.identity/client-id" = var.azure_workload_identity_client_id
    }
  }
}
```

## 🎯 **Required Variables**

Update your `terraform.tfvars`:

```hcl
# Azure OIDC Configuration
aws_role_arn_for_azure = "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
azure_workload_identity_client_id = "YOUR_AZURE_IDENTITY_CLIENT_ID"
```

## 🔍 **GitHub Secrets Required**

Instead of AWS credentials, you now need:

```
# Remove these (no longer needed)
❌ AWS_ACCESS_KEY_ID_FOR_AZURE
❌ AWS_SECRET_ACCESS_KEY_FOR_AZURE

# Add these
✅ AZURE_WORKLOAD_IDENTITY_CLIENT_ID
✅ AWS_ROLE_ARN_FOR_AZURE
```

## 🚀 **Benefits of OIDC Approach**

### **Security Benefits**
- ✅ **No Static Credentials** - No long-lived AWS keys
- ✅ **Automatic Token Rotation** - Tokens rotate automatically
- ✅ **Scoped Access** - Role can only be assumed by specific Azure identity
- ✅ **Audit Trail** - All access logged in AWS CloudTrail

### **Operational Benefits**
- ✅ **No Credential Management** - No need to rotate keys
- ✅ **Native Integration** - Uses Azure Workload Identity
- ✅ **Secure by Default** - Follows cloud security best practices

## 🔧 **Helm Values Template Update**

The External DNS Helm values now use OIDC:

```yaml
# Environment variables for OIDC
extraEnv:
  - name: AWS_ROLE_ARN
    value: "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
  - name: AWS_WEB_IDENTITY_TOKEN_FILE
    value: "/var/run/secrets/azure/tokens/azure-identity-token"
  - name: AWS_REGION
    value: "eu-west-1"

# Volume mounts for OIDC token
extraVolumeMounts:
  - name: azure-identity-token
    mountPath: /var/run/secrets/azure/tokens
    readOnly: true

extraVolumes:
  - name: azure-identity-token
    projected:
      sources:
      - serviceAccountToken:
          path: azure-identity-token
          audience: api://AzureADTokenExchange
          expirationSeconds: 3600
```

## 📋 **Setup Checklist**

### **AWS Side**
- [ ] Create OIDC Identity Provider
- [ ] Create IAM Role with trust policy
- [ ] Attach Route53 access policy
- [ ] Note down Role ARN

### **Azure Side**
- [ ] Create User-Assigned Managed Identity
- [ ] Configure federated credentials
- [ ] Note down Client ID
- [ ] Enable OIDC on AKS cluster

### **Terraform Side**
- [ ] Update variables with Role ARN and Client ID
- [ ] Set `use_oidc = true`
- [ ] Remove static credential variables
- [ ] Update GitHub Secrets

### **Testing**
- [ ] Deploy External DNS with OIDC
- [ ] Verify DNS records are created
- [ ] Check pod logs for authentication success

## 🎯 **Complete Setup Commands**

Here's the complete setup script:

```bash
#!/bin/bash

# Variables
AZURE_TENANT_ID="YOUR_AZURE_TENANT_ID"
AZURE_SUBSCRIPTION_ID="ecd977ed-b8df-4eb6-9cba-98397e1b2491"
AWS_ACCOUNT_ID="319422413814"
RESOURCE_GROUP="rg-msdp-network-dev"
IDENTITY_NAME="id-aks-route53-access"
ROLE_NAME="AzureRoute53AccessRole"

# 1. Create AWS OIDC Provider
aws iam create-open-id-connect-provider \
  --url "https://login.microsoftonline.com/${AZURE_TENANT_ID}/v2.0" \
  --thumbprint-list "626d44e704d1ceabe3bf0d53397464ac8080142c" \
  --client-id-list "api://AzureADTokenExchange"

# 2. Create AWS IAM Role (trust policy in separate file)
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json

# 3. Attach Route53 policy
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Route53AccessPolicy

# 4. Create Azure Managed Identity
az identity create \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --location uksouth

# 5. Get identity details
IDENTITY_CLIENT_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $IDENTITY_NAME \
  --query clientId -o tsv)

echo "✅ Setup complete!"
echo "AWS Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo "Azure Identity Client ID: ${IDENTITY_CLIENT_ID}"
```

## 🎉 **Result**

With this setup, your Azure AKS cluster can securely access AWS Route53 using:
- ✅ **Azure Workload Identity** for authentication
- ✅ **AWS IAM Role** with minimal permissions
- ✅ **OIDC federation** for secure token exchange
- ✅ **No static credentials** stored anywhere

**Much more secure than static AWS keys!** 🔐