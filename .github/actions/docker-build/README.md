Docker Build and Push (Composite Action)

Purpose
- Build and push Docker images to GHCR, ECR, or ACR using Buildx, with optional OIDC cloud login handled by your separate `cloud-login` action.
- Adds OCI labels, supports extra tags, caching, and optional post-push manifest verification.

Usage (direct composite)
- Minimal GHCR:
  - uses: msdp-platform/msdp-devops-infrastructure/.github/actions/docker-build@dev
    with:
      registry: ghcr
      repository: myapp
      context: .
      file: ./Dockerfile
      platforms: linux/amd64
      push: true
      tags: latest

- ECR with OIDC (assume role):
  - name: AWS OIDC login
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/cloud-login@dev
    with:
      aws-role-arn: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: eu-west-1
  - uses: msdp-platform/msdp-devops-infrastructure/.github/actions/docker-build@dev
    with:
      registry: ecr
      repository: my/team/app
      context: .
      file: ./Dockerfile
      push: true
      tags: latest
      aws_region: eu-west-1
      verify: true

- ACR with OIDC:
  - name: Azure OIDC login
    uses: msdp-platform/msdp-devops-infrastructure/.github/actions/cloud-login@dev
    with:
      azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  - uses: msdp-platform/msdp-devops-infrastructure/.github/actions/docker-build@dev
    with:
      registry: acr
      acr_name: myacr
      repository: team/app
      context: .
      file: ./Dockerfile
      push: true
      tags: latest
      verify: true

Inputs (most relevant)
- registry: ghcr | ecr | acr
- repository: repo path/name (under registry)
- context, file, platforms: standard Docker params
- push: boolean (default true)
- tags, labels: extra tagging/labels
- cache: boolean (default true)
- verify: boolean (default true) — imagetools inspect each pushed tag
- use_cloud_login: boolean (default false) — if true, calls `./.github/actions/cloud-login`
- aws_region, aws_role_arn, acr_name, azure_*: only when relevant

Permissions/Secrets
- GHCR: packages: write; uses GITHUB_TOKEN for `docker/login-action`.
- ECR: id-token: write; secret `AWS_ROLE_ARN` when using OIDC login.
- ACR: id-token: write; secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` for OIDC login.

