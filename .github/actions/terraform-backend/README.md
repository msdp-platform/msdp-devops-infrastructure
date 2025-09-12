# Terraform Backend (Provision/Configure)

Distributed reusable action to provision Terraform backend resources per environment.

## Naming Rules
- Bucket: `<function>-<4digit_random>` (e.g., tfstate-4721)
- Object key: `<repo_shortname>/<project>/<env>/<app>/terraform.tfstate`
- DynamoDB table: `<bucket>-locks` (e.g., tfstate-4721-locks)
- Random suffix persists once created (stored in backend-config.json for idempotency)

## AWS Backend Features
- S3 bucket with versioning enabled
- Server-side encryption (AES256)
- Lifecycle rule (cleanup incomplete multipart uploads)
- DynamoDB table with LockID primary key (PAY_PER_REQUEST billing)
- Tags: Repo, Project, Env, App, Function applied to all resources

## Outputs
- `infrastructure/environment/<env>/backend/backend-config.json` with bucket, key, region, dynamodb_table

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

  - name: Terraform Init
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/terraform-init@main
    with:
      working-directory: infrastructure/environment/dev/aws/eks
      backend-config-file: infrastructure/environment/dev/backend/backend-config.json
```

## Governance
- Encryption, versioning, and tagging enforced centrally
- DevOps team owns backend provisioning patterns
- Safe to re-run (idempotent)
