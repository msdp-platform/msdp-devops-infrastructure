# Cloud Login (AWS + Azure via OIDC)

Reusable composite action for organization-wide cloud logins without static keys.

## Usage (from any repo in the org)

```yaml
permissions:
  contents: read
  id-token: write

jobs:
  login-and-verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Cloud Login (AWS + Azure)
        uses: msdp-platform/msdp-devops-infrastructure/.github/actions/cloud-login@main
        with:
          aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: eu-west-1
          azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
          azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - run: aws sts get-caller-identity
      - run: az account show
```

Notes:
- Pin a released tag (e.g., `@v1`) once published instead of `@main`.
- No secrets are hardcoded; pass values via `with:` (typically mapped from repo secrets).
