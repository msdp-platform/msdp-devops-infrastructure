# Multi-Cloud Kubernetes Compliance Analysis

## 🔍 **Current Configuration Analysis**

Let me analyze our current setup for AKS and EKS compliance and identify what needs to be addressed.

## ✅ **What's Currently Compliant**

### **EKS (AWS) Clusters** ✅
```yaml
# AWS clusters work perfectly with current config
external-dns:
  provider: aws
  domain_filters: ["aztech-msdp.com"]
  hosted_zone_id: "Z0581458B5QGVNLDPESN"

cert-manager:
  dns_provider: route53
  hosted_zone_id: "Z0581458B5QGVNLDPESN"
```
- ✅ Native Route53 access via IAM roles
- ✅ OIDC integration for service accounts
- ✅ No additional credentials needed

### **Plugin Compatibility** ✅
- ✅ NGINX Ingress Controller: Works on both AKS and EKS
- ✅ Cert-Manager: Works on both clouds
- ✅ External DNS: Works on both clouds
- ✅ Prometheus Stack: Cloud-agnostic
- ✅ Grafana: Cloud-agnostic

## ⚠️ **AKS (Azure) Compliance Issues**

### **Issue 1: Cross-Cloud DNS Access**
**Problem**: AKS clusters need AWS credentials to access Route53
```yaml
# Current Azure config tries to use AWS Route53
external-dns:
  provider: aws  # AKS cluster accessing AWS Route53
  hosted_zone_id: "Z0581458B5QGVNLDPESN"
```

**Impact**: 
- ❌ No native AWS credentials in AKS
- ❌ External DNS will fail to create records
- ❌ Cert-Manager DNS challenges will fail

### **Issue 2: Missing AWS Credentials Configuration**
**Problem**: No AWS credential management for Azure clusters

### **Issue 3: Service Account Annotations**
**Problem**: Azure-specific service account annotations missing

## 🔧 **Required Fixes for AKS Compliance**

### **Fix 1: AWS Credentials for AKS**

**Option A: Static Credentials (Simple)**
```yaml
# Add to Azure configuration
aws_credentials:
  access_key_id: "{{ AWS_ACCESS_KEY_ID }}"
  secret_access_key: "{{ AWS_SECRET_ACCESS_KEY }}"
  region: "eu-west-1"
```

**Option B: Workload Identity (Recommended)**
```yaml
# Use Azure Workload Identity to assume AWS role
workload_identity:
  enabled: true
  client_id: "{{ AZURE_CLIENT_ID }}"
  aws_role_arn: "arn:aws:iam::319422413814:role/AzureRoute53AccessRole"
```

### **Fix 2: Update External DNS Values for Azure**

**Current Issue**: External DNS plugin values need AWS credentials
```yaml
# external-dns/values/azure.yaml needs AWS credential support
extraEnv:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: access-key-id
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: secret-access-key
```

### **Fix 3: Update Cert-Manager Values for Azure**

**Current Issue**: Cert-Manager needs AWS credentials for Route53 challenges
```yaml
# cert-manager/values/azure.yaml needs AWS credential support
extraEnv:
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: access-key-id
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: aws-credentials
        key: secret-access-key
```

## 🛠️ **Implementation Plan**

### **Step 1: Create AWS IAM Role for Azure Access**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "route53:ListHostedZonesByName",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/Z0581458B5QGVNLDPESN",
        "arn:aws:route53:::change/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Step 2: Create AWS User for Azure Clusters**
```bash
# Create dedicated AWS user for Azure clusters
aws iam create-user --user-name AzureRoute53User
aws iam attach-user-policy --user-name AzureRoute53User --policy-arn arn:aws:iam::319422413814:policy/Route53AccessPolicy
aws iam create-access-key --user-name AzureRoute53User
```

### **Step 3: Store AWS Credentials in GitHub Secrets**
```yaml
# Add to GitHub Secrets
AWS_ACCESS_KEY_ID_FOR_AZURE: "AKIA..."
AWS_SECRET_ACCESS_KEY_FOR_AZURE: "..."
```

