# AKS Setup Guide

## Overview

This guide covers the complete setup of Azure Kubernetes Service (AKS) with Crossplane and ArgoCD for the Multi-Service Delivery Platform. The setup includes cost optimization features with automatic scaling and scale-to-zero capabilities.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AKS Cluster                              │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   System Pool   │  │   User Pool     │                  │
│  │   (Always 1)    │  │   (0-3 nodes)   │                  │
│  │                 │  │   Auto-scaling  │                  │
│  └─────────────────┘  └─────────────────┘                  │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   Crossplane    │  │     ArgoCD      │                  │
│  │   (Multi-cloud) │  │   (GitOps)      │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Azure CLI installed and configured
- kubectl installed
- Azure subscription with sufficient permissions
- GitHub repository access

## Quick Start

### 1. Access AKS Cluster

```bash
# Get AKS credentials
az aks get-credentials --resource-group delivery-platform-aks-rg --name delivery-platform-aks

# Verify connection
kubectl get nodes
```

### 2. Access ArgoCD

```bash
# Get ArgoCD access information
./scripts/argocd-access.sh status

# Access ArgoCD UI
# URL: https://4.156.116.106
# Username: admin
# Password: D3vR370p8MkyErPv
```

### 3. Monitor Costs

```bash
# Check current costs and optimization
./scripts/aks-cost-monitor.sh status

# Get cost optimization recommendations
./scripts/aks-cost-monitor.sh optimize
```

## Detailed Setup

### AKS Cluster Configuration

**Cluster Details:**
- **Name**: `delivery-platform-aks`
- **Resource Group**: `delivery-platform-aks-rg`
- **Location**: `eastus`
- **Kubernetes Version**: `1.32.6`

**Node Pools:**
- **System Pool**: `nodepool1`
  - VM Size: `Standard_B2s` (2 vCPUs, 4GB RAM)
  - Count: 1 (min: 1, max: 2)
  - Mode: System
  
- **User Pool**: `userpool`
  - VM Size: `Standard_B2s` (2 vCPUs, 4GB RAM)
  - Count: 0 (min: 0, max: 3)
  - Mode: User
  - **Scale-to-Zero Capable**

### Crossplane Configuration

**Installed Providers:**
- AWS Provider: `v0.44.0`
- Azure Provider: `v2.0.1`
- GCP Provider: `v2.0.1`

**Provider Status:**
```bash
kubectl get providers
```

### ArgoCD Configuration

**Access Information:**
- **URL**: `https://4.156.116.106`
- **Username**: `admin`
- **Password**: `admin123`
- **Service Type**: LoadBalancer

**Sample Application:**
- **Name**: `sample-app`
- **Repository**: `https://github.com/argoproj/argocd-example-apps`
- **Path**: `guestbook`

## Cost Optimization

### Current Cost Structure

| Component | Cost | Notes |
|-----------|------|-------|
| System Node | $1.01/day | Always running |
| User Nodes | $1.01/day each | Only when needed |
| **Total (Idle)** | **$1.01/day** | **50% cost reduction** |
| **Total (Active)** | **$2.02/day** | **When developing** |

### Cost Optimization Features

1. **Automatic Scaling**
   - Scale up when workloads are deployed
   - Scale down after 10 minutes of inactivity
   - No manual intervention required

2. **Scale-to-Zero**
   - User pool can scale to 0 nodes
   - System pool maintains cluster management
   - Significant cost savings when idle

3. **Cost Monitoring**
   - Real-time cost tracking
   - Optimization recommendations
   - Usage pattern analysis

### Cost Management Commands

```bash
# Monitor current costs
./scripts/aks-cost-monitor.sh status

# Get optimization recommendations
./scripts/aks-cost-monitor.sh optimize

# Test autoscaler functionality
./scripts/test-aks-scaling.sh scale-up
./scripts/test-aks-scaling.sh scale-down
```

## Development Workflow

### 1. Start Development

```bash
# Deploy your workload
kubectl apply -f your-workload.yaml

# ArgoCD will automatically sync
# Autoscaler will scale up user nodes
```

### 2. Monitor Resources

```bash
# Check node status
kubectl get nodes

# Check pod status
kubectl get pods --all-namespaces

# Monitor costs
./scripts/aks-cost-monitor.sh status
```

### 3. Stop Development

```bash
# Remove workloads
kubectl delete -f your-workload.yaml

# Autoscaler will scale down after 10 minutes
# Costs will automatically reduce
```

## Multi-Cloud Deployment

### Using Crossplane

```bash
# Deploy to AWS
kubectl apply -f infrastructure/crossplane/aws-resources/

# Deploy to Azure
kubectl apply -f infrastructure/crossplane/azure-resources/

# Deploy to GCP
kubectl apply -f infrastructure/crossplane/gcp-resources/
```

### Using ArgoCD

```bash
# Create ArgoCD application
kubectl apply -f infrastructure/argocd/your-app.yaml

# ArgoCD will automatically sync from Git
```

## Troubleshooting

### Common Issues

1. **ArgoCD Not Accessible**
   ```bash
   # Check service status
   kubectl get svc argocd-server -n argocd
   
   # Check pod status
   kubectl get pods -n argocd
   ```

2. **Crossplane Providers Not Healthy**
   ```bash
   # Check provider status
   kubectl get providers
   
   # Check provider logs
   kubectl logs -n crossplane-system -l app=crossplane
   ```

3. **Autoscaler Not Working**
   ```bash
   # Check node pool status
   az aks nodepool list --resource-group delivery-platform-aks-rg --cluster-name delivery-platform-aks
   
   # Check cluster autoscaler logs
   kubectl logs -n kube-system -l app=cluster-autoscaler
   ```

### Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check ArgoCD applications
kubectl get applications -n argocd

# Check Crossplane resources
kubectl get managed
```

## Security Considerations

1. **Network Security**
   - AKS uses Azure CNI
   - Network policies enabled
   - LoadBalancer for external access

2. **RBAC**
   - Kubernetes RBAC enabled
   - ArgoCD RBAC configured
   - Crossplane RBAC configured

3. **Secrets Management**
   - Azure Key Vault integration available
   - Kubernetes secrets for sensitive data
   - OIDC authentication for cloud providers

## Backup and Recovery

1. **Cluster Backup**
   - AKS managed backup
   - Crossplane resource definitions in Git
   - ArgoCD application definitions in Git

2. **Disaster Recovery**
   - Multi-region deployment capability
   - Git-based infrastructure as code
   - Automated recovery procedures

## Monitoring and Observability

1. **Built-in Monitoring**
   - Azure Monitor integration
   - Kubernetes metrics
   - Application metrics

2. **Logging**
   - Azure Log Analytics
   - Container logs
   - Application logs

3. **Alerting**
   - Cost alerts
   - Resource utilization alerts
   - Application health alerts

## Next Steps

1. **Deploy Applications**
   - Use Crossplane for infrastructure
   - Use ArgoCD for application deployment
   - Monitor costs and performance

2. **Scale Globally**
   - Deploy to multiple regions
   - Use multi-cloud strategy
   - Implement disaster recovery

3. **Optimize Costs**
   - Use spot instances for non-critical workloads
   - Implement scheduled scaling
   - Monitor and optimize resource usage

## Support and Resources

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/aks/
- **Crossplane Documentation**: https://crossplane.io/docs/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **Cost Management**: https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/Overview
