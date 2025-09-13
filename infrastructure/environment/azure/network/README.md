# Azure Network Stack

Production-ready, parameterized Terraform for Azure VNet and subnets with two modes: explicit (user-provided CIDRs) and computed (derived subnets from a base CIDR).

Defaults match current dev behavior so `terraform plan` in dev remains unchanged.

## Prerequisites
- Terraform >= 1.6
- Azure OIDC auth available to the workflow or CLI session
- S3/DynamoDB backend is configured via the reusable backend action (workflow)

## Variables (high level)
- resource_group, location, vnet_name
- address_space: list of CIDRs (explicit mode). If set with `subnets`, computed mode is disabled.
- subnets: list of objects `{ name, cidr, nsg_name? }` (explicit mode)
- base_cidr, subnet_count, subnet_newbits, subnet_names (computed mode)
- nsg_enabled, nsg_prefix (optional; only used to auto-name NSGs in computed mode)
- tags: map(string)

## Usage

### Explicit mode example
Example `network.auto.tfvars.json`:

```json
{
  "resource_group": "rg-shared-dev",
  "location": "uksouth",
  "vnet_name": "vnet-shared-dev",
  "address_space": ["10.60.0.0/16"],
  "subnets": [
    { "name": "snet-aks-dev", "cidr": "10.60.1.0/24" },
    { "name": "snet-db",     "cidr": "10.60.2.0/24", "nsg_name": "nsg-db" }
  ]
}
```

### Computed mode example
Derive subnets deterministically with `cidrsubnet()`:

```json
{
  "resource_group": "rg-network-prod",
  "location": "westeurope",
  "vnet_name": "msdp-prod-vnet",
  "base_cidr": "10.20.0.0/16",
  "subnet_count": 3,
  "subnet_newbits": 8,
  "subnet_names": ["app", "db", "ops"],
  "nsg_prefix": "nsg-prod"
}
```

## Outputs
- vnet_name: Name of the VNet
- address_space: List of VNet CIDRs
- subnets: Map of `{ name -> { id, cidr } }`

## Notes
- Explicit mode is used when both `address_space` and `subnets` are provided and non-empty.
- Computed mode is used otherwise; `base_cidr` and `subnet_count` are required for useful results.
- If `nsg_name` is provided for a subnet (or computed when `nsg_enabled=true`), an NSG is created and associated to that subnet.

## Multi-Cluster Subnet Sizing (Config-Driven)

When `azure.aksClusters` is present in `config/envs/<env>.yaml`, the workflow builds `computed_subnets_spec` automatically from that list and `azure.vnetCidr`. Each cluster gets its own subnet, sized by the `size` label:

- Size mapping (for a `base_cidr` like /16):
  - `large` → `newbits=8` → `/24`
  - `medium` → `newbits=9` → `/25`
  - `small` → `newbits=10` → `/26`

Example (env config):

```yaml
azure:
  resourceGroup: msdp-aks-eu
  vnetName: msdp-prod-vnet
  vnetCidr: 10.60.0.0/16
  aksClusters:
    - name: aks-dev-a   # subnet defaults to snet-aks-dev-a
      size: medium
    - name: aks-dev-b
      size: large
      subnetName: snet-custom-b  # optional override
```

The network workflow writes `network.auto.tfvars.json` with:

```json
{
  "resource_group": "msdp-aks-eu",
  "location": "westeurope",
  "vnet_name": "msdp-prod-vnet",
  "base_cidr": "10.60.0.0/16",
  "computed_subnets_spec": [
    {"name":"snet-aks-dev-a","newbits":9},
    {"name":"snet-custom-b","newbits":8}
  ]
}
```

Downstream (AKS) selects the proper subnet by name via remote state.
