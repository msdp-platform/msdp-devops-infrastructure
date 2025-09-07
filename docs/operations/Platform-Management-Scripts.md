# Platform Management Script

## 🎯 Overview

This document describes the unified platform management script for starting, stopping, and monitoring your Multi-Service Delivery Platform. The script provides easy control over your AKS infrastructure to optimize costs and manage resources.

## 🚀 Unified Platform Manager

### **Main Script**
**File**: `scripts/platform-manager.py`

**Purpose**: Unified Python script to manage all platform operations with a single command.

**Features**:
- ✅ Start platform (scale up nodes)
- ✅ Stop platform (scale down to 0 nodes)
- ✅ Check platform status
- ✅ Azure CLI authentication checks
- ✅ AKS cluster connection management
- ✅ Service health verification
- ✅ Cost information display
- ✅ Safety confirmations

### **Usage Options**

#### **Start Platform**
```bash
# Using Python directly
python3 scripts/platform-manager.py start

# Using shell wrapper (easier)
./scripts/platform start
```

**What it does**:
1. Verifies Azure CLI authentication
2. Connects to your AKS cluster
3. Scales up nodes (if currently at 0)
4. Checks that ArgoCD, NGINX Ingress, and sample app are running
5. Displays service URLs and credentials
6. Shows cost monitoring information

#### **Stop Platform**
```bash
# Using Python directly
python3 scripts/platform-manager.py stop

# Using shell wrapper (easier)
./scripts/platform stop
```

**What it does**:
1. Asks for confirmation before stopping
2. Scales down all user deployments to 0 replicas
3. Waits for pods to terminate gracefully
4. Allows autoscaler to scale nodes down to 0
5. Shows cost savings and final status

#### **Check Status**
```bash
# Using Python directly
python3 scripts/platform-manager.py status

# Using shell wrapper (easier)
./scripts/platform status
```

**What it shows**:
1. Current node count and status
2. Running pods by namespace
3. LoadBalancer and ingress status
4. Service URLs and credentials
5. Cost impact (running vs stopped)
6. Platform state and next actions

## 💰 Cost Optimization

### **Cost Savings with Stop Script**
When you run the stop script:
- **Compute Costs**: Reduced to 0 (nodes scaled to 0)
- **Storage Costs**: Minimal (persistent volumes remain)
- **LoadBalancer Costs**: Small ongoing cost (cannot be stopped)
- **Total Savings**: ~90% of compute costs

### **Cost Monitoring**
Use these scripts to monitor costs:
```bash
# Check current status and costs
./scripts/platform-status.sh

# Detailed cost analysis
./scripts/aks-cost-monitor.sh

# Start platform (will consume resources)
./scripts/start-platform.sh

# Stop platform (will save costs)
./scripts/stop-platform.sh
```

## 🔧 Technical Details

### **Node Scaling Strategy**
- **Start**: Creates temporary deployment to trigger autoscaling
- **Stop**: Scales down deployments first, then waits for autoscaler
- **Autoscaler**: Automatically scales nodes based on pod requirements
- **Scale to 0**: Achieved by removing all user workloads

### **Service Management**
- **System Services**: ArgoCD, NGINX Ingress, cert-manager remain running
- **User Services**: Sample apps and deployments are scaled down
- **LoadBalancer**: Remains active (cannot be stopped without losing public IP)

### **Safety Features**
- **Confirmation**: Stop script asks for confirmation
- **Graceful Shutdown**: Waits for pods to terminate properly
- **Status Checks**: Verifies operations before proceeding
- **Error Handling**: Provides clear error messages

## 📊 Usage Examples

### **Daily Development Workflow**
```bash
# Morning: Start platform
./scripts/start-platform.sh

# Work on your applications
# Access ArgoCD: https://argocd.dev.aztech-msdp.com
# Deploy applications, test, develop

# Evening: Stop platform to save costs
./scripts/stop-platform.sh
```

### **Check Status Anytime**
```bash
# Quick status check
./scripts/platform-status.sh

# Detailed cost analysis
./scripts/aks-cost-monitor.sh
```

### **Emergency Stop**
```bash
# Stop immediately (with confirmation)
./scripts/stop-platform.sh
```

## 🚨 Important Notes

### **Before Using Scripts**
1. **Azure CLI**: Must be logged in (`az login`)
2. **Permissions**: Need AKS cluster access
3. **Resource Group**: `delivery-platform-aks-rg`
4. **Cluster Name**: `delivery-platform-aks`

### **When Stopping Platform**
- ⚠️ **Services Unavailable**: All services will be inaccessible
- ⚠️ **Data Persistence**: Persistent volumes remain (data safe)
- ⚠️ **Public IP**: LoadBalancer keeps public IP (small cost)
- ⚠️ **Restart Time**: Takes 2-5 minutes to fully start

### **When Starting Platform**
- ✅ **Automatic Scaling**: Nodes scale up automatically
- ✅ **Service Recovery**: All services become available
- ✅ **SSL Certificates**: Automatically renewed if needed
- ✅ **DNS**: Domain resolution works immediately

## 🎯 Best Practices

### **Cost Optimization**
1. **Stop at Night**: Use stop script when not developing
2. **Start for Work**: Use start script when beginning work
3. **Monitor Costs**: Check costs regularly with status script
4. **Weekend Shutdown**: Stop platform on weekends

### **Development Workflow**
1. **Start Platform**: Begin development session
2. **Deploy Applications**: Use ArgoCD for deployments
3. **Test Services**: Verify applications work
4. **Stop Platform**: End development session

### **Monitoring**
1. **Regular Status Checks**: Use status script frequently
2. **Cost Monitoring**: Check costs weekly
3. **Service Health**: Verify services are running
4. **Resource Usage**: Monitor node and pod counts

## 🎉 Benefits

### **Cost Savings**
- **90% Cost Reduction**: When platform is stopped
- **Pay for Use**: Only pay when actively developing
- **Automatic Scaling**: No manual node management
- **Resource Optimization**: Efficient resource utilization

### **Operational Efficiency**
- **One-Command Control**: Simple start/stop operations
- **Status Visibility**: Clear platform state information
- **Safety Features**: Confirmation and error handling
- **Automated Management**: No manual intervention needed

### **Development Experience**
- **Quick Start**: Platform ready in minutes
- **Cost Awareness**: Clear cost information
- **Service Access**: Easy access to all services
- **Professional Setup**: Production-ready infrastructure

## 🚀 Next Steps

1. **Try the Scripts**: Test start, stop, and status scripts
2. **Monitor Costs**: Use cost monitoring scripts
3. **Develop Applications**: Use ArgoCD for deployments
4. **Optimize Usage**: Stop platform when not needed

**Your platform is now fully manageable with simple, cost-optimized scripts!** 🎉
