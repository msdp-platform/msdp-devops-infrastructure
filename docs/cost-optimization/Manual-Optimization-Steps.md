# 🚀 Manual AKS Cost Optimization Steps

## 🎯 **Step-by-Step Optimization for Visual Studio Subscription**

Since the automated script is having issues, here are the manual steps you can execute to optimize your AKS cluster:

### **Step 1: Check Current Status**
```bash
# Check current subscription
az account show --query "{subscriptionId: id, subscriptionName: name, subscriptionType: subscriptionPolicies.quotaId}" -o table

# Check current nodes
kubectl get nodes

# Check current node pools
az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table
```

### **Step 2: Remove Karpenter (if present)**
```bash
# Scale down Karpenter
kubectl scale deployment karpenter -n kube-system --replicas=0

# Delete Karpenter components
kubectl delete nodepools --all
kubectl delete nodeclaims --all
kubectl delete deployment karpenter -n kube-system

# Check for any Karpenter nodes and remove them
kubectl get nodes -l karpenter.sh/nodepool
# If any found, drain and delete them:
# kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
# kubectl delete node <node-name>
```

### **Step 3: Test Spot Instance Support**
```bash
# Test if Spot instances are supported in your subscription
az vm create \
  --resource-group delivery-platform-aks-rg \
  --name spot-test-vm \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --priority Spot \
  --eviction-policy Delete \
  --admin-username azureuser \
  --generate-ssh-keys \
  --no-wait

# Check if the command succeeded
# If it fails with quota/not supported error, Spot instances are not available
# If it succeeds, clean up:
# az vm delete --resource-group delivery-platform-aks-rg --name spot-test-vm --yes
```

### **Step 4: Test System Pool B1s Support**
```bash
# Test if B1s is supported for system pools
az aks nodepool add \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name test-b1s-system \
  --mode System \
  --vm-size Standard_B1s \
  --node-count 0 \
  --min-count 0 \
  --max-count 1 \
  --no-wait

# Check if the command succeeded
# If it fails, B1s is not supported for system pools
# If it succeeds, clean up:
# az aks nodepool delete --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name test-b1s-system --yes
```

### **Step 5: Optimize User Pool**

#### **Option A: If Spot Instances Supported**
```bash
# Check if user pool exists
az aks nodepool show --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name userpool

# If user pool doesn't exist, create it with Spot instances:
az aks nodepool add \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name userpool \
  --mode User \
  --vm-size Standard_B2s \
  --node-count 0 \
  --min-count 0 \
  --max-count 3 \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --labels "cost-optimized=true,spot-instance=true"

# If user pool exists, update it to Spot instances:
az aks nodepool update \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name userpool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --labels "cost-optimized=true,spot-instance=true"
```

#### **Option B: If Spot Instances Not Supported**
```bash
# Create/update user pool with on-demand instances
az aks nodepool add \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name userpool \
  --mode User \
  --vm-size Standard_B2s \
  --node-count 0 \
  --min-count 0 \
  --max-count 2 \
  --enable-cluster-autoscaler \
  --labels "cost-optimized=true,scale-to-zero=true"
```

### **Step 6: Optimize System Pool**

#### **Option A: If B1s Supported for System Pools**
```bash
# Create new optimized system pool
az aks nodepool add \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name system-optimized \
  --mode System \
  --vm-size Standard_B1s \
  --node-count 1 \
  --min-count 1 \
  --max-count 2 \
  --enable-cluster-autoscaler \
  --labels "cost-optimized=true,system-pool=true"

# Wait for new nodes to be ready
kubectl get nodes

# Once new nodes are ready and pods are running, delete old system pool:
az aks nodepool delete \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name nodepool1 \
  --yes
```

#### **Option B: If B1s Not Supported for System Pools**
```bash
# Keep existing system pool but optimize it
az aks nodepool update \
  --resource-group delivery-platform-aks-rg \
  --cluster-name delivery-platform-aks \
  --nodepool-name nodepool1 \
  --min-count 1 \
  --max-count 2 \
  --enable-cluster-autoscaler \
  --labels "cost-optimized=true,system-pool=true"
```

### **Step 7: Verify Optimization**
```bash
# Check final node pools
az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table

# Check final nodes
kubectl get nodes -o wide

# Check pod distribution
kubectl get pods --all-namespaces -o wide | head -20
```

## 📊 **Expected Cost Savings**

### **Best Case Scenario (Spot + B1s supported):**
- System Pool: B1s (~$3.74/month)
- User Pool: B2s Spot (~$3.02/month when running)
- **Total**: $3.74/month (idle) to $6.76/month (active)
- **Savings**: 87-89%

### **Good Case Scenario (Spot supported, B1s not):**
- System Pool: B2s (~$30/month)
- User Pool: B2s Spot (~$3.02/month when running)
- **Total**: $30/month (idle) to $33.02/month (active)
- **Savings**: 45% when active

### **Fallback Scenario (Neither supported):**
- System Pool: B2s (~$30/month)
- User Pool: B2s On-demand (~$30/month when running)
- **Total**: $30/month (idle) to $60/month (active)
- **Savings**: Scale-to-zero capability

## 🎯 **Key Benefits**

1. **Scale-to-Zero**: User pool scales to 0 when not needed
2. **Cost Optimization**: Maximum savings based on subscription capabilities
3. **No Karpenter Complexity**: Simple AKS native auto-scaling
4. **Reliable**: System components on stable instances
5. **Flexible**: User workloads on cost-effective instances

## ⚠️ **Important Notes**

- Execute steps in order
- Wait for each step to complete before proceeding
- Monitor pod health during system pool changes
- Keep old system pool until new one is verified working
- All changes are reversible if needed

## 🚀 **Ready to Execute**

You can now run these commands step by step to optimize your AKS cluster based on your Visual Studio subscription capabilities!
