# System Node Pool Scale-Down Status

## 🔍 **Current Situation**

### **Configuration Applied**
✅ **Cluster Autoscaler Setting Updated**: `skipNodesWithSystemPods: false`
✅ **System Pod Affinity Enforced**: All system pods restricted to system nodes
✅ **Timing Requirements Met**: 14+ minutes since second node creation

### **Current Node Pool Status**
```
Name       OsType    KubernetesVersion    VmSize        Count    MaxPods    Mode
---------  --------  -------------------  ------------  -------  ---------  ------
nodepool1  Linux     1.32                 Standard_B2s  2        250        System
userpool   Linux     1.32                 Standard_B2s  0        250        User
```

**Expected**: System node pool should scale down to 1 node
**Actual**: System node pool still has 2 nodes

## 📊 **Node Utilization Analysis**

### **Node 1** (`aks-nodepool1-64530647-vmss000000`)
- **CPU**: 10% (200m cores)
- **Memory**: 88% (2475Mi)
- **Pods**: All system components + guestbook-ui
- **Status**: High memory usage, should remain

### **Node 2** (`aks-nodepool1-64530647-vmss000001`)
- **CPU**: 4% (91m cores)
- **Memory**: 29% (833Mi)
- **Pods**: Only system daemon pods (kube-proxy, azure-cns, etc.)
- **Status**: Low utilization, ideal candidate for scale-down

## 🚫 **Why Scale-Down May Be Delayed**

### **1. Cluster Autoscaler Conservative Behavior**
The cluster autoscaler is designed to be conservative about scaling down to avoid disrupting workloads. Even with the setting changed, it may take additional time to evaluate.

### **2. System Daemon Pod Rescheduling**
The second node has system daemon pods that need to be rescheduled:
- `kube-proxy-mwbnh`
- `azure-cns-ctmrk`
- `azure-ip-masq-agent-jbzsc`
- `cloud-node-manager-knp4s`
- `csi-azuredisk-node-p5427`
- `csi-azurefile-node-dnkjc`

### **3. Autoscaler Evaluation Cycle**
- **Scan Interval**: 10 seconds
- **Scale-down Delay**: 10 minutes after node addition
- **Unneeded Time**: 10 minutes before considering scale-down
- **Total Time**: May take 20+ minutes for full evaluation

## ⏰ **Timeline Analysis**

### **Node Creation Timeline**
- **Second Node Created**: ~14 minutes ago
- **Scale-down Delay**: 10 minutes ✅ (met)
- **Unneeded Time**: 10 minutes ✅ (met)
- **Total Evaluation Time**: May need additional time

### **Expected Scale-Down Window**
- **Earliest Possible**: 20 minutes after node creation
- **Realistic Timeline**: 25-30 minutes after node creation
- **Current Status**: Still within normal evaluation window

## 🔧 **Possible Solutions**

### **Option 1: Wait for Natural Scale-Down (Recommended)**
**Timeline**: 5-15 more minutes
**Action**: Continue monitoring
**Command**: 
```bash
watch -n 30 'az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table'
```

### **Option 2: Temporarily Disable Autoscaling**
**Action**: Disable autoscaling, manually scale, then re-enable
**Commands**:
```bash
# Disable autoscaling
az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --disable-cluster-autoscaler

# Scale down manually
az aks nodepool scale --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --node-count 1

# Re-enable autoscaling
az aks nodepool update --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --nodepool-name nodepool1 --enable-cluster-autoscaler --min-count 1 --max-count 2
```

### **Option 3: Force Pod Eviction**
**Action**: Manually drain the second node to trigger scale-down
**Commands**:
```bash
# Drain the second node
kubectl drain aks-nodepool1-64530647-vmss000001 --ignore-daemonsets --delete-emptydir-data --force

# Wait for autoscaler to scale down
# Then uncordon if needed
kubectl uncordon aks-nodepool1-64530647-vmss000001
```

## 🎯 **Recommended Approach**

### **Step 1: Continue Monitoring (Next 10 minutes)**
```bash
# Monitor every 2 minutes
for i in {1..5}; do
  echo "Check $i/5: $(date)"
  az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table
  sleep 120
done
```

### **Step 2: If No Scale-Down After 30 Minutes**
Use Option 2 (temporarily disable autoscaling) to force the scale-down.

## 📈 **Expected Results After Scale-Down**

### **System Node Pool**
- **Count**: 1 node (minimum)
- **Cost**: 50% reduction in system node costs
- **Availability**: All system components remain available

### **Pod Distribution**
- **System Components**: All on remaining system node
- **System Daemon Pods**: Rescheduled on remaining system node
- **User Workloads**: Can be scheduled on user nodes when available

## 🔍 **Monitoring Commands**

### **Check Node Pool Status**
```bash
az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks --output table
```

### **Check Node Utilization**
```bash
kubectl top nodes
```

### **Check Pod Distribution**
```bash
kubectl get pods --all-namespaces -o wide | grep -E "(argocd|cert-manager|ingress-nginx|crossplane)"
```

### **Check Autoscaler Events**
```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -i "scale\|autoscaler"
```

## 🎉 **Success Criteria**

✅ **System node pool scales down to 1 node**
✅ **All system components remain available**
✅ **System daemon pods rescheduled successfully**
✅ **Cost reduction achieved (50% system node costs)**
✅ **User node pool remains at 0 nodes (90% user node cost reduction)**

## ⚠️ **Important Notes**

- **System components** will remain available during scale-down
- **System daemon pods** will be rescheduled on the remaining node
- **User workloads** are not affected by this change
- **Cost optimization** will be achieved once scale-down completes
- **Platform manager** will work optimally with 1 system node
