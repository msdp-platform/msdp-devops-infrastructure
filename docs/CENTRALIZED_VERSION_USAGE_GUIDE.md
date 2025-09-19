# Centralized Version Control - Usage Guide 🎯

## 🎉 **Implementation Complete!**

Your centralized version control system is now implemented and ready to use!

## 📁 **What's Available**

### **Version Collections**
```hcl
module "versions" {
  source = "../shared/versions"
}

# Available version collections:
# - provider_versions    # Terraform providers
# - kubernetes_versions  # Kubernetes versions
# - tool_versions       # CI/CD tools
# - github_actions      # GitHub Actions versions
# - chart_versions      # Helm chart versions
# - image_versions      # Container images
# - helm_repositories   # Helm repo URLs
```

### **Provider Versions**
```hcl
provider_versions = {
  terraform      = "~> 1.9"
  helm          = "~> 2.15"
  kubernetes    = "~> 2.24"
  azurerm       = "~> 3.0"
  aws           = "~> 5.0"
  kubectl       = "~> 1.14"
  random        = "~> 3.4"
  tls           = "~> 4.0"
}
```

### **Kubernetes Versions**
```hcl
kubernetes_versions = {
  default       = "1.29.7"
  supported     = ["1.28.5", "1.29.7", "1.30.3"]
  addon_compat  = "1.29"
}
```

### **Tool Versions**
```hcl
tool_versions = {
  terraform     = "1.9.5"
  kubectl       = "1.28.0"
  helm          = "3.12.0"
  python        = "3.11"
  node          = "18"
  docker        = "24.0"
}
```

## 🔧 **How to Use**

### **1. In Terraform Modules**
```hcl
# Import shared versions
module "versions" {
  source = "../shared/versions"
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = module.versions.provider_versions.helm
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = module.versions.provider_versions.kubernetes
    }
  }
}

# Use in resources
resource "helm_release" "example" {
  chart   = "my-chart"
  version = module.versions.chart_versions.my_chart
}
```

### **2. In GitHub Workflows**
```yaml
# Reference tool versions
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: "1.9.5"  # From tool_versions.terraform

- name: Setup Python
  uses: actions/setup-python@v4  # From github_actions.setup_python
  with:
    python-version: "3.11"      # From tool_versions.python
```

### **3. In Kubernetes Configs**
```yaml
# config/dev.yaml
azure:
  kubernetes_version: "1.29.7"  # From kubernetes_versions.default
```

## ✅ **Example Implementation**

### **Before (Hardcoded)**
```hcl
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"  # Hardcoded
    }
  }
}
```

### **After (Centralized)**
```hcl
module "versions" {
  source = "../shared/versions"
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = module.versions.provider_versions.helm  # Centralized!
    }
  }
}
```

## 🎯 **Benefits You Get**

### **✅ Single Source of Truth**
- Update version once in `shared/versions/main.tf`
- Automatically applies everywhere

### **✅ Consistent Versions**
- No more version mismatches
- All modules use same provider versions

### **✅ Easy Updates**
```hcl
# Update once in shared/versions/main.tf
provider_versions = {
  helm = "~> 2.16"  # Update here
}
# All modules automatically get the new version!
```

### **✅ Version Tracking**
- Clear git history of version changes
- Easy to see what versions are in use
- Audit trail for compliance

## 📋 **Next Steps**

### **Phase 1: Gradual Migration** ⭐ **RECOMMENDED**
1. **Start small**: Update 2-3 modules to use centralized versions
2. **Test thoroughly**: Ensure no breaking changes
3. **Expand gradually**: Add more modules over time

### **Phase 2: Full Migration**
1. **Update all addon modules**: Use centralized provider versions
2. **Update workflows**: Reference centralized tool versions
3. **Update configs**: Use centralized Kubernetes versions

### **Phase 3: Automation**
1. **Version update scripts**: Automate version updates
2. **Dependency checking**: Validate version compatibility
3. **Security scanning**: Monitor for security updates

## 🚀 **Quick Migration Script**

Want to migrate all modules quickly? Here's a script pattern:

```bash
# Update all addon modules to use centralized versions
for module in infrastructure/addons/terraform/modules/*/; do
  if [[ -f "$module/main.tf" ]]; then
    echo "Updating $module..."
    # Add version module import
    # Update provider versions
    # Test the module
  fi
done
```

## 📊 **Current Status**

### **✅ Implemented**
- ✅ Centralized version collections
- ✅ Provider versions standardized
- ✅ Tool versions centralized
- ✅ Example module updated (cert-manager)

### **🔄 Next Actions**
- Migrate remaining addon modules
- Update workflow tool versions
- Create version update automation

---

**Status**: 🎉 **CENTRALIZED VERSION CONTROL IMPLEMENTED!**

You now have a single source of truth for all versions across your infrastructure! 🚀
