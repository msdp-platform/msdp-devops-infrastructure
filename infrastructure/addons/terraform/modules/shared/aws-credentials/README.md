# AWS Credentials Shared Module

This module manages AWS credentials as Kubernetes secrets for cross-cloud access scenarios (e.g., accessing AWS Route53 from Azure AKS clusters).

## Features

- 🔐 Secure AWS credential storage in Kubernetes secrets
- ☁️ Cross-cloud authentication support
- 🔄 OIDC and static credential options
- 🛡️ Security best practices implementation
- 📊 Integration with cert-manager and external-dns

## Usage

### Basic Usage with Static Credentials
```hcl
module "aws_credentials" {
  source = "../shared/aws-credentials"
  
  enabled   = true
  namespace = "cert-manager"
  
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}
```

### Advanced Usage with OIDC
```hcl
module "aws_credentials" {
  source = "../shared/aws-credentials"
  
  enabled   = true
  namespace = "external-dns-system"
  
  use_oidc = true
  azure_workload_identity_client_id = "your-client-id"
  aws_role_arn = "arn:aws:iam::123456789012:role/ExternalDNSRole"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| kubernetes | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| kubernetes | >= 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Enable or disable AWS credentials secret creation | `bool` | `true` | no |
| namespace | Kubernetes namespace for the secret | `string` | n/a | yes |
| secret_name | Name of the Kubernetes secret | `string` | `"aws-credentials"` | no |
| aws_access_key_id | AWS access key ID | `string` | `""` | no |
| aws_secret_access_key | AWS secret access key | `string` | `""` | no |
| use_oidc | Use OIDC authentication instead of static credentials | `bool` | `false` | no |
| azure_workload_identity_client_id | Azure Workload Identity client ID | `string` | `""` | no |
| aws_role_arn | AWS IAM role ARN for OIDC authentication | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_name | Name of the created Kubernetes secret |
| namespace | Namespace where the secret is created |

## Architecture

### Static Credentials Flow
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │────│   Kubernetes     │────│   AWS Services  │
│   Variables     │    │   Secret         │    │   (Route53)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### OIDC Flow
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Azure AD      │────│   Workload       │────│   AWS STS       │
│   (Identity)    │    │   Identity       │    │   (AssumeRole)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                                ▼                        ▼
                    ┌──────────────────┐    ┌─────────────────┐
                    │   Kubernetes     │────│   AWS Services  │
                    │   Pod            │    │   (Route53)     │
                    └──────────────────┘    └─────────────────┘
```

## Security Considerations

- **Static Credentials**: Stored as Kubernetes secrets with base64 encoding
- **OIDC Authentication**: Uses Azure Workload Identity for token exchange
- **Least Privilege**: IAM roles should have minimal required permissions
- **Secret Rotation**: Regular credential rotation recommended
- **Namespace Isolation**: Secrets are namespace-scoped

## Integration Examples

### With cert-manager
```hcl
module "aws_credentials" {
  source = "../shared/aws-credentials"
  
  enabled   = true
  namespace = "cert-manager"
  
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

module "cert_manager" {
  source = "../../cert-manager"
  
  enabled        = true
  cloud_provider = "azure"
  
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  
  depends_on = [module.aws_credentials]
}
```

### With external-dns
```hcl
module "aws_credentials" {
  source = "../shared/aws-credentials"
  
  enabled   = true
  namespace = "external-dns-system"
  
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

module "external_dns" {
  source = "../../external-dns"
  
  enabled        = true
  cloud_provider = "azure"
  txt_owner_id   = "azure-cluster"
  
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  
  depends_on = [module.aws_credentials]
}
```

## Required AWS Permissions

### For cert-manager (Route53)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/*",
                "arn:aws:route53:::change/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        }
    ]
}
```

### For external-dns (Route53)
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

## Troubleshooting

### Common Issues

1. **Secret not found**: Verify namespace and secret name
2. **Permission denied**: Check AWS IAM permissions
3. **OIDC authentication failed**: Verify Azure Workload Identity configuration

### Debug Commands

```bash
# Check secret existence
kubectl get secret aws-credentials -n <namespace>

# View secret contents (base64 encoded)
kubectl get secret aws-credentials -n <namespace> -o yaml

# Test AWS credentials
kubectl run -it --rm aws-cli --image=amazon/aws-cli --restart=Never -- \
  --env AWS_ACCESS_KEY_ID=<key> \
  --env AWS_SECRET_ACCESS_KEY=<secret> \
  aws sts get-caller-identity
```

## Best Practices

1. **Credential Rotation**: Regularly rotate AWS access keys
2. **Least Privilege**: Grant minimal required permissions
3. **Monitoring**: Monitor AWS API usage for anomalies
4. **Backup**: Ensure credentials are backed up securely
5. **Documentation**: Document credential usage and dependencies

## Contributing

When updating this module:
1. Test with both static and OIDC authentication
2. Verify integration with dependent modules
3. Update security documentation
4. Test credential rotation procedures
