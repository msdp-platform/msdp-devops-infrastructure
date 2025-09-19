# Terraform Init (Reusable)

Installs Terraform, runs `terraform init` (with optional backend-config), and validates configuration.

## Usage

```yaml
permissions:
  contents: read

jobs:
  tf-init:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Terraform Init
        uses: msdp-platform/msdp-devops-infrastructure/.github/actions/terraform-init@main
        with:
          working-directory: infrastructure/environment/dev/aws/eks
          terraform-version: "1.13.2"
          backend-config-file: infrastructure/environment/dev/aws/eks/backend.tfvars
```

Notes:
- Pin a released tag (e.g., `@v1`) once published instead of `@main`.
- `var-file` is accepted for future plan/apply steps but not used by this action.
