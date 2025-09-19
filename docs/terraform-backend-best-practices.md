# Terraform Backend Best Practices for Azure Infrastructure

## Overview

This document outlines industry best practices for Terraform backend configuration, specifically for Azure network infrastructure in enterprise environments.

## Backend Storage Options Comparison

### 1. **Azure Storage Account (Native Azure)**
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatemsdpdev"
    container_name       = "tfstate"
    key                  = "network/terraform.tfstate"
  }
}
```

**Pros:**
- Native Azure integration
- Built-in encryption at rest
- Azure RBAC integration
- Blob versioning and soft delete
- Lower latency within Azure regions

**Cons:**
- Azure-specific (vendor lock-in)
- Less mature than S3 for multi-cloud
- Limited cross-region replication options

### 2. **AWS S3 + DynamoDB (Multi-Cloud)**
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-msdp-dev"
    key            = "azure/network/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

**Pros:**
- Industry standard (most mature)
- Excellent versioning and lifecycle policies
- Strong consistency with DynamoDB locking
- Multi-cloud strategy support
- Rich ecosystem and tooling

**Cons:**
- Cross-cloud complexity
- Additional AWS costs
- Network latency for Azure operations

### 3. **Terraform Cloud/Enterprise**
```hcl
terraform {
  cloud {
    organization = "msdp-platform"
    workspaces {
      name = "azure-network-dev"
    }
  }
}
```

**Pros:**
- Managed service (no infrastructure to maintain)
- Built-in collaboration features
- Policy as code (Sentinel)
- Cost estimation and drift detection
- Enterprise governance features

**Cons:**
- Vendor lock-in to HashiCorp
- Subscription costs
- Less control over infrastructure
- Potential compliance concerns

## **Recommended Approach: Hybrid Strategy**

Based on your current setup and industry best practices, I recommend a **hybrid approach** that balances flexibility, security, and operational efficiency.

### **Primary Recommendation: Azure Storage with S3 Backup**

```hcl
# Primary backend: Azure Storage
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-${var.environment}"
    storage_account_name = "tfstate${var.org}${var.environment}${random_id.suffix.hex}"
    container_name       = "tfstate"
    key                  = "${var.component}/${var.environment}/terraform.tfstate"
    
    # Security
    use_azuread_auth = true
    use_oidc        = true
  }
}
```

### **Why This Approach?**

1. **Native Integration**: Stays within Azure ecosystem
2. **Security**: Uses Azure AD authentication and OIDC
3. **Performance**: Lower latency for Azure operations
4. **Compliance**: Easier to meet data residency requirements
5. **Cost Effective**: No cross-cloud data transfer costs

## **Implementation Strategy**

### **1. Storage Account Naming Convention**

```
Pattern: tfstate{org}{env}{suffix}
Examples:
- tfstatemsdpdev1a2b3c (dev environment)
- tfstatemsdpprod4d5e6f (prod environment)
```

### **2. State Key Structure**

```
Pattern: {component}/{environment}/{region?}/terraform.tfstate
Examples:
- network/dev/terraform.tfstate
- aks/dev/cluster-01/terraform.tfstate
- monitoring/prod/terraform.tfstate
```

### **3. Resource Group Strategy**

```
Pattern: rg-terraform-state-{environment}
Examples:
- rg-terraform-state-dev
- rg-terraform-state-prod
```

## **Security Best Practices**

### **1. Authentication & Authorization**

```yaml
# GitHub Actions Environment Variables
env:
  ARM_USE_OIDC: "true"
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### **2. Storage Account Security**

```hcl
resource "azurerm_storage_account" "tfstate" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  
  # Enable versioning
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }
  
  # Network restrictions
  network_rules {
    default_action = "Deny"
    ip_rules       = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
}
```

### **3. RBAC Configuration**

```hcl
# Service Principal for Terraform
resource "azurerm_role_assignment" "terraform_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.terraform_service_principal_id
}

# Read-only access for developers
resource "azurerm_role_assignment" "developers_reader" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.developers_group_id
}
```

## **State Locking Strategy**

### **Option 1: Azure Storage Native Locking**
```hcl
# Azure Storage provides built-in locking via lease mechanism
# No additional configuration needed
```

### **Option 2: External Locking (Redis/Cosmos DB)**
```hcl
# For advanced scenarios requiring custom locking logic
terraform {
  backend "azurerm" {
    # ... storage config
  }
}

# Custom locking implementation
resource "azurerm_cosmosdb_account" "terraform_locks" {
  # Configuration for distributed locking
}
```

## **Multi-Environment Strategy**

### **1. Environment Isolation**

```
Storage Structure:
├── rg-terraform-state-dev/
│   └── tfstatemsdpdev1a2b3c/
│       ├── network/dev/terraform.tfstate
│       └── aks/dev/cluster-01/terraform.tfstate
├── rg-terraform-state-staging/
│   └── tfstatemsdpstaging2b3c4d/
└── rg-terraform-state-prod/
    └── tfstatemsdpprod3c4d5e/
```

### **2. Cross-Environment References**

```hcl
# Use data sources instead of remote state
data "azurerm_virtual_network" "shared" {
  name                = var.vnet_name
  resource_group_name = var.network_resource_group
}

# Avoid remote state dependencies
# data "terraform_remote_state" "network" { ... } # Don't do this
```

## **Backup and Disaster Recovery**

