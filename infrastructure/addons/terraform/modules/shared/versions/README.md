# Shared Versions Module

This module provides centralized version management for all Helm charts and container images used across the infrastructure.

## Features

- 🎯 Centralized version management
- 📦 Helm chart version definitions
- 🐳 Container image version definitions
- 🔄 Easy version updates across all modules
- 📋 Version consistency enforcement

## Usage

```hcl
module "versions" {
  source = "../shared/versions"
}

# Use in other modules
resource "helm_release" "example" {
  name    = "example"
  chart   = "example"
  version = module.versions.chart_versions.example
}
```

## Outputs

### Chart Versions

| Name | Description | Current Version |
|------|-------------|-----------------|
| cert_manager | Cert-Manager Helm chart | v1.13.2 |
| external_dns | External DNS Helm chart | 1.13.1 |
| nginx_ingress | NGINX Ingress Controller | 4.11.3 |
| argocd | ArgoCD Helm chart | 5.51.3 |
| prometheus_stack | Kube-Prometheus-Stack | 65.5.1 |
| keda | KEDA Helm chart | 2.12.1 |
| karpenter | Karpenter Helm chart | v0.32.1 |
| crossplane | Crossplane Helm chart | 2.0.2 |
| backstage | Backstage Helm chart | 2.6.1 |
| azure_disk_csi_driver | Azure Disk CSI Driver | 1.29.2 |

### Container Versions

| Name | Description | Current Version |
|------|-------------|-----------------|
| cert_manager_controller | Cert-Manager controller image | v1.13.2 |
| external_dns | External DNS image | 0.13.6 |
| nginx_ingress_controller | NGINX Ingress controller image | v1.11.3 |

## Architecture

```
┌─────────────────┐
│  shared/versions│
│     module      │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   cert-manager  │    │  external-dns   │    │  nginx-ingress  │
│     module      │    │     module      │    │     module      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Helm Chart    │    │   Helm Chart    │    │   Helm Chart    │
│   v1.13.2       │    │   1.13.1        │    │   4.11.3        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Version Update Process

1. **Update versions.tf**: Modify chart or container versions
2. **Test changes**: Validate with terraform plan
3. **Apply updates**: All dependent modules automatically use new versions
4. **Verify deployment**: Check that all services update correctly

## Benefits

- **Consistency**: All modules use the same version definitions
- **Maintainability**: Single point of version management
- **Auditability**: Clear version history and changes
- **Efficiency**: Bulk version updates across infrastructure

## File Structure

```
shared/versions/
├── main.tf          # Version definitions
├── outputs.tf       # Version outputs
└── README.md        # This documentation
```

## Contributing

When updating versions:
1. Test compatibility with existing configurations
2. Update version numbers in main.tf
3. Document breaking changes
4. Coordinate with team for deployment timing
