# AWS Network Infrastructure

This module creates the foundational network infrastructure for AWS EKS clusters.

## Resources Created

- **VPC**: Virtual Private Cloud with DNS support
- **Public Subnets**: For load balancers and NAT gateways
- **Private Subnets**: For EKS worker nodes
- **Internet Gateway**: For public internet access
- **NAT Gateways**: For private subnet internet access (one per AZ)
- **Route Tables**: Proper routing for public and private subnets
- **VPC Flow Logs**: For network monitoring and security

## Features

- **High Availability**: Resources distributed across multiple AZs
- **Security**: Private subnets for worker nodes, public subnets only for load balancers
- **Kubernetes Ready**: Proper subnet tagging for EKS integration
- **Monitoring**: VPC Flow Logs enabled for network visibility
- **Cost Optimized**: NAT gateways only in required AZs

## Usage

This module is automatically deployed by the EKS workflow when network infrastructure doesn't exist.

## Subnet Tagging

- Public subnets: Tagged with `kubernetes.io/role/elb=1` for external load balancers
- Private subnets: Tagged with `kubernetes.io/role/internal-elb=1` for internal load balancers

## Security Considerations

- Worker nodes are placed in private subnets
- VPC Flow Logs are enabled for monitoring
- Proper security group rules are applied by the EKS module