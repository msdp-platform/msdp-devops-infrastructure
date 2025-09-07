# 🏗️ Infrastructure - Multi-Service Delivery Platform

This directory contains the complete **production-ready infrastructure** for the Multi-Service Delivery Platform, built on **Azure AKS + AWS Route53 + Crossplane + ArgoCD** with comprehensive DevOps/CI-CD capabilities.

## 🎯 **Infrastructure Overview**

The infrastructure provides a **complete DevOps/CI-CD platform** with:

- **🔄 GitOps**: Complete infrastructure and application deployment automation
- **☁️ Multi-Cloud**: Azure AKS + AWS Route53 hybrid architecture
- **💰 Cost Optimization**: Up to 90% cost reduction with Spot instances
- **🔒 Enterprise Security**: Automated SSL and security policies
- **⚡ High Availability**: Multi-zone deployment with auto-failover
- **🧪 Comprehensive Testing**: Infrastructure validation and testing
- **📊 Full Monitoring**: Complete observability and monitoring

## 🚀 **DevOps/CI-CD Infrastructure**

### **📁 Infrastructure Structure**
```
infrastructure/
├── devops-ci-cd/                    # 🚀 Complete DevOps/CI-CD Infrastructure
│   ├── gitops/                      # 🔄 GitOps (ArgoCD + Crossplane)
│   ├── networking/                  # 🌐 Networking (NGINX + Route53)
│   ├── security/                    # 🔒 Security (cert-manager + SSL)
│   ├── node-management/             # ⚙️ Node Management (Karpenter + NAP)
│   ├── testing/                     # 🧪 Testing (Validation + Workloads)
│   └── monitoring/                  # 📊 Monitoring (Azure Monitor + Prometheus)
└── README.md                        # 📖 This documentation
```

## 🚀 **Quick Start - Live Infrastructure**

### **🌐 Access Your Live Services**
- **ArgoCD**: `https://argocd.dev.aztech-msdp.com` (admin/admin123)
- **Sample App**: `https://app.dev.aztech-msdp.com`
- **SSL Certificates**: Automatically managed and renewed
- **DNS**: Managed via AWS Route53

### **🔧 Platform Management**

#### **Method 1: GitHub Actions (Recommended)**
```bash
# Deploy to production
git push origin main

# Deploy to staging
git push origin develop

# Manual deployment with custom parameters
# Go to Actions tab → Deploy Backstage → Run workflow
```

#### **Method 2: Local Scripts**
```bash
# Start platform (scale up nodes)
./scripts/platform start

# Stop platform (scale down to 0 nodes - saves costs)
./scripts/platform stop

# Check platform status
./scripts/platform status

# Optimize costs
./scripts/platform optimize
```

### **📊 Infrastructure Monitoring**
```bash
# Check ArgoCD status
kubectl get applications -n argocd

# Check Crossplane resources
kubectl get managed

# Check node status
kubectl get nodes

# Check certificate status
kubectl get certificates
```

## 📁 **DevOps/CI-CD Infrastructure Structure**

