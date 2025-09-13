# Azure AKS Stack (Reusable)

Production-ready, parameterized Terraform for AKS with flexible subnet resolution and optional RG management. Defaults mirror dev behavior and won’t break existing pipelines.

## Subnet Resolution
Remote state only: the module reads the subnet ID from the Network stack's Terraform outputs in S3/DynamoDB and fails fast if it cannot resolve.

## Variables (high level)
- Cluster: `resource_group`, `location`, `aks_name`, `kubernetes_version`, `manage_resource_group`
- Subnet: `subnet_id` or `remote_state_*` or `vnet_name/subnet_name`
- Node pools: `system_vm_size`, `system_node_count`, `user_vm_size`, `user_min_count`, `user_max_count`, `user_spot`
- `tags`

## Outputs
- `cluster_id`, `cluster_name`, `fqdn`, `kube_config_raw` (sensitive), `kubelet_identity_*`, `oidc_issuer_url`, `node_resource_group`, `principal_id`, `kubernetes_version`, pool names

## Example (remote state)
```json
{
  "resource_group": "rg-shared-dev",
  "location": "uksouth",
  "aks_name": "aks-dev-01",
  "remote_state_bucket": "<bucket>",
  "remote_state_region": "eu-west-1",
  "remote_state_key": "network/dev.tfstate",
  "subnet_name": "snet-aks-dev"
}
```

## Matrix Deployment (Multiple Clusters)

Define clusters in `config/envs/<env>.yaml` under `azure.aksClusters`. Each entry must have a `name` and may optionally set `subnetName` (defaults to `snet-<name>`) and a `size` used by the Network workflow to derive per-cluster subnets.

Example:

```yaml
azure:
  resourceGroup: msdp-aks-eu
  vnetName: msdp-prod-vnet
  vnetCidr: 10.60.0.0/16
  aksClusters:
    - name: aks-dev-a   # subnet defaults to snet-aks-dev-a
      size: medium      # network stack maps size -> newbits
    - name: aks-dev-b
      size: large
      subnetName: snet-custom-b
state:
  networkKey: network/dev.tfstate
```

The AKS workflow reads this list and runs a job matrix, one for each cluster (`name`, `subnetName`). It also sets a unique backend pipeline name per cluster (`aks-<name>`) so each cluster has its own Terraform state key.
