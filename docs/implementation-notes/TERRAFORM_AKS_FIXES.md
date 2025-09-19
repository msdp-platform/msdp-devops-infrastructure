# Terraform AKS Module Fixes

## Issues Fixed

### 1. Azure AD RBAC Configuration
**Error:**
```
Error: Unsupported argument
│ on main.tf line 70, in resource "azurerm_kubernetes_cluster" "main":
│ 70: managed = true
│ An argument named "managed" is not expected here.
```

**Cause:** The `managed` field is not valid in the `azure_active_directory_role_based_access_control` block in AzureRM provider v4.x.

**Fix:** Removed the `managed = true` line. The Azure AD integration is managed by default when using this block.

**Before:**
```hcl
azure_active_directory_role_based_access_control {
  managed                = true  # ❌ Not valid in v4.x
  tenant_id              = var.tenant_id
  admin_group_object_ids = var.admin_group_object_ids
  azure_rbac_enabled     = true
}
```

**After:**
```hcl
azure_active_directory_role_based_access_control {
  tenant_id              = var.tenant_id
  admin_group_object_ids = var.admin_group_object_ids
  azure_rbac_enabled     = true
}
```

### 2. Node Pool Auto-scaling
**Issue:** Used `auto_scaling_enabled` instead of `enable_auto_scaling`

**Fix:** Changed to correct attribute name.

**Before:**
```hcl
auto_scaling_enabled = true  # ❌ Wrong attribute name
```

**After:**
```hcl
enable_auto_scaling = true  # ✅ Correct
```

### 3. Default Node Pool Labels
**Issue:** `node_labels` is not supported in `default_node_pool` in the same way as separate node pools.

**Fix:** Removed node_labels from default_node_pool as they can cause issues. Labels can be added after cluster creation if needed.

## AzureRM Provider v4.x Changes

The AzureRM provider v4.x introduced several breaking changes for AKS:

### Key Changes:
1. **Azure AD RBAC**: The `managed` field was removed (it's always managed now)
2. **Node Pool**: Some attributes renamed for consistency
3. **Network Profile**: Some options deprecated or changed
4. **Monitoring**: OMS agent configuration changed

### Best Practices for v4.x:
- Always check the [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)
- Use `terraform plan` to catch configuration issues
- Keep provider version consistent across modules

## Testing the Fixes

After these fixes, the Terraform plan should:
1. ✅ Pass validation without "Unsupported argument" errors
2. ✅ Correctly configure Azure AD RBAC
3. ✅ Set up auto-scaling for user node pool
4. ✅ Create AKS cluster with proper configuration

## Next Steps

Run the workflow again:
```bash
gh workflow run aks.yml -f action=plan -f environment=dev
```

The Terraform plan should now execute successfully without configuration errors.