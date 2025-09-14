# Terraform Backend Naming Convention & Configuration Strategy

## Overview

This document defines the comprehensive naming convention and configuration strategy for Terraform backends across the MSDP organization, ensuring consistency, scalability, and conflict prevention.

## **Core Principles**

1. **Hierarchical Structure**: Logical grouping from broad to specific
2. **Predictable Patterns**: Anyone should be able to guess the correct name
3. **Conflict Prevention**: Unique identifiers at every level
4. **Self-Documenting**: Names should tell you what they contain
5. **Scalable**: Works for 1 team or 100 teams
6. **Tool Friendly**: Compatible with automation and tooling

## **Naming Convention Framework**

### **1. S3 Bucket Naming**

#### **Pattern**:
```
tf-state-{org}-{account-type}-{region-code}-{suffix}
```

#### **Examples**:
```
tf-state-msdp-dev-euw1-a1b2c3d4     # Development account
tf-state-msdp-prod-euw1-e5f6g7h8    # Production account
tf-state-msdp-shared-euw1-i9j0k1l2  # Shared services account
```

#### **Components**:
- `tf-state`: Fixed prefix for all Terraform state buckets
- `{org}`: Organization identifier (msdp)
- `{account-type}`: Account purpose (dev, staging, prod, shared, sandbox)
- `{region-code}`: AWS region short code (euw1, use1, aps1)
- `{suffix}`: 8-character deterministic hash for uniqueness

#### **Region Code Mapping**:
```yaml
region_codes:
  eu-west-1: euw1
  eu-west-2: euw2
  eu-central-1: euc1
  us-east-1: use1
  us-east-2: use2
  us-west-1: usw1
  us-west-2: usw2
  ap-south-1: aps1
  ap-southeast-1: apse1
  ap-southeast-2: apse2
```

### **2. DynamoDB Lock Table Naming**

#### **Pattern**:
```
tf-locks-{org}-{account-type}-{region-code}
```

#### **Examples**:
```
tf-locks-msdp-dev-euw1      # Development locks
tf-locks-msdp-prod-euw1     # Production locks
tf-locks-msdp-shared-euw1   # Shared services locks
```

#### **Rationale**:
- One lock table per account/region combination
- Shared across all Terraform states in that account
- Simpler management and cost optimization

### **3. State Key Structure**

#### **Pattern**:
```
{platform}/{component}/{environment}/{region?}/{instance?}/terraform.tfstate
```

#### **Examples**:
```
# Network Infrastructure
azure/network/dev/terraform.tfstate
azure/network/staging/terraform.tfstate
azure/network/prod/terraform.tfstate

# AKS Clusters
azure/aks/dev/cluster-01/terraform.tfstate
azure/aks/dev/cluster-02/terraform.tfstate
azure/aks/prod/primary/terraform.tfstate

# AWS Infrastructure
aws/eks/dev/terraform.tfstate
aws/vpc/prod/us-east-1/terraform.tfstate

# Shared Services
shared/monitoring/prod/terraform.tfstate
shared/dns/prod/terraform.tfstate
shared/backup/prod/terraform.tfstate
```

#### **Components**:
- `{platform}`: Cloud platform (azure, aws, gcp, shared)
- `{component}`: Infrastructure component (network, aks, eks, monitoring)
- `{environment}`: Environment (dev, staging, prod, sandbox)
- `{region}`: Optional region for multi-region deployments
- `{instance}`: Optional instance identifier for multiple instances

### **4. Pipeline/Workflow Naming**

#### **Pattern**:
```
{platform}-{component}-{environment}
```

#### **Examples**:
```
azure-network-dev          # Azure network for dev
azure-aks-dev             # Azure AKS for dev
aws-eks-prod               # AWS EKS for prod
shared-monitoring-prod     # Shared monitoring for prod
```

## **Configuration Strategy**

### **1. Configuration File Structure**

```
config/
├── global/
│   ├── naming.yaml           # Global naming conventions
│   ├── accounts.yaml         # Account mappings
│   └── regions.yaml          # Region configurations
├── environments/
│   ├── dev.yaml             # Development environment
│   ├── staging.yaml         # Staging environment
│   └── prod.yaml            # Production environment
└── components/
    ├── network.yaml         # Network component defaults
    ├── aks.yaml            # AKS component defaults
    └── monitoring.yaml      # Monitoring component defaults
```

### **2. Global Naming Configuration**

