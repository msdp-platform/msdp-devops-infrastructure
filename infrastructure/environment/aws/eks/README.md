# AWS EKS Cluster Infrastructure

This module creates production-ready EKS clusters with proper security, networking, and node group configurations.

## Resources Created

- **EKS Cluster**: Managed Kubernetes control plane
- **IAM Roles**: Proper service roles for cluster and node groups
- **Security Groups**: Network security for cluster and nodes
- **Node Groups**: Managed worker nodes with auto-scaling
- **EKS Add-ons**: Essential cluster add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI)

## Features

- **Production Ready**: Proper IAM roles, security groups, and logging
- **High Availability**: Multi-AZ deployment with private subnets
- **Security**: Private worker nodes, proper security group rules
- **Monitoring**: CloudWatch logging enabled for all components
- **Scalability**: Auto-scaling node groups with spot instance support
- **Storage**: EBS CSI driver for persistent volumes

## Node Group Types

- **System Nodes**: On-demand instances for critical system workloads
- **User Nodes**: Spot instances for cost-effective application workloads

## Security Features

- Worker nodes in private subnets only
- Proper security group rules between cluster and nodes
- IAM roles with least privilege access
- API server endpoint access control

## Add-ons Included

- **VPC CNI**: Pod networking
- **CoreDNS**: Cluster DNS
- **kube-proxy**: Service networking
- **EBS CSI Driver**: Persistent storage

## Usage

This module is automatically deployed by the EKS workflow based on configuration in `config/dev.yaml`.

## Monitoring

- CloudWatch logging enabled for API server, audit, authenticator, controller manager, and scheduler
- VPC Flow Logs available from the network module