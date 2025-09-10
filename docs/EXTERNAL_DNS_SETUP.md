# External DNS Setup for AKS + Route53

This guide explains how to set up External DNS in an AKS cluster to manage Route53 DNS records using OIDC/IRSA authentication.

## Overview

External DNS automatically creates and manages DNS records in AWS Route53 based on Kubernetes ingress resources. This setup uses:

- **AKS (Azure Kubernetes Service)** - Your Kubernetes cluster
- **Route53 (AWS)** - DNS service for managing domain records
- **OIDC/IRSA** - Secure authentication without storing AWS credentials

## Prerequisites

1. **AKS Cluster** with OIDC and Workload Identity enabled
2. **AWS Account** with Route53 access
3. **AWS CLI** configured with appropriate permissions
4. **kubectl** configured to access your AKS cluster

## Setup Steps

### Step 1: Verify OIDC is Enabled

Your AKS cluster should have OIDC and Workload Identity enabled:

```bash
az aks show --resource-group delivery-platform-aks-rg --name msdp-infra-aks --query "oidcIssuerProfile"
```

Expected output:
```json
{
  "enabled": true,
  "issuerUrl": "https://eastus.oic.prod-aks.azure.com/a4474822-c84f-4bd1-bc35-baed17234c9f/e7abd138-540d-4eea-9d06-5b4a88562748/"
}
```

### Step 2: Run the Setup Script

Execute the automated setup script:

```bash
# Make sure you're in the project root
cd /Users/santanu/github/msdp-devops-infrastructure

# Run the setup script
./scripts/setup-aws-oidc-external-dns.sh
```

This script will:
1. ✅ Create AWS OIDC Provider
2. ✅ Create IAM Policy with Route53 permissions
3. ✅ Create IAM Role with trust relationship
4. ✅ Update External DNS service account with IAM role annotation
5. ✅ Restart External DNS to pick up new configuration

### Step 3: Verify Setup

Check that External DNS is running and can access AWS:

```bash
# Check External DNS pod status
kubectl get pods -n external-dns

# Check External DNS logs
kubectl logs -f deployment/external-dns -n external-dns

# Verify service account has IAM role annotation
kubectl get serviceaccount external-dns -n external-dns -o yaml
```

## Configuration Details

### IAM Policy Permissions

The IAM policy grants the following permissions:
- `route53:ChangeResourceRecordSets` - Create/update/delete DNS records
- `route53:ListResourceRecordSets` - List existing DNS records
- `route53:ListHostedZones` - List hosted zones
- `route53:GetChange` - Check change status

### Trust Policy

The IAM role trust policy allows the External DNS service account to assume the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/eastus.oic.prod-aks.azure.com/..."
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "eastus.oic.prod-aks.azure.com/...:sub": "system:serviceaccount:external-dns:external-dns",
          "eastus.oic.prod-aks.azure.com/...:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

## Usage

### Adding External DNS Annotations

To have External DNS manage DNS records for your ingress resources, add the annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: my-app.dev.aztech-msdp.com
spec:
  # ... ingress spec
```

### Domain Filters

External DNS is configured to manage these domains:
- `aztech-msdp.com`
- `dev.aztech-msdp.com`
- `test.aztech-msdp.com`
- `prod.aztech-msdp.com`

### Current Ingress Resources

The following ingress resources are already configured with External DNS annotations:

1. **Backstage**: `backstage.dev.aztech-msdp.com`
2. **Grafana**: `grafana.dev.aztech-msdp.com`

## Troubleshooting

### Common Issues

1. **External DNS not creating records**
   - Check IAM role permissions
   - Verify service account annotation
   - Check External DNS logs for AWS authentication errors

2. **DNS records not updating**
   - Verify ingress has correct External DNS annotation
   - Check domain filters in External DNS configuration
   - Ensure Route53 hosted zone exists for the domain

3. **Authentication failures**
   - Verify OIDC provider is created in AWS
   - Check trust policy conditions
   - Ensure service account name and namespace match

### Useful Commands

```bash
# Check External DNS configuration
kubectl get deployment external-dns -n external-dns -o yaml

# View External DNS logs
kubectl logs -f deployment/external-dns -n external-dns

# Check service account annotations
kubectl get serviceaccount external-dns -n external-dns -o jsonpath='{.metadata.annotations}'

# List all ingress resources with External DNS annotations
kubectl get ingress --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{.metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}{"\n"}{end}'
```

## Security Considerations

1. **Least Privilege**: The IAM policy only grants necessary Route53 permissions
2. **No Credentials**: No AWS access keys are stored in the cluster
3. **Scoped Access**: The trust policy restricts access to the specific service account
4. **Audit Trail**: All DNS changes are logged in Route53

## Next Steps

After successful setup:
1. Monitor External DNS logs for successful DNS record creation
2. Test DNS resolution for your domains
3. Add External DNS annotations to new ingress resources as needed
4. Consider setting up monitoring and alerting for External DNS operations