```yaml
# config/global/naming.yaml
organization:
  name: msdp
  full_name: "Microsoft Developer Platform"
  
naming_conventions:
  s3_bucket:
    prefix: "tf-state"
    pattern: "{prefix}-{org}-{account_type}-{region_code}-{suffix}"
    max_length: 63
    
  dynamodb_table:
    prefix: "tf-locks"
    pattern: "{prefix}-{org}-{account_type}-{region_code}"
    
  state_key:
    pattern: "{platform}/{component}/{environment}/{region?}/{instance?}/terraform.tfstate"
    
  pipeline:
    pattern: "{platform}-{component}-{environment}"

platforms:
  - azure
  - aws
  - gcp
  - shared

components:
  azure:
    - network
    - aks
    - storage
    - keyvault
  aws:
    - vpc
    - eks
    - s3
    - iam
  shared:
    - monitoring
    - dns
    - backup
    - security

environments:
  - dev
  - staging
  - prod
  - sandbox

account_types:
  - dev
  - staging
  - prod
  - shared
  - sandbox
  - security
```

### **3. Account Configuration**

```yaml
# config/global/accounts.yaml
accounts:
  aws:
    dev:
      account_id: "319422413814"
      region: "eu-west-1"
      purpose: "Development and testing"
    prod:
      account_id: "123456789012"
      region: "eu-west-1"
      purpose: "Production workloads"
    shared:
      account_id: "234567890123"
      region: "eu-west-1"
      purpose: "Shared services and tools"
      
  azure:
    dev:
      subscription_id: "ecd977ed-b8df-4eb6-9cba-98397e1b2491"
      tenant_id: "your-tenant-id"
      region: "uksouth"
    prod:
      subscription_id: "prod-subscription-id"
      tenant_id: "your-tenant-id"
      region: "uksouth"
```

### **4. Environment-Specific Configuration**

```yaml
# config/environments/dev.yaml
environment:
  name: dev
  full_name: "Development"
  account_type: dev
  
backend:
  aws:
    account_id: "319422413814"
    region: "eu-west-1"
    
azure:
  subscription_id: "ecd977ed-b8df-4eb6-9cba-98397e1b2491"
  tenant_id: "your-tenant-id"
  location: "uksouth"
  
  # Network configuration
  network:
    resource_group: "rg-network-dev"
    vnet_name: "vnet-msdp-dev"
    vnet_cidr: "10.60.0.0/16"
    
  # AKS configuration
  aks:
    clusters:
      - name: "aks-msdp-dev-01"
        size: "medium"
        subnet_name: "snet-aks-dev-01"
      - name: "aks-msdp-dev-02"
        size: "large"
        subnet_name: "snet-aks-dev-02"
```

## **Implementation Strategy**

### **1. Configuration Management Composite Action**

```yaml
# .github/actions/load-config/action.yml
name: "Load Configuration"
description: "Loads and validates configuration for Terraform operations"

inputs:
  environment:
    description: "Environment name (dev, staging, prod)"
    required: true
  platform:
    description: "Platform name (azure, aws, shared)"
    required: true
  component:
    description: "Component name (network, aks, eks)"
    required: true

outputs:
  backend_config:
    description: "Backend configuration JSON"
    value: ${{ steps.generate.outputs.backend_config }}
  resource_config:
    description: "Resource configuration JSON"
    value: ${{ steps.generate.outputs.resource_config }}
  naming_config:
    description: "Naming configuration JSON"
    value: ${{ steps.generate.outputs.naming_config }}
```

### **2. Backend Configuration Generator**

