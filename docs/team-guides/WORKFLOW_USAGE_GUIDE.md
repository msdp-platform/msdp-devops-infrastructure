# Workflow Usage Guide - MSDP DevOps Infrastructure

## Overview
This guide covers how to use the new refactored CI/CD workflows for infrastructure deployment and management.

## 🚀 **Quick Start Commands**

### Deploy Individual Components

#### Network Infrastructure
```bash
# Plan network changes
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=plan \
  --field environment=dev

# Apply network changes
gh workflow run "Network Infrastructure" \
  --field cloud_provider=azure \
  --field action=apply \
  --field environment=dev
```

#### Kubernetes Clusters
```bash
# Plan all clusters
gh workflow run "Kubernetes Clusters" \
  --field cloud_provider=azure \
  --field action=plan \
  --field environment=dev

# Deploy specific cluster
gh workflow run "Kubernetes Clusters" \
  --field cloud_provider=azure \
  --field action=apply \
  --field environment=dev \
  --field cluster_name=aks-msdp-dev-01
```

#### Kubernetes Addons
```bash
# Plan addons deployment
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=plan

# Apply addons
gh workflow run "Kubernetes Add-ons (Terraform)" \
  --field environment=dev \
  --field cloud_provider=azure \
  --field action=apply
```

### Advanced Orchestration (Phase 2)

#### Infrastructure Orchestrator
Deploy entire environments with intelligent dependency management:

```bash
# Deploy full environment (network + clusters + addons)
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network,clusters,addons" \
  --field action=apply \
  --field cloud_provider=azure

# Deploy only specific components
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network" \
  --field action=plan \
  --field cloud_provider=azure

# Force sequential deployment (disable parallelization)
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network,clusters,addons" \
  --field action=apply \
  --field cloud_provider=azure \
  --field force_sequential=true
```

#### Environment Promotion
Promote infrastructure between environments:

```bash
# Promote from dev to staging (with approval)
gh workflow run "Environment Promotion" \
  --field source_environment=dev \
  --field target_environment=staging \
  --field components="network,clusters,addons" \
  --field cloud_provider=azure

# Auto-approve for non-production
gh workflow run "Environment Promotion" \
  --field source_environment=dev \
  --field target_environment=staging \
  --field components="network,clusters,addons" \
  --field cloud_provider=azure \
  --field auto_approve=true
```

## 📋 **Workflow Reference**

### Phase 1 Workflows (Refactored)

| Workflow | Purpose | Trigger | Key Features |
|----------|---------|---------|--------------|
| **Network Infrastructure** | Deploy VPC/VNet and networking | Manual + Push | Multi-cloud, shared actions |
| **Kubernetes Clusters** | Deploy AKS/EKS clusters | Manual + Push | Dependency checking, parallel deployment |
| **Kubernetes Add-ons** | Deploy cluster addons | Manual | Comprehensive addon management |
| **Platform Engineering** | Deploy Backstage + Crossplane | Manual | Platform tooling |

### Phase 2 Workflows (Advanced)

| Workflow | Purpose | Trigger | Key Features |
|----------|---------|---------|--------------|
| **Infrastructure Orchestrator** | Full environment deployment | Manual | Dependency resolution, parallel execution |
| **Environment Promotion** | Promote between environments | Manual | Config diff, approval gates, validation |

## 🔧 **Common Parameters**

### Required Parameters
- **cloud_provider**: `aws` or `azure`
- **environment**: `dev`, `staging`, or `prod`
- **action**: `plan`, `apply`, or `destroy`

### Optional Parameters
- **cluster_name**: Specific cluster to target (leave empty for all)
- **components**: Comma-separated list for orchestrator
- **force_sequential**: Disable parallel execution
- **auto_approve**: Skip manual approval gates

## 📊 **Monitoring Workflow Status**

### Check Running Workflows
```bash
# List all workflow runs
gh run list --limit 10

# Watch specific run
gh run watch <run-id>

# Check specific workflow
gh run list --workflow="Infrastructure Orchestrator" --limit 5
```

### View Workflow Logs
```bash
# View logs for specific run
gh run view <run-id> --log

# View logs for specific job
gh run view <run-id> --log --job=<job-name>
```

## 🎯 **Best Practices**

### 1. Development Workflow
```bash
# 1. Always plan first
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network" \
  --field action=plan \
  --field cloud_provider=azure

# 2. Apply after reviewing plan
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network" \
  --field action=apply \
  --field cloud_provider=azure

# 3. Deploy incrementally
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network,clusters" \
  --field action=apply \
  --field cloud_provider=azure
```

### 2. Production Deployment
```bash
# 1. Validate in staging first
gh workflow run "Environment Promotion" \
  --field source_environment=dev \
  --field target_environment=staging \
  --field components="network,clusters,addons" \
  --field cloud_provider=azure

# 2. Promote to production (requires approval)
gh workflow run "Environment Promotion" \
  --field source_environment=staging \
  --field target_environment=prod \
  --field components="network,clusters,addons" \
  --field cloud_provider=azure
```

### 3. Emergency Procedures
```bash
# Quick rollback (destroy and redeploy)
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="addons" \
  --field action=destroy \
  --field cloud_provider=azure

# Force sequential for troubleshooting
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="clusters" \
  --field action=apply \
  --field cloud_provider=azure \
  --field force_sequential=true
```

## 🔍 **Troubleshooting**

### Common Issues

#### 1. Workflow Not Found
```bash
# Check if workflow exists
gh workflow list | grep "Infrastructure Orchestrator"

# Wait for GitHub to register new workflows (can take 2-3 minutes)
```

#### 2. Dependency Failures
```bash
# Check orchestration state
gh run view <orchestrator-run-id> --log --job=orchestration-plan

# Deploy dependencies first
gh workflow run "Infrastructure Orchestrator" \
  --field target_environment=dev \
  --field components="network" \
  --field action=apply \
  --field cloud_provider=azure
```

#### 3. Permission Issues
```bash
# Ensure you have workflow dispatch permissions
gh auth status

# Check repository permissions
gh repo view msdp-platform/msdp-devops-infrastructure
```

### Getting Help

#### 1. Check Workflow Status
```bash
# View recent failures
gh run list --status=failure --limit 5

# Get detailed error information
gh run view <failed-run-id> --log
```

#### 2. Review Configuration
```bash
# Check environment configuration
cat config/dev.yaml

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('config/dev.yaml'))"
```

## 📚 **Additional Resources**

- **Phase 1 Completion Summary**: `docs/implementation-notes/PIPELINE_REFACTORING_COMPLETION.md`
- **Phase 2 Orchestration Plan**: `docs/implementation-notes/PHASE_2_ORCHESTRATION_PLAN.md`
- **Testing Results**: `docs/implementation-notes/TESTING_VALIDATION_RESULTS.md`
- **Configuration Reference**: `config/dev.yaml`

## 🆘 **Emergency Contacts**

- **Platform Team**: @platform-team
- **Infrastructure Issues**: Create issue with `infrastructure` label
- **Workflow Failures**: Create issue with `ci-cd` label

---

**Last Updated**: 2025-09-19  
**Version**: 2.0 (Phase 2 Advanced Orchestration)