### **1. Automated Backups**

```yaml
# GitHub Actions workflow for state backup
name: terraform-state-backup
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Backup Terraform State
        run: |
          # Copy state files to backup storage account
          az storage blob copy start-batch \
            --source-container tfstate \
            --destination-container tfstate-backup-$(date +%Y%m%d)
```

### **2. Cross-Region Replication**

```hcl
resource "azurerm_storage_account" "tfstate_backup" {
  name                     = "${local.storage_account_name}backup"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.backup_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Automated replication
resource "azurerm_storage_management_policy" "backup" {
  storage_account_id = azurerm_storage_account.tfstate.id
  
  rule {
    name    = "backup-rule"
    enabled = true
    
    filters {
      prefix_match = ["tfstate/"]
      blob_types   = ["blockBlob"]
    }
    
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }
}
```

## **Monitoring and Alerting**

### **1. State File Monitoring**

```hcl
# Monitor state file access
resource "azurerm_monitor_diagnostic_setting" "tfstate" {
  name                       = "tfstate-diagnostics"
  target_resource_id         = azurerm_storage_account.tfstate.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "StorageRead"
  }
  
  enabled_log {
    category = "StorageWrite"
  }
  
  metric {
    category = "Transaction"
    enabled  = true
  }
}
```

### **2. Alerting Rules**

```hcl
resource "azurerm_monitor_metric_alert" "state_access" {
  name                = "terraform-state-unusual-access"
  resource_group_name = azurerm_resource_group.monitoring.name
  scopes              = [azurerm_storage_account.tfstate.id]
  
  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }
}
```

## **Cost Optimization**

### **1. Storage Tiering**

```hcl
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.tfstate.id
  
  rule {
    name    = "lifecycle-rule"
    enabled = true
    
    filters {
      prefix_match = ["tfstate/"]
      blob_types   = ["blockBlob"]
    }
    
    actions {
      base_blob {
        # Move to cool storage after 30 days
        tier_to_cool_after_days_since_modification_greater_than = 30
        # Archive after 90 days
        tier_to_archive_after_days_since_modification_greater_than = 90
        # Delete after 7 years (compliance requirement)
        delete_after_days_since_modification_greater_than = 2555
      }
      
      version {
        # Clean up old versions
        delete_after_days_since_creation = 90
      }
    }
  }
}
```

### **2. Right-Sizing**

```hcl
# Use appropriate replication for each environment
locals {
  replication_type = {
    dev     = "LRS"  # Locally redundant (cheapest)
    staging = "ZRS"  # Zone redundant
    prod    = "GRS"  # Geo redundant (highest availability)
  }
}

resource "azurerm_storage_account" "tfstate" {
  account_replication_type = local.replication_type[var.environment]
  # ... other configuration
}
```

## **Migration Strategy**

### **From S3 to Azure Storage**

```bash
#!/bin/bash
# Migration script from S3 to Azure Storage

# 1. Download current state from S3
terraform state pull > current.tfstate

# 2. Update backend configuration
# Edit backend.tf to use azurerm backend

# 3. Initialize new backend
terraform init -migrate-state

# 4. Verify state integrity
terraform plan

# 5. Update CI/CD pipelines
# Update GitHub Actions workflows
```

### **Rollback Plan**

```bash
#!/bin/bash
# Rollback to S3 if needed

# 1. Backup current Azure state
az storage blob download \
  --container-name tfstate \
  --name network/dev/terraform.tfstate \
  --file backup-azure.tfstate

# 2. Restore S3 backend configuration
# 3. Initialize with S3
terraform init -migrate-state

# 4. Verify and test
terraform plan
```

## **Recommended Implementation for Your Project**

Based on your current setup, here's the specific recommendation:

### **Phase 1: Immediate (Keep S3, Improve Isolation)**
```yaml
# Current approach with better isolation
- name: Setup Terraform Backend
  uses: ./.github/actions/terraform-backend
  with:
    pipeline-name: "azure-network-${var.environment}"  # Better isolation
    key-salt: "infrastructure/environment/azure/network"
    use-shared-lock-table: "true"
```

### **Phase 2: Medium-term (Migrate to Azure Storage)**
```yaml
# New composite action for Azure backend
- name: Setup Azure Terraform Backend
  uses: ./.github/actions/terraform-backend-azure
  with:
    component: "network"
    environment: "dev"
    resource_group: "rg-terraform-state-dev"
```

### **Phase 3: Long-term (Hybrid with Backup)**
```yaml
# Primary: Azure Storage
# Backup: S3 for disaster recovery
- name: Setup Terraform Backend with Backup
  uses: ./.github/actions/terraform-backend-hybrid
  with:
    primary_backend: "azurerm"
    backup_backend: "s3"
```

## **Conclusion**

**For your Azure network infrastructure, I recommend:**

1. **Short-term**: Keep S3 backend but improve state key isolation
2. **Medium-term**: Migrate to Azure Storage backend for better integration
3. **Long-term**: Implement hybrid approach with automated backups

This strategy provides the best balance of:
- **Security**: OIDC authentication, encryption, RBAC
- **Performance**: Native Azure integration
- **Reliability**: Versioning, backups, monitoring
- **Cost**: Optimized storage tiers and replication
- **Compliance**: Data residency and audit trails

The key is to implement this migration gradually, ensuring each phase is stable before moving to the next.