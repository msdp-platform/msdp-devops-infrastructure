# 🏗️ Infrastructure Setup Scripts

## 🎯 **Overview**

This directory contains scripts for infrastructure deployment, configuration, and setup automation.

## 📁 **Scripts**

### **setup-minikube-crossplane-argocd.sh**
**Purpose**: Complete Minikube + Crossplane + ArgoCD setup

**Features**:
- Automated Minikube installation and configuration
- Crossplane installation and provider setup
- ArgoCD installation and configuration
- Multi-cloud provider configuration
- Complete infrastructure setup automation

**Usage**:
```bash
# Run complete infrastructure setup
./scripts/infrastructure-setup/setup-minikube-crossplane-argocd.sh
```

**What it sets up**:
- Minikube cluster with proper configuration
- Crossplane with AWS, GCP, Azure providers
- ArgoCD with GitOps configuration
- Multi-cloud infrastructure capabilities
- Complete development environment

### **setup-multi-cloud-providers.sh**
**Purpose**: Multi-cloud provider configuration

**Features**:
- AWS provider configuration
- GCP provider configuration
- Azure provider configuration
- Provider authentication setup
- Multi-cloud capabilities enablement

**Usage**:
```bash
# Configure multi-cloud providers
./scripts/infrastructure-setup/setup-multi-cloud-providers.sh
```

**Providers configured**:
- **AWS**: RDS, ElastiCache, S3, Route53
- **GCP**: Cloud SQL, Memorystore, Cloud Storage
- **Azure**: Database for PostgreSQL, Cache for Redis, Blob Storage

### **apply-system-pod-affinity.sh**
**Purpose**: System pod affinity configuration

**Features**:
- System pod scheduling configuration
- Pod affinity rules application
- System component isolation
- Node affinity enforcement

**Usage**:
```bash
# Apply system pod affinity
./scripts/infrastructure-setup/apply-system-pod-affinity.sh
```

**Components configured**:
- ArgoCD system pod affinity
- cert-manager system pod affinity
- NGINX Ingress system pod affinity
- Crossplane system pod affinity

### **apply-system-pod-affinity-patch.sh**
**Purpose**: System pod affinity patch application

**Features**:
- Patch-based pod affinity application
- Strategic merge patch operations
- System pod isolation enforcement
- Node affinity rule updates

**Usage**:
```bash
# Apply system pod affinity patches
./scripts/infrastructure-setup/apply-system-pod-affinity-patch.sh
```

## 🎯 **Key Benefits**

- **Automated Setup**: Complete infrastructure deployment automation
- **Multi-Cloud Support**: AWS, GCP, Azure provider configuration
- **Pod Scheduling**: System pod affinity and isolation
- **Configuration Management**: Automated configuration and patching
- **Development Environment**: Complete local development setup

## 🚀 **Quick Start**

```bash
# Complete infrastructure setup
./scripts/infrastructure-setup/setup-minikube-crossplane-argocd.sh

# Configure multi-cloud providers
./scripts/infrastructure-setup/setup-multi-cloud-providers.sh

# Apply system pod affinity
./scripts/infrastructure-setup/apply-system-pod-affinity.sh
```

## 🏗️ **Infrastructure Components**

### **Minikube Setup**
- Local Kubernetes cluster
- Proper resource allocation
- Addon configuration
- Development environment

### **Crossplane Configuration**
- Infrastructure as Code
- Multi-cloud resource management
- Provider configurations
- Resource compositions

### **ArgoCD Setup**
- GitOps application deployment
- Repository configuration
- Application definitions
- Automated synchronization

### **System Pod Affinity**
- System component isolation
- Node affinity rules
- Pod scheduling optimization
- Resource allocation

## 🔧 **Prerequisites**

- Docker installed and running
- kubectl configured
- Helm v3+ installed
- Cloud provider credentials configured
- Sufficient system resources (8GB+ RAM recommended)

## 📊 **Setup Validation**

After running the setup scripts, validate the installation:

```bash
# Check Minikube status
minikube status

# Check Crossplane providers
kubectl get providers

# Check ArgoCD status
kubectl get pods -n argocd

# Check system pod affinity
kubectl get pods -A -o wide
```