### **Step 4: Update Workflow to Handle Cross-Cloud Credentials**
```yaml
# In .github/workflows/k8s-addons-pluggable.yml
- name: Set Cross-Cloud Credentials
  if: ${{ env.CLOUD_PROVIDER == 'azure' }}
  run: |
    # Set AWS credentials for Azure clusters
    echo "AWS_ACCESS_KEY_ID_FOR_AZURE=${{ secrets.AWS_ACCESS_KEY_ID_FOR_AZURE }}" >> $GITHUB_ENV
    echo "AWS_SECRET_ACCESS_KEY_FOR_AZURE=${{ secrets.AWS_SECRET_ACCESS_KEY_FOR_AZURE }}" >> $GITHUB_ENV
```

## 🔄 **Updated Architecture**

### **EKS Clusters (No Changes)**
```
EKS Cluster → IAM Role → Route53 (Native Access)
```

### **AKS Clusters (Updated)**
```
AKS Cluster → AWS Credentials Secret → Route53 (Cross-Cloud Access)
```

## 📋 **Compliance Checklist**

### **EKS Compliance** ✅
- ✅ Native AWS integration
- ✅ IAM roles for service accounts
- ✅ Route53 access via OIDC
- ✅ No additional configuration needed

### **AKS Compliance** (Needs Updates)
- ⚠️ AWS credentials for Route53 access
- ⚠️ Updated plugin configurations
- ⚠️ Cross-cloud secret management
- ⚠️ Service account annotations

## 🎯 **Recommended Solution**

### **Option 1: Static AWS Credentials (Quick Fix)**
**Pros**: 
- ✅ Simple to implement
- ✅ Works immediately
- ✅ No complex setup

**Cons**:
- ❌ Less secure
- ❌ Manual credential rotation
- ❌ Stored in Kubernetes secrets

### **Option 2: Azure Workload Identity + AWS Cross-Account Role (Best Practice)**
**Pros**:
- ✅ No static credentials
- ✅ Automatic token rotation
- ✅ Better security posture
- ✅ Audit trail

**Cons**:
- ❌ More complex setup
- ❌ Requires AWS cross-account trust
- ❌ Azure Workload Identity setup

### **Option 3: Hybrid Approach (Recommended)**
**Implementation**:
- Use **static credentials** for initial setup and testing
- Migrate to **Workload Identity** for production

## 🚀 **Immediate Action Items**

### **For AKS Compliance**:
1. **Create AWS IAM user** with Route53 permissions
2. **Update plugin configurations** to support AWS credentials
3. **Add credential management** to the workflow
4. **Test cross-cloud DNS** functionality

### **For Production Readiness**:
1. **Implement Workload Identity** for better security
2. **Set up cross-account roles** between Azure and AWS
3. **Add credential rotation** automation
4. **Implement monitoring** for cross-cloud access

## 🔍 **Testing Strategy**

### **EKS Testing** ✅
```bash
# Should work out of the box
GitHub Actions → k8s-addons-pluggable.yml
  cloud_provider: aws
  cluster_name: eks-msdp-dev-01
  action: install
  plugins: external-dns,cert-manager
```

### **AKS Testing** (After Fixes)
```bash
# Will work after implementing AWS credentials
GitHub Actions → k8s-addons-pluggable.yml
  cloud_provider: azure
  cluster_name: aks-msdp-dev-01
  action: install
  plugins: external-dns,cert-manager
```

## 📊 **Summary**

### **Current Status**:
- ✅ **EKS**: Fully compliant and ready
- ⚠️ **AKS**: Needs AWS credential configuration for Route53 access

### **Required Work**:
- 🔧 AWS IAM user/role creation
- 🔧 Plugin configuration updates
- 🔧 Workflow credential management
- 🔧 Cross-cloud testing

### **Timeline**:
- **Quick Fix**: 2-4 hours (static credentials)
- **Production Ready**: 1-2 days (Workload Identity)

**Would you like me to implement the quick fix with static credentials first, or go straight to the production-ready Workload Identity approach?** 🤔