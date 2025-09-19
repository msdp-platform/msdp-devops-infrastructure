# Troubleshooting Guide 🔧

## 🎯 **Overview**

This guide helps you diagnose and resolve common issues when setting up and using the MSDP DevOps Infrastructure.

## 🚨 **Quick Diagnostic Commands**

Run these commands to quickly identify issues:

```bash
# Validate your configuration
./scripts/validate-organization-config.sh

# Check cloud authentication
aws sts get-caller-identity
az account show

# Check GitHub authentication
gh auth status

# Test DNS resolution
nslookup your-domain.com
```

## ☁️ **Cloud Authentication Issues**

### **AWS Authentication Failures**

**Error**: `Unable to locate credentials`
```
NoCredentialsError: Unable to locate credentials
```

**Solutions**:
1. **Configure AWS CLI**:
   ```bash
   aws configure
   # Enter your Access Key ID, Secret Access Key, and region
   ```

2. **Check environment variables**:
   ```bash
   echo $AWS_ACCESS_KEY_ID
   echo $AWS_SECRET_ACCESS_KEY
   ```

3. **Verify IAM permissions**:
   ```bash
   aws sts get-caller-identity
   aws iam list-attached-user-policies --user-name your-username
   ```

**Error**: `AccessDenied` for Route53
```
AccessDenied: User is not authorized to perform: route53:ListHostedZones
```

**Solution**: Add Route53 permissions to your IAM user/role:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### **Azure Authentication Failures**

**Error**: `Please run 'az login' to setup account`
```
Please run 'az login' to setup account
```

**Solutions**:
1. **Login to Azure**:
   ```bash
   az login
   ```

2. **Set correct subscription**:
   ```bash
   az account set --subscription "your-subscription-id"
   ```

