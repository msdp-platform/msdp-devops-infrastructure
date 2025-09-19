# Terraform Modules

This directory contains reusable Terraform modules for Kubernetes addons deployment.

## 📁 Module Structure

Each module follows a standardized structure:

```
module-name/
├── main.tf           # Main resource definitions
├── variables.tf      # Input variables
├── outputs.tf        # Output values (if applicable)
├── values.yaml       # Helm values template (for Helm-based modules)
└── README.md         # Module documentation
```

## 🧩 Available Modules

### Core Infrastructure
- **`shared/`** - Shared components and utilities
  - `aws-credentials/` - AWS credential secret management
  - `versions/` - Centralized version management

### Kubernetes Addons
- **`argocd/`** - GitOps continuous deployment
- **`cert-manager/`** - TLS certificate management
- **`external-dns/`** - DNS record automation
- **`nginx-ingress/`** - Ingress controller
- **`prometheus-stack/`** - Monitoring and observability

### Storage & Scaling
- **`azure-disk-csi-driver/`** - Azure disk storage
- **`keda/`** - Event-driven autoscaling
- **`virtual-node/`** - Azure Container Instances integration

### Development Tools
- **`backstage/`** - Developer portal
- **`crossplane/`** - Cloud resource management

### Cloud-Specific
- **`karpenter/`** - AWS node provisioning (EKS only)

## 🔧 Usage Patterns

### Basic Module Usage
```hcl
module "cert_manager" {
  source = "../../modules/cert-manager"
  
  enabled = true
  namespace = "cert-manager"
  email = "admin@example.com"
  cloud_provider = "azure"
}
```

### With Shared Components
```hcl
module "external_dns" {
  source = "../../modules/external-dns"
  
  enabled = true
  aws_access_key_id = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  
  depends_on = [module.cert_manager]
}
```

## 📋 Module Standards

### Required Files
- `main.tf` - Resource definitions
- `variables.tf` - Input variables with descriptions
- `outputs.tf` - Output values (if module produces outputs)

### Optional Files
- `values.yaml` - Helm values template (for Helm-based modules)
- `README.md` - Module-specific documentation

### Variable Conventions
- `enabled` - Boolean to enable/disable module
- `namespace` - Kubernetes namespace
- `cloud_provider` - Cloud provider (aws or azure)
- `*_timeout` - Timeout configurations
- `*_resources` - Resource limits/requests
- `ingress_annotations` - Additional ingress annotations
- `cluster_issuer_name` - Cert-Manager cluster issuer name

### Output Conventions
- `namespace` - Deployed namespace
- `helm_release_status` - Helm release status
- `*_status` - Module deployment status

## 🔗 Dependencies

### Common Dependencies
1. **external-dns** → Foundation (no dependencies)
2. **cert-manager** → Depends on external-dns
3. **nginx-ingress** → Depends on cert-manager
4. **prometheus-stack** → Depends on cert-manager + nginx-ingress
5. **argocd** → Depends on cert-manager + nginx-ingress

### Shared Components
All modules can use:
- `shared/aws-credentials` - For AWS authentication
- `shared/versions` - For centralized version management

## 🚀 Development Guidelines

### Adding New Modules
1. Create module directory with standard structure
2. Follow naming conventions
3. Include proper variable validation
4. Add comprehensive outputs
5. Document usage examples
6. Test with multiple environments

### Updating Existing Modules
1. Maintain backward compatibility
2. Update version references via `shared/versions`
3. Test changes thoroughly
4. Update documentation

## 🔍 Troubleshooting

### Common Issues
- **Module not found**: Check relative path in source
- **Version conflicts**: Use `shared/versions` for consistency
- **Dependency errors**: Ensure proper `depends_on` configuration
- **Namespace conflicts**: Use unique namespaces per module

### Debug Commands
```bash
# Validate module
terraform validate

# Plan specific module
terraform plan -target=module.module_name

# Check module dependencies
terraform graph | grep module_name
```
