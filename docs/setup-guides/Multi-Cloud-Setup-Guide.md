# 🌐 Multi-Cloud Setup Guide - Crossplane + ArgoCD

This guide provides comprehensive instructions for setting up multi-cloud infrastructure provisioning using Crossplane with AWS, GCP, and Azure providers.

## 📋 Overview

The Multi-Service Delivery Platform now supports **true multi-cloud deployment** with:

- **AWS**: RDS PostgreSQL, ElastiCache Redis, EKS, S3, Lambda
- **GCP**: Cloud SQL PostgreSQL, Memorystore Redis, GKE, Cloud Storage, Cloud Functions  
- **Azure**: Database for PostgreSQL, Cache for Redis, AKS, Blob Storage, Functions

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Multi-Cloud Architecture                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │    AWS      │  │    GCP      │  │   Azure     │           │
│  │             │  │             │  │             │           │
│  │ • RDS       │  │ • Cloud SQL │  │ • PostgreSQL│           │
│  │ • ElastiCache│  │ • Memorystore│  │ • Redis     │           │
│  │ • EKS       │  │ • GKE       │  │ • AKS       │           │
│  │ • S3        │  │ • Storage   │  │ • Blob      │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Crossplane Control Plane                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ AWS Provider│  │ GCP Provider│  │Azure Provider│           │
│  │   v0.44.0   │  │   v0.33.0   │  │   v0.32.0   │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ArgoCD GitOps                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ AWS Apps    │  │ GCP Apps    │  │ Azure Apps  │           │
│  │             │  │             │  │             │           │
│  │ • Dev       │  │ • Dev       │  │ • Dev       │           │
│  │ • Staging   │  │ • Staging   │  │ • Staging   │           │
│  │ • Prod      │  │ • Prod      │  │ • Prod      │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Minikube running with Crossplane v2.0.2
- ArgoCD installed and accessible
- Cloud provider accounts (AWS, GCP, Azure)

### 1. Install Multi-Cloud Providers

```bash
# Install AWS Provider
crossplane xpkg install provider xpkg.upbound.io/crossplane-contrib/provider-aws:v0.44.0

# Install GCP Provider  
crossplane xpkg install provider xpkg.upbound.io/crossplane-contrib/provider-gcp:v0.33.0

# Install Azure Provider (already installed)
crossplane xpkg install provider xpkg.upbound.io/crossplane-contrib/provider-azure:v0.32.0
```

### 2. Verify Provider Installation

```bash
kubectl get providers
```

Expected output:
```
NAME                                INSTALLED   HEALTHY   PACKAGE
crossplane-contrib-provider-aws     True        True      xpkg.upbound.io/crossplane-contrib/provider-aws:v0.44.0
crossplane-contrib-provider-gcp     True        True      xpkg.upbound.io/crossplane-contrib/provider-gcp:v0.33.0
crossplane-contrib-provider-azure   True        True      xpkg.upbound.io/crossplane-contrib/provider-azure:v0.32.0
```

## 🔐 Cloud Provider Configuration

### AWS Configuration

#### 1. Create AWS IAM User
```bash
# Create IAM user with programmatic access
aws iam create-user --user-name crossplane-delivery-platform

# Attach required policies
aws iam attach-user-policy \
  --user-name crossplane-delivery-platform \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

#### 2. Create Access Keys
```bash
# Create access keys
aws iam create-access-key --user-name crossplane-delivery-platform
```

#### 3. Create Kubernetes Secret
```bash
kubectl create secret generic aws-credentials \
  --from-literal=credentials='[default]
aws_access_key_id=YOUR_ACCESS_KEY_ID
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
region=us-east-1' \
  -n crossplane-system
```

#### 4. Apply Provider Configuration
```bash
kubectl apply -f infrastructure/crossplane/provider-configs/aws-provider-config.yaml
```

### GCP Configuration

#### 1. Create Service Account
```bash
# Create service account
gcloud iam service-accounts create crossplane-delivery-platform \
  --display-name="Crossplane Delivery Platform"

# Grant required roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:crossplane-delivery-platform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"
```

#### 2. Create Service Account Key
```bash
# Create and download key
gcloud iam service-accounts keys create crossplane-key.json \
  --iam-account=crossplane-delivery-platform@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

#### 3. Create Kubernetes Secret
```bash
kubectl create secret generic gcp-credentials \
  --from-file=credentials=crossplane-key.json \
  -n crossplane-system
```

#### 4. Apply Provider Configuration
```bash
kubectl apply -f infrastructure/crossplane/provider-configs/gcp-provider-config.yaml
```

### Azure Configuration

#### 1. Create Service Principal
```bash
# Create service principal
az ad sp create-for-rbac \
  --name "crossplane-delivery-platform" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

#### 2. Create Kubernetes Secret
```bash
kubectl create secret generic azure-credentials \
  --from-literal=client_id=YOUR_CLIENT_ID \
  --from-literal=client_secret=YOUR_CLIENT_SECRET \
  --from-literal=tenant_id=YOUR_TENANT_ID \
  --from-literal=subscription_id=YOUR_SUBSCRIPTION_ID \
  -n crossplane-system
```

#### 3. Apply Provider Configuration
```bash
kubectl apply -f infrastructure/crossplane/provider-configs/azure-provider-config.yaml
```

## 🏗️ Infrastructure Provisioning

### Database Infrastructure

#### AWS RDS + ElastiCache
```yaml
apiVersion: delivery-platform.io/v1alpha1
kind: Database
metadata:
  name: delivery-platform-aws-db
