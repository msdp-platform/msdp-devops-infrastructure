Reusable Docker Build Pipelines

Overview
- This repo provides a composite action and a reusable workflow to build and push Docker images to GHCR, ECR, and ACR using GitHub Actions.
- Authentication is OIDC-based for AWS and Azure; GHCR uses GITHUB_TOKEN (packages: write).

Components
- Composite action: .github/actions/docker-build/action.yml
  - Directly builds and pushes images; supports caching, extra tags, OCI labels, and post-push verification.
- Reusable workflow: .github/workflows/docker-build.yml
  - Thin wrapper around the composite; call from other repos via `workflow_call`.
- Cloud login (optional): .github/actions/cloud-login/action.yml
  - Logs into AWS and/or Azure using OIDC. The docker-build action can be used after calling this.

Caller Permissions
- contents: read
- packages: write (for GHCR)
- id-token: write (when using OIDC for ECR/ACR)

Secrets
- ECR: AWS_ROLE_ARN (OIDC assume role)
- ACR: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID (OIDC)

Usage — Reusable Workflow
- GHCR:
  - name: Docker build
    uses: msdp-platform/msdp-devops-infrastructure/.github/workflows/docker-build.yml@dev
    with:
      registry: ghcr
      repository: myapp
      context: .
      file: ./Dockerfile
      platforms: linux/amd64
      push: true
      tags: latest

- ECR (OIDC):
  - name: Docker build
    uses: msdp-platform/msdp-devops-infrastructure/.github/workflows/docker-build.yml@dev
    with:
      registry: ecr
      repository: my/repo
      aws_region: eu-west-1
      use_cloud_login: true
      push: true
      tags: latest
    secrets:
      AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}

- ACR (OIDC):
  - name: Docker build
    uses: msdp-platform/msdp-devops-infrastructure/.github/workflows/docker-build.yml@dev
    with:
      registry: acr
      acr_name: myacr
      repository: team/app
      use_cloud_login: true
      push: true
      tags: latest
    secrets:
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

Verification
- By default, the composite action verifies that pushed tags exist by running `docker buildx imagetools inspect` on each tag.
- Set `verify: false` in inputs to skip this check (not recommended).

Troubleshooting
- GHCR: ensure the workflow has `packages: write` permission.
- ECR: IAM role trust must allow GitHub OIDC; set `AWS_ROLE_ARN` and `id-token: write` permission.
- ACR: Entra Application must be configured for federated credentials; pass Azure OIDC secrets and `id-token: write` permission.