```
infrastructure/
├── devops-ci-cd/                       # 🚀 Complete DevOps/CI-CD Infrastructure
│   ├── README.md                       # 📖 DevOps infrastructure documentation
│   ├── gitops/                         # 🔄 GitOps Infrastructure
│   │   ├── argocd/                     # ArgoCD GitOps deployment
│   │   │   └── applications/            # ArgoCD applications
│   │   │       └── sample-app.yaml     # Sample application
│   │   └── crossplane/                 # Crossplane Infrastructure as Code
│   │       ├── compositions/           # Crossplane compositions
│   │       │   ├── database-composition.yaml
│   │       │   ├── simple-database-composition.yaml
│   │       │   ├── multi-cloud-database-composition.yaml
│   │       │   └── simple-multi-cloud-composition.yaml
│   │       ├── claims/                 # Resource claims
│   │       │   ├── database-claim.yaml
│   │       │   ├── aws-database-claim.yaml
│   │       │   ├── gcp-database-claim.yaml
│   │       │   └── azure-database-claim.yaml
│   │       └── provider-configs/       # Provider configurations
│   │           ├── aws-provider-config.yaml
│   │           └── gcp-provider-config.yaml
│   ├── networking/                     # 🌐 Networking Infrastructure
│   │   └── ingress/                    # NGINX Ingress Controller
│   │       ├── argocd-http-ingress.yaml
│   │       └── route53-aztech-msdp-ingress.yaml
│   ├── security/                       # 🔒 Security Infrastructure
│   │   └── cert-manager/               # Certificate Management
│   │       ├── cluster-issuer.yaml     # Let's Encrypt cluster issuer
│   │       └── certificate.yaml        # SSL certificate configuration
│   ├── node-management/                # ⚙️ Node Management Infrastructure
│   │   ├── karpenter/                  # Karpenter Node Auto-Provisioning
│   │   │   └── spot-nodepool-broad-sku.yaml
│   │   └── system-pod-affinity/        # System Pod Scheduling
│   │       ├── argocd-system-affinity.yaml
│   │       ├── cert-manager-system-affinity.yaml
│   │       ├── nginx-ingress-system-affinity.yaml
│   │       └── crossplane-system-affinity.yaml
│   ├── testing/                        # 🧪 Testing Infrastructure
│   │   ├── test-pods/                  # Pod Testing
│   │   │   ├── test-user-workload.yaml
│   │   │   ├── test-system-workload.yaml
│   │   │   └── test-autoscaler-trigger.yaml
│   │   └── test-workloads/             # Workload Testing
│   │       ├── karpenter-scaling-test.yaml
│   │       └── karpenter-ondemand-test.yaml
│   └── monitoring/                     # 📊 Monitoring Infrastructure
│       └── (Azure Monitor + Prometheus + Grafana)
└── README.md                           # 📖 This documentation
```

## 🔧 **DevOps/CI-CD Components**

### **🚀 GitHub Actions Workflows**

The platform includes comprehensive GitHub Actions workflows for automated deployment, testing, and secrets management:

#### **1. Deploy Backstage (`deploy-backstage.yml`)**
- **Automatic deployment** on push to main/develop branches
- **Manual deployment** with custom parameters (environment, business unit, country)
- **Multi-environment support** (dev, staging, prod)
- **Multi-BU support** (platform-core, food-delivery, grocery-delivery, cleaning-services, repair-services)
- **Multi-country support** (UK, India, global)
- **Infrastructure validation** (YAML linting, configuration validation)
- **Prerequisites checking** (Crossplane, ArgoCD, kubectl)
- **Secrets management** (automatic secret creation)
- **Health verification** (pods, services, ingress)
- **Deployment notifications** (success/failure notifications)

#### **2. Manage Secrets (`manage-secrets.yml`)**
- **Create secrets** for new deployments
- **Update secrets** with new values
- **Rotate secrets** for security (passwords, tokens)
- **Validate secrets** for completeness
- **Multi-environment** secret management per environment/BU/country
- **Secure storage** in Kubernetes secrets

#### **3. Test Backstage (`test-backstage.yml`)**
- **Health checks** - Pod, service, and ingress health
- **Smoke tests** - Basic functionality testing
- **Integration tests** - API and service integration
- **Load tests** - Performance testing with k6
- **Security tests** - Security configuration validation
- **Multi-environment** testing for any environment/BU/country combination

#### **GitHub Actions Benefits**
- ✅ **No local dependencies** - Everything runs in GitHub's cloud
- ✅ **Consistent environment** - Same execution environment for all deployments
- ✅ **GitOps integration** - Automatic deployment on code changes
- ✅ **Security** - Secrets managed in GitHub, no local credential storage
- ✅ **Audit trail** - Complete deployment history and logs
- ✅ **Scalability** - Multiple concurrent deployments
- ✅ **Monitoring** - Built-in logging and status tracking

### **🔄 GitOps Infrastructure**

#### Multi-Cloud Database Composition
- **File**: `crossplane/compositions/multi-cloud-database-composition.yaml`
- **Purpose**: Creates database infrastructure across AWS, GCP, and Azure
- **Resources**:
  - **AWS**: RDS PostgreSQL, ElastiCache Redis
  - **GCP**: Cloud SQL PostgreSQL, Memorystore Redis
  - **Azure**: Database for PostgreSQL, Cache for Redis
  - Connection secrets for applications