spec:
  provider: aws
  environment: dev
  region: us-east-1
  aws-vpc-id: vpc-12345678
  aws-subnet-ids:
    - subnet-12345678
    - subnet-87654321
```

#### GCP Cloud SQL + Memorystore
```yaml
apiVersion: delivery-platform.io/v1alpha1
kind: Database
metadata:
  name: delivery-platform-gcp-db
spec:
  provider: gcp
  environment: dev
  region: us-central1
  gcp-project-id: your-gcp-project-id
  gcp-network: default
```

#### Azure Database + Cache
```yaml
apiVersion: delivery-platform.io/v1alpha1
kind: Database
metadata:
  name: delivery-platform-azure-db
spec:
  provider: azure
  environment: dev
  region: "East US"
  azure-resource-group: delivery-platform-rg
  azure-location: "East US"
```

### Apply Infrastructure Claims

```bash
# Apply AWS infrastructure
kubectl apply -f infrastructure/crossplane/claims/aws-database-claim.yaml

# Apply GCP infrastructure
kubectl apply -f infrastructure/crossplane/claims/gcp-database-claim.yaml

# Apply Azure infrastructure
kubectl apply -f infrastructure/crossplane/claims/azure-database-claim.yaml
```

## 📊 Monitoring and Management

### Check Resource Status
```bash
# Check database claims
kubectl get databases

# Check managed resources
kubectl get managed

# Check specific provider resources
kubectl get dbinstances  # AWS RDS
kubectl get databaseinstances  # GCP Cloud SQL
kubectl get flexibleservers  # Azure PostgreSQL
```

### ArgoCD Application Management

#### Multi-Cloud Applications
```yaml
# AWS Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: delivery-platform-aws
spec:
  source:
    repoURL: https://github.com/santanubiswas2k1/multi-service-delivery-platform
    path: infrastructure/argocd/applications
    helm:
      valueFiles:
        - values-aws.yaml
  destination:
    server: https://aws-cluster.example.com
    namespace: delivery-platform

---
# GCP Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: delivery-platform-gcp
spec:
  source:
    repoURL: https://github.com/santanubiswas2k1/multi-service-delivery-platform
    path: infrastructure/argocd/applications
    helm:
      valueFiles:
        - values-gcp.yaml
  destination:
    server: https://gcp-cluster.example.com
    namespace: delivery-platform

---
# Azure Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: delivery-platform-azure
spec:
  source:
    repoURL: https://github.com/santanubiswas2k1/multi-service-delivery-platform
    path: infrastructure/argocd/applications
    helm:
      valueFiles:
        - values-azure.yaml
  destination:
    server: https://azure-cluster.example.com
    namespace: delivery-platform
```

## 🔧 Troubleshooting

### Common Issues

#### Provider Not Healthy
```bash
# Check provider status
kubectl describe provider crossplane-contrib-provider-aws

# Check provider pods
kubectl get pods -n crossplane-system

# Check provider logs
kubectl logs -n crossplane-system deployment/crossplane-contrib-provider-aws
```

#### Authentication Issues
```bash
# Verify credentials secret
kubectl get secret aws-credentials -n crossplane-system -o yaml

# Test provider configuration
kubectl describe providerconfig aws-config
```

#### Resource Creation Failures
```bash
# Check claim status
kubectl describe database delivery-platform-aws-db

# Check managed resource status
kubectl describe dbinstance <instance-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Provider-Specific Troubleshooting

#### AWS
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam list-attached-user-policies --user-name crossplane-delivery-platform
```

#### GCP
```bash
# Check GCP authentication
gcloud auth list

# Verify service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID
```

#### Azure
```bash
# Check Azure authentication
az account show

# Verify service principal permissions
az role assignment list --assignee YOUR_CLIENT_ID
```

## 📚 Best Practices

### Security
- Use least privilege IAM roles
- Rotate credentials regularly
- Enable audit logging
- Use private networks where possible

### Cost Optimization
- Use appropriate instance sizes
- Enable auto-scaling
- Implement resource tagging
- Monitor usage with cloud cost tools

### Reliability
- Enable backups and point-in-time recovery
- Use multi-AZ deployments for production
- Implement health checks
- Set up monitoring and alerting

### GitOps
- Store all configurations in Git
- Use environment-specific branches
- Implement approval workflows
- Monitor drift detection

## 🎯 Next Steps

1. **Configure Cloud Credentials**: Set up authentication for each cloud provider
2. **Test Infrastructure Provisioning**: Create test resources in each cloud
3. **Set Up Monitoring**: Configure observability across all clouds
4. **Implement CI/CD**: Set up automated deployment pipelines
5. **Production Deployment**: Deploy to production environments

## 📖 Additional Resources

- [Crossplane Documentation](https://docs.crossplane.io/)
- [AWS Provider Documentation](https://doc.crds.dev/github.com/crossplane-contrib/provider-aws)
- [GCP Provider Documentation](https://doc.crds.dev/github.com/crossplane-contrib/provider-gcp)
- [Azure Provider Documentation](https://doc.crds.dev/github.com/crossplane-contrib/provider-azure)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## 🤝 Contributing

When adding new multi-cloud resources:

1. **Add Provider Resources**: Update compositions with new cloud resources
2. **Create Claims**: Add example claims for new resources
3. **Update Documentation**: Document new capabilities
4. **Test Across Clouds**: Verify functionality in all supported clouds
