# Azure AKS Stack (Reusable)

Production-ready, parameterized Terraform for AKS with flexible subnet resolution and optional RG management. Defaults mirror dev behavior and won’t break existing pipelines.

## Subnet Resolution Modes
- Explicit: set `subnet_id`
- Remote state (S3+DDB): set `remote_state_bucket`, `remote_state_region`, `remote_state_key` (and optionally `remote_state_dynamodb_table`) and ensure the network outputs include `subnets` map
- Name-based: set `vnet_name`, `subnet_name`, and `resource_group`

Priority: explicit > remote_state > name-based. The module fails fast if none resolve.

## Variables (high level)
- Cluster: `resource_group`, `location`, `aks_name`, `kubernetes_version`, `manage_resource_group`
- Subnet: `subnet_id` or `remote_state_*` or `vnet_name/subnet_name`
- Node pools: `system_vm_size`, `system_node_count`, `user_vm_size`, `user_min_count`, `user_max_count`, `user_spot`
- `tags`

## Outputs
- `cluster_id`, `cluster_name`, `fqdn`, `kube_config_raw` (sensitive), `kubelet_identity_*`, `oidc_issuer_url`, `node_resource_group`, `principal_id`, `kubernetes_version`, pool names

## Examples

Explicit subnet:
```json
{
  "resource_group": "rg-shared-dev",
  "location": "uksouth",
  "aks_name": "aks-dev-01",
  "subnet_id": "/subscriptions/<sub>/resourceGroups/rg-shared-dev/providers/Microsoft.Network/virtualNetworks/vnet-shared-dev/subnets/snet-aks-dev"
}
```

Remote state subnet (reuses backend config from workflow):
```json
{
  "resource_group": "rg-shared-dev",
  "location": "uksouth",
  "aks_name": "aks-dev-01",
  "remote_state_bucket": "<bucket>",
  "remote_state_region": "eu-west-1",
  "remote_state_key": "network/dev.tfstate"
}
```

Name-based subnet:
```json
{
  "resource_group": "rg-shared-dev",
  "location": "uksouth",
  "aks_name": "aks-dev-01",
  "vnet_name": "vnet-shared-dev",
  "subnet_name": "snet-aks-dev"
}
```

