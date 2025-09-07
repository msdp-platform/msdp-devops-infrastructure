# 🏗️ MSDP DevOps Infrastructure

## 📋 **Repository Overview**

This repository contains the complete **DevOps infrastructure** for the Multi-Service Delivery Platform (MSDP), providing a scalable foundation for multi-business unit, multi-country deployment using **Crossplane + ArgoCD + GitHub Actions**.

**Repository Name**: `msdp-devops-infrastructure`  
**Purpose**: Multi-BU infrastructure, CI/CD, and deployment automation  
**Team**: DevOps/Platform Engineering  
**Source**: Transformed from existing multi-service-delivery-platform repository

---

## 🎯 **Infrastructure Overview**

The infrastructure provides a **complete DevOps/CI-CD platform** with:

- **🔄 GitOps**: Complete infrastructure and application deployment automation
- **☁️ Multi-Cloud**: Azure AKS + AWS Route53 hybrid architecture
- **💰 Cost Optimization**: Up to 90% cost reduction with Spot instances
- **🔒 Enterprise Security**: Automated SSL and security policies
- **⚡ High Availability**: Multi-zone deployment with auto-failover
- **🧪 Comprehensive Testing**: Infrastructure validation and testing
- **📊 Full Monitoring**: Complete observability and monitoring

---

## 🏗️ **Repository Structure**

```
msdp-devops-infrastructure/
├── infrastructure/                    # 🏗️ Infrastructure as Code
│   ├── crossplane/                   # Crossplane compositions and claims
│   │   ├── compositions/             # Reusable infrastructure compositions
│   │   ├── claims/                   # Resource claims
│   │   └── xrds/                     # Composite Resource Definitions
│   ├── argocd/                       # ArgoCD GitOps configurations
│   │   └── applications/             # ArgoCD applications
│   ├── kubernetes/                   # Kubernetes manifests
│   │   └── backstage/                # Backstage deployment
│   ├── devops-ci-cd/                 # DevOps/CI-CD infrastructure
│   │   ├── gitops/                   # GitOps configurations
│   │   ├── networking/               # Networking infrastructure
│   │   ├── security/                 # Security infrastructure
│   │   ├── node-management/          # Node management
│   │   ├── testing/                  # Testing infrastructure
│   │   └── monitoring/               # Monitoring infrastructure
│   └── README.md                     # Infrastructure documentation
├── ci-cd/                            # 🚀 CI/CD Pipelines
│   └── workflows/                    # GitHub Actions workflows
│       ├── deploy-backstage.yml      # Backstage deployment
│       ├── manage-secrets.yml        # Secrets management
│       ├── test-backstage.yml        # Testing workflows
│       └── README.md                 # CI/CD documentation
├── scripts/                          # 🔧 Automation Scripts
│   ├── platform-management/          # Platform management
│   ├── cost-optimization/            # Cost optimization
│   ├── infrastructure-setup/         # Infrastructure setup
│   ├── monitoring/                   # Monitoring scripts
│   ├── testing/                      # Testing scripts
│   └── utilities/                    # Utility scripts
├── configs/                          # ⚙️ Configuration Files
│   ├── environments/                 # Environment configurations
│   ├── countries/                    # Country-specific configs
│   └── business-units/               # BU-specific configs
├── docs/                             # 📚 Documentation
│   ├── architecture/                 # Architecture documentation
│   ├── infrastructure/               # Infrastructure guides
│   ├── setup-guides/                 # Setup guides
│   ├── operations/                   # Operations documentation
│   ├── cost-optimization/            # Cost optimization docs
│   ├── testing/                      # Testing documentation
│   └── diagrams/                     # Architecture diagrams
└── README.md                         # This documentation
```

---

## 🚀 **Quick Start**

### **Prerequisites**

1. **Azure CLI** configured with AKS access
2. **kubectl** configured to access your cluster
3. **Crossplane** installed and configured
4. **ArgoCD** installed and configured
5. **GitHub Actions** secrets configured

### **Access Your Live Services**

- **ArgoCD**: `https://argocd.dev.aztech-msdp.com` (admin/admin123)
- **Sample App**: `https://app.dev.aztech-msdp.com`
- **SSL Certificates**: Automatically managed and renewed
- **DNS**: Managed via AWS Route53

### **Platform Management**

```bash
# Start platform (scale up nodes)
./scripts/platform-management/platform start

# Stop platform (scale down to 0 nodes - saves costs)
./scripts/platform-management/platform stop

# Check platform status
./scripts/platform-management/platform status

# Optimize costs
./scripts/platform-management/platform optimize
```

---

## 🔧 **Infrastructure Components**

### **🔄 GitOps Infrastructure**

#### **Crossplane**
- **Multi-cloud providers**: AWS, Azure, GCP
- **Infrastructure compositions**: Database, storage, networking
- **Resource claims**: Environment-specific resource provisioning
- **Provider management**: Automated provider installation and configuration

#### **ArgoCD**
- **Application deployment**: GitOps-driven application deployment
- **Multi-repo support**: Support for multiple repository structures
- **Health monitoring**: Application health and sync status
- **Rollback capabilities**: Automated rollback on failures

### **🌐 Networking Infrastructure**

#### **NGINX Ingress Controller**
- **Load balancing**: Intelligent traffic routing
- **SSL termination**: Automated SSL certificate management
- **Rate limiting**: DDoS protection and rate limiting
- **Path-based routing**: Service-specific routing rules

#### **Route53 Integration**
- **DNS management**: Centralized DNS management
- **Health checks**: Automated health monitoring
- **Failover**: Multi-region failover support
- **Cost optimization**: Single public IP setup

### **🔒 Security Infrastructure**

