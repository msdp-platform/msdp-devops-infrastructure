# 🔐 GitHub OIDC Setup Guide for AWS

## 📋 **Overview**

This guide walks you through setting up GitHub OIDC (OpenID Connect) authentication with AWS using your SSO profile "AWSAdministratorAccess-319422413814". This eliminates the need for long-term AWS access keys and provides secure, short-lived credentials for GitHub Actions.

## 🎯 **What You'll Get**

- **✅ Secure Authentication**: No more AWS access keys stored in GitHub secrets
- **✅ Short-lived Credentials**: Automatic token rotation and expiration
- **✅ Fine-grained Permissions**: IAM roles with specific permissions
- **✅ Terraform Backend**: S3 bucket for Terraform state storage
- **✅ GitHub Actions Integration**: Seamless AWS authentication in workflows

## 📋 **Prerequisites**

### **1. AWS SSO Profile**
- AWS SSO profile "AWSAdministratorAccess-319422413814" configured
- AWS CLI configured with the profile
- Administrator access to create IAM resources

### **2. GitHub Repository**
- GitHub repository with Actions enabled
- Admin access to repository settings

### **3. Tools Required**
- AWS CLI
- Terraform
- Git

## 🔧 **Step-by-Step Setup**

### **Step 1: Configure AWS SSO Profile**

First, ensure your AWS SSO profile is configured:

```bash
# Configure AWS SSO (if not already done)
aws configure sso --profile AWSAdministratorAccess-319422413814

# Test the profile
aws sts get-caller-identity --profile AWSAdministratorAccess-319422413814
```

### **Step 2: Run the OIDC Setup Script**

```bash
# Make the script executable
chmod +x scripts/setup-github-oidc.sh

# Run the setup script
export AWS_PROFILE=AWSAdministratorAccess-319422413814
export GITHUB_ORG=your-github-org
export GITHUB_REPO=msdp-devops-infrastructure

./scripts/setup-github-oidc.sh
```

### **Step 3: Configure GitHub Secrets**

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```bash
AWS_ROLE_ARN=arn:aws:iam::YOUR-ACCOUNT-ID:role/GitHubActions-Role
AWS_REGION=us-west-2
TERRAFORM_BUCKET_NAME=msdp-terraform-state-XXXXXXXX
```

### **Step 4: Update Terraform Backend Configuration**

Update your Terraform backend configuration in `infrastructure/terraform/environments/dev/main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "msdp-terraform-state-XXXXXXXX"  # From TERRAFORM_BUCKET_NAME secret
    key    = "dev/eks-blueprint/terraform.tfstate"
    region = "us-west-2"
  }
}
```

### **Step 5: Test the Setup**

Push a change to trigger the GitHub Actions workflow and verify OIDC authentication works.

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions                          │
├─────────────────────────────────────────────────────────────┤
│  OIDC Token Request                                        │
│  ↓                                                         │
│  GitHub OIDC Provider                                      │
│  ↓                                                         │
│  AWS IAM Role (GitHubActions-Role)                        │
│  ↓                                                         │
│  AWS Services (EKS, EC2, S3, etc.)                       │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 **Security Features**

### **OIDC Provider Configuration**
- **URL**: `https://token.actions.githubusercontent.com`
- **Audience**: `sts.amazonaws.com`
- **Thumbprint**: GitHub's official thumbprint
- **Subject**: Restricted to your specific repository

### **IAM Role Trust Policy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

### **IAM Permissions**
The GitHub Actions role has permissions for:
- EKS cluster management
- EC2 instance management
- IAM role management
- VPC and networking
- S3 bucket access
- Route53 DNS management
- ACM certificate management
- Secrets Manager access
- CloudWatch monitoring

## 🚀 **GitHub Actions Workflow**

Your workflow now uses OIDC authentication:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Deploy infrastructure
        run: terraform apply
```

## 🧪 **Testing the Setup**

### **Test 1: Verify OIDC Provider**
```bash
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com" \
  --profile AWSAdministratorAccess-319422413814
```

### **Test 2: Verify IAM Role**
```bash
aws iam get-role \
  --role-name GitHubActions-Role \
  --profile AWSAdministratorAccess-319422413814
```

### **Test 3: Verify S3 Bucket**
```bash
aws s3 ls s3://msdp-terraform-state-XXXXXXXX \
  --profile AWSAdministratorAccess-319422413814
```

### **Test 4: GitHub Actions Test**
Create a simple test workflow to verify OIDC authentication:

```yaml
name: Test OIDC
on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Test AWS access
        run: aws sts get-caller-identity
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. OIDC Provider Already Exists**
```bash
# Check if provider exists
aws iam list-open-id-connect-providers --profile AWSAdministratorAccess-319422413814

# If it exists, you can skip the creation step
```

#### **2. IAM Role Already Exists**
```bash
# Check existing roles
aws iam list-roles --query 'Roles[?contains(RoleName, `GitHubActions`)]' --profile AWSAdministratorAccess-319422413814

# Update the role if needed
aws iam update-assume-role-policy --role-name GitHubActions-Role --policy-document file://trust-policy.json
```

#### **3. GitHub Actions Authentication Fails**
- Verify the repository name in the trust policy matches exactly
- Check that the `AWS_ROLE_ARN` secret is correct
- Ensure the workflow has `id-token: write` permission

#### **4. Terraform Backend Access Denied**
- Verify the S3 bucket name in secrets
- Check IAM permissions for S3 access
- Ensure the bucket exists and is accessible

### **Debug Commands**

```bash
# Check AWS identity
aws sts get-caller-identity --profile AWSAdministratorAccess-319422413814

# List OIDC providers
aws iam list-open-id-connect-providers --profile AWSAdministratorAccess-319422413814

# Check IAM roles
aws iam list-roles --profile AWSAdministratorAccess-319422413814

# Test S3 access
aws s3 ls --profile AWSAdministratorAccess-319422413814
```

## 🔄 **Maintenance**

### **Updating Permissions**
To add or remove permissions:

1. Update the IAM policy in the Terraform module
2. Apply the changes: `terraform apply`
3. The changes will be automatically reflected in GitHub Actions

### **Rotating Credentials**
OIDC tokens are automatically rotated, but if you need to update the setup:

1. Update the Terraform configuration
2. Run `terraform apply`
3. Update GitHub secrets if needed

### **Adding New Repositories**
To add OIDC access for additional repositories:

1. Update the trust policy to include the new repository
2. Apply the changes: `terraform apply`
3. Add the same secrets to the new repository

## 📚 **Additional Resources**

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security/hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AWS Actions Documentation](https://github.com/aws-actions/configure-aws-credentials)

## 🆘 **Support**

If you encounter issues:

1. Check the troubleshooting section above
2. Verify your AWS SSO profile configuration
3. Check GitHub repository settings and secrets
4. Review AWS CloudTrail logs for authentication issues

---

**Last Updated**: $(date)  
**Version**: 1.0.0  
**Maintainer**: DevOps Team
