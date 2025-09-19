# Cloud Account Setup Guide ☁️

## 🎯 **Overview**

This guide walks you through setting up cloud accounts and authentication for the MSDP DevOps Infrastructure. Follow these steps to configure AWS and Azure accounts for your organization.

## 📋 **Prerequisites**

- [ ] AWS Account with administrative access
- [ ] Azure Subscription with Owner/Contributor role
- [ ] GitHub repository with Actions enabled
- [ ] Domain name registered and accessible
- [ ] CLI tools installed (aws-cli, az-cli, gh-cli)

## 🔧 **AWS Account Setup**

### **Step 1: Create IAM User for GitHub Actions**

```bash
# Create IAM user
aws iam create-user --user-name github-actions-msdp

# Create access key
aws iam create-access-key --user-name github-actions-msdp
```

### **Step 2: Create IAM Policies**

**Route53 Access Policy:**
```bash
cat > route53-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "route53:GetHostedZone",
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/*",
                "arn:aws:route53:::change/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy \
    --policy-name Route53AccessPolicy \
    --policy-document file://route53-policy.json
```

**Infrastructure Management Policy:**
```bash
cat > infrastructure-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "eks:*",
                "iam:*",
                "s3:*",
                "dynamodb:*",
                "kms:*",
                "logs:*",
                "sts:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy \
    --policy-name InfrastructureManagementPolicy \
    --policy-document file://infrastructure-policy.json
```

### **Step 3: Attach Policies to User**

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach policies
aws iam attach-user-policy \
    --user-name github-actions-msdp \
    --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/Route53AccessPolicy"

aws iam attach-user-policy \
    --user-name github-actions-msdp \
    --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/InfrastructureManagementPolicy"
```

### **Step 4: Setup Route53 Hosted Zone**

```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone \
    --name your-domain.com \
    --caller-reference $(date +%s)

# Get the hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
    --query "HostedZones[?Name=='your-domain.com.'].Id" \
    --output text | cut -d'/' -f3)

echo "Your Hosted Zone ID: $HOSTED_ZONE_ID"
```

## 🔵 **Azure Account Setup**

### **Step 1: Create Service Principal**

```bash
# Login to Azure
az login

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Create service principal
az ad sp create-for-rbac \
    --name "github-actions-msdp" \
    --role "Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth
```

### **Step 2: Create Resource Groups**

```bash
# Create resource groups for different environments
az group create --name "rg-msdp-network-dev" --location "uksouth"
az group create --name "rg-msdp-backup-dev" --location "uksouth"
```

### **Step 3: Setup Azure OIDC (Recommended)**

For enhanced security, set up OIDC instead of service principal:

```bash
# Run the OIDC setup script
./scripts/setup-azure-oidc.sh

# Add dev branch support
./scripts/add-dev-branch-oidc.sh
```

## 🐙 **GitHub Repository Setup**

### **Step 1: Configure Repository Secrets**

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

**AWS Secrets:**
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_ACCOUNT_ID=123456789012
```

**Azure Secrets:**
```
AZURE_CLIENT_ID=...
AZURE_CLIENT_SECRET=...
AZURE_TENANT_ID=...
AZURE_SUBSCRIPTION_ID=...
```

**Cross-Cloud Secrets (for Route53 from Azure):**
```
AWS_ROLE_ARN_FOR_AZURE=arn:aws:iam::123456789012:role/AzureRoute53AccessRole
AZURE_WORKLOAD_IDENTITY_CLIENT_ID=...
```

### **Step 2: Configure Repository Variables**

Add these variables to your GitHub repository (Settings → Secrets and variables → Actions → Variables):

**Organization Variables:**
```
ORG_NAME=your-org
ORG_DOMAIN=your-domain.com
ORG_EMAIL=devops@your-domain.com
ORG_GITHUB=your-github-org
```

**Cloud Configuration:**
```
AWS_ACCOUNT_ID=123456789012
AZURE_SUBSCRIPTION_ID=12345678-1234-1234-1234-123456789012
ROUTE53_ZONE_ID=Z1234567890ABC
AWS_DEFAULT_REGION=us-east-1
AZURE_DEFAULT_LOCATION=eastus
```

## 🔐 **Cross-Cloud Authentication Setup**

For Azure AKS to access AWS Route53, set up cross-cloud authentication:

### **Step 1: Create AWS IAM Role for Azure**

```bash
# Run the cross-cloud setup script
./scripts/setup-azure-oidc-aws-role.sh
```

This script will:
- Create AWS OIDC provider for Azure
- Create IAM role for Azure workload identity
- Set up Route53 access permissions
- Configure Azure managed identity

### **Step 2: Verify Setup**

```bash
# Verify the cross-cloud setup
./scripts/verify-oidc-setup.sh
```

## 🧪 **Testing Your Setup**

### **Step 1: Test AWS Connectivity**

```bash
# Test AWS access
aws sts get-caller-identity

# Test Route53 access
aws route53 list-hosted-zones
```

### **Step 2: Test Azure Connectivity**

```bash
# Test Azure access
az account show

# Test resource group access
az group list --output table
```

### **Step 3: Test GitHub Actions**

Run a test workflow to verify everything is working:

```bash
# Test network infrastructure
gh workflow run "Network Infrastructure" \
    --field environment=dev \
    --field action=plan \
    --field cloud_provider=azure
```

## 🔍 **Validation Checklist**

Use this checklist to ensure your setup is complete:

```bash
# Run the validation script
./scripts/validate-organization-config.sh
```

**Manual Verification:**
- [ ] AWS CLI authenticated and working
- [ ] Azure CLI authenticated and working
- [ ] GitHub CLI authenticated and working
- [ ] Route53 hosted zone created and accessible
- [ ] Azure resource groups created
- [ ] GitHub repository secrets configured
- [ ] GitHub repository variables configured
- [ ] Cross-cloud authentication working
- [ ] Test workflows running successfully

## 🆘 **Troubleshooting**

### **Common AWS Issues**

**Issue**: `AccessDenied` errors
**Solution**: Check IAM policies and ensure user has required permissions

**Issue**: Route53 domain not resolving
**Solution**: Update nameservers at your domain registrar

### **Common Azure Issues**

**Issue**: `Forbidden` errors
**Solution**: Check service principal has Contributor role on subscription

**Issue**: Resource group creation fails
**Solution**: Verify location is valid and subscription has quota

### **Common GitHub Actions Issues**

**Issue**: Secrets not found
**Solution**: Verify secrets are added to repository settings

**Issue**: OIDC authentication fails
**Solution**: Check federated identity credentials in Azure AD

## 🎯 **Next Steps**

After completing this setup:

1. **Follow the [Organization Setup Guide](ORGANIZATION_SETUP.md)**
2. **Run validation scripts to verify configuration**
3. **Deploy your first environment**
4. **Set up monitoring and alerting**

## 📚 **Additional Resources**

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)
- [Route53 Documentation](https://docs.aws.amazon.com/route53/)

---

**Security Note**: Always follow the principle of least privilege. Grant only the minimum permissions required for your use case.
