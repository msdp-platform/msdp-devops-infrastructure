# Azure AKS Module

A cost-effective, production-ready Azure Kubernetes Service (AKS) module with automatic version detection, spot node pools, and comprehensive monitoring.

## Features

- **🔄 Auto Version Detection**: Automatically uses the latest stable AKS version
- **💰 Cost Optimization**: Spot node pools, overlay networking, minimal logging
- **🔐 Security**: OIDC issuer, workload identity, RBAC enabled
- **📊 Monitoring**: Optional Log Analytics with configurable retention
- **🏷️ Tagging**: Comprehensive resource tagging for governance
- **⚡ Performance**: Azure CNI or Azure Overlay networking options

## Cost Optimization Features

### Spot Node Pools
- **Default**: Spot pool enabled with 0-5 nodes
- **Eviction Policy**: Delete (cost-effective)
- **Taints**: `spot=true:NoSchedule` (workload isolation)
- **Max Price**: Current market price (-1)

### Network Optimization
- **Azure Overlay**: Reduces IP consumption (default in stack)
- **Standard Load Balancer**: Cost-effective for most workloads

### Logging
- **Retention**: 30 days (configurable)
- **SKU**: PerGB2018 (pay-per-use)
- **Categories**: Minimal (control plane, audit, API server)

## Usage

### Basic Example

```hcl
module "aks" {
  source = "./modules/azure/aks"
  
  org                = "msdp"
  env                = "dev"
  region             = "uksouth"
  resource_group_name = "rg-aks-dev"
  cluster_name       = "aks-dev"
  subnet_id          = "/subscriptions/.../subnets/aks-subnet"
  
  tags = {
    Environment = "dev"
    Project     = "platform"
  }
}
```

### Advanced Configuration

