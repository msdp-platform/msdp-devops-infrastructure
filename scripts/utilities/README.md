# 🛠️ MSDP Component Management Utilities

This directory contains Python scripts for managing component versions and generating configuration for the MSDP DevOps Infrastructure platform.

## 📋 Scripts Overview

### 1. `component-version-manager-simple.py`
**Main component version management script** - Automatically discovers components from global config and checks Helm repositories for latest versions.

**Features:**
- ✅ Discovers components from `infrastructure/config/global.yaml`
- ✅ Connects to Helm repositories to fetch latest versions
- ✅ Compares current vs latest versions
- ✅ Updates global.yaml with latest versions (optional)
- ✅ Excludes external-dns from processing (as requested)
- ✅ Uses only system tools (yq, helm) - no Python dependencies

**Usage:**
```bash
# Check current vs latest versions (read-only)
python3 scripts/utilities/component-version-manager-simple.py --check-only

# Update global.yaml with latest versions
python3 scripts/utilities/component-version-manager-simple.py --update
```

### 2. `generate-component-registry.py`
**Component registry generator** - Creates a component registry file for the new modular pipeline architecture.

**Features:**
- ✅ Generates `.github/components.yml` registry
- ✅ Maps components to Helm charts or YAML paths
- ✅ Includes dependency relationships
- ✅ Categorizes components (networking, monitoring, etc.)
- ✅ Ready for new pipeline architecture

**Usage:**
```bash
# Generate component registry
python3 scripts/utilities/generate-component-registry.py

# Generate to custom location
python3 scripts/utilities/generate-component-registry.py --output path/to/components.yml
```

### 3. `component-version-manager.py` (Advanced)
**Full-featured version** - Includes additional features but requires Python packages.

**Additional Features:**
- 📊 Detailed reporting and logging
- 🔄 Dry-run mode
- 📝 Component info dataclasses
- 🎯 More advanced version comparison

## 🚀 Quick Start

### Prerequisites
```bash
# Required system tools
brew install yq helm

# Optional: For advanced script
pip3 install PyYAML requests packaging
```

### Basic Usage
```bash
# 1. Check what updates are available
python3 scripts/utilities/component-version-manager-simple.py --check-only

# 2. Generate component registry for new pipeline
python3 scripts/utilities/generate-component-registry.py

# 3. Update to latest versions (creates backup)
python3 scripts/utilities/component-version-manager-simple.py --update
```

## 📊 Example Output

### Version Check Report
```
================================================================================
🔍 COMPONENT VERSION REPORT
================================================================================

📦 PLATFORM COMPONENTS
--------------------------------------------------------------------------------
Component       Current Chart   Latest Chart    Current App  Latest App   Update?
--------------------------------------------------------------------------------
nginx_ingress   4.8.3           4.13.2          v1.13.2      1.13.2       🔄 YES
cert_manager    v1.18.0         v1.18.2         v1.18.0      v1.18.2      🔄 YES
external_dns    SKIPPED         (requested)     N/A          N/A          ➖
prometheus      25.8.2          77.5.0          v3.5.0       v0.85.0      🔄 YES
grafana         6.61.0          9.4.4           12.1.1       12.1.1       🔄 YES

📦 APPLICATIONS
--------------------------------------------------------------------------------
Component       Current Chart   Latest Chart    Current App  Latest App   Update?
--------------------------------------------------------------------------------
argocd          5.53.0          8.3.5           v2.9.3       v3.1.4       🔄 YES
backstage       0.6.0           ERROR           1.25.0       ERROR        ❌
crossplane      2.0.2           2.0.2           v2.0.2       2.0.2        ✅ NO

📊 SUMMARY
----------------------------------------
Total components: 7
Updates available: 5
Up to date: 2
```

## 🏗️ Component Registry Structure

The generated `.github/components.yml` file contains:

```yaml
metadata:
  name: msdp-components
  description: Component registry for MSDP DevOps Infrastructure
  version: 1.0.0
  generated: "2025-09-09T03:30:35Z"

components:
  nginx_ingress:
    type: helm                    # Deployment type: helm or yaml
    category: networking          # Component category
    namespace: ingress-nginx      # Kubernetes namespace
    version: v1.13.2             # Application version
    dependencies: []              # Component dependencies
    chart: ingress-nginx          # Helm chart name
    repository: https://...       # Helm repository URL
    chart_version: 4.8.3          # Helm chart version
  
  backstage:
    type: yaml                    # YAML-based deployment
    category: platform
    namespace: backstage
    version: 1.25.0
    dependencies: [argocd]        # Depends on ArgoCD
    path: infrastructure/applications/backstage  # Path to YAML files
```

## 🎯 Integration with New Pipeline

The component registry is designed to work with a new modular pipeline architecture:

1. **Dynamic Component Discovery**: Pipeline reads `.github/components.yml`
2. **Dependency-Aware Deployment**: Respects component dependencies
3. **Mixed Deployment Types**: Supports both Helm and YAML deployments
4. **Environment-Specific Values**: Merges global + environment configs

## 🔧 Configuration Files

### Source Configuration
- `infrastructure/config/global.yaml` - Main component definitions
- `infrastructure/config/environments/` - Environment-specific overrides
- `infrastructure/config/components/` - Detailed component configs

### Generated Files
- `.github/components.yml` - Component registry for new pipeline
- `infrastructure/config/global.yaml.backup.*` - Automatic backups

## ⚠️ Important Notes

1. **External DNS Exclusion**: As requested, external-dns is skipped in version updates but included in registry
2. **Backup Creation**: Scripts automatically backup `global.yaml` before making changes
3. **Helm Repository Setup**: Scripts automatically add and update required Helm repositories
4. **Version Normalization**: Handles version strings with/without 'v' prefix correctly

## 🚀 Future Enhancements

- **Multi-environment Support**: Update versions per environment
- **Rollback Capability**: Restore from backups
- **Validation**: Verify configurations before applying
- **Integration**: Direct pipeline integration for automated updates

## 🆘 Troubleshooting

### Common Issues

**Script fails with "yq not found":**
```bash
brew install yq
```

**Script fails with "helm not found":**
```bash
brew install helm
```

**Backstage shows ERROR:**
- Backstage doesn't have a public Helm repository
- This is expected and normal

**Permission denied:**
```bash
chmod +x scripts/utilities/*.py
```

## 📝 Usage Examples

### Daily Workflow
```bash
# Morning routine: Check for updates
python3 scripts/utilities/component-version-manager-simple.py --check-only

# If updates available, review and apply
python3 scripts/utilities/component-version-manager-simple.py --update

# Regenerate component registry for pipeline
python3 scripts/utilities/generate-component-registry.py

# Commit changes
git add infrastructure/config/global.yaml .github/components.yml
git commit -m "Update component versions to latest"
```

### CI/CD Integration
```yaml
# In GitHub Actions
- name: Check Component Versions
  run: python3 scripts/utilities/component-version-manager-simple.py --check-only

- name: Generate Component Registry  
  run: python3 scripts/utilities/generate-component-registry.py
```

This provides a complete, automated solution for managing component versions while excluding external-dns as requested! 🎉