#### Database Claims
- **AWS**: `crossplane/claims/aws-database-claim.yaml`
- **GCP**: `crossplane/claims/gcp-database-claim.yaml`
- **Azure**: `crossplane/claims/azure-database-claim.yaml`
- **Purpose**: Example claims for creating database infrastructure in each cloud
- **Usage**: Apply the appropriate claim to provision database resources

### ArgoCD Applications

#### Project Configuration
- **Name**: `delivery-platform`
- **Source**: This repository
- **Destinations**: Local Minikube cluster

#### Applications
1. **delivery-platform-dev**: Development environment
2. **delivery-platform-crossplane**: Crossplane compositions
3. **delivery-platform-app-of-apps**: Application of applications pattern

## 🛠️ Manual Setup (Alternative)

If you prefer to set up manually:

### 1. Install Crossplane
```bash
# Create namespace
kubectl create namespace crossplane-system

# Add Helm repository
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Install Crossplane v2.0.2
helm install crossplane crossplane-stable/crossplane --version 2.0.2 -n crossplane-system

# Install Crossplane CLI
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/release-2.0/install.sh | sh
sudo mv crossplane /usr/local/bin
```

### 2. Install Azure Provider
```bash
# Install Azure provider
crossplane xpkg install provider xpkg.upbound.io/crossplane-contrib/provider-azure:v0.32.0

# Verify installation
kubectl get providers
```

### 3. Install ArgoCD
```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### 4. Apply Configurations
```bash
# Apply Crossplane compositions
kubectl apply -f infrastructure/crossplane/compositions/

# Apply ArgoCD applications
kubectl apply -f infrastructure/argocd/applications/
```

## 🔍 Verification

### Check Crossplane Status
```bash
# Check Crossplane pods
kubectl get pods -n crossplane-system

# Check providers
kubectl get providers

# Check compositions
kubectl get compositions
```

### Check ArgoCD Status
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check applications
kubectl get applications -n argocd

# Check projects
kubectl get appprojects -n argocd
```

## 🌐 Multi-Cloud Configuration

The platform now supports **AWS**, **GCP**, and **Azure** providers. See the comprehensive [Multi-Cloud Setup Guide](../docs/Multi-Cloud-Setup-Guide.md) for detailed instructions.

### Quick Multi-Cloud Setup

```bash
# Run the multi-cloud setup script
./scripts/setup-multi-cloud-providers.sh

# Configure cloud credentials (see detailed guide)
# AWS, GCP, and Azure credentials setup
```

### Supported Cloud Resources

| Cloud Provider | Database | Cache | Compute | Storage |
|----------------|----------|-------|---------|---------|
| **AWS** | RDS PostgreSQL | ElastiCache Redis | EKS | S3 |
| **GCP** | Cloud SQL PostgreSQL | Memorystore Redis | GKE | Cloud Storage |
| **Azure** | Database for PostgreSQL | Cache for Redis | AKS | Blob Storage |

## 🔐 Azure Configuration

To use Azure resources, you need to configure Azure credentials:

### 1. Create Azure Service Principal
```bash
# Create service principal
az ad sp create-for-rbac --name "crossplane-delivery-platform" --role Contributor --scopes /subscriptions/{subscription-id}

# Note the output values:
# - appId (client_id)
# - password (client_secret)
# - tenant (tenant_id)
```

### 2. Create Kubernetes Secret
```bash
# Create secret with Azure credentials
kubectl create secret generic azure-credentials \
  --from-literal=client_id="<appId>" \
  --from-literal=client_secret="<password>" \
  --from-literal=tenant_id="<tenant>" \
  --from-literal=subscription_id="<subscription-id>" \
  -n crossplane-system
```

### 3. Configure Provider Config
```yaml
apiVersion: azure.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: azure-config
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-credentials
      key: credentials
```

## 🚀 Usage Examples

### Create Database Infrastructure
```bash
# Apply database claim
kubectl apply -f infrastructure/crossplane/claims/database-claim.yaml

# Check claim status
kubectl get database delivery-platform-dev-db

# Check managed resources
kubectl get managed
```

