# 🚀 Smart Branch-Driven Infrastructure Deployment

## Overview

This repository implements a smart, branch-driven deployment system for the MSDP DevOps infrastructure. The system uses a single codebase with environment-specific configurations driven by branch selection, enabling seamless promotion through pull requests.

## 🎯 Key Features

- **Single Codebase**: Same IaC code for all environments
- **Branch-Driven**: Environment determined by Git branch
- **PR-Based Promotion**: Promote changes through pull requests
- **GitHub Actions**: Automated deployment and validation
- **Multi-Environment**: Dev, Test, and Production support

## 🌳 Branch Strategy

| Branch | Environment | Purpose |
|--------|-------------|---------|
| `dev` | Development | Active development and testing |
| `test` | Test | Pre-production validation |
| `prod` | Production | Live production environment |

## 🔄 Promotion Flow

```
dev → test → prod
 ↓     ↓     ↓
dev   test   prod
```

### Promotion Process

1. **Dev to Test**: Create PR from `dev` to `test`
2. **Test to Prod**: Create PR from `test` to `prod`
3. **Direct to Prod**: Create PR from `dev` to `prod` (emergency fixes)

## 🏗️ Infrastructure Components

### 1. Crossplane
- **Purpose**: Infrastructure as Code management
- **Location**: `infrastructure/components/crossplane/`
- **Features**: Multi-cloud resource provisioning

### 2. ArgoCD
- **Purpose**: GitOps application deployment
- **Location**: `infrastructure/components/argocd/`
- **Features**: Automated application synchronization

### 3. Backstage
- **Purpose**: Developer portal
- **Location**: `infrastructure/components/backstage/`
- **Features**: Service catalog and developer experience

## 📁 Directory Structure

```
infrastructure/
├── components/                    # Reusable component definitions
│   ├── crossplane/               # Crossplane IaC
│   │   ├── xrds/                 # Composite Resource Definitions
│   │   ├── compositions/         # Infrastructure compositions
│   │   ├── claims/               # Resource claims
│   │   └── providers/            # Provider configurations
│   ├── argocd/                   # ArgoCD configurations
│   │   ├── install/              # ArgoCD installation
│   │   ├── applications/         # ArgoCD applications
│   │   └── projects/             # ArgoCD projects
│   └── backstage/                # Backstage configurations
│       ├── helm/                 # Helm charts
│       ├── configs/              # Configuration files
│       └── claims/               # Resource claims
├── environments/                 # Environment-specific values
│   ├── dev/values.yaml          # Development configuration
│   ├── test/values.yaml         # Test configuration
│   └── prod/values.yaml         # Production configuration
└── README-Smart-Deployment.md   # This documentation
```

## 🚀 Deployment Process

### Automatic Deployment

Deployments are triggered automatically on:

- **Push to `dev`**: Deploys to development environment
- **Push to `test`**: Deploys to test environment
- **Push to `prod`**: Deploys to production environment

### Manual Deployment

You can also trigger deployments manually:

1. Go to **Actions** tab in GitHub
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Choose environment and components

## 🔧 Environment Configuration

Each environment has its own configuration file:

### Development (`dev/values.yaml`)
- **Cluster**: `msdp-infra-aks-dev`
- **Resources**: Minimal (1 node, B2s)
- **Replicas**: 1
- **Cost Optimization**: Enabled (Spot instances)

### Test (`test/values.yaml`)
- **Cluster**: `msdp-infra-aks-test`
- **Resources**: Medium (2 nodes, D2s_v3)
- **Replicas**: 2
- **Cost Optimization**: Enabled (Spot instances)

### Production (`prod/values.yaml`)
- **Cluster**: `msdp-infra-aks-prod`
- **Resources**: High (3 nodes, D4s_v3)
- **Replicas**: 3
- **Cost Optimization**: Disabled (Regular instances)

## 🛠️ GitHub Actions Workflow

The deployment workflow (`ci-cd/workflows/deploy-infrastructure.yml`) includes:

### 1. Environment Detection
- Determines environment based on branch
- Sets cluster and resource group names
- Configures deployment parameters

### 2. Validation
- Validates YAML configurations
- Checks Crossplane compositions
- Verifies ArgoCD applications

### 3. Deployment
- **Crossplane**: Infrastructure management
- **ArgoCD**: GitOps platform
- **Backstage**: Developer portal

### 4. Verification
- Checks pod status
- Validates service health
- Confirms deployment success

## 🔐 Security

### Secrets Management
- Azure credentials stored in GitHub Secrets
- Environment-specific secret scoping
- Automatic secret rotation support

### RBAC
- Role-based access control enabled
- Environment-specific permissions
- Service account isolation

## 📊 Monitoring

### Health Checks
- Pod readiness verification
- Service endpoint validation
- Application health monitoring

### Logging
- Centralized logging with Azure Monitor
- Structured logging format
- Error tracking and alerting

## 🚨 Troubleshooting

### Common Issues

#### 1. Deployment Fails
```bash
# Check workflow logs
gh run list --workflow=deploy-infrastructure.yml

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

#### 2. Environment Mismatch
```bash
# Verify environment detection
echo $GITHUB_REF_NAME
echo $ENVIRONMENT
```

#### 3. Resource Conflicts
```bash
# Check existing resources
kubectl get all --all-namespaces
az aks list --resource-group delivery-platform-aks-rg-*
```

### Debug Commands

```bash
# Check Crossplane status
kubectl get providers
kubectl get compositions
kubectl get managed

# Check ArgoCD status
kubectl get applications -n argocd
kubectl get pods -n argocd

# Check Backstage status
kubectl get pods -n backstage
kubectl get services -n backstage
```

## 🎯 Best Practices

### 1. Branch Management
- Keep `dev` branch stable
- Test thoroughly in test environment
- Use feature branches for development

### 2. Configuration Changes
- Update environment values files
- Test in dev environment first
- Promote through PRs

### 3. Resource Management
- Use appropriate resource sizes
- Enable cost optimization in dev/test
- Monitor resource usage

### 4. Security
- Rotate secrets regularly
- Use least privilege access
- Enable audit logging

## 📈 Future Enhancements

- [ ] Multi-region deployment support
- [ ] Blue-green deployment strategy
- [ ] Advanced monitoring and alerting
- [ ] Cost optimization automation
- [ ] Disaster recovery procedures

## 🤝 Contributing

1. Create feature branch from `dev`
2. Make changes and test locally
3. Create PR to `dev` branch
4. Promote through test to production

## 📞 Support

For issues and questions:
- **GitHub Issues**: Create issue in this repository
- **Team Chat**: #devops-platform
- **Email**: devops@msdp.com

---

**Happy Deploying! 🚀**
