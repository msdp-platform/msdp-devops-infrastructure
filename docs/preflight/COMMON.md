# Preflight – Common Prerequisites

Use this checklist before provisioning EKS/AKS in any environment (dev, sit, prod).

## Identity & CI/CD

- [ ] GitHub OIDC federation configured (Owner: Security)

Verify:
```bash
# AWS: OIDC provider exists (token.actions.githubusercontent.com)
aws iam list-open-id-connect-providers
# Inspect specific provider
aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com

# Azure: Federated credentials on App Registration (CI principal)
az ad app federated-credential list --id <APP_ID> -o table
```

- [ ] CI/CD roles/permissions are least-privilege (Owner: Security)

Verify:
```bash
# AWS: Check role and attached policies for GH Actions
aws iam get-role --role-name <gha-role>
aws iam list-attached-role-policies --role-name <gha-role>

# Azure: Role assignments for CI principal
az role assignment list --assignee <principalId> --scope /subscriptions/<SUB_ID> -o table
```

## Networking & DNS

- [ ] CIDR plan (non-overlapping across env/cloud) approved (Owner: Networking)

Verify:
```bash
# Example: show configured CIDRs from YAML (adjust path/keys)
yq '.network.cidrs' infrastructure/config/globals.yaml
# Quick overlap test (edit CIDRs inline)
python - <<'PY'
import ipaddress as i
cidrs=["10.10.0.0/16","10.20.0.0/16"]
print("overlap?", any(i.ip_network(a).overlaps(i.ip_network(b)) for a in cidrs for b in cidrs if a!=b))
PY
```

- [ ] Public DNS zone present (Route53 or Azure DNS) (Owner: Platform)

Verify:
```bash
# AWS Route53
aws route53 list-hosted-zones --query 'HostedZones[].{Name:Name,Id:Id}'
# Azure DNS
az network dns zone list -o table
```

## State & Tooling

- [ ] Terraform remote state backend and locking exist (Owner: Platform)

Verify:
```bash
# AWS: S3 bucket + DynamoDB table
aws s3 ls s3://<TF_STATE_BUCKET>
aws dynamodb describe-table --table-name <TF_LOCKS>

# Azure: Storage account container + Table
az storage container list --account-name <STORAGE_ACCOUNT> -o table
az storage table list --account-name <STORAGE_ACCOUNT> -o table
```

- [ ] Required CLIs available/pinned (Owner: Platform)

Verify:
```bash
terraform -v   # >= 1.5.0
aws --version
az version
gh --version
kubectl version --client
```

## Capacity & Naming

- [ ] Quotas/capacity sufficient (IPs, cores, NAT/LB) (Owner: Platform)

Verify:
```bash
# AWS quotas (examples)
aws service-quotas list-service-quotas --service-code ec2 --query 'Quotas[?contains(Name, `VPC`)||contains(Name, `NAT`)||contains(Name, `Elastic IP`)]'
# Azure cores in region
az vm list-usage -l uksouth -o table
```

- [ ] Naming/tags align with dictionary.yaml (Owner: Platform)

Verify:
```bash
# Render key fields from YAML and confirm kebab-case
yq '{org: .org, env: .env, cloud: .cloud, region: .region}' infrastructure/config/local.yaml
# Example name preview: {org}-{env}-{cloud}-{region}
```

## GitHub Actions prerequisites

| Item | Purpose | Scope | How/Where | Notes |
|---|---|---|---|---|
| Fine-grained workflow permissions | Allow OIDC and GHCR push | Per workflow | Set `permissions` in workflow | contents: read; id-token: write; packages: write |
| AWS OIDC trust (role) | Keyless auth for TF/CLI | Per env/account | Create IAM role with OIDC trust | Limit `sub` to repo/branch or env |
| AWS role policy | Least-privilege TF backend + plan/apply | Per role | Attach inline policy | Split plan vs apply roles if desired |
| Azure OIDC (federated credential) | Keyless auth for TF/CLI | Per env/subscription | AAD App Reg + federated credential | Use azure/login with OIDC |
| Azure role assignments | TF apply scope | RG/subnet/ACR | Assign PrincipalId roles | Prefer least-privilege over Contributor |
| Required repo/environment vars | Drive actions and backends | Repo/env | Settings → Variables | No cloud secrets required for OIDC |
| GHCR permissions | Push/pull images | Repo/org | Enable packages: write | No PAT needed; uses GITHUB_TOKEN |
| Build matrix | Map env→backend and region | Workflow | strategy.matrix | Keeps stacks isolated |

