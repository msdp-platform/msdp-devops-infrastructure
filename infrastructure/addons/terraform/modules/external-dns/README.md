# External DNS Terraform Module

This module deploys external-dns for automated DNS record management in Kubernetes clusters.

## Features

- 🌐 Automated DNS record creation/deletion for Kubernetes services and ingresses
- ☁️ Multi-cloud support (AWS EKS, Azure AKS)
- 🔑 OIDC authentication for cross-cloud access
- 📊 Prometheus metrics integration
- 🛡️ Security hardening with non-root containers
- 🔄 Configurable sync policies (sync, upsert-only)

## Usage

### Basic Usage (Azure AKS with Route53)
```hcl
module "external_dns" {
  source = "../../modules/external-dns"
  
  enabled        = true
  cloud_provider = "azure"
  txt_owner_id   = "azure-dev-cluster"
  
  # AWS credentials for Route53 access
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  
  domain_filters = ["aztech-msdp.com"]
}
```

### Advanced Usage with OIDC
```hcl
module "external_dns" {
  source = "../../modules/external-dns"
  
  enabled        = true
  cloud_provider = "azure"
  txt_owner_id   = "azure-prod-cluster"
  
  # OIDC authentication
  use_oidc = true
  azure_workload_identity_client_id = "your-client-id"
  
  # Custom configuration
  policy = "upsert-only"
  domain_filters = ["example.com", "api.example.com"]
  log_level = "debug"
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
| enabled | Enable or disable External DNS deployment | `bool` | `true` | no |
| namespace | Kubernetes namespace for External DNS | `string` | `"external-dns-system"` | no |
| cloud_provider | Cloud provider (aws or azure) | `string` | n/a | yes |
| txt_owner_id | Unique identifier for this External DNS instance | `string` | n/a | yes |
| domain_filters | List of domains to manage | `list(string)` | `["aztech-msdp.com"]` | no |
| policy | DNS record management policy | `string` | `"sync"` | no |
| registry | Registry type for tracking DNS records | `string` | `"txt"` | no |
| aws_region | AWS region | `string` | `"eu-west-1"` | no |
| hosted_zone_id | AWS Route53 hosted zone ID | `string` | `"Z0581458B5QGVNLDPESN"` | no |
| aws_access_key_id | AWS access key ID (for Azure clusters) | `string` | `""` | no |
| aws_secret_access_key | AWS secret access key (for Azure clusters) | `string` | `""` | no |
| use_oidc | Use OIDC authentication instead of static credentials | `bool` | `false` | no |
| azure_workload_identity_client_id | Azure workload identity client ID for federated AWS access | `string` | `""` | no |
| replica_count | Number of External DNS replicas | `number` | `1` | no |
| log_level | Log level for External DNS | `string` | `"info"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where external-dns is deployed |

## Dependencies

This module depends on:
- `shared/versions` - For centralized version management
- `shared/aws-credentials` - For AWS credential secret management (when using static credentials)

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  external-dns   │────│   Kubernetes     │────│   AWS Route53   │
│   controller    │    │   Services &     │    │   DNS Records   │
│                 │    │   Ingresses      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────┐
│   TXT Records   │    │   A/CNAME        │
│   (ownership)   │    │   Records        │
└─────────────────┘    └──────────────────┘
```

## Sync Policies

- **sync**: Creates and deletes DNS records (default)
- **upsert-only**: Only creates DNS records, never deletes

## Security Considerations

- Uses non-root containers with read-only root filesystem
- Drops all Linux capabilities
- Supports both static credentials and OIDC authentication
- AWS credentials are stored in Kubernetes secrets
- TXT record ownership prevents conflicts between clusters

## Troubleshooting

### Common Issues

1. **DNS records not created**: Check service/ingress annotations and external-dns logs
2. **Permission denied**: Verify AWS credentials and Route53 permissions
3. **TXT record conflicts**: Ensure unique `txt_owner_id` per cluster

### Debug Commands

```bash
# Check external-dns pods
kubectl get pods -n external-dns-system

# Check external-dns logs
kubectl logs -n external-dns-system deployment/external-dns

# Check DNS records in Route53
aws route53 list-resource-record-sets --hosted-zone-id Z0581458B5QGVNLDPESN
```

### Required AWS Permissions

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

## Version Management

This module uses centralized version management through the `shared/versions` module. Chart versions are automatically managed and updated centrally.

## Contributing

When updating this module:
1. Maintain backward compatibility
2. Test with both sync policies
3. Verify AWS and Azure environments
4. Update documentation
