# Fresh Start Guide - Destroy and Rebuild Infrastructure

## 🎯 **Overview**

This guide helps you safely destroy existing infrastructure and rebuild it step-by-step using our new orchestration workflows to validate the complete system.

## ⚠️ **IMPORTANT: Destruction Order**

Infrastructure must be destroyed in **reverse dependency order** to avoid errors:

1. **Platform Engineering Stack** (Backstage + Crossplane)
2. **Kubernetes Add-ons** (cert-manager, external-dns, etc.)
3. **Kubernetes Clusters** (AKS/EKS)
4. **Network Infrastructure** (VPC/VNet)

## 🗑️ **Step 1: Destroy Existing Infrastructure**

### **Option A: Automated Cleanup (Recommended)**
```bash
# Run the automated cleanup script
python3 scripts/safe-infrastructure-cleanup.py

# Or destroy only (no rebuild)
python3 scripts/safe-infrastructure-cleanup.py --destroy-only
```

### **Option B: Manual Destruction**

#### **1. Destroy Platform Engineering Stack**
```bash
gh workflow run "Platform Engineering Stack (Backstage + Crossplane)" \
  --field action=destroy \
  --field environment=dev \
  --field component=all
```

#### **2. Destroy Kubernetes Add-ons**
```bash
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field cluster_name=aks-msdp-dev-01 \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=destroy \
  --field auto_approve=true
```

#### **3. Destroy Kubernetes Clusters**
```bash
gh workflow run "Kubernetes Clusters" \
  --field cloud_provider=azure \
  --field action=destroy \
  --field environment=dev \
  --field cluster_name=""
```

#### **4. Destroy Network Infrastructure**
```bash
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=destroy \
  --field environment=dev
```

## 🚀 **Step 2: Fresh Provisioning (One by One)**

### **1. Provision Network Infrastructure (Foundation)**
```bash
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=apply \
  --field environment=dev
```
**Wait**: ~8 minutes for completion

### **2. Provision Kubernetes Cluster**
```bash
gh workflow run "Kubernetes Clusters" \
  --field cloud_provider=azure \
  --field action=apply \
  --field environment=dev \
  --field cluster_name=aks-msdp-dev-01
```
**Wait**: ~15 minutes for completion

### **3. Provision Kubernetes Add-ons**
```bash
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field cluster_name=aks-msdp-dev-01 \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=apply \
  --field auto_approve=true
```
**Wait**: ~12 minutes for completion

### **4. Provision Platform Engineering Stack**
```bash
gh workflow run "Platform Engineering Stack (Backstage + Crossplane)" \
  --field action=apply \
  --field environment=dev \
  --field component=all \
  --field cluster_name=aks-msdp-dev-01
```
**Wait**: ~10 minutes for completion

## 🧪 **Step 3: Test Infrastructure Orchestrator**

Once everything is provisioned, test the orchestrator:

### **Test with Plan (Dry Run)**
```bash
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network,clusters,addons,platform" \
  --field action=plan \
  --field cloud_provider=azure
```

### **Test Environment Promotion**
```bash
gh workflow run "Environment Promotion" \
  --field source_environment=dev \
  --field target_environment=staging \
  --field components="network" \
  --field cloud_provider=azure \
  --field auto_approve=true \
  --field dry_run=true
```

## 📊 **Monitoring Progress**

### **Check Workflow Status**
```bash
# Monitor all recent runs
gh run list --limit 10

# Monitor specific workflow
gh run list --workflow="Network Infrastructure" --limit 3

# View specific run details
gh run view <run-id>

# Use our monitoring script
python3 scripts/monitor-workflows.py status
```

### **Check Infrastructure State**
```bash
# After each step, verify the infrastructure
az group list --query "[?contains(name, 'msdp')].{Name:name, Location:location}" -o table

# Check AKS clusters
az aks list --query "[].{Name:name, ResourceGroup:resourceGroup, Status:powerState.code}" -o table

# Check network resources
az network vnet list --query "[?contains(name, 'msdp')].{Name:name, ResourceGroup:resourceGroup, AddressSpace:addressSpace.addressPrefixes[0]}" -o table
```

## 🎯 **Expected Outcomes**

### **After Network Infrastructure**
- ✅ Resource Group created
- ✅ Virtual Network with subnets
- ✅ Network Security Groups
- ✅ Route tables

### **After Kubernetes Cluster**
- ✅ AKS cluster running
- ✅ Node pools active
- ✅ Cluster accessible via kubectl

### **After Kubernetes Add-ons**
- ✅ cert-manager deployed
- ✅ external-dns deployed
- ✅ Ingress controller deployed
- ✅ DNS integration working

### **After Platform Engineering**
- ✅ Backstage service catalog
- ✅ Crossplane infrastructure engine
- ✅ GitOps integration

## 🔧 **Troubleshooting**

### **If a Workflow Fails**
1. **Check the logs**: `gh run view <run-id> --log-failed`
2. **Review the error**: Look for authentication, permission, or resource conflicts
3. **Retry if needed**: Re-run the workflow after fixing issues
4. **Manual cleanup**: Use Azure CLI if needed

### **Common Issues**
- **Authentication**: Ensure Azure OIDC is configured
- **Permissions**: Check Azure service principal permissions
- **Resource conflicts**: Ensure previous resources are fully deleted
- **Timeouts**: Some operations may take longer than expected

### **Emergency Manual Cleanup**
```bash
# If automated cleanup fails, manually delete resource groups
az group delete --name rg-aks-msdp-dev-01 --yes --no-wait
az group delete --name rg-network-msdp-dev --yes --no-wait
```

## 📚 **Additional Resources**

- **Workflow Usage Guide**: `docs/team-guides/WORKFLOW_USAGE_GUIDE.md`
- **Implementation Documentation**: `docs/implementation-notes/`
- **Monitoring Tools**: `scripts/monitor-workflows.py`
- **Validation Tools**: `scripts/validate-implementation.py`

## 🎉 **Success Criteria**

You'll know the fresh start is successful when:

1. ✅ All workflows complete without errors
2. ✅ Infrastructure is accessible and functional
3. ✅ Orchestrator can manage the full stack
4. ✅ Environment promotion works correctly
5. ✅ All components integrate properly

---

**Remember**: This process validates that our new orchestration system can manage the complete infrastructure lifecycle from scratch!

## 🚀 **Quick Start Commands**

```bash
# Option 1: Fully automated (recommended)
python3 scripts/safe-infrastructure-cleanup.py

# Option 2: Step by step manual
python3 scripts/safe-infrastructure-cleanup.py --destroy-only
# Then run provisioning commands above one by one

# Option 3: Just test orchestrator
python3 scripts/safe-infrastructure-cleanup.py --test-orchestrator
```