Minimal workflow permissions:
```yaml
permissions:
  contents: read
  id-token: write
  packages: write
```

AWS OIDC trust policy (assume-role trust relationship):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDC",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:msdp-platform/<REPO>:ref:refs/heads/<BRANCH>"
        }
      }
    }
  ]
}
```

AWS example role policy (backend + read-only plan; expand for apply):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "TFStateS3",
      "Effect": "Allow",
      "Action": ["s3:ListBucket","s3:GetObject","s3:PutObject","s3:DeleteObject"],
      "Resource": ["arn:aws:s3:::<TF_STATE_BUCKET>","arn:aws:s3:::<TF_STATE_BUCKET>/*"]
    },
    { "Sid": "TFStateLockDDB",
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem","dynamodb:PutItem","dynamodb:UpdateItem","dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:<REGION>:<ACCOUNT_ID>:table/<TF_LOCKS>"
    },
    { "Sid": "ReadForPlan",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*","eks:Describe*","iam:Get*","iam:List*","route53:List*","logs:Describe*","kms:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
```

Azure OIDC federated credential (attach to App Registration):
```json
{
  "name": "gh-oidc-dev",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:msdp-platform/<REPO>:ref:refs/heads/<BRANCH>",
  "audiences": ["api://AzureADTokenExchange"]
}
```

Azure login step (uses OIDC, no client secret):
```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ vars.AZURE_CLIENT_ID }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

Required GitHub variables/secrets (suggest repo-level variables; environment overrides allowed):

| Name | Type | Used by | Example |
|---|---|---|---|
| AWS_ACCOUNT_ID | Variable | aws-actions/configure-aws-credentials | 123456789012 |
| AWS_ROLE_TO_ASSUME_ARN | Variable | aws-actions/configure-aws-credentials | arn:aws:iam::123456789012:role/gha-terraform-dev |
| AWS_REGION | Variable | Workflows | eu-west-1 |
| AZURE_CLIENT_ID | Variable | azure/login | 00000000-0000-0000-0000-000000000000 |
| AZURE_TENANT_ID | Variable | azure/login | 00000000-0000-0000-0000-000000000000 |
| AZURE_SUBSCRIPTION_ID | Variable | azure/login | 00000000-0000-0000-0000-000000000000 |
| TF_STATE_BUCKET | Variable | Terraform backend (AWS) | msdp-tf-state-dev |
| TF_LOCKS_TABLE | Variable | Terraform backend (AWS) | msdp-tf-locks-dev |
| TF_AZURE_STORAGE_ACCOUNT | Variable | Terraform backend (Azure) | msdptfstateprod |
| TF_AZURE_CONTAINER | Variable | Terraform backend (Azure) | tfstate |
| BASE_DOMAIN | Variable | external-dns/cert-manager | example.com |
| GHCR_ORG | Variable | build/push | ghcr.io/msdp-platform |

Minimal build matrix (env → backend/region mapping):

| env | cloud | region | backend | backend config |
|---|---|---|---|---|
| dev | aws | eu-west-1 | s3+dynamodb | bucket=${{ vars.TF_STATE_BUCKET }} table=${{ vars.TF_LOCKS_TABLE }} |
| sit | aws | eu-west-1 | s3+dynamodb | bucket=msdp-tf-state-sit table=msdp-tf-locks-sit |
| prod | aws | eu-west-1 | s3+dynamodb | bucket=msdp-tf-state-prod table=msdp-tf-locks-prod |
| dev | azure | uksouth | az storage+table | account=${{ vars.TF_AZURE_STORAGE_ACCOUNT }} container=${{ vars.TF_AZURE_CONTAINER }} |
| sit | azure | uksouth | az storage+table | account=msdptfstate container=tfstate |
| prod | azure | uksouth | az storage+table | account=msdptfstateprod container=tfstate |
