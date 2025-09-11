## Lessons Learned – EKS + Karpenter (Sept 2025)

### Identity & Access
- IRSA must match the running ServiceAccount exactly. Ensure Helm doesn’t recreate the SA (set `serviceAccount.create=false`) and patch/annotate post-install.
- Karpenter controller requires `iam:PassRole` to the node role ARN with `Condition { "iam:PassedToService": "ec2.amazonaws.com" }`.
- Prefer a stable controller role name; avoid Helm-generated role names that change across runs.

### Karpenter Configuration
- Version compatibility matters: pin Karpenter to a version compatible with the cluster (K8s 1.32 → Karpenter v1.1.x).
- NodePool validation:
  - Taint effects must be `NoSchedule | PreferNoSchedule | NoExecute` (not `NO_SCHEDULE`).
  - Don’t use restricted label domains like `karpenter.sh` in metadata.labels.
  - `consolidateAfter` cannot be combined with `consolidationPolicy=WhenUnderutilized`.
- EC2NodeClass selectors should use the cluster tag for SGs: `{ tags: { "kubernetes.io/cluster/<cluster>": "owned" } }`.
- Provide a pre-created InstanceProfile and set Karpenter `settings.aws.defaultInstanceProfile` to avoid ephemeral instance-profile creation loops.

### Add-ons (Blueprints/Helm)
- Core EKS Add-ons (vpc-cni, kube-proxy, coredns) often already exist; choose one:
  - Import into state, or
  - Use `resolve_conflicts_on_create/update = "OVERWRITE"`.
- ExternalDNS IRSA: namespace and SA names must match the trust policy. Keep in a dedicated ns (e.g., `external-dns`) and annotate the SA.
- Webhook readiness: set explicit dependencies and avoid racing Helm installations against an unready API/webhook.

### Cluster & Nodes
- Managed node group sizing must respect `desired <= max` and instance/AMI compatibility (AL2_ARM_64 for Graviton with 1.31/1.32 where needed).
- Keep a small on-demand system node group for control-plane-critical pods; let Karpenter handle the rest.

### CI/CD & Backend
- Use OIDC in Actions with a single admin role; parameterize the TF S3 backend via secrets (no hardcoded bucket/key/region).
- Standardize `terraform init` with backend-configs injected by the pipeline.

### Process & Structure
- Prefer readiness gates for sequencing: wait for cluster → add-ons → Karpenter → NodePools.
- Avoid manual in-console ops; codify all changes (policy attachments, SA annotations) in Terraform.
- Modularize to stay cloud-agnostic: keep core k8s contract separate from cloud-provider adapters (EKS/AKS/GKE).

### Quick Remediations Checklist
- [ ] Karpenter SA annotated to stable controller role (IRSA)
- [ ] Controller policy includes `iam:PassRole` to node role with `iam:PassedToService`
- [ ] Karpenter `defaultInstanceProfile` set
- [ ] NodePools validated (taints, labels, disruption rules)
- [ ] EC2NodeClass SG selector uses cluster tag
- [ ] Add-ons imported or set to OVERWRITE
- [ ] CI uses OIDC and parameterized backend


