# EKS Upgrade Manager

A Terraform module that provides intelligent EKS deployment and upgrade management. It automatically determines whether to perform a fresh deployment or incremental upgrades based on the current cluster state.

## Features

- **Automatic Strategy Detection**: Determines deployment strategy based on cluster existence and version
- **Incremental Upgrades**: Supports safe, incremental Kubernetes version upgrades
- **Component Version Management**: Automatically selects compatible component versions
- **Multi-Version Upgrade Support**: Handles upgrades across multiple minor versions
- **Safety Checks**: Prevents downgrades and validates upgrade paths

## Deployment Strategies

### 1. Fresh Deployment
- **When**: No existing cluster found
- **Action**: Deploy with target version and latest compatible components
- **Example**: Deploy Kubernetes 1.32 with all latest components

### 2. Single Version Upgrade
- **When**: Target version is exactly one minor version ahead
- **Action**: Direct upgrade to target version
- **Example**: 1.28 → 1.29

### 3. Multi-Version Upgrade
- **When**: Target version is multiple minor versions ahead
- **Action**: Incremental upgrades (requires `auto_upgrade = true`)
- **Example**: 1.28 → 1.29 → 1.30 → 1.31 → 1.32

### 4. No Change
- **When**: Cluster is already at target version
- **Action**: No changes needed

### 5. Downgrade (Blocked)
- **When**: Target version is lower than current version
- **Action**: Blocked (not supported)

## Usage

### Basic Usage

```hcl
module "eks_upgrade_manager" {
  source = "./modules/eks-upgrade-manager"
  
  cluster_name              = "my-eks-cluster"  # Empty for fresh deployment
  target_kubernetes_version = "1.32"
  auto_upgrade             = false
  aws_region               = "us-west-2"
}

# Use the outputs to configure your EKS deployment
module "eks_blueprint" {
  source = "./modules/eks-blueprint"
  
  kubernetes_version = module.eks_upgrade_manager.component_versions.kubernetes_version
  karpenter_version  = module.eks_upgrade_manager.component_versions.karpenter_version
  # ... other component versions
}
```

### Using the Script

```bash
# Check upgrade plan for existing cluster
./scripts/eks-upgrade-manager.sh -c msdp-eks-dev -t 1.32

# Fresh deployment with latest version
./scripts/eks-upgrade-manager.sh -t 1.32

# Auto-upgrade existing cluster
./scripts/eks-upgrade-manager.sh -c msdp-eks-dev -t 1.32 -a

# Apply the upgrade plan
./scripts/eks-upgrade-manager.sh -c msdp-eks-dev -t 1.32 -x apply
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the existing EKS cluster (empty for fresh deployment) | `string` | `""` | no |
| target_kubernetes_version | Target Kubernetes version to deploy or upgrade to | `string` | `"1.32"` | no |
| auto_upgrade | Whether to automatically proceed with multi-version upgrades | `bool` | `false` | no |
| aws_region | AWS region where the cluster is located | `string` | `"us-west-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| upgrade_plan | The complete upgrade plan including strategy and versions |
| upgrade_status | Status of the upgrade process (proceeding/blocked) |
| component_versions | Recommended component versions for the final Kubernetes version |
| deployment_strategy | The deployment strategy to use |
| should_proceed | Whether the deployment should proceed |
| next_version | Next version to upgrade to (for multi-version upgrades) |
| upgrade_path | Complete upgrade path from current to target version |

## Supported Kubernetes Versions

- 1.28
- 1.29
- 1.30
- 1.31
- 1.32
- 1.33
- 1.34

## Component Version Compatibility

The module automatically selects compatible component versions based on the target Kubernetes version:

| Kubernetes | Karpenter | AWS LB Controller | Cert-Manager | External DNS | Prometheus | ArgoCD | Crossplane |
|------------|-----------|-------------------|--------------|--------------|------------|--------|------------|
| 1.28 | 0.37.0 | 1.6.2 | v1.13.2 | 1.13.1 | 55.4.0 | 5.51.6 | 1.14.1 |
| 1.29 | 0.38.0 | 1.7.0 | v1.14.0 | 1.14.0 | 56.0.0 | 5.52.0 | 1.15.0 |
| 1.30 | 0.39.0 | 1.7.1 | v1.15.0 | 1.15.0 | 57.0.0 | 5.53.0 | 1.16.0 |
| 1.31 | 0.40.0 | 1.8.0 | v1.16.0 | 1.16.0 | 58.0.0 | 5.54.0 | 1.17.0 |
| 1.32 | 0.41.0 | 1.8.1 | v1.17.0 | 1.17.0 | 59.0.0 | 5.55.0 | 1.18.0 |

## Examples

### Fresh Deployment

```bash
# Deploy fresh cluster with Kubernetes 1.32
./scripts/eks-upgrade-manager.sh -t 1.32 -x apply
```

### Single Version Upgrade

```bash
# Upgrade from 1.28 to 1.29
./scripts/eks-upgrade-manager.sh -c msdp-eks-dev -t 1.29 -x apply
```

### Multi-Version Upgrade

```bash
# Upgrade from 1.28 to 1.32 (requires multiple steps)
./scripts/eks-upgrade-manager.sh -c msdp-eks-dev -t 1.32 -a -x apply
```

## Safety Features

- **Version Validation**: Ensures target version is supported
- **Downgrade Prevention**: Blocks attempts to downgrade Kubernetes versions
- **Incremental Upgrades**: Enforces safe, one-version-at-a-time upgrades
- **Component Compatibility**: Automatically selects compatible component versions
- **Dry Run Support**: Plan mode shows what will be changed before applying

## Best Practices

1. **Always Plan First**: Use `-x plan` to review changes before applying
2. **Backup Data**: Ensure important data is backed up before upgrades
3. **Test in Dev**: Test upgrades in development environment first
4. **Monitor Resources**: Watch cluster resources during upgrades
5. **Gradual Rollout**: Use blue-green deployments for production upgrades

## Troubleshooting

### Common Issues

1. **"Unsupported Kubernetes minor version update"**
   - Solution: Use incremental upgrades or fresh deployment

2. **"Multi-version upgrade requires auto_upgrade=true"**
   - Solution: Add `-a` flag or set `auto_upgrade = true`

3. **"Downgrades are not supported"**
   - Solution: Use fresh deployment or upgrade to higher version

### Getting Help

- Check the upgrade plan output for detailed information
- Review AWS EKS documentation for version compatibility
- Use `terraform plan` to preview changes before applying
