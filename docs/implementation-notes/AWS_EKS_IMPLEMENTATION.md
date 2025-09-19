# AWS EKS Implementation

This document describes the comprehensive AWS EKS implementation following the same DevOps principles and patterns as the Azure AKS solution.

## Overview

The AWS EKS implementation provides:
- **Multi-cluster support** with matrix-based deployments
- **Automatic network provisioning** with VPC, subnets, and NAT gateways
- **Production-ready security** with proper IAM roles and security groups
- **Cost optimization** with spot instances and right-sized resources
- **High availability** across multiple availability zones
- **Comprehensive monitoring** with CloudWatch integration

## Architecture

### Network Layer
- **VPC**: Isolated network environment
- **Public Subnets**: For load balancers and NAT gateways (3 AZs)
- **Private Subnets**: For EKS worker nodes (3 AZs)
- **Internet Gateway**: Public internet access
- **NAT Gateways**: Private subnet internet access (one per AZ)
- **VPC Flow Logs**: Network monitoring and security

### EKS Layer
- **EKS Cluster**: Managed Kubernetes control plane
- **Node Groups**: Managed worker nodes with auto-scaling
- **IAM Roles**: Service roles for cluster and nodes
- **Security Groups**: Network security between components
- **Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver

## Configuration Structure

### File Organization
```
config/dev.yaml                           # Multi-cloud configuration
infrastructure/environment/aws/
├── network/                              # VPC and networking
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── README.md
└── eks/                                  # EKS clusters
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    └── README.md
.github/workflows/eks.yml                 # CI/CD workflow
```

### Configuration Example
```yaml
# config/dev.yaml
aws:
  region: eu-west-1
  
  network:
    vpc_name: vpc-msdp-dev
    vpc_cidr: 10.50.0.0/16
    availability_zones: ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    
    public_subnets:
      - name: subnet-public-dev-1a
        cidr: 10.50.1.0/24
        availability_zone: eu-west-1a
    
    private_subnets:
      - name: subnet-private-dev-1a
        cidr: 10.50.11.0/24
        availability_zone: eu-west-1a
  
  eks:
    clusters:
      - name: eks-msdp-dev-01
        kubernetes_version: "1.31"
        node_groups:
          - name: system-nodes
            instance_types: ["t3.medium"]
            capacity_type: ON_DEMAND
            min_size: 2
            max_size: 4
            desired_size: 2
```

## DevOps Principles Applied

### 1. Infrastructure as Code
- **Terraform modules** for reusable infrastructure components
- **Version controlled** configuration and infrastructure code
- **Declarative configuration** in YAML format

### 2. GitOps Workflow
- **GitHub Actions** for CI/CD automation
- **Matrix deployments** for multiple clusters
- **Environment-based** configuration management
- **Automated testing** with plan/apply/destroy actions

### 3. Security Best Practices
- **Private worker nodes** in private subnets only
- **Least privilege IAM** roles and policies
- **Security groups** with minimal required access
- **VPC Flow Logs** for network monitoring
- **Encrypted storage** with EBS CSI driver

### 4. High Availability
- **Multi-AZ deployment** across 3 availability zones
- **Redundant NAT gateways** for private subnet internet access
- **Auto-scaling node groups** for workload resilience
- **EKS managed control plane** with built-in HA

### 5. Cost Optimization
- **Spot instances** for non-critical workloads
- **Right-sized instances** based on workload requirements
- **Auto-scaling** to match demand
- **Resource tagging** for cost allocation

### 6. Monitoring and Observability
- **CloudWatch logging** for EKS control plane
- **VPC Flow Logs** for network visibility
- **Resource tagging** for operational insights
- **Terraform outputs** for integration points

## Workflow Features

### Network Auto-Provisioning
```yaml
check-network:
  - Checks if VPC and subnets exist
  - Triggers network deployment if missing
  - Skips if infrastructure already exists

deploy-network:
  - Creates VPC, subnets, gateways
  - Sets up proper routing and security
  - Enables VPC Flow Logs
```

