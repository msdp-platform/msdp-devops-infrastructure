# 🔐 OIDC Authentication Setup Guide

## 🎯 **Overview**

This guide sets up OpenID Connect (OIDC) authentication for both Azure and AWS, eliminating the need for long-lived secrets and providing better security.

## ✅ **Azure OIDC Setup (Completed)**

### **What We've Set Up:**

1. **Azure App Registration**: `msdp-platform-github-oidc`
   - **Client ID**: `129dd1fb-3d94-4e10-b451-2b0dea64daee`
   - **Tenant ID**: `a4474822-c84f-4bd1-bc35-baed17234c9f`
   - **Subscription ID**: `ecd977ed-b8df-4eb6-9cba-98397e1b2491`

2. **Federated Identity Credentials**:
   - `github-actions-msdp-platform` (main branch)
   - `github-actions-msdp-platform-dev` (dev branch)
   - `github-actions-msdp-platform-test` (test branch)

3. **Service Principal**: `msdp-platform-github-oidc`
   - **Role**: Contributor (subscription level)
   - **Object ID**: `5e997217-ffe5-4a39-b36d-61cc0bd9d4e6`

### **GitHub Actions Configuration:**
```yaml
env:
  AZURE_CLIENT_ID: 129dd1fb-3d94-4e10-b451-2b0dea64daee
  AZURE_TENANT_ID: a4474822-c84f-4bd1-bc35-baed17234c9f
  AZURE_SUBSCRIPTION_ID: ecd977ed-b8df-4eb6-9cba-98397e1b2491

steps:
  - name: Setup Azure CLI
    uses: azure/login@v1
    with:
      client-id: ${{ env.AZURE_CLIENT_ID }}
      tenant-id: ${{ env.AZURE_TENANT_ID }}
      subscription-id: ${{ env.AZURE_SUBSCRIPTION_ID }}
```

## 🚀 **AWS OIDC Setup (Next Steps)**

### **Step 1: Create OIDC Identity Provider**

```bash
# Create OIDC identity provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com
```

### **Step 2: Create IAM Role for GitHub Actions**

```bash
# Create trust policy for GitHub Actions
cat > github-actions-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:msdp-platform/msdp-devops-infrastructure:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name GitHubActions-MSDP-Platform \
  --assume-role-policy-document file://github-actions-trust-policy.json
```

### **Step 3: Attach Route53 Permissions**

```bash
# Create policy for Route53 access
cat > route53-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create and attach policy
aws iam create-policy \
  --policy-name GitHubActions-Route53-Policy \
  --policy-document file://route53-policy.json

aws iam attach-role-policy \
  --role-name GitHubActions-MSDP-Platform \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActions-Route53-Policy
```

### **Step 4: Configure GitHub Secret**

```bash
# Get the role ARN
aws iam get-role --role-name GitHubActions-MSDP-Platform --query 'Role.Arn' --output text

# Set GitHub secret (replace YOUR_ACCOUNT_ID with actual account ID)
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-MSDP-Platform"
```

## 🔧 **GitHub Actions Workflow Updates**

### **Updated Workflow Configuration:**

```yaml
env:
  AZURE_CLIENT_ID: 129dd1fb-3d94-4e10-b451-2b0dea64daee
  AZURE_TENANT_ID: a4474822-c84f-4bd1-bc35-baed17234c9f
  AZURE_SUBSCRIPTION_ID: ecd977ed-b8df-4eb6-9cba-98397e1b2491
  AWS_REGION: us-east-1

jobs:
  deploy-networking:
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Setup Azure CLI
        uses: azure/login@v1
        with:
          client-id: ${{ env.AZURE_CLIENT_ID }}
          tenant-id: ${{ env.AZURE_TENANT_ID }}
          subscription-id: ${{ env.AZURE_SUBSCRIPTION_ID }}

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
```

## 🧪 **Testing OIDC Authentication**

### **Test Azure OIDC:**
```bash
# Test the workflow
gh workflow run "Deploy Platform Components" \
  --field environment=dev \
  --field component=all \
  --field dry_run=true
```

### **Test AWS OIDC:**
```bash
# Test AWS credentials in workflow
aws sts get-caller-identity
```

## 🔐 **Security Benefits**

### **OIDC vs Service Principal Secrets:**

| Aspect | OIDC | Service Principal Secrets |
|--------|------|---------------------------|
| **Security** | ✅ Short-lived tokens | ❌ Long-lived secrets |
| **Rotation** | ✅ Automatic | ❌ Manual rotation required |
| **Storage** | ✅ No secrets to store | ❌ Secrets in GitHub |
| **Audit** | ✅ Better audit trail | ❌ Limited audit |
| **Compliance** | ✅ Better compliance | ❌ Compliance challenges |

## 📋 **Required GitHub Secrets**

### **Current Secrets:**
- ✅ `AZURE_CREDENTIALS` (can be removed after OIDC testing)

### **OIDC Secrets (No Secrets Required):**
- ✅ Azure: Client ID, Tenant ID, Subscription ID (in workflow)
- 🔄 AWS: Role ARN (to be configured)

## 🎯 **Next Steps**

1. **Test Azure OIDC** - Run the workflow to verify Azure authentication
2. **Set up AWS OIDC** - Follow the AWS setup steps above
3. **Remove old secrets** - Delete `AZURE_CREDENTIALS` after testing
4. **Update other workflows** - Apply OIDC to all GitHub Actions workflows

## 🚨 **Troubleshooting**

### **Azure OIDC Issues:**
```bash
# Check federated credentials
az ad app federated-credential list --id 129dd1fb-3d94-4e10-b451-2b0dea64daee

# Check service principal permissions
az role assignment list --assignee 129dd1fb-3d94-4e10-b451-2b0dea64daee
```

### **AWS OIDC Issues:**
```bash
# Check OIDC provider
aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com

# Check role trust policy
aws iam get-role --role-name GitHubActions-MSDP-Platform
```

---

**OIDC setup provides better security and eliminates the need for long-lived secrets!** 🔐
