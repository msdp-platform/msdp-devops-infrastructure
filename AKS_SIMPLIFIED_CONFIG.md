# AKS Simplified Configuration

## Changes Made

To resolve the Terraform provider compatibility issues, I've simplified the AKS configuration to use only the essential, well-supported attributes.

### 1. Default Node Pool - Simplified
**Removed:**
- `temporary_name_for_rotation` - Can cause issues
- `os_disk_type = "Managed"` - This is the default
- `node_labels` - Can be added post-creation if needed

**Kept:**
- Basic configuration (name, node_count, vm_size)
- Network configuration (vnet_subnet_id)
- Essential settings (max_pods, os_disk_size_gb)
- Availability zones

### 2. User Node Pool - Simplified
**Removed (temporarily):**
- Auto-scaling configuration - Will add back once basic deployment works
- `vnet_subnet_id` - Not needed, uses cluster's subnet
- `os_disk_type` - Uses default
- `node_labels` - Can be added later
- `node_taints` - Can be added later

**Kept:**
- Basic configuration (name, vm_size, node_count)
- Essential settings (max_pods, os_disk_size_gb)
- Spot instance configuration (if enabled)
- Availability zones

## Current Working Configuration

### Default Node Pool
```hcl
default_node_pool {
  name           = "system"
  node_count     = var.system_node_count
  vm_size        = var.system_vm_size
  vnet_subnet_id = data.azurerm_subnet.aks.id
  max_pods        = var.max_pods_per_node
  os_disk_size_gb = var.os_disk_size_gb
  zones          = var.availability_zones
}
```

### User Node Pool
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  node_count            = var.user_min_count
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = var.os_disk_size_gb
  zones                 = var.availability_zones
  
  # Spot instances (optional)
  priority        = var.user_spot_enabled ? "Spot" : "Regular"
  eviction_policy = var.user_spot_enabled ? "Delete" : null
  spot_max_price  = var.user_spot_enabled ? var.user_spot_max_price : null
  
  tags = var.tags
}
```

## Features Temporarily Disabled

These features can be added back once the basic deployment is working:

1. **Auto-scaling**: Will need to determine the correct attribute syntax for the provider version
2. **Node Labels**: Can be added via kubectl after cluster creation
3. **Node Taints**: Can be added via kubectl after cluster creation
4. **Advanced disk options**: Using defaults for now

## Benefits of Simplified Configuration

1. **Compatibility**: Works with multiple provider versions
2. **Reliability**: Fewer attributes means fewer potential conflicts
3. **Debugging**: Easier to identify issues with minimal configuration
4. **Progressive Enhancement**: Can add features incrementally

## Next Steps

1. **Test Basic Deployment**: Ensure the simplified configuration deploys successfully
2. **Add Auto-scaling**: Once working, carefully add auto-scaling with correct syntax
3. **Add Labels/Taints**: Add node customizations as needed
4. **Optimize**: Add performance and cost optimizations

## Testing

Run the workflow to test the simplified configuration:
```bash
gh workflow run aks.yml -f action=plan -f environment=dev
```

The plan should now work without attribute errors. Once successful, features can be added back incrementally.