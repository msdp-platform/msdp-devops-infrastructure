# 🚀 Next Steps: Platform Components Deployment Setup

## 🎯 **Overview**

This guide outlines the next steps to set up and deploy platform components using the GitHub Actions pipeline we've created.

## 📋 **Prerequisites Checklist**

### **1. GitHub Repository Setup**
- [ ] Repository: `msdp-platform/msdp-devops-infrastructure`
- [ ] Branch structure: `dev`, `test`, `prod` branches exist
- [ ] Branch protection rules configured
- [ ] GitHub Actions enabled

### **2. Azure Resources**
- [ ] AKS clusters created for each environment:
  - `msdp-dev-aks` in `msdp-dev-rg`
  - `msdp-test-aks` in `msdp-test-rg`
  - `msdp-prod-aks` in `msdp-prod-rg`
- [ ] Azure Service Principal with AKS access
- [ ] Azure CLI configured locally

### **3. AWS Resources**
- [ ] Route53 hosted zones created:
  - `aztech-msdp.com`
  - `dev.aztech-msdp.com`
  - `test.aztech-msdp.com`
  - `prod.aztech-msdp.com`
- [ ] AWS IAM user with Route53 permissions
- [ ] AWS CLI configured locally

## 🔐 **Step 1: Configure GitHub Secrets**

### **Required Secrets**

Navigate to your GitHub repository → Settings → Secrets and variables → Actions

#### **Azure Credentials**
```yaml
AZURE_CREDENTIALS: |
  {
    "clientId": "your-service-principal-client-id",
    "clientSecret": "your-service-principal-client-secret",
    "subscriptionId": "your-azure-subscription-id",
    "tenantId": "your-azure-tenant-id"
  }
```

#### **AWS Credentials**
```yaml
AWS_ACCESS_KEY_ID: your-aws-access-key-id
AWS_SECRET_ACCESS_KEY: your-aws-secret-access-key
```

### **How to Get Azure Credentials**

```bash
# Create service principal
az ad sp create-for-rbac --name "msdp-platform-github-actions" \
  --role contributor \
  --scopes /subscriptions/your-subscription-id \
  --sdk-auth

# Output will be the JSON to use for AZURE_CREDENTIALS
```

### **How to Get AWS Credentials**

```bash
# Create IAM user with Route53 permissions
aws iam create-user --user-name msdp-platform-github-actions

# Attach Route53 policy
aws iam attach-user-policy \
  --user-name msdp-platform-github-actions \
  --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess

# Create access keys
aws iam create-access-key --user-name msdp-platform-github-actions
```

## 🌿 **Step 2: Verify Branch Structure**

### **Check Current Branches**
```bash
# List all branches
git branch -a

# Ensure you have dev, test, prod branches
git checkout dev
git checkout test
git checkout prod
```

### **Create Missing Branches**
```bash
# If branches don't exist, create them
git checkout -b dev
git push origin dev

git checkout -b test
git push origin test

git checkout -b prod
git push origin prod
```

## 🧪 **Step 3: Test the Deployment Workflow**

### **3.1 Test with Dry Run**

#### **Manual Workflow Dispatch**
1. Go to GitHub Actions in your repository
2. Select "Deploy Platform Components" workflow
3. Click "Run workflow"
4. Configure:
   - Environment: `dev`
   - Component: `all`
   - Dry Run: `true`
5. Click "Run workflow"

#### **Expected Output**
- ✅ Validation steps should pass
- ✅ Dry run deployment should show what would be deployed
- ✅ No actual resources should be created

### **3.2 Test with Real Deployment**

#### **Push to Dev Branch**
```bash
# Make a small change to trigger deployment
echo "# Test deployment" >> infrastructure/platforms/networking/README.md
git add .
git commit -m "🧪 Test platform components deployment"
git push origin dev
```

#### **Expected Results**
- ✅ GitHub Actions workflow should trigger automatically
- ✅ Platform components should deploy to dev AKS cluster
- ✅ All components should be healthy and ready

## 🔍 **Step 4: Validate Platform Components**

