# MSDP Backstage Deployment

This directory contains the simplified Backstage deployment configuration for the MSDP platform, integrated with the smart deployment system.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Smart Deployment System                      │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │ Crossplane  │ │   ArgoCD    │ │  Backstage  │ │  GitHub     │ │
│  │Infrastructure│ │   GitOps    │ │   Portal    │ │  Actions    │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Environment Deployment                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │     Dev     │ │    Test     │ │    Prod     │ │  Monitoring │ │
│  │ Environment │ │ Environment │ │ Environment │ │   Stack     │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Simplified Directory Structure

```
infrastructure/applications/backstage/
├── Chart.yaml                          # Helm chart metadata
├── values.yaml                         # Base values
├── values-dev.yaml                     # Development overrides
├── values-test.yaml                    # Test overrides
├── values-prod.yaml                    # Production overrides
├── values-simplified.yaml              # Reference configuration
├── templates/                          # Helm templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml
│   └── _helpers.tpl
└── README.md                           # This documentation
```

## 🚀 Quick Start

### Prerequisites

1. **Smart Deployment System** configured and running
2. **Crossplane** installed with Azure provider
3. **ArgoCD** installed and configured
4. **GitHub repository** with required secrets configured

### Deploy Backstage

#### **Method 1: Smart Branch-Driven Deployment (Recommended)**

**Automatic Deployment:**
```bash
# Deploy to development
git push origin dev

# Deploy to test
git push origin test

# Deploy to production
git push origin prod
```

**Manual Deployment:**
1. Go to **Actions** tab in GitHub
2. Select **"Deploy Infrastructure"**
3. Click **"Run workflow"**
4. Choose parameters:
   - Environment: `dev`, `test`, `prod`
   - Components: `crossplane,argocd,backstage`

#### **Method 2: Direct Helm Deployment**

```bash
# Deploy to development
helm upgrade --install backstage ./infrastructure/applications/backstage \
  --namespace backstage-dev \
  --values ./infrastructure/applications/backstage/values-dev.yaml

# Deploy to test
helm upgrade --install backstage ./infrastructure/applications/backstage \
  --namespace backstage-test \
  --values ./infrastructure/applications/backstage/values-test.yaml

# Deploy to production
helm upgrade --install backstage ./infrastructure/applications/backstage \
  --namespace backstage-prod \
  --values ./infrastructure/applications/backstage/values-prod.yaml
```

## 🔧 Configuration

### Environment-Specific Values

The deployment uses environment-specific value files:

- **`values.yaml`**: Base configuration
- **`values-dev.yaml`**: Development environment overrides
- **`values-test.yaml`**: Test environment overrides  
- **`values-prod.yaml`**: Production environment overrides

### Key Configuration Areas

1. **Application Settings**: Title, base URL, organization details
2. **Database Configuration**: PostgreSQL connection settings
3. **Authentication**: GitHub OAuth integration
4. **Integrations**: GitHub, ArgoCD connections
5. **Kubernetes Resources**: Replicas, resource limits, scaling
6. **Ingress**: SSL certificates, domain configuration

### Secrets Management

Secrets are managed through the smart deployment system:
- Database passwords
- GitHub tokens
- ArgoCD credentials
- Session secrets

All secrets are injected automatically during deployment.

## 🔒 Security

- **Secrets Management**: All secrets managed through smart deployment system
- **Authentication**: GitHub OAuth integration
- **Network Security**: TLS/SSL encryption, ingress controller
- **RBAC**: Role-based access control for service access

## 📊 Monitoring

- **Health Checks**: Pod, service, and ingress health monitoring
- **Prometheus Integration**: Service metrics and resource utilization
- **Application Insights**: Performance monitoring and error tracking
- **Grafana Dashboards**: Service overview and performance metrics

## 🔄 Smart Deployment Integration

### GitHub Actions Workflow

The Backstage deployment is integrated with the smart deployment system:

- **Branch-Driven**: Automatic deployment based on branch (`dev`, `test`, `prod`)
- **Environment-Specific**: Different configurations per environment
- **GitOps**: ArgoCD manages the deployment lifecycle
- **Infrastructure as Code**: Crossplane manages infrastructure resources

### Deployment Flow

```
Code Push → GitHub Actions → Crossplane → ArgoCD → Backstage
```

## 🛠️ Troubleshooting

### Common Commands

```bash
# Check Backstage pods
kubectl get pods -n backstage-<environment>

# Check Backstage logs
kubectl logs -f deployment/backstage -n backstage-<environment>

# Check ArgoCD application
kubectl get application -n argocd

# Check Crossplane resources
kubectl get xbackstageinfrastructure -n crossplane-system
```

### Health Checks

```bash
# Check service health
kubectl get svc -n backstage-<environment>

# Check ingress
kubectl get ingress -n backstage-<environment>

# Check secrets
kubectl get secrets -n backstage-<environment>
```

## 📚 Additional Resources

- [Backstage Documentation](https://backstage.io/docs/)
- [Smart Deployment System](../README-Smart-Deployment.md)
- [Crossplane Documentation](https://crossplane.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Contributing

1. Make changes to the appropriate values file
2. Test in development environment
3. Create PR to promote to test/prod
4. Follow the smart deployment workflow

---

**This Backstage configuration is now fully integrated with the smart deployment system for seamless, automated deployment across all environments.** 🚀
