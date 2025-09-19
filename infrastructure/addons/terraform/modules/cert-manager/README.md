# Cert-Manager Terraform Module

This module deploys cert-manager for automated TLS certificate management in Kubernetes clusters.

## Features

- 🔒 Automated TLS certificate provisioning via Let's Encrypt
- 🌐 Support for DNS-01 challenges (Route53, Azure DNS)
- ☁️ Multi-cloud support (AWS EKS, Azure AKS)
- 🔑 OIDC authentication for cross-cloud access
- 📊 Prometheus metrics integration
- 🛡️ Security hardening with non-root containers

## Usage

### Basic Usage (Azure AKS)
```hcl
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  enabled        = true
  email          = "admin@example.com"
  cloud_provider = "azure"
  
  # AWS credentials for Route53 access
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}
```

### Advanced Usage with OIDC
```hcl
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  enabled        = true
  email          = "admin@example.com"
  cloud_provider = "azure"
  
  # OIDC authentication
  use_oidc = true
  azure_workload_identity_client_id = "your-client-id"
  
  # Custom configuration
  cluster_issuer_name = "letsencrypt-prod"
  dns_provider        = "route53"
  hosted_zone_id      = "Z0581458B5QGVNLDPESN"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| helm | >= 2.0 |
| kubernetes | >= 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Enable or disable Cert-Manager deployment | `bool` | `true` | no |
| namespace | Kubernetes namespace for Cert-Manager | `string` | `"cert-manager"` | no |
| email | Email address for Let's Encrypt registration | `string` | n/a | yes |
| cloud_provider | Cloud provider (aws or azure) | `string` | n/a | yes |
| cluster_issuer_name | Name of the ClusterIssuer to create | `string` | `"letsencrypt-prod"` | no |
| dns_provider | DNS provider for DNS-01 challenge | `string` | `"route53"` | no |
| aws_region | AWS region for Route53 | `string` | `"eu-west-1"` | no |
| hosted_zone_id | AWS Route53 hosted zone ID | `string` | `"Z0581458B5QGVNLDPESN"` | no |
| aws_access_key_id | AWS access key ID (for Azure clusters) | `string` | `""` | no |
| aws_secret_access_key | AWS secret access key (for Azure clusters) | `string` | `""` | no |
| use_oidc | Use OIDC authentication instead of static credentials | `bool` | `false` | no |
| azure_workload_identity_client_id | Azure Workload Identity client ID for OIDC federation | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where cert-manager is deployed |
| cluster_issuer_name | The name of the created ClusterIssuer |

## Dependencies

This module depends on:
- `shared/versions` - For centralized version management
- `shared/aws-credentials` - For AWS credential secret management (when using static credentials)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   cert-manager  │────│  ClusterIssuer   │────│  Let's Encrypt  │
│   controller    │    │  (Route53 DNS)   │    │     ACME        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────┐
│   Certificate   │    │   AWS Route53    │
│   Resources     │    │   DNS Records    │
└─────────────────┘    └──────────────────┘
```

## Security Considerations

- Uses non-root containers with read-only root filesystem
- Drops all Linux capabilities
- Supports both static credentials and OIDC authentication
- AWS credentials are stored in Kubernetes secrets
- Validates input parameters to prevent misconfigurations

## Troubleshooting

### Common Issues

1. **Certificate not issued**: Check ClusterIssuer status and DNS propagation
2. **DNS challenge failed**: Verify AWS credentials and Route53 permissions
3. **OIDC authentication failed**: Check Azure Workload Identity configuration

### Debug Commands

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check ClusterIssuer status
kubectl get clusterissuer

# Check certificate status
kubectl describe certificate <cert-name>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

## Version Management

This module uses centralized version management through the `shared/versions` module. Chart versions are automatically managed and updated centrally.

## Contributing

When updating this module:
1. Maintain backward compatibility
2. Update variable validation rules
3. Test with both AWS and Azure environments
4. Update documentation
