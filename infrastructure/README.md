# 🏗️ Comprehensive EKS Platform - Infrastructure as Code

## 📋 **Overview**

This infrastructure provides a comprehensive EKS platform with all the components you requested. The platform includes cost-optimized EKS cluster with Karpenter, security components, observability, GitOps, and developer tools. The setup ensures you can never scale down to 0 instances while maximizing cost savings through spot instances.

## 🎯 **Key Features**

### **Core EKS Cluster Components**
- **✅ EKS Cluster** with managed node groups
- **✅ Fargate Profiles** for serverless workloads
- **✅ VPC CNI** for advanced networking

### **Security & Governance**
- **✅ AWS Load Balancer Controller** (ALB/NLB ingress)
- **✅ External DNS** (auto-manage Route 53 DNS records)
- **✅ Cert-Manager** (TLS cert automation with ACM)
- **✅ Secrets Store CSI Driver** (integrates with AWS Secrets Manager & SSM Parameter Store)
- **✅ Karpenter** (intelligent autoscaling, spot instance optimization)

### **Networking & Traffic Management**
- **✅ Amazon VPC CNI** (default networking)
- **✅ NGINX Ingress Controller** (popular ingress option)

### **Observability (Monitoring & Logging)**
- **✅ Prometheus + Alertmanager** (metrics + alerting)
- **✅ Grafana** (dashboards, often with AWS Managed Grafana)

### **CI/CD & GitOps**
- **✅ ArgoCD** (GitOps controller, deploy workloads via Git)
- **✅ AWS Controllers for Kubernetes (ACK)**

### **Others**
- **✅ Crossplane** (Infrastructure as Code)
- **✅ Backstage** (Developer portal)

### **Cost Optimization**
- **✅ ARM-Based Instances**: AWS Graviton processors for up to 40% better price/performance
- **✅ Spot Instances Only**: Up to 90% cost savings with no on-demand instances
- **✅ Zero Downtime**: Minimum node configuration prevents 0 instance scaling
- **✅ Multi-Instance Types**: Support for various ARM instance types and families
- **✅ Auto-Scaling**: Intelligent node provisioning based on workload demands
- **✅ Spot Interruption Handling**: Graceful handling of spot instance interruptions
- **✅ System Node Isolation**: Dedicated system nodes for critical workloads

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                Comprehensive EKS Platform                  │
├─────────────────────────────────────────────────────────────┤
│  Core EKS Cluster Components                               │
│  ├── EKS Cluster with Managed Node Groups                  │
│  ├── Fargate Profiles (Serverless)                        │
│  └── VPC CNI (Advanced Networking)                        │
├─────────────────────────────────────────────────────────────┤
│  Security & Governance                                     │
│  ├── AWS Load Balancer Controller (ALB/NLB)               │
│  ├── External DNS (Route 53)                              │
│  ├── Cert-Manager (TLS Automation)                        │
│  ├── Secrets Store CSI Driver (AWS Secrets)               │
│  └── Karpenter (Intelligent Autoscaling)                  │
├─────────────────────────────────────────────────────────────┤
│  Networking & Traffic Management                           │
│  ├── NGINX Ingress Controller                             │
│  └── Amazon VPC CNI                                       │
├─────────────────────────────────────────────────────────────┤
│  Observability (Monitoring & Logging)                     │
│  ├── Prometheus + Alertmanager                            │
│  └── Grafana (Dashboards)                                 │
├─────────────────────────────────────────────────────────────┤
│  CI/CD & GitOps                                           │
│  ├── ArgoCD (GitOps Controller)                           │
│  └── AWS Controllers for Kubernetes (ACK)                 │
├─────────────────────────────────────────────────────────────┤
│  Others                                                    │
│  ├── Crossplane (Infrastructure as Code)                  │
│  └── Backstage (Developer Portal)                         │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** >= 1.28
4. **Helm** >= 3.13
5. **GitHub Actions** secrets configured

### **Required AWS Permissions**

Your AWS credentials need the following permissions:
- EKS cluster management
- EC2 instance management
- IAM role creation and management
- VPC and networking
- SQS queue management
- CloudWatch Events

### **GitHub Secrets**

Configure these secrets in your GitHub repository:

```bash
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

### **Deployment**

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd msdp-devops-infrastructure
   ```

2. **Deploy via GitHub Actions**:
   - Push to `dev` branch for development environment
   - Push to `main` branch for production environment
   - Use manual workflow dispatch for custom deployments

