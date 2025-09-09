# 🔐 External Secrets Operator - Simplified Certificate Management

## 🎯 **Overview**

This directory contains the simplified External Secrets Operator setup for certificate management using Azure Key Vault with OIDC authentication.

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Secrets Operator                   │
│                    (Secret Manager Controller)                 │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Key Vault (OIDC)                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Dev Certs     │  │   Test Certs    │  │   Prod Certs    │ │
│  │   - argocd-tls  │  │   - argocd-tls  │  │   - argocd-tls  │ │
│  │   - grafana-tls │  │   - grafana-tls │  │   - grafana-tls │ │
│  │   - backstage   │  │   - backstage   │  │   - backstage   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 **Key Features**

- ✅ **Helm Chart Deployment**: Uses official External Secrets Operator Helm chart
- ✅ **Azure OIDC Authentication**: No secrets stored in Kubernetes
- ✅ **Automatic Certificate Sync**: Certificates automatically synced from Azure Key Vault
- ✅ **Environment-Aware**: Different certificates per environment
- ✅ **Pipeline Integration**: Deployed via your existing pipeline strategy

## 📋 **Configuration**

### **1. Component Registry**
```yaml
# .github/components.yml
external_secrets:
  type: helm
  category: security
  namespace: external-secrets
  version: v0.9.11
  dependencies: []
  chart: external-secrets
  repository: https://charts.external-secrets.io
  chart_version: 0.9.11
```

### **2. Global Configuration**
```yaml
# infrastructure/config/global.yaml
external_secrets:
  version: "v0.9.11"
  namespace: "external-secrets"
  chart_version: "0.9.11"
  azure_keyvault:
    vault_url: "https://msdp-certificates-kv.vault.azure.net/"
    tenant_id: "{{ .Values.azure.tenantId }}"
    workload_identity:
      client_id: "{{ .Values.azure.workloadIdentity.clientId }}"
```

### **3. Component Configuration**
```yaml
# infrastructure/config/components/external-secrets.yaml
external_secrets:
  installCRDs: true
  serviceAccount:
    create: true
    annotations:
      azure.workload.identity/client-id: "{{ .Values.azure.workloadIdentity.clientId }}"
  azureKeyVault:
    enabled: true
    vaultUrl: "https://msdp-certificates-kv.vault.azure.net/"
    tenantId: "{{ .Values.azure.tenantId }}"
    useWorkloadIdentity: true
```

## 🚀 **Deployment**

The External Secrets Operator is deployed automatically via your pipeline:

1. **Component Registration**: Added to `.github/components.yml`
2. **Pipeline Deployment**: Deployed via `deploy-modular.yml`
3. **Azure OIDC**: Automatically configured with Workload Identity
4. **Certificate Sync**: Automatically syncs certificates from Azure Key Vault

## 🔄 **How It Works**

1. **External Secrets Operator** is deployed via Helm chart
2. **Azure OIDC** provides secure authentication to Azure Key Vault
3. **Certificate Sync** happens automatically based on ExternalSecret resources
4. **Applications** use the synced certificates for TLS

## 📚 **Benefits**

- ✅ **Simplified Setup**: No complex configurations
- ✅ **Secure Authentication**: Azure OIDC instead of stored secrets
- ✅ **Automatic Management**: External Secrets handles all orchestration
- ✅ **Pipeline Integration**: Fits seamlessly into your existing workflow
- ✅ **Environment Isolation**: Separate certificates per environment

## 🎉 **Result**

Once deployed, External Secrets Operator will:
- Automatically sync certificates from Azure Key Vault
- Create Kubernetes secrets for applications
- Handle certificate rotation and renewal
- Provide secure, environment-specific certificate management

**The secret manager controller does all the orchestration automatically!**
