# 🛠️ Scripts - Multi-Service Delivery Platform

## 🎯 **Overview**

This directory contains all automation scripts for the Multi-Service Delivery Platform, organized into logical categories for better management and maintenance.

## 📁 **Script Organization Structure**

### **🎛️ Platform Management** (`platform-management/`)
**Purpose**: Core platform operations and management
- **platform-manager.py**: Unified Python platform manager with intelligent cost optimization
- **platform**: Shell wrapper for platform manager
- **scale-aks-nodes.sh**: AKS node scaling operations

### **🏗️ Infrastructure Setup** (`infrastructure-setup/`)
**Purpose**: Infrastructure deployment and configuration
- **setup-minikube-crossplane-argocd.sh**: Complete Minikube + Crossplane + ArgoCD setup
- **setup-multi-cloud-providers.sh**: Multi-cloud provider configuration
- **apply-system-pod-affinity-patch.sh**: System pod affinity patch application
- **apply-system-pod-affinity.sh**: System pod affinity configuration

### **💰 Cost Optimization** (`cost-optimization/`)
**Purpose**: Cost analysis and optimization strategies
- **cost-optimization.sh**: Comprehensive cost optimization analysis
- **cost-optimization-summary.sh**: Cost optimization summary and recommendations
- **optimize-node-pool-sizes.sh**: Node pool size optimization
- **check-aws-free-tier.sh**: AWS free tier eligibility and usage check

### **📊 Monitoring** (`monitoring/`)
**Purpose**: Infrastructure monitoring and observability
- **aks-cost-monitor.sh**: AKS cost monitoring and analysis

### **🧪 Testing** (`testing/`)
**Purpose**: Infrastructure testing and validation
- **test-aks-scaling.sh**: AKS scaling functionality testing

### **🔧 Utilities** (`utilities/`)
**Purpose**: General utility scripts and helpers
- **access-argocd.sh**: ArgoCD access and port-forwarding
- **argocd-access.sh**: Alternative ArgoCD access script
- **cleanup-laptop.sh**: Laptop resource cleanup and optimization

## 🚀 **Quick Start**

### **Platform Management**
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

### **Infrastructure Setup**
```bash
# Complete infrastructure setup
./scripts/infrastructure-setup/setup-minikube-crossplane-argocd.sh

# Configure multi-cloud providers
./scripts/infrastructure-setup/setup-multi-cloud-providers.sh

# Apply system pod affinity
./scripts/infrastructure-setup/apply-system-pod-affinity.sh
```

### **Cost Optimization**
```bash
# Run comprehensive cost analysis
./scripts/cost-optimization/cost-optimization.sh

# Check AWS free tier eligibility
./scripts/cost-optimization/check-aws-free-tier.sh

# Optimize node pool sizes
./scripts/cost-optimization/optimize-node-pool-sizes.sh
```

### **Monitoring**
```bash
# Monitor AKS costs
./scripts/monitoring/aks-cost-monitor.sh
```

### **Testing**
```bash
# Test AKS scaling
./scripts/testing/test-aks-scaling.sh
```

### **Utilities**
```bash
# Access ArgoCD
./scripts/utilities/access-argocd.sh

# Cleanup laptop resources
./scripts/utilities/cleanup-laptop.sh
```

## 🎯 **Script Categories**

### **🎛️ Platform Management Scripts**

#### **platform-manager.py**
- **Purpose**: Unified platform management with intelligent cost optimization
- **Features**: Start, stop, status, optimize operations
- **Cost Optimization**: Automatic Spot instance selection and node pool optimization
- **Usage**: `python3 scripts/platform-management/platform-manager.py [start|stop|status|optimize|optimize-spot]`

#### **platform**
- **Purpose**: Shell wrapper for platform manager
- **Usage**: `./scripts/platform-management/platform [action]`

#### **scale-aks-nodes.sh**
- **Purpose**: AKS node scaling operations
- **Features**: Scale up/down nodes, cost monitoring
- **Usage**: `./scripts/platform-management/scale-aks-nodes.sh [up|down|status]`

### **🏗️ Infrastructure Setup Scripts**

#### **setup-minikube-crossplane-argocd.sh**
- **Purpose**: Complete Minikube + Crossplane + ArgoCD setup
- **Features**: Automated installation and configuration
- **Usage**: `./scripts/infrastructure-setup/setup-minikube-crossplane-argocd.sh`

#### **setup-multi-cloud-providers.sh**
- **Purpose**: Multi-cloud provider configuration
- **Features**: AWS, GCP, Azure provider setup
- **Usage**: `./scripts/infrastructure-setup/setup-multi-cloud-providers.sh`

#### **apply-system-pod-affinity.sh**
- **Purpose**: System pod affinity configuration
- **Features**: Pod scheduling and isolation
- **Usage**: `./scripts/infrastructure-setup/apply-system-pod-affinity.sh`

