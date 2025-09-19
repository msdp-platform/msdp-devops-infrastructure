# Hardcoded Values Audit - Making Code Shipable 🚀

## 🎯 **Executive Summary**

This audit identifies all hardcoded values that prevent the codebase from being shipable to other organizations. These values need to be parameterized or moved to configuration files.

## 🔴 **Critical Hardcoded Values (Must Fix)**

### **1. Organization/Company Specific**

#### **Domain Names**
- **Value**: `aztech-msdp.com`
- **Locations**: 25+ files
- **Impact**: HIGH - Prevents other organizations from using the code
- **Files**:
  - `infrastructure/config/globals.yaml`
  - `infrastructure/addons/config/*/dev.yaml`
  - `infrastructure/addons/terraform/modules/*/variables.tf`
  - `.github/workflows/k8s-addons-terraform.yml`
  - `.github/actions/generate-terraform-vars/action.yml`

#### **Email Addresses**
- **Value**: `devops@aztech-msdp.com`
- **Locations**: 10+ files
- **Impact**: HIGH - Company-specific email for certificates
- **Files**:
  - `infrastructure/addons/config/*/dev.yaml`
  - `infrastructure/addons/terraform/environments/*/variables.tf`

#### **GitHub Organization**
- **Value**: `msdp-platform`
- **Locations**: 20+ files
- **Impact**: HIGH - Prevents other orgs from using GitHub Actions
- **Files**:
  - `infrastructure/config/globals.yaml`
  - `scripts/setup-azure-oidc.sh`
  - `.github/actions/*/README.md`
  - `.github/CODEOWNERS`

### **2. Cloud Account Specific**

#### **AWS Account ID**
- **Value**: `319422413814`
- **Locations**: 15+ files
- **Impact**: CRITICAL - Hardcoded AWS account prevents multi-tenant use
- **Files**:
  - `infrastructure/config/globals.yaml`
  - `config/global/accounts.yaml`
  - `.github/workflows/k8s-addons-terraform.yml`
  - `scripts/verify-oidc-setup.sh`

#### **Azure Subscription ID**
- **Value**: `ecd977ed-b8df-4eb6-9cba-98397e1b2491`
- **Locations**: 10+ files
- **Impact**: CRITICAL - Hardcoded Azure subscription prevents multi-tenant use
- **Files**:
  - `infrastructure/config/globals.yaml`
  - `config/global/accounts.yaml`
  - `infrastructure/addons/config/azure/dev.yaml`

#### **Route53 Hosted Zone ID**
- **Value**: `Z0581458B5QGVNLDPESN`
- **Locations**: 15+ files
- **Impact**: HIGH - DNS-specific to current setup
- **Files**:
  - `infrastructure/addons/terraform/modules/*/variables.tf`
  - `.github/workflows/k8s-addons-terraform.yml`
  - `scripts/setup-azure-oidc-aws-role.sh`

### **3. Resource Names**

#### **Cluster Names**
- **Value**: `aks-msdp-dev-01`, `eks-msdp-dev-01`
- **Locations**: 20+ files
- **Impact**: MEDIUM - Organization-specific naming
- **Files**:
  - `infrastructure/addons/config/*/dev.yaml`
  - `config/dev.yaml`
  - Documentation files

#### **Resource Group Names**
- **Value**: `rg-msdp-*`, `rg-network-msdp-dev`
- **Locations**: 10+ files
- **Impact**: MEDIUM - Azure-specific naming convention

## 🟡 **Medium Priority Hardcoded Values**

### **Container Registry**
- **Value**: `ghcr.io/msdp-platform`
- **Locations**: 5+ files
- **Impact**: MEDIUM - Prevents other orgs from using container images

### **Application Repository URLs**
- **Value**: `https://github.com/msdp-platform/msdp-applications`
- **Locations**: 2+ files
- **Impact**: MEDIUM - ArgoCD configuration specific to current org

### **Default Regions**
- **Value**: `eu-west-1` (AWS), `uksouth` (Azure)
- **Locations**: 10+ files
- **Impact**: LOW-MEDIUM - Regional preferences

## 🟢 **Low Priority (Acceptable Defaults)**

### **Tool Versions**
- Kubernetes versions, Terraform versions, etc.
- **Impact**: LOW - These are reasonable defaults

### **Standard Resource Configurations**
- VM sizes, storage classes, etc.
- **Impact**: LOW - Standard configurations

## 🛠️ **Recommended Solutions**

### **1. Create Organization Template Variables**

Create `infrastructure/config/organization.yaml.template`:
```yaml
# Organization Configuration Template
# Copy this file to organization.yaml and customize for your organization

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
  provider: "route53"  # or "azure-dns"
  route53_zone_id: "YOUR_HOSTED_ZONE_ID"  # if using Route53
```

### **2. Update Configuration Loading**

Modify configuration loading to:
1. Load organization-specific values from `organization.yaml`
2. Override with environment-specific values
3. Provide clear error messages for missing required values

### **3. Environment Variable Support**

Support environment variables for sensitive values:
```yaml
aws_account_id: "${AWS_ACCOUNT_ID:-319422413814}"
azure_subscription_id: "${AZURE_SUBSCRIPTION_ID:-ecd977ed-b8df-4eb6-9cba-98397e1b2491}"
```

### **4. GitHub Actions Parameterization**

Update GitHub Actions to read from:
- Repository variables for organization settings
- Repository secrets for sensitive values
- Workflow inputs for deployment-specific values

### **5. Documentation Updates**

Create setup guides:
- `docs/ORGANIZATION_SETUP.md` - How to customize for new organization
- `docs/CLOUD_ACCOUNT_SETUP.md` - How to configure cloud accounts
- `docs/DNS_SETUP.md` - How to configure DNS providers

## 📋 **Implementation Checklist**

### **Phase 1: Critical Values (Required for Shipability)**
- [ ] Create organization configuration template
- [ ] Parameterize AWS account ID
- [ ] Parameterize Azure subscription ID
- [ ] Parameterize domain names
- [ ] Parameterize GitHub organization
- [ ] Update GitHub Actions workflows

### **Phase 2: Medium Priority**
- [ ] Parameterize Route53 hosted zone ID
- [ ] Parameterize cluster names
- [ ] Parameterize resource group names
- [ ] Update container registry references

### **Phase 3: Documentation and Polish**
- [ ] Create organization setup guide
- [ ] Create cloud account setup guide
- [ ] Add validation scripts
- [ ] Create example configurations

## 🎯 **Success Criteria**

The code is considered "shipable" when:
1. ✅ No hardcoded organization-specific values
2. ✅ All cloud accounts parameterized
3. ✅ Clear setup documentation exists
4. ✅ Example configurations provided
5. ✅ Validation scripts detect missing configuration

## 📊 **Current Status**

- **Hardcoded Values Found**: 50+ instances
- **Critical Issues**: 8 categories
- **Files Affected**: 40+ files
- **Estimated Effort**: 2-3 days for Phase 1

## 🚀 **Next Steps**

1. **Start with Phase 1** - Focus on critical organization-specific values
2. **Create organization.yaml template** - Provide clear customization path
3. **Update one module at a time** - Systematic approach to avoid breaking changes
4. **Test with different values** - Validate parameterization works
5. **Document the process** - Enable easy adoption by other organizations

---

**Note**: This audit focuses on making the code shipable to other organizations. Some hardcoded values (like tool versions) are acceptable as defaults and don't prevent shipability.
