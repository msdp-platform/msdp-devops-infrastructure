# Karpenter on AKS - Analysis and Implementation Guide

## Executive Summary

**Can we implement Karpenter on AKS?** 
**Answer: No, not directly. But Azure has a native alternative.**

Karpenter is an **AWS-specific** node provisioning solution that works with Amazon EKS. However, Azure provides **Karpenter-like functionality** through native AKS features.

## Why Karpenter Doesn't Work on AKS

1. **Cloud Provider Specific**: Karpenter is tightly integrated with AWS APIs (EC2, IAM, etc.)
2. **Architecture Mismatch**: Karpenter relies on AWS-specific constructs like:
   - EC2 Fleet API
   - AWS Instance Metadata Service
   - IAM Roles for Service Accounts (IRSA)
   - AWS pricing APIs

## Azure's Alternative: AKS Node Auto-provisioning (NAP)

Azure provides similar functionality through **Node Auto-provisioning (NAP)**, which is currently in **Preview**.

### Features Comparison

| Feature | Karpenter (EKS) | AKS Native Solution |
|---------|-----------------|---------------------|
| **Automatic node provisioning** | ✅ | ✅ (NAP + Cluster Autoscaler) |
| **Right-sizing nodes** | ✅ | ✅ (NAP) |
| **Spot instance support** | ✅ | ✅ |
| **Fast scaling** | ✅ (< 60s) | ⚡ (60-90s) |
| **Bin packing** | ✅ | ✅ |
| **Custom node pools** | ✅ | ✅ |
| **GPU support** | ✅ | ✅ |
| **Multi-architecture** | ✅ | ✅ |

## Current Best Practice for AKS Auto-scaling

### 1. **Cluster Autoscaler** (Production Ready)
```hcl
# In your AKS configuration
resource "azurerm_kubernetes_cluster" "main" {
  # ... other config ...
  
  default_node_pool {
    name                = "system"
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 3
    # ...
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                = "user"
  enable_auto_scaling = true
  min_count          = 0
  max_count          = 10
  # ...
}
```

### 2. **KEDA** (Kubernetes Event-driven Autoscaling)
For pod-level autoscaling based on events:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: app-scaler
spec:
  scaleTargetRef:
    name: my-app
  minReplicaCount: 0
  maxReplicaCount: 100
  triggers:
  - type: azure-queue
    metadata:
      queueName: myqueue
      queueLength: '5'
```

### 3. **Virtual Nodes** (Azure Container Instances)
For serverless burst capacity:
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  addon_profile {
    aci_connector_linux {
      enabled     = true
      subnet_name = "virtual-node-subnet"
    }
  }
}
```

## Recommended Auto-scaling Strategy for Your AKS Setup

### Phase 1: Basic Auto-scaling (Immediate)
```hcl
# Update your AKS configuration
resource "azurerm_kubernetes_cluster" "main" {
  # ... existing config ...
  
  default_node_pool {
    name                = "system"
    vm_size            = "Standard_D2s_v3"
    enable_auto_scaling = true
    min_count          = 2
    max_count          = 4
    node_count         = 2  # Initial count
  }
  
  # Auto-scaler profile for fine-tuning
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "least-waste"  # or "priority" or "random"
    max_graceful_termination_sec     = "600"
    max_node_provisioning_time       = "15m"
    max_unready_nodes               = 3
    max_unready_percentage          = 45
    new_pod_scale_up_delay          = "10s"
    scale_down_delay_after_add      = "10m"
    scale_down_delay_after_delete   = "10s"
    scale_down_delay_after_failure  = "3m"
    scan_interval                   = "10s"
    scale_down_unneeded             = "10m"
    scale_down_unready              = "20m"
    scale_down_utilization_threshold = "0.5"
    skip_nodes_with_local_storage   = true
    skip_nodes_with_system_pods     = true
  }
}

# Multiple node pools for different workload types
resource "azurerm_kubernetes_cluster_node_pool" "general" {
  name                = "general"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size            = "Standard_D4s_v3"
  enable_auto_scaling = true
  min_count          = 0
  max_count          = 20
  
  node_labels = {
    "workload-type" = "general"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size            = "Standard_D4s_v3"
  priority           = "Spot"
  eviction_policy    = "Delete"
  spot_max_price     = -1  # Use market price
  
  enable_auto_scaling = true
  min_count          = 0
  max_count          = 50
  
  node_labels = {
    "workload-type" = "batch"
    "node-type"     = "spot"
  }
  
  node_taints = [
    "spot=true:NoSchedule"
  ]
}
```

### Phase 2: Add KEDA for Event-driven Scaling
```bash
# Install KEDA
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
```

### Phase 3: Monitor and Optimize
```yaml
# Monitoring with Azure Monitor
apiVersion: v1
kind: ConfigMap
metadata:
  name: container-azm-ms-agentconfig
  namespace: kube-system
data:
  schema-version: v1
  config-version: ver1
  log-data-collection-settings: |-
    [log_collection_settings]
       [log_collection_settings.stdout]
          enabled = true
       [log_collection_settings.stderr]
          enabled = true
  prometheus-data-collection-settings: |-
    [prometheus_data_collection_settings]
       [prometheus_data_collection_settings.cluster]
          interval = "1m"
          monitor_kubernetes_pods = true
```

## Implementation Steps for Your Project

### 1. Update AKS Module with Auto-scaling
```hcl
# infrastructure/environment/azure/aks/main.tf
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  
  # Enable auto-scaling
  enable_auto_scaling = true
  min_count          = var.user_min_count
  max_count          = var.user_max_count
  
  # Other configurations...
}
```

### 2. Configure Pod Disruption Budgets
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

### 3. Use Node Affinity for Workload Placement
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spot-workload
spec:
  template:
    spec:
      tolerations:
      - key: "spot"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      nodeSelector:
        node-type: spot
```

## Cost Optimization Tips

1. **Use Spot Instances**: Up to 90% cost savings for fault-tolerant workloads
2. **Right-size VMs**: Use different node pools for different workload requirements
3. **Scale to Zero**: Configure min_count=0 for non-critical node pools
4. **Reserved Instances**: For predictable base capacity

## Monitoring Auto-scaling

```bash
# Check autoscaler status
kubectl get nodes
kubectl get events --all-namespaces | grep scale

# View autoscaler logs
kubectl logs -n kube-system -l component=cluster-autoscaler

# Check node pool status
az aks nodepool list --resource-group <rg> --cluster-name <cluster>
```

## Conclusion

While Karpenter itself cannot be used on AKS, Azure provides robust auto-scaling capabilities through:
1. **Native Cluster Autoscaler** - Production ready
2. **Node Auto-provisioning (NAP)** - Preview
3. **KEDA** - Event-driven scaling
4. **Virtual Nodes** - Serverless burst

These solutions together provide Karpenter-like functionality optimized for Azure infrastructure.

## Next Steps for Your Implementation

1. **Enable auto-scaling** in your current AKS configuration
2. **Test with the simplified configuration** first
3. **Add multiple node pools** for different workload types
4. **Implement KEDA** for advanced scaling scenarios
5. **Monitor and optimize** based on actual usage patterns