# Configuration Management

This directory contains all configuration files for the MSDP DevOps Infrastructure platform.

## Directory Structure

```
infrastructure/config/
├── global.yaml                    # Global variables (versions, domains, etc.)
├── environments/                  # Environment-specific configurations
│   ├── dev.yaml                  # Development environment
│   ├── test.yaml                 # Test environment
│   └── prod.yaml                 # Production environment
├── components/                    # Component-specific configurations
│   ├── nginx-ingress.yaml        # NGINX Ingress Controller
│   ├── cert-manager.yaml         # Cert-Manager
│   ├── external-dns.yaml         # External DNS
│   ├── prometheus.yaml           # Prometheus
│   ├── grafana.yaml              # Grafana
│   ├── argocd.yaml               # ArgoCD
│   ├── backstage.yaml            # Backstage
│   └── crossplane.yaml           # Crossplane
├── load-config.sh                # Configuration loader script
└── README.md                     # This file
```

## Configuration Hierarchy

1. **Global Configuration** (`global.yaml`)
   - Component versions
   - Azure credentials
   - Domain configuration
   - AWS configuration
   - Default timeouts
   - Default resource limits

2. **Environment Configuration** (`environments/*.yaml`)
   - Cluster names
   - Resource groups
   - Environment-specific overrides
   - Environment-specific resource limits

3. **Component Configuration** (`components/*.yaml`)
   - Detailed component-specific settings
   - Resource configurations
   - Service configurations
   - Ingress configurations

## Usage

### Loading Configuration in Pipeline

```bash
# Load configuration for specific environment
source infrastructure/config/load-config.sh dev

# Or use the loader function directly
load_configuration
```

### Environment Variables

After loading configuration, the following environment variables are available:

```bash
# Azure Configuration
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID

# AWS Configuration
AWS_REGION

# Cluster Configuration
CLUSTER_NAME
RESOURCE_GROUP

# Component Versions
EXPECTED_ARGOCD_VERSION
EXPECTED_GRAFANA_VERSION
EXPECTED_CROSSPLANE_VERSION
EXPECTED_CERT_MANAGER_VERSION
EXPECTED_NGINX_VERSION

# Timeouts
DEPLOYMENT_TIMEOUT
VERIFICATION_TIMEOUT
POD_READY_TIMEOUT

# Domain Configuration
DOMAIN_BASE
```

## Version Management

### Updating Component Versions

To update a component version across all environments:

1. Edit `global.yaml`
2. Update the version in the appropriate section
3. Commit and push changes
4. The pipeline will automatically detect version changes and deploy

### Example: Updating Grafana Version

```yaml
# In global.yaml
platform_components:
  grafana:
    version: "10.5.0"  # Updated version
    image: "docker.io/grafana/grafana"
    chart_version: "6.62.0"
```

## Environment-Specific Overrides

### Development Environment

- More generous resource limits for debugging
- Longer timeouts for development
- Disabled persistence for easier resets
- Simple passwords for development

### Test Environment

- Balanced resource limits for testing
- Medium retention periods
- Enabled persistence
- Test-specific passwords

### Production Environment

- Optimized resource limits for performance
- Long retention periods
- High availability configurations
- Secure password requirements

## Component Configurations

Each component has its own configuration file with:

- **Resource Limits**: CPU and memory requests/limits
- **Service Configuration**: Service type, ports, annotations
- **Ingress Configuration**: Ingress settings, TLS, domains
- **Security Configuration**: Security contexts, RBAC
- **Monitoring Configuration**: Prometheus integration
- **Persistence Configuration**: Storage settings

## Best Practices

1. **Version Management**: Always update versions in `global.yaml`
2. **Environment Consistency**: Keep the same versions across environments
3. **Resource Planning**: Adjust resource limits based on environment needs
4. **Security**: Use environment-specific secrets and passwords
5. **Documentation**: Update this README when adding new configurations

## Troubleshooting

### Configuration Loading Issues

```bash
# Test configuration loading
./infrastructure/config/load-config.sh dev

# Check if files exist
ls -la infrastructure/config/
ls -la infrastructure/config/environments/
ls -la infrastructure/config/components/
```

### Version Mismatch Issues

```bash
# Check current versions in cluster
kubectl get deployment -n argocd argocd-server -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get deployment -n monitoring grafana -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Environment Variable Issues

```bash
# Check loaded environment variables
env | grep -E "(AZURE_|AWS_|CLUSTER_|EXPECTED_)"
```
