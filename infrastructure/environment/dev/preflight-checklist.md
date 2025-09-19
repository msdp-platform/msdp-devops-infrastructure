# Preflight – Environment: dev

Follow COMMON, then cloud-specific (EKS/AKS) sections.

## Common

- [ ] OIDC and CI roles validated (Owner: Security)

Verify:
```bash
aws iam list-open-id-connect-providers || true
az ad app federated-credential list --id <APP_ID> -o table || true
```

- [ ] DNS zones exist (Owner: Platform)

Verify:
```bash
aws route53 list-hosted-zones --query 'HostedZones[].Name' || true
az network dns zone list -o table || true
```

- [ ] TF state backends exist (Owner: Platform)

Verify:
```bash
aws s3 ls s3://<TF_STATE_BUCKET> || true
aws dynamodb describe-table --table-name <TF_LOCKS> || true
```

## EKS (if building AWS in dev)

- [ ] VPC + subnets + routes ready (Owner: Networking)

Verify:
```bash
aws ec2 describe-vpcs --region eu-west-1
aws ec2 describe-subnets --region eu-west-1
```

- [ ] IAM OIDC and roles ready (Owner: Security)

Verify:
```bash
aws iam list-open-id-connect-providers
aws iam list-attached-role-policies --role-name <nodeRole>
```

## AKS (if building Azure in dev)

- [ ] RGs + VNet + subnet ready (Owner: Networking)

Verify:
```bash
az group list -o table
az network vnet list -o table
```

- [ ] MI and role assignments ready (Owner: Security)

Verify:
```bash
az aks show -g <aksRG> -n <cluster> --query identity || true
az role assignment list --assignee <principalId> -o table
```
