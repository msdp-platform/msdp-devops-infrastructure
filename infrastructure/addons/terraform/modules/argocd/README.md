# ArgoCD Terraform Module

This module deploys ArgoCD for GitOps continuous deployment in Kubernetes clusters.

## Features

- 🚀 GitOps continuous deployment
- 🌐 Web UI with ingress support
- 🔒 TLS certificate integration with cert-manager
- 📊 Application monitoring and health checks
- 🛡️ RBAC and security configurations
- 🔄 Multi-cluster management capabilities

## Usage

### Basic Usage
```hcl
module "argocd" {
  source = "../../modules/argocd"
  
  enabled  = true
  hostname = "argocd.aztech-msdp.com"
  
  cluster_issuer_name = "letsencrypt-prod"
  ingress_class_name  = "nginx"
}
```

### Advanced Usage with Custom Annotations
```hcl
module "argocd" {
  source = "../../modules/argocd"
  
  enabled   = true
  namespace = "argocd"
  hostname  = "argocd.example.com"
  
  # TLS Configuration
  cluster_issuer_name = "letsencrypt-prod"
  tls_secret_name     = "argocd-tls"
  
  # Ingress Configuration
  ingress_class_name = "nginx"
  ingress_annotations = {
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    "nginx.ingress.kubernetes.io/backend-protocol" = "GRPC"
  }
  
  # Server Configuration
  server_extra_args = ["--insecure", "--enable-proxy-extension"]
  installation_timeout = 900
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
| enabled | Enable or disable Argo CD deployment | `bool` | `true` | no |
| namespace | Kubernetes namespace for Argo CD | `string` | `"argocd"` | no |
| hostname | Hostname used to expose the Argo CD UI | `string` | n/a | yes |
| cluster_issuer_name | Cert-Manager cluster issuer for TLS | `string` | `""` | no |
| ingress_class_name | Ingress class name used by NGINX | `string` | `"nginx"` | no |
| tls_secret_name | TLS secret name for the Argo CD ingress | `string` | `"argocd-tls"` | no |
| ingress_annotations | Additional ingress annotations | `map(string)` | `{}` | no |
| server_extra_args | Additional arguments for the Argo CD server | `list(string)` | `["--insecure"]` | no |
| installation_timeout | Helm installation timeout in seconds | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where ArgoCD is deployed |
| hostname | The hostname where ArgoCD UI is accessible |

## Dependencies

This module depends on:
- `shared/versions` - For centralized version management
- `cert-manager` - For TLS certificate management (optional)
- `nginx-ingress` - For ingress controller

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   ArgoCD UI     │────│     Ingress      │────│  cert-manager   │
│   (Web/CLI)     │    │   (nginx)        │    │   (TLS Certs)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────┐
│   ArgoCD        │────│   Git Repository │
│   Controller    │    │   (App Configs)  │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐
│   Kubernetes    │
│   Applications  │
└─────────────────┘
```

## Default Configuration

- Server runs in insecure mode (suitable behind ingress with TLS termination)
- Automatic TLS certificate provisioning via cert-manager
- NGINX ingress controller integration
- Standard RBAC policies

## Security Considerations

- Uses HTTPS with automatic certificate management
- RBAC policies restrict access to ArgoCD resources
- Server runs in insecure mode behind TLS-terminating ingress
- Supports integration with external identity providers

## Troubleshooting

### Common Issues

1. **UI not accessible**: Check ingress configuration and DNS resolution
2. **TLS certificate not issued**: Verify cert-manager and ClusterIssuer status
3. **Applications not syncing**: Check ArgoCD server logs and Git repository access

### Debug Commands

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Check ingress status
kubectl get ingress -n argocd

# Access ArgoCD CLI
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080
```

### Initial Admin Password

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## GitOps Workflow

1. **Application Definition**: Define applications in Git repositories
2. **ArgoCD Sync**: ArgoCD monitors Git repositories for changes
3. **Deployment**: ArgoCD applies changes to Kubernetes clusters
4. **Health Monitoring**: ArgoCD monitors application health and status

## Version Management

This module uses centralized version management through the `shared/versions` module. Chart versions are automatically managed and updated centrally.

## Contributing

When updating this module:
1. Test UI accessibility and functionality
2. Verify TLS certificate provisioning
3. Test with sample applications
4. Update documentation
