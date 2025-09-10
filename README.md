# 🏗️ MSDP DevOps Infrastructure - AWS EKS Platform

## 📋 **Repository Overview**

This repository contains the **comprehensive AWS EKS platform** for the Multi-Service Delivery Platform (MSDP), featuring a complete Kubernetes infrastructure with GitOps, monitoring, and cost optimization.

**Repository Name**: `msdp-devops-infrastructure`  
**Purpose**: AWS EKS platform with Karpenter, ArgoCD, and comprehensive DevOps tooling  
**Team**: DevOps/Platform Engineering  
**Status**: Production Ready - AWS EKS Platform

---

## 🎯 **AWS EKS Platform Features**

A **production-ready AWS EKS platform** with comprehensive DevOps tooling:

- **☁️ AWS EKS Cluster**: Managed Kubernetes with ARM-based Graviton instances
- **🚀 Karpenter**: Intelligent autoscaling with cost-optimized mixed architecture spot instances
- **🔄 GitOps**: ArgoCD for automated deployments
- **💰 Cost Optimization**: Mixed ARM/x86 spot instances with automatic cost-based selection, up to 90% cost savings
- **🔒 Enterprise Security**: OIDC authentication, IAM roles, secrets management
- **⚡ High Availability**: Multi-AZ deployment with auto-scaling
- **📊 Full Observability**: Prometheus, Grafana, and CloudWatch integration
- **🌐 Networking**: ALB controller, External DNS, NGINX ingress

---

## 🏗️ **Repository Structure**

```
msdp-devops-infrastructure/
├── infrastructure/                   # 🏗️ Infrastructure as Code
│   ├── terraform/                    # Terraform configurations
│   │   ├── modules/                  # Reusable Terraform modules
│   │   │   ├── eks-blueprint/        # EKS cluster with all components
│   │   │   └── github-oidc/          # GitHub OIDC authentication
│   │   └── environments/             # Environment-specific configs
│   │       ├── dev/                  # Development environment
│   │       └── oidc-setup/           # OIDC setup environment
│   └── applications/                 # Kubernetes applications
├── scripts/                          # 🔧 Automation scripts
│   └── setup-github-oidc.sh         # GitHub OIDC setup script
├── .github/                          # 🚀 GitHub Actions workflows
│   └── workflows/
│       └── deploy-eks.yml           # EKS deployment pipeline
├── docs/                             # 📚 Documentation
│   ├── architecture/                 # Architecture documentation
│   └── setup-guides/                 # Setup and deployment guides
└── README.md                         # This documentation
```

---

## 🚀 **Quick Start Guide**

### **1. Setup GitHub OIDC Authentication**
```bash
# Configure AWS SSO profile
aws configure sso --profile AWSAdministratorAccess-319422413814

# Run OIDC setup script
export AWS_PROFILE=AWSAdministratorAccess-319422413814
export GITHUB_ORG=your-github-org
export GITHUB_REPO=msdp-devops-infrastructure
./scripts/setup-github-oidc.sh
```

### **2. Configure GitHub Secrets**
Add these secrets to your GitHub repository:
- `AWS_ROLE_ARN` - From OIDC setup output
- `AWS_REGION` - us-west-2
- `TERRAFORM_BUCKET_NAME` - From OIDC setup output

### **3. Deploy EKS Platform**
```bash
# Deploy via GitHub Actions
git push origin dev

# Or deploy manually
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### **4. Access Your Platform**
- **EKS Cluster**: `kubectl get nodes`
- **ArgoCD**: Port-forward to access UI
- **Grafana**: Access via ingress or port-forward
- **Backstage**: Developer portal access

---

## 📚 **Documentation**

Comprehensive documentation for the AWS EKS platform:

- **Architecture**: Technical architecture and design decisions
- **Setup Guides**: 
  - [Comprehensive EKS Platform Setup](docs/setup-guides/Comprehensive-EKS-Platform-Setup.md)
  - [GitHub OIDC Setup Guide](docs/setup-guides/GitHub-OIDC-Setup-Guide.md)
  - [GitHub Organization Setup](docs/setup-guides/GitHub-Organization-Setup.md)

---

## 🔧 **Development Workflow**

### **Infrastructure Changes**
1. **Make changes** to Terraform modules in `infrastructure/terraform/modules/`
2. **Test locally** using AWS CLI and local tools
3. **Commit changes** to Git repository
4. **GitHub Actions** automatically validates and deploys via OIDC
5. **ArgoCD** synchronizes changes to cluster
6. **Monitor** deployment status and health

### **Application Deployment**
1. **Create ArgoCD application** for new service
2. **Configure Helm values** for environment-specific settings
3. **Deploy via GitHub Actions** or ArgoCD UI
4. **Monitor** application health and performance
5. **Karpenter** automatically scales based on demand

---

## 🛠️ **Prerequisites**

1. **AWS CLI** configured with SSO profile "AWSAdministratorAccess-319422413814"
2. **kubectl** configured to access EKS cluster
3. **Terraform** >= 1.0 for infrastructure
4. **GitHub repository** with Actions enabled
5. **GitHub OIDC** configured for AWS authentication

---

## 🏗️ **Platform Components**

### **Core EKS Cluster**
- **EKS** - Managed Kubernetes service with mixed architecture support
- **Karpenter** - Intelligent autoscaling with cost-optimized mixed architecture spot instances
- **Fargate Profiles** - Serverless compute for system workloads

### **Security & Governance**
- **AWS Load Balancer Controller** - ALB/NLB ingress management
- **External DNS** - Automatic Route 53 DNS record management
- **Cert-Manager** - TLS certificate automation with ACM
- **Secrets Store CSI Driver** - AWS Secrets Manager integration
- **GitHub OIDC** - Secure authentication without long-term credentials

### **Networking & Traffic Management**
- **Amazon VPC CNI** - High-performance networking
- **NGINX Ingress Controller** - Advanced ingress capabilities

### **Observability**
- **Prometheus** - Metrics collection and alerting
- **Grafana** - Dashboards and visualization
- **CloudWatch** - AWS-native monitoring integration

### **CI/CD & GitOps**
- **ArgoCD** - GitOps deployment automation
- **AWS Controllers for Kubernetes (ACK)** - S3, RDS controllers
- **GitHub Actions** - CI/CD pipeline with OIDC authentication

### **Developer Experience**
- **Crossplane** - Infrastructure provisioning
- **Backstage** - Developer portal and service catalog

---

## 🤝 **Contributing**

When contributing to the AWS EKS platform:

1. **Infrastructure as Code**: Use Terraform modules in `infrastructure/terraform/modules/`
2. **GitOps**: All deployments through ArgoCD
3. **Security First**: Use OIDC authentication and IAM roles
4. **Cost Optimization**: Leverage mixed architecture spot instances with automatic cost-based selection
5. **Documentation**: Update setup guides and architecture docs
6. **Testing**: Use GitHub Actions for automated testing

---

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Repository Version**: 3.0.0 (AWS EKS Platform)  
**Last Updated**: December 2024  
**Platform Status**: Production Ready  
**Infrastructure**: AWS EKS with Karpenter, ArgoCD, and comprehensive DevOps tooling