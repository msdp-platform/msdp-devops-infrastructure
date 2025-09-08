# 🎛️ Platform Management Scripts

## 🎯 **Overview**

This directory contains the core platform management scripts that provide unified control over the Multi-Service Delivery Platform operations.

## 📁 **Scripts**

### **platform-manager.py**
**Purpose**: Unified Python platform manager with intelligent cost optimization

**Features**:
- Start, stop, status, optimize operations
- Intelligent cost optimization with automatic Spot instance selection
- Broad SKU selection for maximum cost efficiency
- System pod affinity and isolation
- Comprehensive cost reporting and analysis

**Usage**:
```bash
# Start platform (scale up nodes)
python3 scripts/platform-management/platform-manager.py start

# Stop platform (scale down to 0 nodes - saves costs)
python3 scripts/platform-management/platform-manager.py stop

# Check platform status
python3 scripts/platform-management/platform-manager.py status

# Optimize costs
python3 scripts/platform-management/platform-manager.py optimize

# Optimize Spot NodePool
python3 scripts/platform-management/platform-manager.py optimize-spot
```

**Key Capabilities**:
- **Intelligent Cost Optimization**: Automatic selection of most cost-effective Spot instances
- **Broad SKU Selection**: Uses B, D, E, F series for maximum availability
- **System Pod Isolation**: Ensures system components run on dedicated nodes
- **Automatic Scaling**: Intelligent node scaling based on demand
- **Cost Monitoring**: Real-time cost tracking and optimization

### **deploy-platform-components.sh**
**Purpose**: Deploy platform components (NGINX Ingress, Cert-Manager, External DNS)

**Features**:
- Deploy networking platform components
- Deploy monitoring platform components
- Environment-specific deployment (dev, test, prod)
- Dry-run mode for validation
- Comprehensive verification

**Usage**:
```bash
# Deploy all platform components to dev
./scripts/platform-management/deploy-platform-components.sh

# Deploy networking components to test
./scripts/platform-management/deploy-platform-components.sh -e test -c networking

# Dry run for prod
./scripts/platform-management/deploy-platform-components.sh -e prod -d

# Deploy monitoring to dev with verbose output
./scripts/platform-management/deploy-platform-components.sh -e dev -c monitoring -v
```

### **platform**
**Purpose**: Shell wrapper for platform manager

**Usage**:
```bash
# Start platform
./scripts/platform-management/platform start

# Stop platform
./scripts/platform-management/platform stop

# Check status
./scripts/platform-management/platform status

# Optimize costs
./scripts/platform-management/platform optimize
```

### **scale-aks-nodes.sh**
**Purpose**: AKS node scaling operations

**Features**:
- Scale up/down AKS nodes
- Cost monitoring and reporting
- Node pool management
- Scaling validation

**Usage**:
```bash
# Scale up nodes
./scripts/platform-management/scale-aks-nodes.sh up

# Scale down nodes
./scripts/platform-management/scale-aks-nodes.sh down

# Check status
./scripts/platform-management/scale-aks-nodes.sh status
```

## 🎯 **Key Benefits**

- **Unified Management**: Single interface for all platform operations
- **Intelligent Optimization**: Automatic cost optimization and Spot instance selection
- **Cost Monitoring**: Real-time cost tracking and optimization
- **Automated Scaling**: Intelligent node scaling based on demand
- **System Isolation**: Proper system pod scheduling and isolation

## 🚀 **Quick Start**

```bash
# Start the platform
./scripts/platform-management/platform start

# Check status
./scripts/platform-management/platform status

# Stop the platform (saves costs)
./scripts/platform-management/platform stop
```