```python
#!/usr/bin/env python3
# scripts/generate-backend-config.py

import yaml
import json
import hashlib
import sys
from pathlib import Path

class BackendConfigGenerator:
    def __init__(self, config_dir="config"):
        self.config_dir = Path(config_dir)
        self.load_global_config()
    
    def load_global_config(self):
        """Load global configuration files"""
        with open(self.config_dir / "global" / "naming.yaml") as f:
            self.naming = yaml.safe_load(f)
        
        with open(self.config_dir / "global" / "accounts.yaml") as f:
            self.accounts = yaml.safe_load(f)
    
    def generate_bucket_name(self, org, account_type, region):
        """Generate S3 bucket name following convention"""
        region_code = self.get_region_code(region)
        
        # Generate deterministic suffix
        suffix_input = f"{org}-{account_type}-{region_code}"
        suffix = hashlib.sha256(suffix_input.encode()).hexdigest()[:8]
        
        pattern = self.naming["naming_conventions"]["s3_bucket"]["pattern"]
        bucket_name = pattern.format(
            prefix=self.naming["naming_conventions"]["s3_bucket"]["prefix"],
            org=org,
            account_type=account_type,
            region_code=region_code,
            suffix=suffix
        )
        
        return bucket_name.lower()
    
    def generate_table_name(self, org, account_type, region):
        """Generate DynamoDB table name following convention"""
        region_code = self.get_region_code(region)
        
        pattern = self.naming["naming_conventions"]["dynamodb_table"]["pattern"]
        table_name = pattern.format(
            prefix=self.naming["naming_conventions"]["dynamodb_table"]["prefix"],
            org=org,
            account_type=account_type,
            region_code=region_code
        )
        
        return table_name
    
    def generate_state_key(self, platform, component, environment, region=None, instance=None):
        """Generate state key following convention"""
        key_parts = [platform, component, environment]
        
        if region:
            key_parts.append(region)
        if instance:
            key_parts.append(instance)
            
        key_parts.append("terraform.tfstate")
        return "/".join(key_parts)
    
    def get_region_code(self, region):
        """Convert AWS region to short code"""
        region_mapping = {
            "eu-west-1": "euw1",
            "eu-west-2": "euw2",
            "eu-central-1": "euc1",
            "us-east-1": "use1",
            "us-east-2": "use2",
            "us-west-1": "usw1",
            "us-west-2": "usw2",
            "ap-south-1": "aps1",
        }
        return region_mapping.get(region, region.replace("-", ""))
    
    def generate_backend_config(self, environment, platform, component, instance=None):
        """Generate complete backend configuration"""
        
        # Load environment config
        env_config_path = self.config_dir / "environments" / f"{environment}.yaml"
        with open(env_config_path) as f:
            env_config = yaml.safe_load(f)
        
        # Get account details
        account_type = env_config["environment"]["account_type"]
        aws_config = env_config["backend"]["aws"]
        account_id = aws_config["account_id"]
        region = aws_config["region"]
        
        # Generate names
        org = self.naming["organization"]["name"]
        bucket_name = self.generate_bucket_name(org, account_type, region)
        table_name = self.generate_table_name(org, account_type, region)
        state_key = self.generate_state_key(platform, component, environment, instance=instance)
        
        # Generate pipeline name
        pipeline_pattern = self.naming["naming_conventions"]["pipeline"]["pattern"]
        pipeline_name = pipeline_pattern.format(
            platform=platform,
            component=component,
            environment=environment
        )
        
        if instance:
            pipeline_name += f"-{instance}"
        
        return {
            "bucket": bucket_name,
            "key": state_key,
            "region": region,
            "dynamodb_table": table_name,
            "encrypt": True,
            "pipeline_name": pipeline_name,
            "account_id": account_id,
            "metadata": {
                "org": org,
                "environment": environment,
                "platform": platform,
                "component": component,
                "instance": instance,
                "account_type": account_type
            }
        }

def main():
    if len(sys.argv) < 4:
        print("Usage: generate-backend-config.py <environment> <platform> <component> [instance]")
        sys.exit(1)
    
    environment = sys.argv[1]
    platform = sys.argv[2]
    component = sys.argv[3]
    instance = sys.argv[4] if len(sys.argv) > 4 else None
    
    generator = BackendConfigGenerator()
    config = generator.generate_backend_config(environment, platform, component, instance)
    
    print(json.dumps(config, indent=2))

if __name__ == "__main__":
    main()
```

### **3. Updated Composite Action**