```hcl
module "aks" {
  source = "./modules/azure/aks"
  
  org                = "msdp"
  env                = "prod"
  region             = "uksouth"
  resource_group_name = "rg-aks-prod"
  cluster_name       = "aks-prod"
  subnet_id          = "/subscriptions/.../subnets/aks-subnet"
  
  # Use specific Kubernetes version
  k8s_version = "1.28.5"
  
  # Private cluster for production
  private_cluster = true
  sku_tier       = "Standard"
  
  # Custom node pools
  system_node = {
    vm_size    = "Standard_D4as_v5"
    min_count  = 2
    max_count  = 5
    os_sku     = "Ubuntu"
  }
  
  spot_node = {
    enabled        = true
    vm_size        = "Standard_D8as_v5"
    min_count      = 0
    max_count      = 10
    max_price      = 0.5  # Max $0.50/hour
    eviction_policy = "Delete"
    taints         = ["spot=true:NoSchedule", "workload=spot:NoSchedule"]
  }
  
  # Extended logging
  log_analytics = {
    enabled        = true
    retention_days = 90
  }
  
  tags = {
    Environment = "prod"
    Project     = "platform"
    CostCenter  = "engineering"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| org | Organization name for resource naming and tagging | `string` | n/a | yes |
| env | Environment name (dev, stg, prod) | `string` | n/a | yes |
| region | Azure region for the AKS cluster | `string` | n/a | yes |
| resource_group_name | Name of the Azure resource group | `string` | n/a | yes |
| cluster_name | Name of the AKS cluster | `string` | n/a | yes |
| subnet_id | ID of the subnet for the AKS cluster | `string` | n/a | yes |
| network_plugin | Network plugin for AKS cluster (azure or azureoverlay) | `string` | `"azure"` | no |
| enable_oidc | Enable OIDC issuer and workload identity for the cluster | `bool` | `true` | no |
| sku_tier | SKU tier for the AKS cluster (Free or Standard) | `string` | `"Free"` | no |
| private_cluster | Enable private cluster (API server not accessible from internet) | `bool` | `false` | no |
| k8s_version | Kubernetes version. If null, uses latest stable version | `string` | `null` | no |
| system_node | Configuration for the system node pool | `object` | See below | no |
| spot_node | Configuration for the spot node pool | `object` | See below | no |
| log_analytics | Configuration for Log Analytics workspace | `object` | See below | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

### system_node Object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vm_size | VM size for system nodes | `string` | `"Standard_D2as_v5"` |
| min_count | Minimum number of system nodes | `number` | `1` |
| max_count | Maximum number of system nodes | `number` | `2` |
| os_sku | OS SKU for system nodes | `string` | `"AzureLinux"` |

### spot_node Object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enabled | Enable spot node pool | `bool` | `true` |
| vm_size | VM size for spot nodes | `string` | `"Standard_D4as_v5"` |
| min_count | Minimum number of spot nodes | `number` | `0` |
| max_count | Maximum number of spot nodes | `number` | `5` |
| max_price | Maximum price per hour (-1 for current market price) | `number` | `-1` |
| eviction_policy | Eviction policy for spot nodes | `string` | `"Delete"` |
| taints | Taints for spot nodes | `list(string)` | `["spot=true:NoSchedule"]` |

### log_analytics Object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enabled | Enable Log Analytics workspace | `bool` | `true` |
| retention_days | Log retention in days | `number` | `30` |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the AKS cluster |
| cluster_name | The name of the AKS cluster |
| cluster_fqdn | The FQDN of the AKS cluster |
| kube_config_raw | Raw Kubernetes config (sensitive) |
| kubelet_identity_object_id | The object ID of the kubelet identity |
| kubelet_identity_client_id | The client ID of the kubelet identity |
| oidc_issuer_url | The OIDC issuer URL for the cluster |
| node_resource_group | The name of the resource group containing the cluster's nodes |
| principal_id | The principal ID of the system-assigned managed identity |
| kubernetes_version | The Kubernetes version of the cluster |
| log_analytics_workspace_id | The ID of the Log Analytics workspace |
| system_node_pool_name | The name of the system node pool |
| spot_node_pool_name | The name of the spot node pool |

## Cost Optimization Tips

### 1. Use Spot Node Pools
- **Default**: Enabled with 0-5 nodes
- **Workloads**: Use taints to schedule spot-tolerant workloads
- **Savings**: Up to 90% cost reduction vs regular instances

### 2. Choose the Right Network Plugin
- **Azure Overlay**: Reduces IP consumption, good for most workloads
- **Azure CNI**: Full control over networking, higher IP consumption

### 3. Optimize Log Retention
- **Development**: 7-30 days
- **Production**: 30-90 days
- **Compliance**: Adjust based on requirements

### 4. Use Azure Linux
- **Default**: Azure Linux (more cost-effective)
- **Alternative**: Ubuntu if specific requirements exist

### 5. Right-size Node Pools
- **System**: Start small (1-2 nodes), scale as needed
- **Spot**: 0 minimum, scale based on workload demand

## Version Management

### Automatic Latest Version (Recommended)
```hcl
# Uses latest stable AKS version automatically
module "aks" {
  # ... other config
  # k8s_version = null  # Default behavior
}
```

### Pin Specific Version
```hcl
# Pin to specific version for stability
module "aks" {
  # ... other config
  k8s_version = "1.28.5"
}
```

## Security Considerations

### OIDC and Workload Identity
- **Default**: Enabled for secure pod-to-Azure authentication
- **Use Case**: External DNS, cert-manager, Azure services integration

### RBAC
- **Default**: Enabled with Azure AD integration
- **Management**: Use Azure AD groups for access control

### Private Clusters
- **Development**: Public (cost-effective)
- **Production**: Consider private for enhanced security

## Monitoring and Observability

### Log Analytics
- **Default**: Enabled with 30-day retention
- **Categories**: Control plane, audit logs, API server
- **Cost**: Pay-per-GB with PerGB2018 SKU

### Metrics
- **Built-in**: Container Insights enabled by default
- **Custom**: Add Prometheus/Grafana for advanced monitoring

## Troubleshooting

### Common Issues

1. **Subnet IP Exhaustion**
   - Use Azure Overlay networking
   - Increase subnet size if needed

2. **Spot Node Evictions**
   - Ensure workloads are spot-tolerant
   - Use proper taints and tolerations

3. **OIDC Issues**
   - Verify OIDC issuer URL is accessible
   - Check workload identity configuration

### Useful Commands

```bash
# Get cluster credentials
az aks get-credentials --resource-group rg-aks-dev --name aks-dev

# Check node pools
kubectl get nodes -o wide

# Check spot nodes
kubectl get nodes -l kubernetes.azure.com/agentpool=spot

# View cluster info
kubectl cluster-info
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| azurerm | >= 3.110 |

## License

This module is part of the MSDP Platform infrastructure and follows the organization's licensing terms.
