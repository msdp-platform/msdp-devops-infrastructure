# 📚 Documentation - MSDP DevOps Infrastructure

## 📋 **Overview**

This directory contains comprehensive documentation for the MSDP DevOps Infrastructure platform, built on AWS EKS with cost optimization and comprehensive DevOps tooling.

## 📁 **Documentation Structure**

### **Architecture**
- [Architecture Index](architecture/ARCHITECTURE-INDEX.md) - Complete architecture documentation index
- [Technical Architecture](architecture/Technical-Architecture.md) - Technical architecture overview

### **Deployment**
- [Deployment Guide](deployment/Deployment-Guide.md) - Step-by-step deployment instructions

### **Infrastructure**
- [AKS Setup Guide](infrastructure/AKS-Setup-Guide.md) - AKS cluster installation and configuration
- [Route53-Azure Hybrid Setup](infrastructure/Route53-Azure-Hybrid-Setup-Complete.md) - Hybrid DNS configuration
- [External DNS Setup](infrastructure/EXTERNAL_DNS_SETUP.md) - ExternalDNS configuration and policies
- [Node Auto-Provisioning](infrastructure/Node-Auto-Provisioning-Setup.md) - Karpenter/Cluster Autoscaler configuration
- [Pod Allocation Analysis](infrastructure/Node-Pool-Pod-Allocation-Analysis.md) - Scheduling and resource allocation
- [Single Public IP Setup](infrastructure/Single-Public-IP-Setup.md) - Egress IP configuration
- [System Node Pool Scale Down (Analysis)](infrastructure/System-Node-Pool-Scale-Down-Analysis.md)
- [System Node Pool Scale Down (Status)](infrastructure/System-Node-Pool-Scale-Down-Status.md)
- [Pod Affinity Enforcement Summary](infrastructure/System-Pod-Affinity-Enforcement-Summary.md)
- [DNS Delegation Fix Complete](infrastructure/DNS-Delegation-Fix-Complete.md)

### **Operations**
- [Operations Guide](operations/Operations-Guide.md) - Operational procedures and maintenance

### **Setup Guides**
- [Comprehensive EKS Platform Setup](setup-guides/Comprehensive-EKS-Platform-Setup.md) - Complete platform setup
- [GitHub OIDC Setup Guide](setup-guides/GitHub-OIDC-Setup-Guide.md) - OIDC authentication setup
- [GitHub Organization Setup](setup-guides/GitHub-Organization-Setup.md) - GitHub organization configuration

### **Testing**
- [Testing Guide](testing/Testing-Guide.md) - Testing procedures and validation

### **Diagrams**
- Architecture diagrams and visual representations

## 🎯 **Quick Start**

### **1. Setup OIDC Authentication**
```bash
./scripts/setup-github-oidc.sh
```

### **2. Deploy Platform**
```bash
cd infrastructure/terraform/environments/dev
terraform init && terraform apply
```

### **3. Access Services**
- **EKS Cluster**: `kubectl get nodes`
- **ArgoCD**: Port-forward to access UI
- **Grafana**: Access via ingress or port-forward

## 🏗️ **Platform Features**

- **Cost Optimization**: Mixed ARM/x86 instances with spot optimization
- **High Availability**: Multi-AZ deployment with auto-scaling
- **Security**: OIDC authentication, IAM roles, network security
- **Observability**: Prometheus, Grafana, CloudWatch integration
- **GitOps**: ArgoCD deployment automation
- **Infrastructure as Code**: Terraform for all infrastructure

## 📊 **Architecture Overview**

```
GitHub Actions → OIDC → AWS IAM → EKS Cluster
                    ↓
            Karpenter (Auto-scaling)
                    ↓
        Mixed Architecture (ARM/x86)
                    ↓
    Platform Components (ArgoCD, Prometheus, Grafana)
```

## 🔧 **Key Components**

### **Core Infrastructure**
- **EKS Cluster**: Managed Kubernetes service
- **Karpenter**: Intelligent autoscaling with cost optimization
- **VPC**: Secure network architecture

### **Platform Components**
- **ArgoCD**: GitOps deployment automation
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboards and visualization
- **Backstage**: Developer portal
- **Crossplane**: Infrastructure provisioning

### **Security & Networking**
- **GitHub OIDC**: Secure authentication
- **AWS Load Balancer Controller**: Ingress management
- **External DNS**: Automatic DNS management
- **Cert-Manager**: TLS certificate automation

## 💰 **Cost Optimization**

- **ARM Instances**: Up to 40% better price/performance
- **Spot Instances**: Up to 90% cost savings
- **Mixed Architecture**: Automatic cost-based instance selection
- **Auto-scaling**: Right-sized instances based on demand

## 🚀 **Getting Started**

1. **Read the Architecture**: Start with [Technical Architecture](architecture/Technical-Architecture.md)
2. **Setup OIDC**: Follow [GitHub OIDC Setup Guide](setup-guides/GitHub-OIDC-Setup-Guide.md)
3. **Deploy Platform**: Use [Comprehensive EKS Platform Setup](setup-guides/Comprehensive-EKS-Platform-Setup.md)
4. **Operate Platform**: Reference [Operations Guide](operations/Operations-Guide.md)

## 📚 **Additional Resources**

- **AWS Documentation**: [EKS User Guide](https://docs.aws.amazon.com/eks/)
- **Karpenter Documentation**: [Karpenter Docs](https://karpenter.sh/)
- **ArgoCD Documentation**: [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- **Prometheus Documentation**: [Prometheus Docs](https://prometheus.io/docs/)

## 🤝 **Contributing**

When contributing to the documentation:

1. **Update relevant sections** when making changes
2. **Add new procedures** to appropriate guides
3. **Update architecture docs** for significant changes
4. **Test procedures** before documenting

## 📄 **License**

This documentation is part of the MSDP DevOps Infrastructure project and follows the same license terms.

---

**Last Updated**: December 2024  
**Version**: 3.0.0  
**Maintainer**: DevOps Team