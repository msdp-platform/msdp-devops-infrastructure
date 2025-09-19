# Organization Setup Guide 🏢

## 🎯 **Overview**

This guide helps you customize the MSDP DevOps Infrastructure for your organization. Follow these steps to replace hardcoded values with your organization's configuration.

## 📋 **Prerequisites**

- [ ] AWS Account (if using AWS)
- [ ] Azure Subscription (if using Azure)
- [ ] GitHub Organization
- [ ] Domain name registered
- [ ] DNS provider configured (Route53 or Azure DNS)

## 🚀 **Quick Start**

### **Step 1: Create Organization Configuration**

1. Copy the organization template:
```bash
cp infrastructure/config/organization.yaml.template infrastructure/config/organization.yaml
```

2. Edit `infrastructure/config/organization.yaml` with your details:
```yaml
organization:
  name: "your-org"
  domain: "your-domain.com"
  email: "devops@your-domain.com"
  github_org: "your-github-org"

cloud_accounts:
  aws:
    account_id: "YOUR_AWS_ACCOUNT_ID"
    default_region: "us-east-1"
  azure:
    subscription_id: "YOUR_AZURE_SUBSCRIPTION_ID"
    default_location: "eastus"

dns:
  provider: "route53"
  route53:
    zone_id: "YOUR_HOSTED_ZONE_ID"
```

3. Add to `.gitignore` to keep it private:
```bash
echo "infrastructure/config/organization.yaml" >> .gitignore
```

### **Step 2: Update Global Configuration**

Edit `infrastructure/config/globals.yaml`:
```yaml
# Replace hardcoded values with references to organization config
org: "{{ organization.name }}"
base_domain: "{{ organization.domain }}"
git_org: "{{ organization.github_org }}"

accounts:
  aws_account_id: "{{ cloud_accounts.aws.account_id }}"
  azure_subscription_id: "{{ cloud_accounts.azure.subscription_id }}"

dns:
  provider: "{{ dns.provider }}"
  route53_zone_id: "{{ dns.route53.zone_id }}"
```

### **Step 3: Configure GitHub Repository**

#### **Repository Variables**
Add these to your GitHub repository settings → Variables:
```
ORG_NAME=your-org
ORG_DOMAIN=your-domain.com
ORG_EMAIL=devops@your-domain.com
```

#### **Repository Secrets**
Add these to your GitHub repository settings → Secrets:
```
AWS_ACCOUNT_ID=123456789012
AZURE_SUBSCRIPTION_ID=12345678-1234-1234-1234-123456789012
ROUTE53_ZONE_ID=Z1234567890ABC
```

### **Step 4: Update Environment Configurations**

For each environment file in `infrastructure/addons/config/*/`:

1. **Replace domain references**:
```yaml
# Before
domain_filters: ["aztech-msdp.com"]
hostname: "grafana-dev.aztech-msdp.com"

# After
domain_filters: ["{{ organization.domain }}"]
hostname: "grafana-dev.{{ organization.domain }}"
```

2. **Replace email references**:
```yaml
# Before
email: "devops@aztech-msdp.com"

# After
email: "{{ organization.email }}"
```

## 🔧 **Detailed Configuration**

### **AWS Setup**

1. **Get your AWS Account ID**:
```bash
aws sts get-caller-identity --query Account --output text
```

2. **Create Route53 Hosted Zone** (if needed):
```bash
aws route53 create-hosted-zone \
  --name your-domain.com \
  --caller-reference $(date +%s)
```

3. **Note the Hosted Zone ID**:
```bash
aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='your-domain.com.'].Id" \
  --output text
```

### **Azure Setup**

1. **Get your Azure Subscription ID**:
```bash
az account show --query id --output tsv
```

2. **Get your Azure Tenant ID**:
```bash
az account show --query tenantId --output tsv
```

### **DNS Setup**

#### **Option 1: AWS Route53**
```yaml
dns:
  provider: "route53"
  route53:
    zone_id: "Z1234567890ABC"
```

#### **Option 2: Azure DNS**
```yaml
dns:
  provider: "azure-dns"
  azure_dns:
    resource_group: "rg-dns"
    zone_name: "your-domain.com"
```

## 🛠️ **Configuration Validation**

### **Step 1: Validate Configuration**
```bash
# Create a validation script
./scripts/validate-organization-config.sh
```

### **Step 2: Test with Dry Run**
```bash
# Test network deployment
gh workflow run "Network Infrastructure" \
  --field environment=dev \
  --field action=plan \
  --field cloud_provider=azure
```

### **Step 3: Verify DNS Resolution**
```bash
# Check if your domain resolves
nslookup your-domain.com

# Check hosted zone
aws route53 list-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID
```

## 📝 **Common Customizations**

### **Resource Naming**
Update naming patterns in `config/dev.yaml`:
```yaml
# Before
cluster_name: aks-msdp-dev-01

# After
cluster_name: aks-{{ organization.name }}-dev-01
```

### **Container Registry**
Update registry references:
```yaml
# Before
registries:
  ghcr: ghcr.io/msdp-platform

# After
registries:
  ghcr: ghcr.io/{{ organization.github_org }}
```

### **Resource Groups (Azure)**
Update resource group naming:
```yaml
# Before
resource_group: "rg-msdp-network-dev"

# After
resource_group: "rg-{{ organization.name }}-network-dev"
```

## 🔍 **Troubleshooting**

### **Common Issues**

1. **Domain not resolving**
   - Check DNS propagation: `dig your-domain.com`
   - Verify nameservers are correct

2. **AWS permissions**
   - Ensure your AWS credentials have required permissions
   - Check IAM roles and policies

3. **Azure permissions**
   - Verify subscription access
   - Check resource provider registrations

### **Validation Commands**
```bash
# Check AWS connectivity
aws sts get-caller-identity

# Check Azure connectivity
az account show

# Check GitHub CLI
gh auth status

# Test DNS resolution
nslookup your-domain.com
```

## 📚 **Next Steps**

1. **Follow the [Cloud Account Setup Guide](CLOUD_ACCOUNT_SETUP.md)**
2. **Configure OIDC authentication**
3. **Set up monitoring and alerting**
4. **Deploy your first environment**

## 🆘 **Support**

If you encounter issues:
1. Check the [Troubleshooting Guide](troubleshooting/README.md)
2. Review the [FAQ](FAQ.md)
3. Open an issue in the repository

---

**Note**: Keep your `organization.yaml` file secure and never commit it to version control. Use environment variables for sensitive values in CI/CD pipelines.