### **4.1 Check AKS Cluster Connectivity**
```bash
# Get AKS credentials
az aks get-credentials --resource-group msdp-dev-rg --name msdp-dev-aks

# Verify connectivity
kubectl get nodes
kubectl get namespaces
```

### **4.2 Verify Platform Components**
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

### **4.3 Test DNS Resolution**
```bash
# Test DNS resolution (after External DNS creates records)
nslookup argocd.dev.aztech-msdp.com
nslookup dev.aztech-msdp.com
```

## 🚀 **Step 5: Deploy Applications**

### **5.1 Deploy ArgoCD**
```bash
# Deploy ArgoCD application
kubectl apply -k infrastructure/applications/argocd/

# Deploy ArgoCD ingress and certificates
kubectl apply -k infrastructure/applications/argocd/ingress/
kubectl apply -k infrastructure/applications/argocd/certificates/
```

### **5.2 Deploy Backstage**
```bash
# Deploy Backstage
kubectl apply -k infrastructure/applications/backstage/
```

### **5.3 Deploy Crossplane**
```bash
# Deploy Crossplane
kubectl apply -k infrastructure/applications/crossplane/
```

## 📊 **Step 6: Monitor and Verify**

### **6.1 Check Application Status**
```bash
# Check all applications
kubectl get pods -A

# Check ingress status
kubectl get ingress -A

# Check certificates
kubectl get certificates -A
```

### **6.2 Access Applications**
```bash
# Get ingress IP
kubectl get svc -n ingress-nginx

# Test application access
curl -I https://argocd.dev.aztech-msdp.com
curl -I https://backstage.dev.aztech-msdp.com
```

## 🔧 **Step 7: Troubleshooting**

### **Common Issues and Solutions**

#### **Issue: GitHub Actions Workflow Fails**
```bash
# Check workflow logs
# Verify secrets are configured correctly
# Check AKS cluster connectivity
```

#### **Issue: Platform Components Not Ready**
```bash
# Check pod logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
kubectl logs -n cert-manager deployment/cert-manager
kubectl logs -n external-dns deployment/external-dns

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### **Issue: DNS Resolution Fails**
```bash
# Check External DNS logs
kubectl logs -n external-dns deployment/external-dns

# Verify Route53 permissions
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID
```

## 📋 **Step 8: Production Readiness**

### **8.1 Security Checklist**
- [ ] All secrets properly configured
- [ ] RBAC permissions minimal and correct
- [ ] Network policies configured
- [ ] Security contexts applied
- [ ] TLS certificates working

### **8.2 Monitoring Checklist**
- [ ] Prometheus metrics enabled
- [ ] Grafana dashboards configured
- [ ] Alerting rules set up
- [ ] Log aggregation working

### **8.3 Backup and Recovery**
- [ ] Backup strategy defined
- [ ] Recovery procedures documented
- [ ] Disaster recovery tested

## 🎯 **Success Criteria**

### **Platform Components Deployed Successfully**
- ✅ NGINX Ingress Controller running and healthy
- ✅ Cert-Manager running with Let's Encrypt issuers
- ✅ External DNS running and creating Route53 records
- ✅ All components accessible via DNS

### **Applications Deployed Successfully**
- ✅ ArgoCD accessible at `argocd.dev.aztech-msdp.com`
- ✅ Backstage accessible at `backstage.dev.aztech-msdp.com`
- ✅ Crossplane running and managing resources
- ✅ All applications have valid SSL certificates

### **GitHub Actions Working**
- ✅ Automatic deployment on push to dev branch
- ✅ Manual deployment via workflow dispatch
- ✅ Proper validation and verification
- ✅ Environment-specific deployments working

## 🚀 **Next Steps After Setup**

1. **Deploy to Test Environment**
   - Create PR from dev to test
   - Verify deployment to test AKS cluster

2. **Deploy to Production Environment**
   - Create PR from test to prod
   - Verify deployment to prod AKS cluster

3. **Set Up Monitoring**
   - Deploy Prometheus and Grafana
   - Configure dashboards and alerts

4. **Application Development**
   - Start developing applications
   - Use the platform for application deployment

---

**Follow these steps to successfully set up and deploy your MSDP platform components!** 🚀
