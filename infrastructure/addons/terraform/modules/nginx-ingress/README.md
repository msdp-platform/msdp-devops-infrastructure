# NGINX Ingress Controller Terraform Module

This module deploys the NGINX Ingress Controller for managing ingress traffic in Kubernetes clusters.

## Features

- 🌐 HTTP/HTTPS traffic routing
- 🔒 SSL/TLS termination
- ⚖️ Load balancing and high availability
- 📊 Metrics and monitoring integration
- 🛡️ Security features (rate limiting, authentication)
- ☁️ Multi-cloud support (AWS EKS, Azure AKS)

## Usage

### Basic Usage
```hcl
module "nginx_ingress" {
  source = "../../modules/nginx-ingress"
  
  enabled = true
}
```

### Advanced Usage with Custom Configuration
```hcl
module "nginx_ingress" {
  source = "../../modules/nginx-ingress"
  
  enabled   = true
  namespace = "nginx-ingress"
  
  # Scaling Configuration
  replica_count = 3
  
  # Service Configuration
  service_type = "LoadBalancer"
  
  # Resource Configuration
  resources = {
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
  
  # Monitoring
  metrics_enabled = true
  
  installation_timeout = 600
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
| enabled | Enable or disable NGINX Ingress Controller deployment | `bool` | `true` | no |
| namespace | Kubernetes namespace for NGINX Ingress Controller | `string` | `"nginx-ingress"` | no |
| replica_count | Number of NGINX Ingress Controller replicas | `number` | `2` | no |
| service_type | Service type for NGINX Ingress Controller | `string` | `"LoadBalancer"` | no |
| load_balancer_source_ranges | Source IP ranges for LoadBalancer service | `list(string)` | `[]` | no |
| resources | Resource requests and limits | `object` | See defaults | no |
| metrics_enabled | Enable Prometheus metrics | `bool` | `true` | no |
| installation_timeout | Timeout for Helm installation in seconds | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where NGINX Ingress Controller is deployed |
| service_name | The name of the NGINX Ingress Controller service |
| ingress_class_name | The ingress class name for this controller |

## Dependencies

This module depends on:
- `shared/versions` - For centralized version management

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   External      │────│   LoadBalancer   │────│  NGINX Ingress  │
│   Traffic       │    │   Service        │    │   Controller    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                                ▼                        ▼
                    ┌──────────────────┐    ┌─────────────────┐
                    │   Ingress        │────│   Backend       │
                    │   Resources      │    │   Services      │
                    └──────────────────┘    └─────────────────┘
```

## Default Configuration

- **Replica Count**: 2 (for high availability)
- **Service Type**: LoadBalancer
- **Metrics**: Enabled for Prometheus scraping
- **Security**: Default security headers enabled
- **Resource Limits**: Configured for production workloads

## Ingress Class

This module creates an ingress class named `nginx` that can be used by other services:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

## Security Features

- **Rate Limiting**: Configurable request rate limits
- **IP Whitelisting**: Source IP filtering
- **SSL/TLS**: Automatic certificate management integration
- **Security Headers**: HSTS, CSP, and other security headers
- **Authentication**: Basic auth, OAuth, and external auth support

## Monitoring and Observability

- **Prometheus Metrics**: Detailed ingress and backend metrics
- **Access Logs**: Configurable logging formats
- **Health Checks**: Readiness and liveness probes
- **Status Pages**: Built-in status and metrics endpoints

## Troubleshooting

### Common Issues

1. **LoadBalancer pending**: Check cloud provider load balancer quotas
2. **502/503 errors**: Verify backend service health and endpoints
3. **SSL certificate issues**: Check cert-manager configuration
4. **High latency**: Review resource limits and replica count

### Debug Commands

```bash
# Check NGINX Ingress Controller pods
kubectl get pods -n nginx-ingress

# Check ingress controller logs
kubectl logs -n nginx-ingress deployment/nginx-ingress-controller

# Check ingress resources
kubectl get ingress --all-namespaces

# Check service endpoints
kubectl get endpoints -n nginx-ingress

# Test configuration
kubectl exec -n nginx-ingress deployment/nginx-ingress-controller -- nginx -T
```

### Performance Tuning

```yaml
# Increase worker processes and connections
controller:
  config:
    worker-processes: "auto"
    max-worker-connections: "16384"
    
# Adjust buffer sizes
    proxy-buffer-size: "8k"
    proxy-buffers-number: "8"
```

## Cloud Provider Integration

### AWS EKS
- Integrates with AWS Load Balancer Controller
- Supports Network Load Balancer (NLB) annotations
- Cross-zone load balancing support

### Azure AKS
- Integrates with Azure Load Balancer
- Supports Azure-specific annotations
- Integration with Azure DNS

## Version Management

This module uses centralized version management through the `shared/versions` module. Chart versions are automatically managed and updated centrally.

## Contributing

When updating this module:
1. Test ingress functionality with sample applications
2. Verify load balancer provisioning
3. Check metrics collection
4. Test SSL/TLS certificate integration
5. Update documentation
