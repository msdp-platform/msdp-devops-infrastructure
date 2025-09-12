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
      aws-account-id: ${{ secrets.AWS_ACCOUNT_ID }}
      aws-region: eu-west-1
      use-shared-lock-table: "true"
      # lock-table-name: "custom-locks"  # Optional: custom table name

  - name: Terraform Init
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/terraform-init@main
    with:
      working-directory: infrastructure/environment/dev/aws/eks
      backend-config-file: infrastructure/environment/dev/backend/backend-config.json
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