#### **cert-manager**
- **SSL certificates**: Automated Let's Encrypt certificates
- **Certificate renewal**: Automatic certificate renewal
- **Multi-domain support**: Support for multiple domains
- **Certificate monitoring**: Health checks and status monitoring

#### **Security Policies**
- **Pod security**: Pod security standards enforcement
- **Network policies**: Network segmentation and isolation
- **RBAC**: Role-based access control
- **Compliance**: GDPR, PCI DSS compliance support

### **⚙️ Node Management Infrastructure**

#### **Karpenter**
- **Node auto-provisioning**: Intelligent node provisioning
- **Cost optimization**: Spot instance utilization
- **Multi-SKU support**: Broad SKU selection for availability
- **Auto-scaling**: Dynamic scaling based on demand

#### **System Pod Affinity**
- **Pod scheduling**: System pod isolation
- **Resource optimization**: Efficient resource utilization
- **High availability**: Multi-zone deployment
- **Cost efficiency**: System node pool optimization

---

## 🚀 **GitHub Actions CI/CD**

### **Available Workflows**

#### **1. Deploy Backstage (`deploy-backstage.yml`)**
- **Automatic deployment** on push to main/develop branches
- **Manual deployment** with custom parameters
- **Multi-environment support** (dev, staging, prod)
- **Multi-BU support** (platform-core, food-delivery, etc.)
- **Multi-country support** (UK, India, global)
- **Infrastructure validation** and health checks
- **No hardcoded values** - all configuration via environment variables

#### **2. Manage Secrets (`manage-secrets.yml`)**
- **Create secrets** for new deployments
- **Update secrets** with new values
- **Rotate secrets** for security
- **Validate secrets** for completeness

#### **3. Test Backstage (`test-backstage.yml`)**
- **Health checks** - Pod, service, and ingress health
- **Smoke tests** - Basic functionality testing
- **Integration tests** - API and service integration
- **Load tests** - Performance testing with k6
- **Security tests** - Security configuration validation

### **Required GitHub Secrets**

```bash
# Azure Configuration
AZURE_CLIENT_ID=your-azure-client-id
AZURE_CLIENT_SECRET=your-azure-client-secret
AZURE_TENANT_ID=your-azure-tenant-id
AZURE_SUBSCRIPTION_ID=your-azure-subscription-id
AZURE_RESOURCE_GROUP=your-resource-group
AKS_CLUSTER_NAME=your-aks-cluster-name

# Backstage Configuration
SESSION_SECRET=your-session-secret
GITHUB_INTEGRATION=your-github-integration-config
AZURE_INTEGRATION=your-azure-integration-config
ARGOCD_INTEGRATION=your-argocd-integration-config
ARGOCD_PASSWORD=your-argocd-password

# Payment Providers
STRIPE_TOKEN=your-stripe-token
RAZORPAY_TOKEN=your-razorpay-token
PAYTM_TOKEN=your-paytm-token

# Government APIs
HMRC_TOKEN=your-hmrc-token
FSSAI_TOKEN=your-fssai-token
GST_TOKEN=your-gst-token
```

---

## 📊 **Monitoring and Observability**

### **Infrastructure Monitoring**
- **Azure Monitor**: Cloud-native monitoring and alerting
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Log Analytics**: Centralized logging and analysis

### **Application Monitoring**
- **Application Insights**: Application performance monitoring
- **Distributed tracing**: Request tracing across services
- **Error tracking**: Error monitoring and alerting
- **Performance monitoring**: Response time and throughput

### **Cost Monitoring**
- **Cost optimization**: Automated cost optimization
- **Resource utilization**: Resource usage monitoring
- **Spot instance monitoring**: Spot instance availability and cost
- **Budget alerts**: Cost threshold monitoring

---

## 🔧 **Development Workflow**

### **Infrastructure Changes**
1. **Make changes** to Crossplane compositions or claims
2. **Test locally** using Crossplane CLI
3. **Commit changes** to Git repository
4. **GitHub Actions** automatically validates and deploys
5. **ArgoCD** synchronizes changes to cluster
6. **Monitor** deployment status and health

### **Application Deployment**
1. **Create ArgoCD application** for new service
2. **Configure Helm values** for environment-specific settings
3. **Deploy via GitHub Actions** or ArgoCD UI
4. **Monitor** application health and performance
5. **Scale** based on demand and metrics

---

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **Crossplane Provider Issues**
```bash
# Check provider status
kubectl get providers

# Check provider logs
kubectl logs -n crossplane-system deployment/crossplane

# Verify provider credentials
kubectl get secret aws-credentials -n crossplane-system
```

#### **ArgoCD Sync Issues**
```bash
# Check application status
kubectl get applications -n argocd

# Check application logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force sync application
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
```

#### **Infrastructure Issues**
```bash
# Check managed resources
kubectl get managed

# Check resource claims
kubectl get claims

# Check resource status
kubectl describe <resource-type> <resource-name>
```

### **Logs and Debugging**
```bash
# Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane

# ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller

# Application logs
kubectl logs -n <namespace> deployment/<app-name>
```

---

## 📚 **Additional Resources**

- [Crossplane Documentation](https://docs.crossplane.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## 🤝 **Contributing**

When adding new infrastructure components:

1. **Crossplane Compositions**: Add to `infrastructure/crossplane/compositions/`
2. **ArgoCD Applications**: Add to `infrastructure/argocd/applications/`
3. **Kubernetes Manifests**: Add to `infrastructure/kubernetes/`
4. **CI/CD Workflows**: Add to `ci-cd/workflows/`
5. **Scripts**: Add to `scripts/` with appropriate categorization
6. **Documentation**: Update relevant documentation

---

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Repository Version**: 1.0.0  
**Last Updated**: $(date)  
**Target Launch**: ASAP (2025)  
**Infrastructure Status**: Production Ready
