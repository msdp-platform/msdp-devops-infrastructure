# Terraform Backend (Provision/Configure)

Distributed reusable action to provision Terraform backend resources per environment with support for shared DynamoDB lock tables.

## Naming Rules
- **Bucket**: `<repo>-<project>-<env>-<function>-<aws-account-id>-<region_short>` (≤63 chars, truncated if needed)
- **Object key**: `<repo_shortname>/<project>/<env>/<cloud_segment>/<app>/<pipeline_name>.tfstate`
- **Pipeline name**: `tf-{repo}-{env}-{cloud}-{app}-{hash8}` (stable, computed from inputs)
- **DynamoDB table** (shared mode, default): `tfstate-locks-{aws-account-id}-{region_short}`
- **DynamoDB table** (legacy mode): `<bucket>-locks`
- All names persist once created (stored in backend-config.json for idempotency)

## AWS Backend Features
- **S3 bucket** with versioning enabled and server-side encryption (AES256)
- **Shared DynamoDB lock table** (default) or per-bucket table (legacy)
- **Point-in-Time Recovery** enabled on DynamoDB tables (with graceful fallback)
- **PAY_PER_REQUEST billing** for DynamoDB tables
- **Comprehensive tagging**: Repo, Project, Environment, App, Function
- **Region mapping**: `eu-west-1` → `euw1`, `us-east-1` → `use1`, etc.

## Outputs
- `infrastructure/environment/<env>/backend/backend-config.json` with:
  - `bucket`: S3 bucket name
  - `key`: State file object key
  - `region`: AWS region
  - `dynamodb_table`: DynamoDB lock table name
  - `pipeline_name`: Stable pipeline identifier

## Usage (from any repo)

```yaml
permissions:
  contents: read
  id-token: write

steps:
  - uses: actions/checkout@v4

  - name: Cloud Login
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/cloud-login@main
    with:
      aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: eu-west-1
      azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

  - name: Provision backend
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/terraform-backend@main
    with:
      repo-shortname: infra
      project: msdp
      env: dev
      app: crossplane
      function: tfstate
      cloud: aws
      cloud-segment: aws
      # aws-account-id: ${{ secrets.AWS_ACCOUNT_ID }}  # Optional: auto-resolved from config files
      aws-region: eu-west-1
      use-shared-lock-table: "true"
      # lock-table-name: "custom-locks"  # Optional: custom table name

  - name: Terraform Init
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/terraform-init@main
    with:
      working-directory: infrastructure/environment/dev/aws/eks
      backend-config-file: infrastructure/environment/dev/backend/backend-config.json
```

## AWS Account ID Auto-Resolution

The action can automatically resolve the AWS account ID from your configuration files, eliminating the need for hardcoded secrets or manual input.

### Auto-Resolution Order
1. **Input Parameter**: If `aws-account-id` is provided, it takes precedence
2. **local.yaml**: Environment-specific overrides
3. **globals.yaml**: Global configuration (default location)
4. **dictionary.yaml**: Fallback configuration

### Supported Keys
The action searches for these keys in order:
- `aws_account_id`
- `account_id` 
- `aws.account_id`
- `accounts.aws_account_id` (for nested structures)

### Example Configuration
```yaml
# globals.yaml
accounts:
  aws_account_id: "319422413814"

# local.yaml (overrides globals.yaml)
aws_account_id: "123456789012"
```

### Usage
```yaml
# Auto-resolve from config files (recommended)
- uses: ./.github/actions/terraform-backend
  with:
    # aws-account-id: # Omit to auto-resolve

# Explicit override
- uses: ./.github/actions/terraform-backend
  with:
    aws-account-id: "123456789012"  # Overrides config files
```

## Shared Lock Table Configuration

### Benefits of Shared Lock Tables
- **Cost reduction**: Single table per account/region vs multiple per-bucket tables
- **Better monitoring**: Centralized lock table management and metrics
- **Consistent locking**: All pipelines use the same table for state locking
- **Enhanced backup**: Point-in-Time Recovery protection for state locks

### Configuration Options

#### Shared Lock Table (Default)
```yaml
use-shared-lock-table: "true"
# Results in: tfstate-locks-{account-id}-{region_short}
# Example: tfstate-locks-319422413814-euw1
```

#### Custom Lock Table Name
```yaml
use-shared-lock-table: "true"
lock-table-name: "my-custom-locks"
# Uses your custom table name
```

#### Legacy Per-Bucket Tables
```yaml
use-shared-lock-table: "false"
# Results in: {bucket-name}-locks
# Example: infra-msdp-dev-tfstate-319422413814-euw1-locks
```

### Region Mapping
- `eu-west-1` → `euw1`
- `eu-west-2` → `euw2`
- `eu-central-1` → `euc1`
- `us-east-1` → `use1`
- `us-west-2` → `usw2`
- Unmapped regions use full region name

## Governance
- Encryption, versioning, and tagging enforced centrally
- DevOps team owns backend provisioning patterns
- Safe to re-run (idempotent)
- Shared lock tables reduce DynamoDB costs and improve monitoring
