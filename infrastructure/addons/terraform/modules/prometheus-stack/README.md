# Prometheus Stack Terraform Module

This module deploys the kube-prometheus-stack for comprehensive monitoring and observability in Kubernetes clusters.

## Features

- 📊 Complete monitoring stack (Prometheus, Grafana, AlertManager)
- 🌐 Web UI access with ingress support
- 🔒 TLS certificate integration with cert-manager
- 📈 Pre-configured dashboards and alerts
- 🛡️ Security hardening and RBAC
- 📱 Alert routing and notification management

## Usage

### Basic Usage
```hcl
module "prometheus_stack" {
  source = "../../modules/prometheus-stack"
  
  enabled = true
  
  prometheus_hostname = "prometheus.aztech-msdp.com"
  grafana_hostname    = "grafana.aztech-msdp.com"
  
  cluster_issuer_name = "letsencrypt-prod"
  ingress_class_name  = "nginx"
}
```

### Advanced Usage with Custom Configuration
```hcl
module "prometheus_stack" {
  source = "../../modules/prometheus-stack"
  
  enabled   = true
  namespace = "monitoring"
  
  # Hostnames
  prometheus_hostname = "prometheus.example.com"
  grafana_hostname    = "grafana.example.com"
  
  # TLS Configuration
  cluster_issuer_name = "letsencrypt-prod"
  prometheus_tls_secret_name = "prometheus-tls"
  grafana_tls_secret_name    = "grafana-tls"
  
  # Ingress Configuration
  ingress_class_name = "nginx"
  prometheus_additional_annotations = {
    "nginx.ingress.kubernetes.io/auth-type" = "basic"
  }
  grafana_additional_annotations = {
    "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
  }
  
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
| enabled | Enable or disable the Prometheus stack deployment | `bool` | `true` | no |
| namespace | Kubernetes namespace for the Prometheus stack | `string` | `"monitoring"` | no |
| prometheus_hostname | Hostname used to expose the Prometheus UI | `string` | n/a | yes |
| grafana_hostname | Hostname used to expose the Grafana UI | `string` | n/a | yes |
| cluster_issuer_name | Cert-Manager cluster issuer used for TLS | `string` | `""` | no |
| ingress_class_name | Ingress class name used by NGINX | `string` | `"nginx"` | no |
| prometheus_tls_secret_name | TLS secret name for Prometheus ingress | `string` | `"prometheus-tls"` | no |
| grafana_tls_secret_name | TLS secret name for Grafana ingress | `string` | `"grafana-tls"` | no |
| prometheus_additional_annotations | Additional annotations for the Prometheus ingress | `map(string)` | `{}` | no |
| grafana_additional_annotations | Additional annotations for the Grafana ingress | `map(string)` | `{}` | no |
| installation_timeout | Helm installation timeout in seconds | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | The namespace where Prometheus stack is deployed |
| prometheus_hostname | The hostname where Prometheus UI is accessible |
| grafana_hostname | The hostname where Grafana UI is accessible |

## Dependencies

This module depends on:
- `shared/versions` - For centralized version management
- `cert-manager` - For TLS certificate management (optional)
- `nginx-ingress` - For ingress controller

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Grafana UI    │────│     Ingress      │────│  cert-manager   │
│   (Dashboard)   │    │   (nginx)        │    │   (TLS Certs)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────┐
│   Prometheus    │────│   AlertManager   │
│   (Metrics)     │    │   (Alerts)       │
└─────────────────┘    └──────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────┐
│   Node Exporter │    │   Notification   │
│   (Node Metrics)│    │   Channels       │
└─────────────────┘    └──────────────────┘
```

## Components

### Prometheus
- Metrics collection and storage
- PromQL query engine
- Alert rule evaluation
- Service discovery

### Grafana
- Visualization dashboards
- User management
- Data source configuration
- Alerting (optional)

### AlertManager
- Alert routing and grouping
- Notification management
- Silence management
- Inhibition rules

### Exporters
- Node Exporter (node metrics)
- kube-state-metrics (Kubernetes metrics)
- cAdvisor (container metrics)

## Default Dashboards

The stack includes pre-configured dashboards for:
- Kubernetes cluster overview
- Node resource utilization
- Pod resource usage
- Persistent volume monitoring
- Network traffic analysis

## Security Considerations

- RBAC policies for service accounts
- Network policies for pod communication
- TLS encryption for web interfaces
- Configurable authentication methods
- Data retention policies

## Troubleshooting

### Common Issues

1. **UI not accessible**: Check ingress configuration and DNS resolution
2. **Metrics not collected**: Verify service discovery and scrape configurations
3. **High resource usage**: Adjust retention policies and scrape intervals
4. **Alerts not firing**: Check AlertManager configuration and routing rules

### Debug Commands

```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
# Visit http://localhost:3000

# Get Grafana admin password
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

### Performance Tuning

```yaml
# Adjust retention and storage
prometheus:
  prometheusSpec:
    retention: "30d"
    retentionSize: "50GB"
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 100Gi
```

## Monitoring Best Practices

1. **Resource Planning**: Allocate sufficient storage and compute resources
2. **Alert Tuning**: Configure meaningful alerts with appropriate thresholds
3. **Dashboard Organization**: Create role-specific dashboards
4. **Data Retention**: Balance storage costs with monitoring needs
5. **High Availability**: Consider multi-replica deployments for production

## Version Management

This module uses centralized version management through the `shared/versions` module. Chart versions are automatically managed and updated centrally.

## Contributing

When updating this module:
1. Test both Prometheus and Grafana UIs
2. Verify alert rule functionality
3. Check dashboard availability
4. Test with different resource configurations
5. Update documentation
