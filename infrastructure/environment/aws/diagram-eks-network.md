# AWS EKS Network Architecture Diagram

## Overview
This diagram shows the AWS network architecture for EKS clusters, including VPC, subnets, NAT gateways, and security groups.

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                AWS Region: eu-west-1                                   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│  │                            VPC: vpc-msdp-dev                                    │  │
│  │                           CIDR: 10.50.0.0/16                                   │  │
│  │                                                                                 │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                │  │
│  │  │  AZ: eu-west-1a │  │  AZ: eu-west-1b │  │  AZ: eu-west-1c │                │  │
│  │  │                 │  │                 │  │                 │                │  │
│  │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │                │  │
│  │  │ │Public Subnet│ │  │ │Public Subnet│ │  │ │Public Subnet│ │                │  │
│  │  │ │10.50.1.0/24 │ │  │ │10.50.2.0/24 │ │  │ │10.50.3.0/24 │ │                │  │
│  │  │ │             │ │  │ │             │ │  │ │             │ │                │  │
│  │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │                │  │
│  │  │ │ │NAT GW-1 │ │ │  │ │ │NAT GW-2 │ │ │  │ │ │NAT GW-3 │ │ │                │  │
│  │  │ │ │EIP      │ │ │  │ │ │EIP      │ │ │  │ │ │EIP      │ │ │                │  │
│  │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │                │  │
│  │  │ │             │ │  │ │             │ │  │ │             │ │                │  │
│  │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │                │  │
│  │  │ │ │   ALB   │ │ │  │ │ │   ALB   │ │ │  │ │ │   ALB   │ │ │                │  │
│  │  │ │ │ (Future)│ │ │  │ │ │ (Future)│ │ │  │ │ │ (Future)│ │ │                │  │
│  │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │                │  │
│  │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │                │  │
│  │  │                 │  │                 │  ���                 │                │  │
│  │  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │                │  │
│  │  │ │Private Subnet│ │  │ │Private Subnet│ │  │ │Private Subnet│ │                │  │
│  │  │ │10.50.11.0/24│ │  │ │10.50.12.0/24│ │  │ │10.50.13.0/24│ │                │  │
│  │  │ │             │ │  │ │             │ │  │ │             │ │                │  │
│  │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │                │  │
│  │  │ │ │EKS Nodes│ │ │  │ │ │EKS Nodes│ │ │  │ │ │EKS Nodes│ │ │                │  │
│  │  │ │ │System   │ │ │  │ │ │System   │ │ │  │ │ │System   │ │ │                │  │
│  │  │ │ │& User   │ │ │  │ │ │& User   │ │ │  │ │ │& User   │ │ │                │  │
│  │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │                ��  │
│  │  │ │             │ │  │ │             │ │  │ │             │ │                │  │
│  │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │ │                │  │
│  │  │ │ │   NLB   │ │ │  │ │ │   NLB   │ │ │  │ │ │   NLB   │ │ │                │  │
│  │  │ │ │(Internal)│ │ │  │ │ │(Internal)│ │ │  │ │ │(Internal)│ │ │                │  │
│  │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │  │ │ └─────────┘ │ │                │  │
│  │  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │                │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘                │  │
│  │                                                                                 │  │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                        EKS Control Plane                                  │  │  │
│  │  │                     (AWS Managed Service)                                 │  │  │
│  │  │                                                                           │  │  │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                      │  │  │
│  │  │  │   Master    │  │   Master    │  │   Master    │                      │  │  │
│  │  │  │ eu-west-1a  │  │ eu-west-1b  │  │ eu-west-1c  │                      │  │  │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘                      │  │  │
│  │  └─────────────────────────────────────────────────────────────────────────┘  │  │
│  └──────────────────��──────────────────────────────────────────────────────────┘  │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                           Internet Gateway                                   │  │
│  │                         (Public Internet)                                   │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Network Components

### VPC (Virtual Private Cloud)
- **Name**: vpc-msdp-dev
- **CIDR**: 10.50.0.0/16
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

### Public Subnets (3 AZs)
- **Purpose**: NAT Gateways, Application Load Balancers
- **Internet Access**: Direct via Internet Gateway
- **Kubernetes Tag**: `kubernetes.io/role/elb=1`

| Subnet | CIDR | AZ | Purpose |
|--------|------|----|---------| 
| subnet-public-dev-1a | 10.50.1.0/24 | eu-west-1a | NAT GW, ALB |
| subnet-public-dev-1b | 10.50.2.0/24 | eu-west-1b | NAT GW, ALB |
| subnet-public-dev-1c | 10.50.3.0/24 | eu-west-1c | NAT GW, ALB |

### Private Subnets (3 AZs)
- **Purpose**: EKS Worker Nodes, Internal Load Balancers
- **Internet Access**: Via NAT Gateways in public subnets
- **Kubernetes Tag**: `kubernetes.io/role/internal-elb=1`

| Subnet | CIDR | AZ | Purpose |
|--------|------|----|---------| 
| subnet-private-dev-1a | 10.50.11.0/24 | eu-west-1a | EKS Nodes |
| subnet-private-dev-1b | 10.50.12.0/24 | eu-west-1b | EKS Nodes |
| subnet-private-dev-1c | 10.50.13.0/24 | eu-west-1c | EKS Nodes |

### NAT Gateways
- **Count**: 3 (one per AZ for high availability)
- **Purpose**: Provide internet access for private subnets
- **Elastic IPs**: Dedicated EIP per NAT Gateway

### Route Tables
- **Public Route Table**: Routes 0.0.0.0/0 to Internet Gateway
- **Private Route Tables**: 3 tables, each routes 0.0.0.0/0 to respective NAT Gateway

### Security Groups
- **EKS Cluster Security Group**: Controls access to EKS API server
- **EKS Node Security Group**: Controls traffic between nodes and cluster
- **Custom Rules**: Minimal required access between components

### EKS Integration
- **Control Plane**: AWS managed, distributed across all AZs
- **Worker Nodes**: Deployed in private subnets only
- **Load Balancers**: 
  - ALB in public subnets for internet-facing services
  - NLB in private subnets for internal services

### Security Features
- **VPC Flow Logs**: Enabled for network monitoring
- **Private Worker Nodes**: No direct internet access
- **Controlled Egress**: Via NAT Gateways only
- **Security Groups**: Least privilege access

### High Availability
- **Multi-AZ**: Resources distributed across 3 availability zones
- **Redundant NAT**: Separate NAT Gateway per AZ
- **EKS Control Plane**: AWS managed HA across all AZs
- **Worker Nodes**: Can be distributed across all AZs

## Traffic Flow

### Inbound Traffic (Internet → EKS)
1. Internet → Internet Gateway
2. Internet Gateway → Public Subnet (ALB)
3. ALB → Private Subnet (EKS Nodes)
4. EKS Nodes → Pods

### Outbound Traffic (EKS → Internet)
1. Pods → EKS Nodes
2. EKS Nodes → Private Subnet Route Table
3. Route Table → NAT Gateway (in public subnet)
4. NAT Gateway → Internet Gateway
5. Internet Gateway → Internet

### Internal Traffic (Pod → Pod)
1. Pod → EKS Node
2. EKS Node → VPC CNI
3. VPC CNI → Target EKS Node
4. Target EKS Node → Target Pod

This architecture provides a secure, highly available, and scalable foundation for EKS clusters while following AWS best practices for network security and design.