# Network Deployment Fix for Plan Action

## ✅ Issue Fixed

The workflow was skipping network deployment when `action=plan` was used. Now it properly handles both `plan` and `apply` actions.

## 📋 What Changed

### 1. **Updated deploy-network job condition**
**Before:**
```yaml
if: ${{ needs.check-network.outputs.should-deploy == 'true' }}
```

**After:**
```yaml
if: ${{ needs.check-network.outputs.should-deploy == 'true' && (github.event.inputs.action == 'plan' || github.event.inputs.action == 'apply' || github.event.inputs.action == '') }}
```

### 2. **Network deployment respects action**
The network deployment now:
- Runs `terraform plan` when action=plan
- Runs `terraform apply` when action=apply
- Shows a warning that network must be applied before AKS can work

## 🚀 How It Works Now

### When action=plan:
```
1. Check network exists → Not found
2. Run terraform plan for network → Shows what will be created
3. Warning: Network must be applied before AKS can be deployed
4. AKS plan will still fail (network doesn't exist yet)
```

### When action=apply:
```
1. Check network exists → Not found
2. Run terraform apply for network → Creates network
3. Network deployed successfully
4. AKS deployment proceeds with existing network
```

## 📊 Workflow Behavior

| Action | Network Exists | Network Job | Result |
|--------|---------------|-------------|---------|
| **plan** | ❌ No | Runs `terraform plan` | Shows network plan, AKS will fail |
| **plan** | ✅ Yes | Skipped | AKS plan succeeds |
| **apply** | ❌ No | Runs `terraform apply` | Creates network, then AKS |
| **apply** | ✅ Yes | Skipped | Deploys AKS only |

## ⚠️ Important Notes

### For First-Time Deployment:
1. **Option 1**: Run with `action=apply` directly
   ```bash
   gh workflow run aks.yml -f action=apply -f environment=dev
   ```
   This will create both network and AKS in one go.

2. **Option 2**: Deploy network first, then plan AKS
   ```bash
   # Deploy network first
   gh workflow run azure-network.yml -f action=apply -f environment=dev
   
   # Then plan AKS
   gh workflow run aks.yml -f action=plan -f environment=dev
   ```

### Why AKS Plan Fails Without Network:
- AKS needs to reference existing network resources
- Terraform data sources fail if resources don't exist
- This is expected behavior - network must exist first

## 🎯 Best Practice

For new environments, always use `action=apply` for the first run:
```bash
# This will:
# 1. Create network infrastructure
# 2. Deploy AKS clusters
gh workflow run aks.yml -f action=apply -f environment=dev
```

For subsequent runs, `action=plan` will work fine since network exists.

## 📝 Workflow Output Examples

### Plan with missing network:
```
⚠️ Resource group not found
🚀 Running network infrastructure: plan
✅ Network infrastructure plan completed
⚠️ Note: Network must be applied before AKS can be deployed
   Run with action=apply to create the network
```

### Apply with missing network:
```
⚠️ Resource group not found
🚀 Running network infrastructure: apply
✅ Network infrastructure deployed successfully
→ Proceeding with AKS deployment...
```

## 🔧 Testing

```bash
# Test the updated workflow
gh workflow run aks.yml -f action=plan -f environment=dev

# You'll see network plan but AKS will fail (expected)
# To actually deploy:
gh workflow run aks.yml -f action=apply -f environment=dev
```

The workflow now properly handles the network dependency for both plan and apply actions!