3. **Or deploy locally**:
   ```bash
   cd infrastructure/terraform/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

## 🔧 **Configuration**

### **Environment Variables**

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | EKS cluster name | `msdp-eks-dev` |
| `aws_region` | AWS region | `us-west-2` |
| `kubernetes_version` | Kubernetes version | `1.28` |
| `karpenter_version` | Karpenter version | `0.37.0` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |

### **Instance Types - ARM-Based (Graviton)**

The configuration supports multiple ARM-based instance types for different workloads:

- **General Purpose**: t4g.medium, t4g.large, t4g.xlarge, t4g.2xlarge
- **Compute Optimized**: c6g.medium, c6g.large, c6g.xlarge, c6g.2xlarge, c6g.4xlarge
- **Memory Optimized**: r6g.medium, r6g.large, r6g.xlarge, r6g.2xlarge, r6g.4xlarge

## 📊 **NodePools Configuration**

### **1. System NodePool**
- **Purpose**: Critical system workloads (DNS, CNI, etc.)
- **Instance Types**: t4g.medium, t4g.large, m6g.medium, m6g.large
- **Capacity Type**: Spot (ARM-based for cost savings)
- **Min/Max**: 2/4 nodes
- **Taint**: `CriticalAddonsOnly=true:NoSchedule`

### **2. Cost-Optimized NodePool**
- **Purpose**: General application workloads
- **Capacity Type**: Spot Only
- **Instance Types**: t4g.*, m6g.*, c6g.* families (ARM-based)
- **Taint**: `workload-type=user:NoSchedule`

### **3. Memory-Optimized NodePool**
- **Purpose**: Memory-intensive workloads
- **Capacity Type**: Spot Only
- **Instance Types**: r6g.* (ARM-based memory instances)
- **Taint**: `workload-type=memory-intensive:NoSchedule`

### **4. Minimum NodePool**
- **Purpose**: Prevents 0 instance scaling
- **Capacity Type**: Spot Only
- **Instance Types**: t4g.medium, t4g.large, m6g.medium, m6g.large
- **Limits**: 4 CPU, 8Gi memory

## 🛡️ **Cost Optimization Features**

### **Spot Instance Strategy**
- **Primary**: Spot instances only for maximum cost savings (up to 90% reduction)
- **ARM-Based**: AWS Graviton processors for up to 40% better price/performance
- **No On-Demand**: All instances use spot pricing for maximum cost optimization
- **Interruption Handling**: Graceful pod migration via SQS queue

### **Node Consolidation**
- **Consolidate After**: 30 seconds of underutilization
- **Consolidation Policy**: WhenEmpty or WhenUnderutilized
- **Expiration**: 90 days maximum node lifetime

### **Resource Limits**
- **CPU Limit**: 1000 cores per NodePool
- **Memory Limit**: 1000Gi per NodePool
- **Minimum Nodes**: Always maintain minimum capacity

## 🔍 **Monitoring and Observability**

### **CloudWatch Integration**
- **Node Metrics**: CPU, memory, disk utilization
- **Custom Metrics**: Karpenter-specific metrics
- **Logs**: Centralized logging via CloudWatch

### **Karpenter Metrics**
```bash
# Check Karpenter status
kubectl get pods -n karpenter

# View NodePools
kubectl get nodepools

# View NodeClasses
kubectl get nodeclasses

# Check node utilization
kubectl top nodes
```

### **Cost Monitoring**
```bash
# Check spot vs on-demand usage
kubectl get nodes -l karpenter.sh/capacity-type=spot
kubectl get nodes -l karpenter.sh/capacity-type=on-demand

# View node types
kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\\.kubernetes\\.io/instance-type,CAPACITY-TYPE:.metadata.labels.karpenter\\.sh/capacity-type
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. No Spot Instances Available**
```bash
# Check spot instance availability
aws ec2 describe-spot-price-history --instance-types t3.medium --max-items 1

# Verify Karpenter configuration
kubectl describe nodepool cost-optimized
```

#### **2. Nodes Not Scaling Down**
```bash
# Check node utilization
kubectl top nodes

# Check pod distribution
kubectl get pods --all-namespaces -o wide

# Check Karpenter logs
kubectl logs -n karpenter deployment/karpenter
```

#### **3. System Pods Not Scheduling**
```bash
# Check system node taints
kubectl describe nodes -l node-type=system

# Verify system node capacity
kubectl get nodes -l node-type=system
```

### **Debug Commands**

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check Karpenter components
kubectl get pods -n karpenter
kubectl logs -n karpenter deployment/karpenter

# Check NodePools
kubectl get nodepools -o yaml
kubectl describe nodepool cost-optimized

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🔄 **Maintenance**

### **Updating Karpenter**
```bash
# Update Karpenter version in variables.tf
# Then run terraform apply
terraform apply
```

### **Scaling NodePools**
```bash
# Update NodePool limits
kubectl patch nodepool cost-optimized --type merge -p '{"spec":{"limits":{"cpu":"2000"}}}'
```

### **Adding New Instance Types**
```bash
# Update karpenter_instance_types in variables.tf
# Add new instance types to the list
# Run terraform apply
```

## 📚 **Additional Resources**

- [Karpenter Documentation](https://karpenter.sh/)
- [EKS Blueprint](https://aws-ia.github.io/terraform-aws-eks-blueprints/)
- [AWS Spot Instances](https://aws.amazon.com/ec2/spot/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🤝 **Contributing**

When making changes to the infrastructure:

1. **Test in dev environment first**
2. **Update documentation**
3. **Follow Terraform best practices**
4. **Use meaningful commit messages**
5. **Update version numbers appropriately**

---

**Last Updated**: $(date)  
**Version**: 1.0.0  
**Maintainer**: DevOps Team