# 🛠️ Scripts - MSDP Platform

## 🎯 **Overview**

This directory contains essential automation scripts for the MSDP platform, aligned with the smart deployment system and consolidated infrastructure.

## 📁 **Clean Script Organization**

```
scripts/
├── platform-management/           # Platform operations
│   ├── platform-manager.py       # Unified platform manager
│   ├── platform                  # Shell wrapper
│   └── README.md                 # Platform management docs
├── utilities/                     # Utility scripts
│   ├── access-argocd.sh          # ArgoCD access helper
│   ├── argocd-access.sh          # ArgoCD management
│   └── cleanup-laptop.sh         # Resource cleanup
├── testing/                       # Testing scripts
│   └── test-aks-scaling.sh       # AKS scaling tests
└── README.md                      # This documentation
```

## 🚀 **Smart Deployment Integration**

### **Primary Deployment Method: GitHub Actions**
- **Automatic deployment** on push to branches (`dev`, `test`, `prod`)
- **Manual deployment** via GitHub Actions workflow dispatch
- **Environment detection** based on branch
- **Secrets management** through smart deployment system

### **Scripts for Support Operations**
Scripts are now focused on **support operations** rather than primary deployment:

## 🎛️ **Platform Management**

### **Unified Platform Manager**
```bash
# Start platform (scale up nodes)
./scripts/platform-management/platform start

# Stop platform (scale down to 0 nodes - saves costs)
./scripts/platform-management/platform stop

# Check platform status
./scripts/platform-management/platform status

# Optimize costs
./scripts/platform-management/platform optimize
```

**Features:**
- **Intelligent cost optimization** with Spot instances
- **Automated scaling** based on demand
- **Real-time cost monitoring**
- **Azure AKS integration**

## 🔧 **Utilities**

### **ArgoCD Access**
```bash
# Show ArgoCD status and access info
./scripts/utilities/argocd-access.sh status

# Login to ArgoCD CLI
./scripts/utilities/argocd-access.sh login

# Show ArgoCD URL
./scripts/utilities/argocd-access.sh url

# Show detailed access information and methods
./scripts/utilities/argocd-access.sh info

# Show admin password
./scripts/utilities/argocd-access.sh password
```

### **Resource Cleanup**
```bash
# Cleanup laptop resources
./scripts/utilities/cleanup-laptop.sh
```

## 🧪 **Testing**

### **AKS Scaling Tests**
```bash
# Test AKS scaling functionality
./scripts/testing/test-aks-scaling.sh
```

## 🎯 **Key Changes from Previous Version**

### **✅ Removed/Archived**
- **`deploy-backstage.sh`**: Complex deployment script (now handled by GitHub Actions)
- **`deploy-multi-argocd.sh`**: Multi-ArgoCD deployment (now handled by smart deployment)
- **`infrastructure-setup/`**: Setup scripts (now handled by GitHub Actions)
- **`cost-optimization/`**: Cost scripts (integrated into platform manager)
- **`monitoring/`**: Monitoring scripts (handled by platform services)

### **✅ Simplified Focus**
- **Platform Management**: Core operations (start/stop/status/optimize)
- **Utilities**: Support operations (access, cleanup)
- **Testing**: Validation and testing scripts

### **✅ Smart Deployment Aligned**
- **No conflicting deployment methods**
- **GitHub Actions as primary deployment**
- **Scripts for support operations only**
- **Consistent with consolidated infrastructure**

## 🔧 **Script Standards**

### **File Naming Convention**
- Use descriptive, kebab-case names
- Include clear purpose in filename
- Use consistent terminology

### **Script Structure**
- Clear help and usage information
- Error handling and validation
- Logging and output formatting
- Consistent parameter handling

### **Documentation**
- Clear purpose and usage descriptions
- Parameter documentation
- Example usage and output
- Error handling and troubleshooting

## 📊 **Script Statistics**

### **Total Scripts**: 5
- **Platform Management**: 3 scripts
- **Utilities**: 2 scripts
- **Testing**: 1 script

### **Script Types**
- **Shell Scripts**: 4 scripts (.sh)
- **Python Scripts**: 1 script (.py)
- **Wrapper Scripts**: 1 script (platform)

## 🎉 **Benefits**

### **✅ Simplified Management**
- **Clear focus** on support operations
- **No deployment conflicts** with smart deployment system
- **Reduced complexity** with fewer, focused scripts
- **Better maintainability** with clear purpose

### **🚀 Smart Deployment Integration**
- **GitHub Actions** as primary deployment method
- **Branch-driven** deployment workflow
- **Environment-specific** configurations
- **Automated secrets** management

### **🔧 Enhanced User Experience**
- **Quick access** to essential operations
- **Clear understanding** of script capabilities
- **Comprehensive documentation** for each script
- **Professional organization** for enterprise use

## 🎯 **Summary**

The cleaned scripts provide:

- **🎯 Focused Purpose**: Support operations only, no deployment conflicts
- **🚀 Smart Integration**: Fully aligned with smart deployment system
- **🔧 Simplified Management**: Clear, maintainable script organization
- **📊 Essential Operations**: Platform management, utilities, and testing
- **🎉 Professional Structure**: Enterprise-ready script organization

**This organization eliminates script conflicts, aligns with the smart deployment system, and provides essential support operations for the platform.** 🚀

## 📚 **Additional Resources**

- [Smart Deployment System](../infrastructure/README-Smart-Deployment.md)
- [Consolidated Infrastructure](../infrastructure/README.md)
- [GitHub Actions Workflows](../ci-cd/workflows/)

## 🤝 **Contributing**

1. Keep scripts focused on support operations
2. Don't create deployment scripts (use GitHub Actions)
3. Follow script standards and documentation
4. Test scripts thoroughly before committing

---

**Scripts are now clean, focused, and fully aligned with the smart deployment system.** 🚀