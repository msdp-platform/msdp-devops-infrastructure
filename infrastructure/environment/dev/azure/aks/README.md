# AKS Dev Environment Stack

This Terraform stack deploys an Azure Kubernetes Service (AKS) cluster for the development environment.

## Prerequisites

### Networking Requirements

**⚠️ IMPORTANT**: This stack does **NOT** create networking resources. The VNet and subnet must be created by a separate networking pipeline before deploying AKS.

### Subnet Resolution

The AKS stack automatically resolves the subnet ID using the following priority order:

1. **Remote State Output** (Preferred): Reads `subnet_id_aks` from the Network stack's remote state
2. **Name-based Lookup** (Fallback): Looks up subnet by name pattern `snet-aks-{env}`
3. **Tag-based Lookup** (Fallback): Finds subnet with tag `role=aks`

### Validation

The stack includes fail-fast validation:

1. **Subnet Resolution**: Exactly one subnet must be resolved
2. **Existence Validation**: The target subnet must exist in Azure
3. **Clear Error Messages**: If resolution fails, you'll see specific error messages

If subnet resolution fails, you'll see:
- `Subnet resolution failed: found X subnets. Expected exactly 1. Check network stack deployment or subnet configuration.`

## Usage

### 1. Configure Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` and update the values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Deploy via GitHub Actions

Use the AKS Deploy workflow:
1. Go to Actions → "AKS Deploy"
2. Click "Run workflow"
3. Select environment: `dev`
4. Select action: `plan` (to preview) or `apply` (to deploy)

### 3. Deploy Locally

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Configuration

### Default Settings (Dev Environment)

- **Network Plugin**: `azureoverlay` (reduces IP consumption)
- **SKU Tier**: `Free` (cost-effective for dev)
- **Private Cluster**: `false` (public for easier access)
- **OIDC**: `enabled` (for workload identity)
- **System Node Pool**: 1-2 nodes, `Standard_D2as_v5`, Azure Linux
- **Spot Node Pool**: 0-5 nodes, `Standard_D4as_v5`, enabled for cost savings
- **Log Analytics**: 30-day retention

### Customization

Override any settings in `terraform.tfvars`:

```hcl
# Custom cluster name
cluster_name = "my-aks-dev"

# Custom resource group
resource_group_name = "rg-my-aks-dev"

# Custom tags
tags = {
  Project     = "my-project"
  CostCenter  = "engineering"
  Owner       = "my-team"
}
```

## Outputs

The stack exposes key outputs from the AKS module:

- `kubelet_identity_object_id`: Object ID of the kubelet identity
- `oidc_issuer_url`: OIDC issuer URL for workload identity
- `kube_config_raw`: Raw kubeconfig (sensitive)
- `cluster_id`: AKS cluster ID
- `node_resource_group`: Resource group containing cluster nodes
- `principal_id`: Principal ID of the cluster

## Troubleshooting

### Subnet Not Found

If you see subnet-related errors:

1. **Verify the subnet exists**:
   ```bash
   az network vnet subnet show \
     --resource-group "rg-networking-dev" \
     --vnet-name "vnet-dev" \
     --name "aks-subnet"
   ```

2. **Check your configuration** in `terraform.tfvars`

3. **Ensure networking pipeline** has been run first

### Permission Issues

Ensure your Azure credentials have:
- `Contributor` role on the AKS resource group
- `Network Contributor` role on the subnet (if using network lookup)

## Cost Optimization

This dev environment is configured for cost efficiency:

- **Spot nodes**: Up to 5 spot instances for non-critical workloads
- **Azure Overlay**: Reduces IP address consumption
- **Free SKU**: No SLA but no additional cost
- **Short retention**: 30-day log retention
- **Small nodes**: D2as_v5 for system pool

## Security

- **OIDC enabled**: For secure workload identity
- **RBAC enabled**: Kubernetes RBAC is active
- **Public cluster**: For easier dev access (consider private for production)

## Related Documentation

- [AKS Module Documentation](../../../../terraform/modules/azure/aks/README.md)
- [Preflight Prerequisites](../../../docs/preflight/AKS.md)
- [Factory Model Blueprint](../../../docs/architecture/Factory-Model-DevOps-Blueprint.md)
