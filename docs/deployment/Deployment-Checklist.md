# ✅ Platform Components Deployment Checklist

## 🎯 **Pre-Deployment Checklist**

### **GitHub Repository**
- [ ] Repository: `msdp-platform/msdp-devops-infrastructure`
- [ ] Branches: `dev`, `test`, `prod` exist
- [ ] GitHub Actions enabled
- [ ] Branch protection rules configured

### **GitHub Secrets**
- [ ] `AZURE_CREDENTIALS` configured
- [ ] `AWS_ACCESS_KEY_ID` configured
- [ ] `AWS_SECRET_ACCESS_KEY` configured

### **Azure Resources**
- [ ] AKS clusters created:
  - [ ] `msdp-dev-aks` in `msdp-dev-rg`
  - [ ] `msdp-test-aks` in `msdp-test-rg`
  - [ ] `msdp-prod-aks` in `msdp-prod-rg`
- [ ] Service Principal with AKS access
- [ ] Azure CLI configured

### **AWS Resources**
- [ ] Route53 hosted zones:
  - [ ] `aztech-msdp.com`
  - [ ] `dev.aztech-msdp.com`
  - [ ] `test.aztech-msdp.com`
  - [ ] `prod.aztech-msdp.com`
- [ ] IAM user with Route53 permissions
- [ ] AWS CLI configured

## 🚀 **Deployment Steps**

### **Step 1: Test Deployment (Dry Run)**
- [ ] Go to GitHub Actions
- [ ] Select "Deploy Platform Components"
- [ ] Run workflow with:
  - Environment: `dev`
  - Component: `all`
  - Dry Run: `true`
- [ ] Verify validation passes
- [ ] Check dry run output

### **Step 2: Deploy to Dev Environment**
- [ ] Push changes to dev branch
- [ ] Monitor GitHub Actions workflow
- [ ] Verify platform components deployed:
  - [ ] NGINX Ingress Controller
  - [ ] Cert-Manager
  - [ ] External DNS
- [ ] Check component health
- [ ] Verify DNS resolution

### **Step 3: Deploy Applications to Dev**
- [ ] Deploy ArgoCD
- [ ] Deploy Backstage
- [ ] Deploy Crossplane
- [ ] Verify application access
- [ ] Check SSL certificates

### **Step 4: Promote to Test Environment**
- [ ] Create PR from dev to test
- [ ] Review and merge PR
- [ ] Monitor deployment to test
- [ ] Verify test environment

### **Step 5: Promote to Production**
- [ ] Create PR from test to prod
- [ ] Review and merge PR
- [ ] Monitor deployment to prod
- [ ] Verify production environment

## 🔍 **Verification Commands**

### **Check Platform Components**
```bash
# Get AKS credentials
az aks get-credentials --resource-group msdp-dev-rg --name msdp-dev-aks

# Check NGINX Ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check Cert-Manager
kubectl get pods -n cert-manager
kubectl get clusterissuer

# Check External DNS
kubectl get pods -n external-dns
kubectl get svc -n external-dns
```

### **Check Applications**
```bash
# Check all pods
kubectl get pods -A

# Check ingress
kubectl get ingress -A

# Check certificates
kubectl get certificates -A
```

### **Test DNS Resolution**
```bash
# Test DNS
nslookup argocd.dev.aztech-msdp.com
nslookup backstage.dev.aztech-msdp.com
```

## 🚨 **Troubleshooting**

### **Common Issues**
- [ ] GitHub Actions workflow fails
- [ ] Platform components not ready
- [ ] DNS resolution fails
- [ ] SSL certificates not working
- [ ] Applications not accessible

### **Debug Commands**
```bash
# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
kubectl logs -n cert-manager deployment/cert-manager
kubectl logs -n external-dns deployment/external-dns

# Check resources
kubectl get all -A
```

## ✅ **Success Criteria**

### **Platform Components**
- [ ] NGINX Ingress Controller running and healthy
- [ ] Cert-Manager running with Let's Encrypt issuers
- [ ] External DNS running and creating Route53 records
- [ ] All components accessible via DNS

### **Applications**
- [ ] ArgoCD accessible at `argocd.dev.aztech-msdp.com`
- [ ] Backstage accessible at `backstage.dev.aztech-msdp.com`
- [ ] Crossplane running and managing resources
- [ ] All applications have valid SSL certificates

### **GitHub Actions**
- [ ] Automatic deployment on push to dev branch
- [ ] Manual deployment via workflow dispatch
- [ ] Proper validation and verification
- [ ] Environment-specific deployments working

---

**Use this checklist to ensure successful deployment of your MSDP platform components!** 🚀
