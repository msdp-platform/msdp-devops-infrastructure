# MSDP DevOps Infrastructure

Enterprise-grade Terraform infrastructure automation with standardized backend management, organizational naming conventions, and multi-cloud support.

## 🎯 Overview

This repository provides a comprehensive infrastructure-as-code solution with:

- **Standardized Backend Management**: S3 + DynamoDB with organizational naming conventions
- **Multi-Cloud Support**: Azure (primary) and AWS infrastructure
- **Configuration-Driven**: YAML-based configuration management
- **GitHub Actions Integration**: Automated CI/CD workflows
- **Security First**: OIDC authentication, encryption, and access controls

## 🏗️ Architecture

```
Infrastructure Components:
├── Azure Network (Shared)
│   ├── Resource Groups
│   ├── Virtual Networks
│   ├── Subnets
│   └── Network Security Groups
├── Azure AKS (Per Cluster)
│   ├── Kubernetes Clusters
│   ├── Node Pools
│   └── Workload Identity
└── Shared Services
    ├── Monitoring
    ├── DNS
    └── Security
```

## 📁 Repository Structure

```
├── config/                          # Configuration files
│   ├── global/                      # Global configuration
│   │   ├── naming.yaml             # Naming conventions
│   │   └── accounts.yaml           # Account mappings
│   ├── environments/               # Environment-specific config
│   │   └── dev.yaml               # Development environment
│   └── envs/                      # Legacy environment config
│       └── dev.yaml               # (backward compatibility)
├── infrastructure/
│   ├── environment/               # Environment-specific Terraform
│   │   └── azure/
│   │       ├── network/          # Shared network infrastructure
│   │       └── aks/              # AKS cluster infrastructure
│   └── modules/                  # Reusable Terraform modules
├── .github/
│   ├── actions/                  # Composite actions
│   │   ├── terraform-backend-enhanced/  # Enhanced backend management
│   │   ├── cloud-login/         # Multi-cloud authentication
│   │   └── network-tfvars/      # Network configuration generation
│   └── workflows/               # CI/CD workflows
│       ├── azure-network.yml    # Network infrastructure
│       └── aks.yml             # AKS cluster deployment
├── scripts/                     # Utility scripts
│   ├── generate-backend-config.py      # Backend config generator
│   ├── validate-naming-convention.py   # Naming validation
│   ├── validate-complete-setup.py      # Complete validation
│   └── migrate-configuration.py        # Configuration migration
└── docs/                       # Documentation
    ├── naming-convention-strategy.md   # Naming strategy
    ├── terraform-backend-best-practices.md  # Backend best practices
    └── implementation-guide.md         # Implementation guide
```

## 🚀 Quick Start

### Prerequisites

1. **GitHub Secrets**: Configure the following secrets in your repository:
   ```
   AWS_ROLE_ARN              # AWS IAM role for OIDC
   AWS_ACCOUNT_ID             # AWS account ID
   AZURE_CLIENT_ID            # Azure service principal client ID
   AZURE_TENANT_ID            # Azure tenant ID
   AZURE_SUBSCRIPTION_ID      # Azure subscription ID
   ```

2. **Permissions**: Ensure the service principals have appropriate permissions:
   - **AWS**: S3, DynamoDB, and IAM permissions
   - **Azure**: Contributor access to subscription

### 1. Validate Setup

```bash
# Validate the complete setup
python3 scripts/validate-complete-setup.py --verbose

# Test naming conventions
python3 scripts/validate-naming-convention.py

# Test backend config generation
python3 scripts/generate-backend-config.py dev azure network
```

### 2. Deploy Network Infrastructure

```bash
# Via GitHub CLI
gh workflow run azure-network.yml -f action=plan

# Via GitHub UI
# Go to Actions → azure-network-stack → Run workflow
```

### 3. Deploy AKS Clusters

```bash
# Via GitHub CLI
gh workflow run aks.yml -f action=plan

# Via GitHub UI
# Go to Actions → aks → Run workflow
```

## 🔧 Configuration

### Global Configuration

#### Naming Conventions (`config/global/naming.yaml`)
```yaml
organization:
  name: msdp
  full_name: "Microsoft Developer Platform"

naming_conventions:
  s3_bucket:
    pattern: "{prefix}-{org}-{account_type}-{region_code}-{suffix}"
  state_key:
    pattern: "{platform}/{component}/{environment}/{instance?}/terraform.tfstate"
```

#### Account Mappings (`config/global/accounts.yaml`)
```yaml
accounts:
  aws:
    dev:
      account_id: "319422413814"
      region: "eu-west-1"
  azure:
    dev:
      subscription_id: "ecd977ed-b8df-4eb6-9cba-98397e1b2491"
      region: "uksouth"
```

### Environment Configuration

#### Development Environment (`config/environments/dev.yaml`)
```yaml
azure:
  resource_group: "dev-ops"
  vnet_name: "dev-ops"
  vnet_cidr: "10.60.0.0/16"
  aks_clusters:
    - name: "dev-ops-01"
      size: "large"
    - name: "dev-ops-02"
      size: "large"
```

## 🎨 Usage Examples

### Backend Configuration

The system automatically generates backend configurations following organizational standards:

```yaml
# Azure Network Infrastructure
- name: Setup Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: dev
    platform: azure
    component: network

# Results in:
# Bucket: tf-state-msdp-dev-euw1-a1b2c3d4
# Key: azure/network/dev/terraform.tfstate
```

### Multi-Instance Components

