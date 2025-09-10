# 🚀 Platform Components Deployment Guide

## 🎯 **Overview**

This guide covers the deployment of platform components using GitHub Actions pipelines, following the MSDP platform's infrastructure as code principles and multi-environment strategy.

## 🏗️ **Platform Components**

### **Networking Platform**
- **NGINX Ingress Controller**: HTTP/HTTPS ingress to services
- **Cert-Manager**: Automatic SSL/TLS certificate management
- **External DNS**: Automatic DNS record management in Route53

### **Monitoring Platform**
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alerting and notifications

## 🚀 **Deployment Methods**

### **1. GitHub Actions Pipeline (Recommended)**

#### **Automatic Deployment**
- **Trigger**: Push to `dev`, `test`, or `prod` branches
- **Path**: Changes to `infrastructure/platforms/**`
- **Environment**: Automatically detected from branch name

#### **Manual Deployment**
- **Trigger**: GitHub Actions workflow dispatch
- **Options**: Choose environment, component, and dry-run mode
- **Flexibility**: Deploy specific components or all components

### **2. Manual Deployment (Alternative)**

#### **Prerequisites**
```bash
# Install required tools
kubectl version --client
helm version
kustomize version
```

#### **Deploy Platform Components**
```bash
# Deploy networking platform
kubectl apply -k infrastructure/platforms/networking/nginx-ingress/
kubectl apply -k infrastructure/platforms/networking/cert-manager/
kubectl apply -k infrastructure/platforms/networking/external-dns/

# Deploy monitoring platform
kubectl apply -k infrastructure/platforms/monitoring/
```

## 🔧 **GitHub Actions Workflow**

### **Workflow File**
- **Location**: `ci-cd/workflows/deploy-platform-components.yml`
- **Triggers**: Push, PR, and manual dispatch
- **Environments**: dev, test, prod with branch-based promotion

### **Workflow Steps**

#### **1. Environment Detection**
```yaml
- Detects environment from branch name or manual input
- Sets component selection (all, networking, monitoring)
- Configures dry-run mode
```

#### **2. Validation**
```yaml
- Validates YAML files with yamllint
- Validates Kustomize configurations
- Validates Helm values
```

#### **3. Deployment**
```yaml
- Deploys NGINX Ingress Controller
- Deploys Cert-Manager
- Deploys External DNS
- Waits for components to be ready
- Verifies deployment status
```

#### **4. Notification**
```yaml
- Reports deployment status
- Provides component status
- Handles failure scenarios
```

## 🌍 **Environment Configuration**

### **Environment Variables**
```yaml
AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
AWS_REGION: us-east-1
```

### **Environment-Specific Settings**
- **Dev**: `msdp-dev-aks` cluster
- **Test**: `msdp-test-aks` cluster
- **Prod**: `msdp-prod-aks` cluster

## 📋 **Deployment Process**

### **1. Automatic Deployment**
```bash
# Push to dev branch
git push origin dev

# GitHub Actions automatically:
# 1. Detects environment (dev)
# 2. Validates configurations
# 3. Deploys platform components
# 4. Verifies deployment
```

### **2. Manual Deployment**
```bash
# Go to GitHub Actions
# Select "Deploy Platform Components"
# Choose:
#   - Environment: dev/test/prod
#   - Component: all/networking/monitoring
#   - Dry Run: true/false
```

### **3. Component-Specific Deployment**
```bash
# Deploy only networking components
# Manual dispatch with component=networking

# Deploy only monitoring components
# Manual dispatch with component=monitoring
```

## 🔍 **Verification**

### **Check Deployment Status**
```bash
# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check Cert-Manager
kubectl get pods -n cert-manager
kubectl get clusterissuer

# Check External DNS
kubectl get pods -n external-dns
kubectl get svc -n external-dns
```

### **Verify Platform Components**
```bash
# Check all platform components
kubectl get pods -A | grep -E "(ingress-nginx|cert-manager|external-dns)"

# Check ingress classes
kubectl get ingressclass

# Check cluster issuers
kubectl get clusterissuer
```

## 🛡️ **Security Considerations**

### **RBAC Permissions**
- **GitHub Actions**: Requires AKS cluster access
- **Service Accounts**: Minimal required permissions
- **Secrets**: Stored in GitHub Secrets

### **Network Security**
- **Ingress Controller**: Configured with security headers
- **Cert-Manager**: Uses Let's Encrypt for certificates
- **External DNS**: Manages DNS records securely

## 🔧 **Troubleshooting**

### **Common Issues**

#### **1. Deployment Failures**
```bash
# Check workflow logs
# Verify environment variables
# Check AKS cluster connectivity
```

#### **2. Component Not Ready**
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

#### **3. DNS Issues**
```bash
# Check External DNS logs
kubectl logs -n external-dns deployment/external-dns

# Verify Route53 permissions
aws route53 list-hosted-zones
```

### **Debug Commands**
```bash
# Check all resources
kubectl get all -A

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check ingress status
kubectl describe ingress <ingress-name>
```

## 📊 **Monitoring**

### **Platform Component Metrics**
- **NGINX Ingress**: Available at `/metrics` endpoint
- **Cert-Manager**: Available at `/metrics` endpoint
- **External DNS**: Available at `/metrics` endpoint

### **Health Checks**
- **Liveness Probes**: Monitor component health
- **Readiness Probes**: Monitor component readiness
- **Startup Probes**: Monitor component startup

## 🎯 **Best Practices**

### **1. Deployment Strategy**
- **Use GitHub Actions** for consistent deployments
- **Test in dev** before promoting to test/prod
- **Use dry-run mode** for validation

### **2. Environment Management**
- **Branch-based promotion** (dev → test → prod)
- **Environment-specific configurations**
- **Proper secret management**

### **3. Monitoring**
- **Monitor deployment status**
- **Set up alerts for failures**
- **Regular health checks**

## 🚀 **Next Steps**

### **1. Application Deployment**
After platform components are deployed:
```bash
# Deploy applications
kubectl apply -k infrastructure/applications/argocd/
kubectl apply -k infrastructure/applications/backstage/
kubectl apply -k infrastructure/applications/crossplane/
```

### **2. Monitoring Setup**
```bash
# Deploy monitoring components
kubectl apply -k infrastructure/platforms/monitoring/
```

### **3. Application Integration**
```bash
# Deploy application-specific ingress and certificates
kubectl apply -k infrastructure/applications/argocd/ingress/
kubectl apply -k infrastructure/applications/argocd/certificates/
```

---

**Platform components provide the foundation for all MSDP applications. Use GitHub Actions for consistent, reliable deployments across all environments.** 🚀
