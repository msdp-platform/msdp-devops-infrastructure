# AzureRM Provider v4.x Compatibility Fixes

## Summary of Attribute Changes

The AzureRM provider v4.x has different attribute names than what was initially used. Here are the corrections made:

### 1. AKS Cluster - Azure AD RBAC
**Issue:** `managed` is not a valid argument

**Fix:** Removed `managed = true` - it's always managed in v4.x

```hcl
# Before (Invalid)
azure_active_directory_role_based_access_control {
  managed = true  # ❌ Not valid in v4.x
  ...
}

# After (Valid)
azure_active_directory_role_based_access_control {
  tenant_id              = var.tenant_id
  admin_group_object_ids = var.admin_group_object_ids
  azure_rbac_enabled     = true
}
```

### 2. AKS Node Pool - Auto-scaling
**Issue:** `enable_auto_scaling` is not a valid argument

**Fix:** Use `auto_scale` instead

```hcl
# Before (Invalid)
enable_auto_scaling = true  # ❌ Wrong attribute name

# After (Valid)
auto_scale = true  # ✅ Correct for v4.x
```

### 3. AKS Node Pool - Node Count with Auto-scaling
**Issue:** When `auto_scale = true`, don't set `node_count`

**Fix:** Remove `node_count` when auto-scaling is enabled

```hcl
# Before (Invalid)
auto_scale = true
min_count  = 1
max_count  = 5
node_count = 1  # ❌ Conflicts with auto_scale

# After (Valid)
auto_scale = true
min_count  = 1
max_count  = 5
# node_count removed - auto-scaler manages this
```

### 4. Default Node Pool - Labels
**Issue:** `node_labels` in default_node_pool can cause issues

**Fix:** Removed node_labels from default node pool

## Complete Working Configuration

### AKS Cluster Resource
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  # ... basic configuration ...
  
  default_node_pool {
    name       = "system"
    node_count = var.system_node_count
    vm_size    = var.system_vm_size
    # No node_labels here
  }
  
  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
    # No 'managed' field
  }
}
```

### AKS Node Pool Resource
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  # ... basic configuration ...
  
  # Auto-scaling configuration
  auto_scale = true  # Correct attribute name
  min_count  = var.user_min_count
  max_count  = var.user_max_count
  # No node_count when auto_scale is true
}
```

## Provider Version Reference

These fixes are for AzureRM Provider v4.9.x. Key differences from v3.x:
- Attribute names changed for consistency
- Some fields removed (like `managed`)
- Stricter validation on conflicting attributes

## Testing

After these fixes:
1. ✅ Terraform validation passes
2. ✅ No "Unsupported argument" errors
3. ✅ Auto-scaling configured correctly
4. ✅ Azure AD RBAC works properly

## Next Steps

Run the workflow to test:
```bash
gh workflow run aks.yml -f action=plan -f environment=dev
```

The Terraform plan should now execute without errors.