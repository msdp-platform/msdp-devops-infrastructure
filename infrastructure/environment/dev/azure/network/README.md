# Azure Network Dev Environment Stack

This Terraform stack creates the foundational networking infrastructure for the dev environment, including resource group, virtual network, and AKS subnet.

## Architecture

- **Resource Group**: `rg-shared-dev`
- **Virtual Network**: `vnet-shared-dev` (10.50.0.0/16)
- **AKS Subnet**: `snet-aks-dev` (10.50.1.0/24)

## Prerequisites

- Azure CLI authenticated with OIDC
- Terraform >= 1.6
- Azure subscription with appropriate permissions

## Usage

### 1. Configure Variables

Copy `terraform.tfvars.example` to `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. Use Outputs

The stack outputs the `subnet_id_aks` which can be used by other stacks:

```bash
# Get the subnet ID for AKS
terraform output subnet_id_aks
```

## Configuration

### Environment Map

The stack uses a local environment map in `locals.tf`:

```hcl
envs = {
  dev = {
    subscription_id = "<REPLACE-SUB-ID>"
    location        = "uksouth"
    resource_group  = "rg-shared-dev"
    vnet_name       = "vnet-shared-dev"
    vnet_cidr       = "10.50.0.0/16"
    subnet_name     = "snet-aks-dev"
    subnet_cidr     = "10.50.1.0/24"
    subnet_tags = {
      role = "aks"
    }
  }
}
```

### Variables

- `env`: Environment name (default: "dev")
- `subscription_id`: Azure subscription ID (optional)

## Outputs

- `subnet_id_aks`: ID of the AKS subnet
- `resource_group_name`: Name of the resource group
- `vnet_name`: Name of the virtual network
- `subnet_name`: Name of the AKS subnet
- `vnet_id`: ID of the virtual network

## Security

- Uses OIDC authentication (no hardcoded credentials)
- Subnet tagged with `role = "aks"`
- All resources tagged with environment and management info

## Dependencies

This stack should be deployed before:
- AKS cluster deployment
- Any application workloads requiring network access

## Related Documentation

- [AKS Environment Stack](../aks/README.md)
- [Factory Model Blueprint](../../../docs/architecture/Factory-Model-DevOps-Blueprint.md)
