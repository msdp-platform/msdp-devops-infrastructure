# Azure Network Infrastructure

This module manages shared Azure network infrastructure including Virtual Networks, Subnets, and Network Security Groups.

## Overview

The Azure Network module is designed to create and manage shared network infrastructure that can be referenced by other components (like AKS clusters) using Azure data sources rather than Terraform remote state.

## Architecture

```
Network Infrastructure:
├── Resource Group (optional, can use existing)
├── Virtual Network
├── Subnets (computed from AKS cluster requirements)
└── Network Security Groups (optional)
```

## Configuration

The module supports two configuration modes:

### 1. Computed Mode (Recommended)
Automatically generates subnets based on AKS cluster definitions in `config/envs/dev.yaml`:

```yaml
azure:
  resourceGroup: dev-ops
  vnetName: dev-ops
  vnetCidr: 10.60.0.0/16
  aksClusters:
    - name: dev-ops-01
      size: large
    - name: dev-ops-02
      size: large
```

This generates subnets with appropriate sizing:
- `large` → /24 subnets (254 IPs)
- `medium` → /25 subnets (126 IPs)  
- `small` → /26 subnets (62 IPs)

### 2. Explicit Mode
Manually define subnets in tfvars:

```json
{
  "resource_group": "dev-ops",
  "location": "uksouth",
  "vnet_name": "dev-ops",
  "address_space": ["10.60.0.0/16"],
  "subnets": [
    {
      "name": "snet-aks-dev",
      "cidr": "10.60.1.0/24"
    }
  ]
}
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group` | string | `"rg-shared-dev"` | Azure resource group name |
| `location` | string | `"uksouth"` | Azure region |
| `vnet_name` | string | `"vnet-shared-dev"` | Virtual network name |
| `manage_resource_group` | bool | `true` | Create/manage RG or use existing |
| `manage_vnet` | bool | `true` | Create/manage VNet or use existing |
| `address_space` | list(string) | `["10.60.0.0/16"]` | VNet CIDR blocks (explicit mode) |
| `subnets` | list(object) | `[]` | Subnet definitions (explicit mode) |
| `base_cidr` | string | `""` | Base CIDR for computed mode |
| `computed_subnets_spec` | list(object) | `[]` | Per-subnet sizing spec (computed mode) |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_name` | Virtual network name |
| `address_space` | VNet address space |
| `subnets` | Map of subnet names to {id, cidr} |

## Usage

### Via GitHub Actions Workflow

1. **Plan**: Review changes before applying
   ```bash
   gh workflow run azure-network.yml -f action=plan
   ```

2. **Apply**: Create/update infrastructure
   ```bash
   gh workflow run azure-network.yml -f action=apply
   ```

3. **Destroy**: Remove infrastructure (⚠️ Use with caution)
   ```bash
   gh workflow run azure-network.yml -f action=destroy
   ```

### Local Development

1. **Generate tfvars**:
   ```bash
   python3 .github/scripts/generate_network_tfvars.py
   mv network.auto.tfvars.json infrastructure/environment/azure/network/
   ```

2. **Initialize Terraform**:
   ```bash
   cd infrastructure/environment/azure/network
   terraform init
   ```

3. **Plan and Apply**:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

## Integration with AKS

The AKS workflow references this network infrastructure using Azure data sources:

```hcl
data "azurerm_subnet" "aks" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group
}

resource "azurerm_kubernetes_cluster" "this" {
  default_node_pool {
    vnet_subnet_id = data.azurerm_subnet.aks.id
  }
}
```

This approach provides:
- **Loose coupling**: No Terraform remote state dependencies
- **Flexibility**: Network can be updated independently
- **Reliability**: AKS clusters reference current network state

## State Management

The network infrastructure uses an isolated Terraform state:
- **State Key**: `infra/msdp/dev/azure/network/azure-network-stack.tfstate`
- **Backend**: S3 with DynamoDB locking
- **Isolation**: Separate from AKS cluster states

## Troubleshooting

### Common Issues

1. **Resource Already Exists**
   - Set `manage_resource_group = false` if RG exists
   - Set `manage_vnet = false` if VNet exists
   - Use `terraform import` for existing resources

2. **Subnet Size Issues**
   - Adjust cluster `size` in config (large/medium/small)
   - Or override with workflow input parameter

3. **State Lock Errors**
   - Ensure AWS credentials have DynamoDB permissions
   - Check if another workflow is running

### Validation

Run the validation script to check configuration:
```bash
./scripts/validate-network-config.sh
```

## Security

- Uses GitHub OIDC for authentication (no long-lived credentials)
- Requires Azure permissions: Network Contributor on subscription
- State stored in encrypted S3 bucket with versioning

## Dependencies

- **GitHub Secrets**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AWS_ROLE_ARN`, `AWS_ACCOUNT_ID`
- **Composite Actions**: `cloud-login`, `network-tfvars`, `terraform-backend`, `terraform-init`
- **Configuration Files**: `infrastructure/config/globals.yaml`, `config/envs/dev.yaml`