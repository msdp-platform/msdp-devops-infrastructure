# Deployment Order Fix - Network Must Be Deployed First

## 🚨 Current Issue

The AKS deployment is failing because it's trying to reference network resources that don't exist:
- Resource Group: `rg-msdp-network-dev` (not found)
- Virtual Network: `vnet-msdp-dev` (not found)
- Subnet: `snet-aks-user-dev` (not found)

## 📋 Root Cause

AKS clusters need to be deployed into an existing network. The deployment order must be:
1. **Network Infrastructure** (creates resource group, VNet, subnets)
2. **AKS Clusters** (uses the network created in step 1)

## ✅ Solution: Deploy in Correct Order

### Step 1: Deploy Network Infrastructure First

```bash
# Run network pipeline with APPLY (not just plan)
gh workflow run azure-network.yml -f action=apply -f environment=dev

# Or using the script
./scripts/rerun-pipelines.sh network apply dev
```

### Step 2: Wait for Network Deployment

Monitor the network deployment:
```bash
# Watch the workflow
gh run watch

# Check if resources were created
az network vnet list --resource-group rg-msdp-network-dev
az network vnet subnet list --resource-group rg-msdp-network-dev --vnet-name vnet-msdp-dev
```

### Step 3: Deploy AKS Clusters

Only after network is successfully deployed:
```bash
# Now run AKS pipeline
gh workflow run aks.yml -f action=plan -f environment=dev

# If plan looks good, apply
gh workflow run aks.yml -f action=apply -f environment=dev
```

## 🔍 Verify Network Resources Exist

Before running AKS deployment, verify the network resources:

```bash
# Check if resource group exists
az group show --name rg-msdp-network-dev

# Check if VNet exists
az network vnet show \
  --resource-group rg-msdp-network-dev \
  --name vnet-msdp-dev

# Check if subnets exist
az network vnet subnet list \
  --resource-group rg-msdp-network-dev \
  --vnet-name vnet-msdp-dev \
  --output table
```

## 📊 Expected Network Resources

After successful network deployment, you should have:

| Resource | Name | Status |
|----------|------|--------|
| **Resource Group** | `rg-msdp-network-dev` | ✅ Created |
| **Virtual Network** | `vnet-msdp-dev` | ✅ Created |
| **Subnet 1** | `snet-aks-system-dev` | ✅ Created |
| **Subnet 2** | `snet-aks-user-dev` | ✅ Created |
| **NSGs** | (optional) | ✅ Created |

## 🚀 Complete Deployment Sequence

```bash
# 1. First, check current network status
echo "Checking if network exists..."
az group show --name rg-msdp-network-dev 2>/dev/null || echo "Network not deployed"

# 2. Deploy network (if not exists)
echo "Deploying network infrastructure..."
gh workflow run azure-network.yml -f action=apply -f environment=dev

# 3. Wait for completion (usually 2-5 minutes)
echo "Waiting for network deployment..."
sleep 30
gh run list --workflow=azure-network.yml --limit=1

# 4. Verify network resources
echo "Verifying network resources..."
az network vnet show --resource-group rg-msdp-network-dev --name vnet-msdp-dev

# 5. Deploy AKS clusters
echo "Deploying AKS clusters..."
gh workflow run aks.yml -f action=plan -f environment=dev
```

## 🔧 Alternative: Create Network Manually (Quick Fix)

If you need to quickly test AKS, create the network manually:

```bash
# Create resource group
az group create --name rg-msdp-network-dev --location uksouth

# Create VNet
az network vnet create \
  --resource-group rg-msdp-network-dev \
  --name vnet-msdp-dev \
  --address-prefix 10.60.0.0/16 \
  --location uksouth

# Create subnets
az network vnet subnet create \
  --resource-group rg-msdp-network-dev \
  --vnet-name vnet-msdp-dev \
  --name snet-aks-system-dev \
  --address-prefix 10.60.1.0/24

az network vnet subnet create \
  --resource-group rg-msdp-network-dev \
  --vnet-name vnet-msdp-dev \
  --name snet-aks-user-dev \
  --address-prefix 10.60.2.0/24
```

## 📝 Update Configuration if Needed

If you want AKS to use different subnet names, update `config/dev.yaml`:

```yaml
azure:
  aks:
    clusters:
      - name: aks-msdp-dev-01
        subnet_name: snet-aks-system-dev  # Make sure this matches what network creates
      - name: aks-msdp-dev-02
        subnet_name: snet-aks-user-dev    # Make sure this matches what network creates
```

## 🎯 Best Practice: CI/CD Pipeline Dependencies

For future, consider adding workflow dependencies:

```yaml
# In .github/workflows/aks.yml
on:
  workflow_run:
    workflows: ["Azure Network Infrastructure"]
    types: [completed]
    branches: [main]
```

Or use a combined workflow:

```yaml
jobs:
  deploy-network:
    runs-on: ubuntu-latest
    steps:
      # Deploy network first
      
  deploy-aks:
    needs: deploy-network  # Wait for network
    runs-on: ubuntu-latest
    steps:
      # Deploy AKS after network
```

## ✅ Summary

**The fix is simple**: Deploy network infrastructure first, then deploy AKS clusters.

```bash
# Right order:
1. gh workflow run azure-network.yml -f action=apply -f environment=dev
2. Wait for completion
3. gh workflow run aks.yml -f action=apply -f environment=dev
```

The AKS deployment is failing because it's looking for network resources that haven't been created yet!