### Deploy Applications via ArgoCD
```bash
# Check application sync status
kubectl get applications -n argocd

# Force sync application
kubectl patch application delivery-platform-dev -n argocd --type merge -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
```

## 🔧 Troubleshooting

### Common Issues

#### Crossplane Provider Not Ready
```bash
# Check provider status
kubectl describe provider crossplane-contrib-provider-azure

# Check provider pods
kubectl get pods -n crossplane-system
```

#### ArgoCD Application Not Syncing
```bash
# Check application status
kubectl describe application delivery-platform-dev -n argocd

# Check repository connectivity
kubectl get applications -n argocd -o yaml
```

#### Azure Authentication Issues
```bash
# Verify Azure credentials secret
kubectl get secret azure-credentials -n crossplane-system -o yaml

# Check provider config
kubectl get providerconfig azure-config -o yaml
```

### Logs
```bash
# Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane

# ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller
```

## 📚 Additional Resources

- [Crossplane Documentation](https://docs.crossplane.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Azure Provider Documentation](https://doc.crds.dev/github.com/crossplane-contrib/provider-azure)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 🤝 Contributing

When adding new infrastructure components:

1. **Crossplane Compositions**: Add to `crossplane/compositions/`
2. **ArgoCD Applications**: Add to `argocd/applications/`
3. **Claims**: Add to `crossplane/claims/`
4. **Documentation**: Update this README

## 🎯 **DevOps/CI-CD Infrastructure Summary**

This infrastructure provides a **complete production-ready DevOps/CI-CD platform** with:

### **🔄 GitOps Infrastructure**
- **ArgoCD**: GitOps application deployment and management
- **Crossplane**: Infrastructure as Kubernetes resources across all clouds
- **Unified API**: Single Kubernetes API for AWS, GCP, and Azure resources
- **Automated Reconciliation**: Continuous drift detection and correction

### **🌐 Networking Infrastructure**
- **NGINX Ingress Controller**: Load balancing and SSL termination
- **Route53 Integration**: DNS management with AWS Route53
- **SSL/TLS**: Automated certificate management with Let's Encrypt
- **Public IP Management**: Cost-optimized single public IP setup

### **🔒 Security Infrastructure**
- **cert-manager**: Automated SSL certificate provisioning and renewal
- **Let's Encrypt Integration**: Free SSL certificates with automatic renewal
- **Certificate Monitoring**: Health checks and renewal status tracking
- **Security Policies**: Pod security standards and network policies

### **⚙️ Node Management Infrastructure**
- **Karpenter**: Intelligent node auto-provisioning with cost optimization
- **Node Auto-Provisioning (NAP)**: Azure AKS native node provisioning
- **System Pod Affinity**: Pod scheduling and isolation strategies
- **Cost Optimization**: Spot instances and automatic scaling

### **🧪 Testing Infrastructure**
- **Test Pods**: Pod scheduling and affinity testing
- **Test Workloads**: Karpenter scaling and node provisioning tests
- **Validation Scripts**: Infrastructure health checks and validation
- **Performance Testing**: Load testing and scaling validation

### **📊 Monitoring Infrastructure**
- **Azure Monitor**: Cloud-native monitoring and alerting
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Log Analytics**: Centralized logging and analysis

## 🎉 **Key Benefits**

- **🔄 Complete GitOps**: Infrastructure and applications managed through Git
- **💰 Cost Optimization**: Up to 90% cost reduction with intelligent provisioning
- **🔒 Enterprise Security**: Automated SSL and security policies
- **⚡ High Availability**: Multi-zone deployment with auto-failover
- **🧪 Comprehensive Testing**: Infrastructure validation and testing
- **📊 Full Monitoring**: Complete observability and monitoring

**This represents a production-ready, enterprise-grade DevOps infrastructure that provides maximum efficiency, security, and cost optimization while maintaining high availability and reliability.** 🎉

## 📝 Notes

- This setup is optimized for **production deployment** using Azure AKS + AWS Route53
- All configurations are designed for **enterprise-grade** infrastructure
- **Live services** are accessible via public DNS with automated SSL
- **GitOps workflow** ensures all changes are tracked in Git
- **Cost optimization** provides up to 90% savings with Spot instances