### **💰 Cost Optimization Scripts**

#### **cost-optimization.sh**
- **Purpose**: Comprehensive cost optimization analysis
- **Features**: VM pricing analysis, cost recommendations
- **Usage**: `./scripts/cost-optimization/cost-optimization.sh`

#### **check-aws-free-tier.sh**
- **Purpose**: AWS free tier eligibility and usage check
- **Features**: Free tier status, usage monitoring
- **Usage**: `./scripts/cost-optimization/check-aws-free-tier.sh`

#### **optimize-node-pool-sizes.sh**
- **Purpose**: Node pool size optimization
- **Features**: VM size optimization, cost reduction
- **Usage**: `./scripts/cost-optimization/optimize-node-pool-sizes.sh`

### **📊 Monitoring Scripts**

#### **aks-cost-monitor.sh**
- **Purpose**: AKS cost monitoring and analysis
- **Features**: Real-time cost tracking, budget alerts
- **Usage**: `./scripts/monitoring/aks-cost-monitor.sh`

### **🧪 Testing Scripts**

#### **test-aks-scaling.sh**
- **Purpose**: AKS scaling functionality testing
- **Features**: Scaling validation, performance testing
- **Usage**: `./scripts/testing/test-aks-scaling.sh`

### **🔧 Utility Scripts**

#### **access-argocd.sh**
- **Purpose**: ArgoCD access and port-forwarding
- **Features**: Port forwarding, access configuration
- **Usage**: `./scripts/utilities/access-argocd.sh`

#### **cleanup-laptop.sh**
- **Purpose**: Laptop resource cleanup and optimization
- **Features**: Resource cleanup, optimization
- **Usage**: `./scripts/utilities/cleanup-laptop.sh`

## 🎯 **Key Features**

### **🎛️ Platform Management**
- **Unified Management**: Single interface for all platform operations
- **Intelligent Optimization**: Automatic cost optimization and Spot instance selection
- **Cost Monitoring**: Real-time cost tracking and optimization
- **Automated Scaling**: Intelligent node scaling based on demand

### **🏗️ Infrastructure Setup**
- **Automated Setup**: Complete infrastructure deployment automation
- **Multi-Cloud Support**: AWS, GCP, Azure provider configuration
- **Pod Scheduling**: System pod affinity and isolation
- **Configuration Management**: Automated configuration and patching

### **💰 Cost Optimization**
- **Comprehensive Analysis**: Detailed cost analysis and recommendations
- **Free Tier Management**: AWS free tier monitoring and optimization
- **Node Pool Optimization**: VM size optimization and cost reduction
- **Real-time Monitoring**: Continuous cost tracking and alerts

### **📊 Monitoring & Testing**
- **Cost Monitoring**: Real-time cost tracking and analysis
- **Scaling Testing**: Infrastructure scaling validation
- **Performance Testing**: Load testing and performance validation
- **Health Checks**: Infrastructure health monitoring

## 🔧 **Script Standards**

### **File Naming Convention**
- Use descriptive, kebab-case names
- Include category prefixes where appropriate
- Use consistent terminology across scripts

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

### **Total Scripts**: 16
- **Platform Management**: 3 scripts
- **Infrastructure Setup**: 4 scripts
- **Cost Optimization**: 4 scripts
- **Monitoring**: 1 script
- **Testing**: 1 script
- **Utilities**: 3 scripts

### **Script Types**
- **Shell Scripts**: 15 scripts (.sh)
- **Python Scripts**: 1 script (.py)
- **Wrapper Scripts**: 1 script (platform)

## 🎉 **Benefits**

### **📈 Improved Organization**
- **Logical grouping** by script purpose and functionality
- **Clear hierarchy** with descriptive category names
- **Easy discovery** of relevant scripts
- **Consistent structure** across all categories

### **🔧 Better Maintenance**
- **Focused updates** within specific script categories
- **Clear ownership** of different script types
- **Easier troubleshooting** with organized script locations
- **Better collaboration** with clear script boundaries

### **👥 Enhanced User Experience**
- **Quick access** to relevant scripts
- **Clear understanding** of script capabilities
- **Comprehensive documentation** for each script
- **Professional organization** for enterprise use

## 🎯 **Summary**

The scripts organization provides:

- **🎯 Clear Structure**: Logical grouping by purpose and functionality
- **📈 Better Navigation**: Easy discovery and access to scripts
- **🔧 Improved Maintenance**: Focused updates and clear ownership
- **👥 Enhanced UX**: Role-based navigation and comprehensive documentation
- **📊 Complete Coverage**: All platform operations automated and documented

**This organization makes the scripts more accessible, maintainable, and user-friendly while preserving all existing functionality and improving the overall user experience.** 🎉
