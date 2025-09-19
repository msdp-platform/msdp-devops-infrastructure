# Complete Secrets Setup Guide

## 🎯 **Required GitHub Secrets**

Based on your workflows and infrastructure setup, you need to configure the following GitHub secrets:

### 🔐 **Azure Secrets (REQUIRED - Already Generated)**
```
AZURE_CLIENT_ID = eff9ea87-879e-4ed1-8fac-3bbff92c2312
AZURE_TENANT_ID = a4474822-c84f-4bd1-bc35-baed17234c9f
AZURE_SUBSCRIPTION_ID = ecd977ed-b8df-4eb6-9cba-98397e1b2491
```

### 🔐 **AWS Secrets (REQUIRED for DNS Integration)**
Based on your workflows, you need AWS credentials for Route53 DNS management:
```
AWS_ACCESS_KEY_ID = <your-aws-access-key-id>
AWS_SECRET_ACCESS_KEY = <your-aws-secret-access-key>
AWS_ROLE_ARN = <your-aws-role-arn> (optional, for OIDC)
```

### 🔐 **Optional Secrets (For Enhanced Functionality)**
```
AWS_ROLE_ARN_FOR_AZURE = <cross-cloud-role-arn> (for Azure→AWS access)
AZURE_WORKLOAD_IDENTITY_CLIENT_ID = <workload-identity-client-id>
```

## 🚀 **Quick Setup Commands**

### **Option 1: Set Secrets via GitHub CLI (Recommended)**
```bash
# Azure secrets (already generated)
gh secret set AZURE_CLIENT_ID --body "eff9ea87-879e-4ed1-8fac-3bbff92c2312"
gh secret set AZURE_TENANT_ID --body "a4474822-c84f-4bd1-bc35-baed17234c9f"
gh secret set AZURE_SUBSCRIPTION_ID --body "ecd977ed-b8df-4eb6-9cba-98397e1b2491"

# AWS secrets (you need to provide these)
gh secret set AWS_ACCESS_KEY_ID --body "<your-aws-access-key-id>"
gh secret set AWS_SECRET_ACCESS_KEY --body "<your-aws-secret-access-key>"
```

### **Option 2: Set Secrets via GitHub Web UI**
1. Go to: https://github.com/msdp-platform/msdp-devops-infrastructure/settings/secrets/actions
2. Click "New repository secret" for each secret above

## 🔧 **AWS Setup (For Route53 DNS)**

Your infrastructure uses AWS Route53 for DNS management from Azure AKS clusters. Here's how to set it up:

### **Step 1: Create AWS IAM User for Route53**
```bash
# Create IAM user
aws iam create-user --user-name github-actions-route53

# Create access key
aws iam create-access-key --user-name github-actions-route53
```

### **Step 2: Create Route53 Policy**
```bash
# Create policy for Route53 access
aws iam create-policy --policy-name Route53DNSPolicy --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetChange",
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*",
        "arn:aws:route53:::change/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListHostedZonesByName"
      ],
      "Resource": "*"
    }
  ]
}'

# Attach policy to user
aws iam attach-user-policy \
  --user-name github-actions-route53 \
  --policy-arn arn:aws:iam::<account-id>:policy/Route53DNSPolicy
```

### **Step 3: Get the Access Keys**
Use the access key ID and secret from Step 1 for the GitHub secrets.

## 🧪 **Test the Complete Setup**

Once all secrets are configured, test the workflows:

### **Test 1: Network Infrastructure**
```bash
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=plan \
  --field environment=dev
```

### **Test 2: Kubernetes Add-ons (with DNS)**
```bash
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field cluster_name=aks-msdp-dev-01 \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=plan \
  --field auto_approve=false
```

### **Test 3: Full Infrastructure Orchestrator**
```bash
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network" \
  --field action=plan \
  --field cloud_provider=azure
```

## 📊 **Expected Results**

After configuring all secrets:

### ✅ **Azure Authentication**
- Workflows should authenticate successfully with Azure
- No more `AADSTS700213` errors
- Azure resources can be created/managed

### ✅ **AWS Route53 Integration**
- cert-manager can create Let's Encrypt certificates
- external-dns can manage Route53 DNS records
- Cross-cloud DNS functionality works

### ✅ **Complete Infrastructure Deployment**
- Network infrastructure deploys successfully
- Kubernetes clusters provision correctly
- Add-ons install and configure properly
- Platform engineering stack deploys

## 🔍 **Verification Commands**

```bash
# Check if secrets are configured
gh secret list

# Monitor workflow runs
gh run list --limit 5

# Check specific workflow
gh run view <run-id>
```

## 🚨 **Security Best Practices**

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Regular Rotation**: Rotate access keys regularly
3. **Monitor Usage**: Monitor AWS CloudTrail and Azure Activity Log
4. **Separate Environments**: Use different credentials for dev/staging/prod

## 🎯 **Priority Setup Order**

1. **Azure Secrets** (CRITICAL) - Required for all Azure resources
2. **AWS Route53 Secrets** (HIGH) - Required for DNS functionality
3. **Optional Secrets** (LOW) - For enhanced cross-cloud features

---

## 🎉 **Ready for Full Infrastructure Deployment!**

Once all secrets are configured, your infrastructure orchestration system will be **fully operational** and ready to deploy complete Azure infrastructure with AWS Route53 DNS integration!

**Next Step**: Configure the GitHub secrets and start testing! 🚀
