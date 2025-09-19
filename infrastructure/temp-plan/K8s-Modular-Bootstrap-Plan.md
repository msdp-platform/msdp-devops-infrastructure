Step 1 — Terraform: multi-cloud, modular provisioning

- Scope:
  - Providers: AWS, Azure, GCP (one at a time; identical module shapes).
  - Modules:
    - common: naming/tags from `dictionary.yaml` + `globals.yaml`
    - aws: network (VPC/subnets), eks, iam
    - azure: network (VNet/subnets), aks, managed identity/role
    - gcp: network (VPC/subnets), gke, iam
  - Stacks layout (by cloud/env): `stacks/{cloud}/{env}/main.tf` references modules.
- Inputs (contract):
  - org, env, cloud, region, base_domain (from YAML)
  - accounts/subscription IDs
  - route53 zone id (if Route53), or use Cloud DNS/Azure DNS later
- Outputs (contract):
  - kubeconfig path/secret
  - cluster_name, nodepool info
  - ingress class, DNS zone info
  - registry endpoint (GHCR by default)
- Tests (per env):
  - validate → plan → tflint/checkov (no drift)
  - minimal apply in dev → kubectl get nodes → deploy hello-world in `namespace={env}-{bu}-{app}`
- Decisions to confirm:
  - First cloud + region; Terraform backend (S3+Dynamo or Azure storage/table or GCS)

Step 2 — Runtime values generator (Python CLI)

- Purpose: generate deployment-time values uniformly for all tools.
- CLI: msdpctl (or `scripts/gen_values.py`)
- Reads:
  - `infrastructure/config/dictionary.yaml`
  - `infrastructure/config/globals.yaml`
  - `infrastructure/config/local.yaml`
- Generates (artifacts only, no apply):
  - Helm values snippet (image repo/tag, env overrides, ingress host, resources)
  - ArgoCD Application parameters (app name, namespace, path, revision)
  - Karpenter/KEDA fragments (when applicable)
  - ExternalDNS annotations host
- Flags:
  - `--cloud`, `--env`, `--region`, `--bu`, `--app`, `--owner`, `--out ./artifacts`
  - `--dry-run` prints derived names (cluster_name, namespace, dns_host)
- Tests:
  - unit test: render all derived fields without violating constraints
  - integration dry-run: produce artifacts for a sample app; no external calls

Step 3 — Reusable GitHub Actions pipelines (workflow_call)

- Pipelines:
  - terraform-reusable: validate → plan → (gated) apply → (optional) destroy
  - build-push-reusable: build → trivy scan → push to GHCR → optional cosign sign
  - deploy-reusable: generate-values → open PR to GitOps repo or path → optional ArgoCD sync
- Orchestrator workflow:
  - Inputs: cloud, env, region, bu, app, approve_gates
  - Jobs (gates between):
    1) tf-validate-plan (always)
    2) tf-apply (manual gate or env-protection)
    3) build-scan-push (GHCR)
    4) gen-values → PR to GitOps (app-of-apps or app chart values)
    5) argocd-sync (auto in dev; manual approval in stg/prod)
- Auth:
  - OIDC from GitHub to cloud (no long-lived keys)
  - GHCR read/pull via imagePullSecret or cloud-native identity (if mirrored later)
- Tests:
  - dry-run jobs on PR
  - full path in dev on merge to dev branch

Promotion and rollback

- Promotion: dev → stg → prod via PR approvals; immutable tags (semver+shortsha)
- Rollback: TF apply gated; ArgoCD app rollback to previous revision; Helm release history preserved

Minimal next decisions to proceed

- Choose first cloud + region to implement Step 1 (recommend Azure uksouth or AWS us-east-1)
- Confirm Terraform backend for state
- Confirm GHCR org path (`ghcr.io/msdp-platform/{bu}/{app}` or flat)
- Confirm ArgoCD lives in which repo/path (infra repo vs separate GitOps repo)

If you approve this shape, I’ll rewrite the temporary plan file to exactly this 3-step structure and stop (no code).