### Matrix-Based Cluster Deployment
```yaml
prepare:
  - Loads configuration from config/dev.yaml
  - Generates deployment matrix for clusters
  - Filters by cluster name if specified

deploy:
  - Deploys each cluster in parallel
  - Creates IAM roles and security groups
  - Provisions node groups with auto-scaling
  - Installs essential EKS add-ons
```

### Multi-Action Support
- **plan**: Dry-run to show what will be created
- **apply**: Actually create/update infrastructure
- **destroy**: Tear down infrastructure

## Security Model

### Network Security
- **Private Subnets**: Worker nodes have no direct internet access
- **NAT Gateways**: Controlled outbound internet access
- **Security Groups**: Minimal required access between components
- **VPC Flow Logs**: Network traffic monitoring

### IAM Security
- **Service Roles**: Separate roles for cluster and node groups
- **Managed Policies**: AWS-managed policies for EKS
- **Least Privilege**: Minimal required permissions
- **OIDC Integration**: For GitHub Actions authentication

### Kubernetes Security
- **Private API Endpoint**: Control plane accessible from VPC
- **Public API Endpoint**: Configurable CIDR restrictions
- **Node Group Security**: Proper communication between components
- **Add-on Security**: Secure defaults for all add-ons

## Comparison with Azure AKS

| Feature | AWS EKS | Azure AKS |
|---------|---------|-----------|
| **Network** | VPC + Subnets | VNet + Subnets |
| **Compute** | EC2 Node Groups | VM Scale Sets |
| **Storage** | EBS CSI Driver | Azure Disk CSI |
| **Networking** | VPC CNI | Azure CNI |
| **Load Balancing** | ALB/NLB | Azure Load Balancer |
| **DNS** | CoreDNS | CoreDNS |
| **Monitoring** | CloudWatch | Azure Monitor |
| **Cost Optimization** | Spot Instances | Spot VMs |

## Usage Instructions

### 1. Prerequisites
- AWS account with appropriate permissions
- GitHub repository secrets configured:
  - `AWS_ROLE_ARN`: IAM role for GitHub Actions
- Terraform backend S3 bucket (auto-created)

### 2. Deploy Network + EKS
```bash
# Via GitHub Actions UI
Action: apply
Environment: dev
Cluster Name: (leave empty for all clusters)

# Or trigger via push to main branch
git push origin main
```

### 3. Connect to Cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-1 --name eks-msdp-dev-01

# Verify connection
kubectl get nodes
kubectl get pods -A
```

### 4. Deploy Applications
```bash
# Example nginx deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

## Monitoring and Troubleshooting

### CloudWatch Logs
- EKS control plane logs in CloudWatch
- VPC Flow Logs for network analysis
- Application logs via CloudWatch Container Insights

### Terraform State
- State stored in S3 with DynamoDB locking
- Separate state files per cluster
- Environment and instance isolation

### Common Issues
1. **Network connectivity**: Check security groups and NACLs
2. **Node group failures**: Verify IAM roles and subnet configuration
3. **Add-on issues**: Check EKS cluster version compatibility
4. **Cost concerns**: Monitor spot instance interruptions

## Future Enhancements

### Planned Features
- **Karpenter integration** for advanced auto-scaling
- **Istio service mesh** for advanced networking
- **ArgoCD integration** for GitOps application deployment
- **Prometheus/Grafana** for enhanced monitoring
- **Cert-manager** for automatic TLS certificate management

### Scaling Considerations
- **Multi-region deployment** for disaster recovery
- **Cross-cluster networking** with VPC peering
- **Centralized logging** with ELK stack
- **Policy enforcement** with OPA Gatekeeper

## Cost Optimization Tips

1. **Use Spot Instances** for non-critical workloads
2. **Right-size instances** based on actual usage
3. **Enable cluster autoscaler** to scale down unused nodes
4. **Use reserved instances** for predictable workloads
5. **Monitor costs** with AWS Cost Explorer and tags
6. **Optimize storage** with appropriate EBS volume types

This AWS EKS implementation provides a production-ready, secure, and cost-effective Kubernetes platform that follows the same high standards as the Azure AKS solution.