```yaml
# AKS Cluster with Instance
- name: Setup Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: dev
    platform: azure
    component: aks
    instance: cluster-01

# Results in:
# Bucket: tf-state-msdp-dev-euw1-a1b2c3d4 (shared)
# Key: azure/aks/dev/cluster-01/terraform.tfstate
```

## 🔒 Security Features

### Authentication
- **GitHub OIDC**: No long-lived credentials
- **Multi-Cloud**: Unified authentication for AWS and Azure
- **Least Privilege**: Minimal required permissions

### Backend Security
- **Encryption**: AES256 encryption at rest
- **Versioning**: State file versioning enabled
- **Access Control**: IAM-based access restrictions
- **Audit Logging**: CloudTrail integration

### Network Security
- **Private Endpoints**: VNet integration where possible
- **Network Policies**: Kubernetes network policies
- **Security Groups**: Restrictive security group rules

## 📊 Generated Examples

### Development Environment
```
S3 Bucket: tf-state-msdp-dev-euw1-a1b2c3d4
DynamoDB:  tf-locks-msdp-dev-euw1

State Keys:
├── azure/network/dev/terraform.tfstate
├── azure/aks/dev/dev-ops-01/terraform.tfstate
├── azure/aks/dev/dev-ops-02/terraform.tfstate
└── shared/monitoring/dev/terraform.tfstate
```

### Production Environment
```
S3 Bucket: tf-state-msdp-prod-euw1-e5f6g7h8
DynamoDB:  tf-locks-msdp-prod-euw1

State Keys:
├── azure/network/prod/terraform.tfstate
├── azure/aks/prod/primary/terraform.tfstate
└── shared/monitoring/prod/terraform.tfstate
```

## 🛠️ Development Workflow

### 1. Local Development

```bash
# Generate configuration locally
python3 scripts/generate-backend-config.py dev azure network

# Initialize Terraform
cd infrastructure/environment/azure/network
terraform init -backend-config=../../../environment/dev/backend/backend-config-azure-network.json

# Plan changes
terraform plan
```

### 2. CI/CD Pipeline

```bash
# Plan (automatic on PR)
gh workflow run azure-network.yml -f action=plan

# Apply (manual approval)
gh workflow run azure-network.yml -f action=apply

# Destroy (manual with confirmation)
gh workflow run azure-network.yml -f action=destroy
```

## 🔄 Migration Guide

### From Legacy Configuration

If you have existing configuration in the old format:

```bash
# Run migration script
python3 scripts/migrate-configuration.py --dry-run

# Apply migration
python3 scripts/migrate-configuration.py

# Validate migration
python3 scripts/validate-complete-setup.py
```

### From Other Backend Systems

1. **Backup existing state**:
   ```bash
   terraform state pull > backup-state.json
   ```

2. **Update backend configuration**:
   ```bash
   # Generate new backend config
   python3 scripts/generate-backend-config.py dev azure network
   ```

3. **Migrate state**:
   ```bash
   terraform init -migrate-state
   ```

## 📈 Monitoring and Alerting

### Cost Monitoring
- S3 storage costs: ~$5-15/month per environment
- DynamoDB costs: ~$1-5/month per environment
- Total backend costs: ~$10-25/month per environment

### Operational Metrics
- Deployment success rate: Target 99.9%
- Backend initialization time: Target <2 minutes
- State lock conflicts: Target <1% of operations

### Alerts
- Failed deployments
- State lock timeouts
- Unusual backend access patterns
- Cost threshold breaches

## 🚨 Troubleshooting

### Common Issues

#### 1. Backend Configuration Not Found
```
Error: Backend config file not found
```
**Solution**: Ensure the terraform-backend-enhanced action runs before terraform-init.

#### 2. State Lock Errors
```
Error: Error acquiring the state lock
```
**Solution**: Check DynamoDB table exists and has correct permissions.

#### 3. Resource Already Exists
```
Error: A resource with the ID already exists
```
**Solution**: Import existing resources or use data sources instead of creating new ones.

### Validation Commands

```bash
# Complete setup validation
python3 scripts/validate-complete-setup.py --verbose

# Test specific backend config
python3 scripts/generate-backend-config.py dev azure network

# Verify AWS access
aws sts get-caller-identity

# Verify Azure access
az account show
```

## 📚 Documentation

- [Naming Convention Strategy](docs/naming-convention-strategy.md)
- [Backend Best Practices](docs/terraform-backend-best-practices.md)
- [Implementation Guide](docs/implementation-guide.md)
- [Codebase Analysis](docs/codebase-analysis-and-cleanup-plan.md)

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes and test**: `python3 scripts/validate-complete-setup.py`
4. **Commit changes**: `git commit -m 'Add amazing feature'`
5. **Push to branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request**

### Development Guidelines

- Follow the established naming conventions
- Add tests for new functionality
- Update documentation for changes
- Validate changes with the provided scripts

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: Create a GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check the `docs/` directory for detailed guides

## 🎯 Roadmap

- [ ] **Multi-Region Support**: Deploy across multiple Azure regions
- [ ] **AWS Integration**: Add AWS EKS and VPC modules
- [ ] **Policy as Code**: Implement Azure Policy and AWS Config
- [ ] **Cost Optimization**: Advanced cost monitoring and optimization
- [ ] **Disaster Recovery**: Cross-region backup and recovery procedures
- [ ] **GitOps Integration**: ArgoCD and Flux integration

---

**Built with ❤️ by the MSDP Platform Team**