3. **Check permissions**:
   ```bash
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

## 🐙 **GitHub Actions Issues**

### **OIDC Authentication Failures**

**Error**: `No matching federated identity record found`
```
AADSTS700213: No matching federated identity record found for presented assertion
```

**Solutions**:
1. **Check branch configuration**:
   - Ensure OIDC is configured for your branch (main/dev)
   - Run: `./scripts/add-dev-branch-oidc.sh` for dev branch support

2. **Verify federated credentials**:
   ```bash
   az ad app federated-credential list --id YOUR_APP_ID
   ```

3. **Check repository secrets**:
   - Verify `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` are set
   - Ensure secrets match your Azure AD app registration

### **Repository Variables Not Found**

**Error**: Variables like `ORG_DOMAIN` not found in workflows

**Solutions**:
1. **Set repository variables**:
   ```bash
   gh variable set ORG_DOMAIN --body "your-domain.com"
   gh variable set ORG_EMAIL --body "devops@your-domain.com"
   ```

2. **Use the setup script**:
   ```bash
   ./scripts/setup-new-organization.sh
   ```

3. **Manual setup via GitHub UI**:
   - Go to repository Settings → Secrets and variables → Actions
   - Add variables in the Variables tab

## 🏗️ **Terraform Issues**

### **Backend Configuration Errors**

**Error**: `Backend configuration changed`
```
Backend configuration changed!
```

**Solutions**:
1. **Reinitialize Terraform**:
   ```bash
   terraform init -reconfigure
   ```

2. **Check backend configuration**:
   ```bash
   # Verify your backend config matches your setup
   cat terraform.tf
   ```

### **Resource Already Exists**

**Error**: `Resource already exists`
```
Error: A resource with the ID already exists
```

**Solutions**:
1. **Import existing resource**:
   ```bash
   terraform import resource_type.name resource_id
   ```

2. **Use different resource names**:
   - Update your configuration to use unique names
   - Check naming conventions in `organization.yaml`

### **Permission Denied Errors**

**Error**: `403 Forbidden` or `Access Denied`

**Solutions**:
1. **Check cloud provider permissions**:
   ```bash
   # AWS
   aws sts get-caller-identity
   
   # Azure
   az account show
   ```

2. **Verify service principal roles**:
   ```bash
   az role assignment list --assignee YOUR_CLIENT_ID
   ```

## 🌐 **DNS and Domain Issues**

### **Domain Not Resolving**

**Error**: Domain doesn't resolve or points to wrong IP

**Solutions**:
1. **Check nameservers**:
   ```bash
   dig NS your-domain.com
   nslookup -type=NS your-domain.com
   ```

2. **Update nameservers at registrar**:
   - Get Route53 nameservers: `aws route53 get-hosted-zone --id YOUR_ZONE_ID`
   - Update at your domain registrar

3. **Wait for propagation**:
   - DNS changes can take up to 48 hours to propagate globally
   - Use online DNS propagation checkers

### **SSL Certificate Issues**

**Error**: `Certificate validation failed`

**Solutions**:
1. **Check cert-manager logs**:
   ```bash
   kubectl logs -n cert-manager deployment/cert-manager
   ```

2. **Verify DNS challenge**:
   ```bash
   kubectl describe certificaterequest -n your-namespace
   ```

3. **Check Route53 permissions**:
   - Ensure cert-manager has Route53 access
   - Verify AWS credentials secret exists

## 🔐 **Security and Access Issues**

### **Pod Security Policy Violations**

**Error**: `Pod Security Policy violation`

**Solutions**:
1. **Update security context**:
   ```yaml
   securityContext:
     runAsNonRoot: true
     runAsUser: 1000
     fsGroup: 2000
   ```

2. **Check pod security standards**:
   ```bash
   kubectl get pods -o yaml | grep -A 5 securityContext
   ```

### **Network Policy Blocking Traffic**

**Error**: Services can't communicate

**Solutions**:
1. **Check network policies**:
   ```bash
   kubectl get networkpolicies -A
   ```

2. **Temporarily disable for testing**:
   ```bash
   kubectl delete networkpolicy policy-name -n namespace
   ```

## 📊 **Monitoring and Logging Issues**

### **Prometheus Not Scraping Metrics**

**Error**: Metrics not appearing in Prometheus

**Solutions**:
1. **Check service monitors**:
   ```bash
   kubectl get servicemonitor -A
   ```

2. **Verify pod annotations**:
   ```yaml
   annotations:
     prometheus.io/scrape: "true"
     prometheus.io/port: "8080"
     prometheus.io/path: "/metrics"
   ```

### **Grafana Dashboard Not Loading**

**Error**: Dashboards show "No data"

**Solutions**:
1. **Check Prometheus data source**:
   - Verify Prometheus URL in Grafana
   - Test connection in Grafana UI

2. **Check dashboard queries**:
   - Ensure metric names match your setup
   - Verify label selectors

## 🔄 **Workflow and Pipeline Issues**

### **Workflow Fails at Terraform Init**

**Error**: `terraform init` fails in GitHub Actions

**Solutions**:
1. **Check backend permissions**:
   ```bash
   # Verify S3 bucket access (AWS)
   aws s3 ls s3://your-terraform-state-bucket
   
   # Verify storage account access (Azure)
   az storage blob list --account-name your-storage-account --container-name tfstate
   ```

2. **Verify backend configuration**:
   - Check `backend-config.json` generation
   - Ensure correct region/location settings

### **Pipeline Timeout Issues**

**Error**: Workflows timeout after 6 hours

**Solutions**:
1. **Increase timeout**:
   ```yaml
   jobs:
     deploy:
       timeout-minutes: 120  # Increase from default
   ```

2. **Optimize Terraform operations**:
   - Use `-parallelism=10` for faster operations
   - Split large deployments into smaller chunks

## 🧪 **Testing and Validation**

### **Validation Script Failures**

**Error**: `validate-organization-config.sh` reports errors

**Solutions**:
1. **Fix configuration issues**:
   ```bash
   # Follow the script's recommendations
   ./scripts/validate-organization-config.sh
   ```

2. **Check file permissions**:
   ```bash
   chmod +x scripts/*.sh
   ```

### **Health Check Failures**

**Error**: Services fail health checks

**Solutions**:
1. **Check pod logs**:
   ```bash
   kubectl logs -f deployment/your-app -n your-namespace
   ```

2. **Verify resource limits**:
   ```bash
   kubectl describe pod your-pod -n your-namespace
   ```

## 📞 **Getting Help**

### **Diagnostic Information to Collect**

When asking for help, include:

```bash
# System information
kubectl version --client
terraform version
aws --version
az --version

# Configuration
./scripts/validate-organization-config.sh

# Logs
kubectl logs -n kube-system
kubectl get events --sort-by=.metadata.creationTimestamp
```

### **Where to Get Help**

1. **Check existing documentation**:
   - [Organization Setup Guide](ORGANIZATION_SETUP.md)
   - [Cloud Account Setup Guide](CLOUD_ACCOUNT_SETUP.md)

2. **Search existing issues**:
   - GitHub repository issues
   - Stack Overflow with relevant tags

3. **Create a detailed issue**:
   - Include error messages
   - Provide configuration (sanitized)
   - List steps to reproduce

## 🔧 **Common Quick Fixes**

### **Reset Everything**
```bash
# WARNING: This will destroy all infrastructure
terraform destroy -auto-approve
rm -rf .terraform/
terraform init
```

### **Refresh State**
```bash
terraform refresh
terraform plan
```

### **Force Unlock**
```bash
terraform force-unlock LOCK_ID
```

### **Clear DNS Cache**
```bash
# macOS
sudo dscacheutil -flushcache

# Linux
sudo systemctl restart systemd-resolved
```

---

**Remember**: When in doubt, check the logs! Most issues can be diagnosed by examining pod logs, GitHub Actions logs, and Terraform output. 🔍