```yaml
# .github/actions/terraform-backend-enhanced/action.yml
name: "Enhanced Terraform Backend"
description: "Creates Terraform backend using organizational naming conventions"

inputs:
  environment:
    description: "Environment (dev, staging, prod)"
    required: true
  platform:
    description: "Platform (azure, aws, shared)"
    required: true
  component:
    description: "Component (network, aks, eks)"
    required: true
  instance:
    description: "Instance identifier (optional)"
    required: false

outputs:
  backend_config_file:
    description: "Path to generated backend config file"
    value: ${{ steps.generate.outputs.config_file }}
  bucket_name:
    description: "S3 bucket name"
    value: ${{ steps.generate.outputs.bucket_name }}
  state_key:
    description: "Terraform state key"
    value: ${{ steps.generate.outputs.state_key }}

runs:
  using: "composite"
  steps:
    - name: Generate backend configuration
      id: generate
      shell: bash
      run: |
        # Generate backend config using naming conventions
        python3 scripts/generate-backend-config.py \
          "${{ inputs.environment }}" \
          "${{ inputs.platform }}" \
          "${{ inputs.component }}" \
          "${{ inputs.instance }}" > backend-config.json
        
        # Extract values for outputs
        BUCKET=$(jq -r '.bucket' backend-config.json)
        KEY=$(jq -r '.key' backend-config.json)
        REGION=$(jq -r '.region' backend-config.json)
        TABLE=$(jq -r '.dynamodb_table' backend-config.json)
        
        # Create backend directory
        BACKEND_DIR="infrastructure/environment/${{ inputs.environment }}/backend"
        mkdir -p "$BACKEND_DIR"
        
        # Save config file
        CONFIG_FILE="$BACKEND_DIR/backend-config-${{ inputs.platform }}-${{ inputs.component }}.json"
        cp backend-config.json "$CONFIG_FILE"
        
        echo "config_file=$CONFIG_FILE" >> $GITHUB_OUTPUT
        echo "bucket_name=$BUCKET" >> $GITHUB_OUTPUT
        echo "state_key=$KEY" >> $GITHUB_OUTPUT
        
        echo "Generated backend configuration:"
        cat "$CONFIG_FILE" | jq .
    
    - name: Ensure S3 bucket exists
      shell: bash
      run: |
        BUCKET=$(jq -r '.bucket' ${{ steps.generate.outputs.config_file }})
        REGION=$(jq -r '.region' ${{ steps.generate.outputs.config_file }})
        
        if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
          echo "Creating S3 bucket: $BUCKET"
          if [ "$REGION" = "us-east-1" ]; then
            aws s3api create-bucket --bucket "$BUCKET"
          else
            aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
              --create-bucket-configuration LocationConstraint="$REGION"
          fi
          
          # Enable versioning
          aws s3api put-bucket-versioning --bucket "$BUCKET" \
            --versioning-configuration Status=Enabled
          
          # Enable encryption
          aws s3api put-bucket-encryption --bucket "$BUCKET" \
            --server-side-encryption-configuration \
            '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
        fi
    
    - name: Ensure DynamoDB table exists
      shell: bash
      run: |
        TABLE=$(jq -r '.dynamodb_table' ${{ steps.generate.outputs.config_file }})
        
        if ! aws dynamodb describe-table --table-name "$TABLE" 2>/dev/null; then
          echo "Creating DynamoDB table: $TABLE"
          aws dynamodb create-table \
            --table-name "$TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST
        fi
```

## **Usage Examples**

### **1. Azure Network Workflow**

```yaml
# .github/workflows/azure-network.yml
- name: Setup Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: dev
    platform: azure
    component: network

# Results in:
# Bucket: tf-state-msdp-dev-euw1-a1b2c3d4
# Table: tf-locks-msdp-dev-euw1
# Key: azure/network/dev/terraform.tfstate
```

### **2. AKS Cluster Workflow**

```yaml
# .github/workflows/azure-aks.yml
- name: Setup Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: dev
    platform: azure
    component: aks
    instance: cluster-01

# Results in:
# Bucket: tf-state-msdp-dev-euw1-a1b2c3d4 (same as network)
# Table: tf-locks-msdp-dev-euw1 (shared)
# Key: azure/aks/dev/cluster-01/terraform.tfstate
```

## **Benefits of This Strategy**

### **1. Conflict Prevention**
- Unique state keys for every component/environment combination
- Shared lock table prevents concurrent access issues
- Clear ownership boundaries

### **2. Scalability**
- Supports unlimited environments, platforms, and components
- Consistent naming across the organization
- Easy to add new teams and projects

### **3. Discoverability**
- Predictable naming makes resources easy to find
- Self-documenting structure
- Clear hierarchy from general to specific

### **4. Automation Friendly**
- Programmatic generation of all names
- Consistent configuration structure
- Easy integration with CI/CD pipelines

### **5. Cost Optimization**
- Shared DynamoDB tables reduce costs
- Lifecycle policies for old state versions
- Right-sized resources per environment

## **Migration Plan**

### **Phase 1: Implement New Naming Convention**
1. Create configuration files
2. Implement backend config generator
3. Update composite actions
4. Test with development environment

### **Phase 2: Migrate Existing Workloads**
1. Generate new backend configs for existing workflows
2. Migrate state files to new locations
3. Update workflow files
4. Validate all workflows work correctly

### **Phase 3: Cleanup and Documentation**
1. Remove old backend configurations
2. Update documentation
3. Train team on new conventions
4. Implement monitoring and alerting

This strategy provides a solid foundation for scaling Terraform across your organization while maintaining consistency and preventing conflicts.