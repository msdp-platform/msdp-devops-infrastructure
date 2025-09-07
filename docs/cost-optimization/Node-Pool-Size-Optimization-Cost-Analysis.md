# Node Pool Size Optimization - Cost Analysis

## 🎯 **Optimization Strategy**

### **Current Configuration**
- **System Node Pool**: B2s (2 vCPU, 4 GB RAM)
- **User Node Pool**: B2s (2 vCPU, 4 GB RAM)

### **Optimized Configuration**
- **System Node Pool**: B1s (1 vCPU, 1 GB RAM) - Always-on
- **User Node Pool**: B2s Spot (2 vCPU, 4 GB RAM) - On-demand with Spot pricing

## 💰 **Cost Comparison Analysis**

### **Azure VM Pricing (East US Region)**

#### **Standard B1s**
- **Specs**: 1 vCPU, 1 GB RAM
- **Price**: ~$0.0052/hour
- **Monthly**: ~$3.74/month
- **Use Case**: System daemon pods (kube-proxy, azure-cns, etc.)

#### **Standard B2s**
- **Specs**: 2 vCPU, 4 GB RAM
- **Price**: ~$0.0416/hour
- **Monthly**: ~$30.00/month
- **Use Case**: System components (ArgoCD, cert-manager, etc.)

#### **Standard B2s Spot**
- **Specs**: 2 vCPU, 4 GB RAM
- **Price**: ~$0.0042/hour (up to 90% discount)
- **Monthly**: ~$3.02/month
- **Use Case**: User workloads (can tolerate interruptions)

## 📊 **Cost Scenarios**

### **Scenario 1: Platform Stopped (Maximum Cost Optimization)**
```
System Node Pool: 1 × B1s = $3.74/month
User Node Pool: 0 × B2s Spot = $0/month
Total: $3.74/month
```

**Cost Reduction**: ~95% compared to running 2 × B2s ($60/month)

### **Scenario 2: Platform Running (Good Cost Optimization)**
```
System Node Pool: 1 × B1s = $3.74/month
User Node Pool: 1 × B2s Spot = $3.02/month
Total: $6.76/month
```

**Cost Reduction**: ~89% compared to running 2 × B2s ($60/month)

### **Scenario 3: High Load (Maximum Capacity)**
```
System Node Pool: 2 × B1s = $7.48/month
User Node Pool: 3 × B2s Spot = $9.06/month
Total: $16.54/month
```

**Cost Reduction**: ~72% compared to running 5 × B2s ($150/month)

## 🎯 **Cost Optimization Benefits**

### **System Node Pool (B1s)**
- ✅ **50% cost reduction** vs B2s
- ✅ **Sufficient resources** for system daemon pods
- ✅ **Always-on** for essential services
- ✅ **Stable pricing** (no Spot interruptions)

### **User Node Pool (B2s Spot)**
- ✅ **Up to 90% cost reduction** vs regular B2s
- ✅ **Same performance** as regular B2s
- ✅ **Scales to 0** when not needed
- ✅ **Perfect for user workloads** that can tolerate interruptions

## 🔧 **Implementation Steps**

### **Step 1: Update System Node Pool to B1s**
```bash
# Disable autoscaling
az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --disable-cluster-autoscaler

# Scale down to 0
az aks nodepool scale --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --node-count 0

# Update VM size
az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --vm-size Standard_B1s

# Scale back to 1
az aks nodepool scale --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --node-count 1

# Re-enable autoscaling
az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --enable-cluster-autoscaler --min-count 1 --max-count 2
```

### **Step 2: Update User Node Pool to B2s Spot**
```bash
# Update to Spot pricing
az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name userpool --vm-size Standard_B2s --priority Spot --eviction-policy Delete --spot-max-price -1
```

### **Step 3: Automated Script**
```bash
# Use the provided script
./scripts/optimize-node-pool-sizes.sh
```

## ⚠️ **Considerations**

### **B1s System Nodes**
- **Pros**: 50% cost reduction, sufficient for system daemon pods
- **Cons**: Limited resources if system components need to run on system nodes
- **Mitigation**: System components are scaled down during stop operation

### **B2s Spot User Nodes**
- **Pros**: Up to 90% cost reduction, same performance
- **Cons**: Can be evicted with 30-second notice
- **Mitigation**: Perfect for user workloads, automatic scaling to 0 when not needed

## 🎉 **Expected Results**

### **Cost Savings**
- **System nodes**: 50% reduction (B1s vs B2s)
- **User nodes**: Up to 90% reduction (Spot vs regular)
- **Overall**: 70-95% cost reduction depending on usage

### **Performance**
- **System daemon pods**: No impact (B1s sufficient)
- **User workloads**: No impact (same B2s specs)
- **Platform functionality**: No impact

### **Reliability**
- **System components**: High reliability (B1s always available)
- **User workloads**: Good reliability (Spot with automatic scaling)

## 📈 **Monitoring and Validation**

### **Cost Monitoring**
```bash
# Check current configuration
az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table

# Monitor costs
python3 scripts/platform-manager.py status
```

### **Performance Validation**
```bash
# Check node resources
kubectl top nodes

# Check pod distribution
kubectl get pods --all-namespaces -o wide
```

## 🎯 **Conclusion**

The optimized node pool configuration provides:

- ✅ **Maximum cost efficiency** with B1s system nodes
- ✅ **Optimal user workload pricing** with B2s Spot
- ✅ **Maintained performance** and functionality
- ✅ **Automatic scaling** and cost optimization
- ✅ **70-95% cost reduction** depending on usage patterns

**This represents the most cost-effective configuration while maintaining full platform functionality and reliability.**
