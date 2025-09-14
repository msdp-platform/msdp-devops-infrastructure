# Copilot Instructions for msdp-devops-infrastructure

This repository manages organization-wide DevOps infrastructure for multi-cloud (Azure, AWS) environments using Terraform, Docker, and GitHub Actions. AI agents should follow these guidelines for effective contributions:

## Architecture Overview

- **Environment Structure**: Infrastructure is organized by cloud (`azure`, `aws`), environment (`dev`, etc.), and component (`aks`, `network`).
- **Terraform Modules**: Reusable modules live under `infrastructure/terraform/modules/`. Environment-specific stacks are under `infrastructure/environment/<env>/<cloud>/<component>/`.
- **Networking**: VNet/subnet stacks are separate from compute (AKS/EKS) stacks. Compute stacks resolve subnet IDs via remote state outputs or naming/tag conventions.
- **CI/CD**: All reusable GitHub Actions are in `.github/actions/`. Reference actions using full repo path and pin tags after release.

## Key Workflows

- **Provisioning**: Use the `terraform-backend` action to provision S3/DynamoDB backend resources. Backend config is stored in `backend/backend-config.json` per environment.
- **Initialization**: Use the `terraform-init` action to install Terraform and run `terraform init` with optional backend config.
- **Cloud Login**: Use the `cloud-login` action for OIDC-based AWS/Azure authentication. Never hardcode secrets; pass via workflow inputs.
- **Docker Builds**: Use the `docker-build` action for building/pushing images to GHCR/ECR/ACR. Cloud login is handled separately.
- **Kubernetes**: AKS/EKS stacks do not create networking resources; ensure VNet/subnet is provisioned first. Subnet resolution is prioritized: remote state > name pattern > tag lookup.

## Project Conventions

- **Naming**: Buckets, tables, and pipeline names follow strict patterns for idempotency and traceability. See `terraform-backend/README.md` for details.
- **Tagging**: All resources are tagged for governance. AKS module supports comprehensive tagging.
- **Matrix Deployments**: Multiple clusters/environments are defined in `config/envs/<env>.yaml`.
- **Validation**: Stacks fail fast with clear error messages if required resources (e.g., subnets) are missing or ambiguous.

## Integration Points

- **Remote State**: Compute stacks read outputs from network stacks via remote state (S3/DynamoDB).
- **OIDC Auth**: All cloud access is via OIDC; workflows require `id-token: write` permission.
- **External Registries**: Docker builds support GHCR, ECR, and ACR.

## Examples

- See `infrastructure/environment/azure/aks/README.md` and `infrastructure/terraform/modules/azure/aks/README.md` for AKS deployment patterns.
- See `.github/actions/terraform-backend/README.md` for backend provisioning and naming rules.
- See `.github/actions/docker-build/README.md` for Docker build/push usage.

## Patterns to Follow

- Always use reusable actions for cloud login, backend provisioning, and Terraform init.
- Never duplicate networking logic in compute stacks; always resolve via remote state or naming/tag conventions.
- Pin action versions after release (avoid `@main` in production).
- Validate all required resources before running apply steps.

---

For unclear or missing conventions, consult the relevant README in the stack or action directory. If a workflow or pattern is ambiguous, ask for clarification or propose improvements in a PR.
