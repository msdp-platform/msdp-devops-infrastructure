# 🚀 Deployment Guide - AWS EKS Platform

## 📋 **Overview**

This guide provides step-by-step instructions for deploying the AWS EKS platform with all components.

## 🎯 **Prerequisites**

### **Required Tools**
- AWS CLI configured with SSO profile
- Terraform >= 1.0
- kubectl >= 1.28
- Helm >= 3.13
- Git

### **AWS Requirements**
- AWS account with appropriate permissions
- SSO profile: `AWSAdministratorAccess-319422413814`
- Region: us-west-2 (configurable)

## 🚀 **Deployment Steps**

### **Step 1: Setup GitHub OIDC**

```bash
# Configure AWS SSO profile
aws configure sso --profile AWSAdministratorAccess-319422413814

# Run OIDC setup script
export AWS_PROFILE=AWSAdministratorAccess-319422413814
export GITHUB_ORG=msdp-platform
export GITHUB_REPO=msdp-devops-infrastructure
./scripts/setup-github-oidc.sh
```

### **Step 2: Configure GitHub Secrets**

Add these secrets to your GitHub repository:
- `AWS_ROLE_ARN` - From OIDC setup output
- `AWS_REGION` - us-west-2
- `TERRAFORM_BUCKET_NAME` - From OIDC setup output

### **Step 3: Deploy Infrastructure**

```bash
# Deploy via GitHub Actions
git push origin dev

# Or deploy manually
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### **Step 4: Verify Deployment**

```bash
# Check cluster status
kubectl get nodes

# Check Karpenter
kubectl get nodepools

# Check platform components
kubectl get pods -A
```

## 🔧 **Component Deployment**

### **EKS Cluster**
- Managed Kubernetes service
- Multi-AZ deployment
- System and user node groups

### **Karpenter**
- Intelligent autoscaling
- Cost-optimized instance selection
- Spot instance management

### **Platform Components**
- ArgoCD: GitOps deployment
- Prometheus: Metrics collection
- Grafana: Dashboards
- Backstage: Developer portal

## 📊 **Post-Deployment**

### **Access Services**
- **EKS Cluster**: `kubectl get nodes`
- **ArgoCD**: Port-forward to access UI
- **Grafana**: Access via ingress or port-forward
- **Backstage**: Developer portal access

### **Monitoring**
- Check Prometheus metrics
- Verify Grafana dashboards
- Monitor Karpenter scaling

## 🆘 **Troubleshooting**

### **Common Issues**
1. **OIDC Setup**: Verify GitHub secrets
2. **Terraform**: Check AWS credentials
3. **Karpenter**: Verify instance types
4. **Components**: Check pod status

### **Debug Commands**
```bash
# Check cluster status
kubectl cluster-info

# Check Karpenter logs
kubectl logs -n karpenter deployment/karpenter

# Check component status
kubectl get pods -A
```

---

**Last Updated**: December 2024  
**Version**: 3.0.0  
**Maintainer**: DevOps Team
