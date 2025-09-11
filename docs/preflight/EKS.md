# Preflight – EKS Prerequisites

## Part A — Checklist

- [ ] VPC created with non-overlapping CIDR (Owner: Networking)

Verify:
```bash
aws ec2 describe-vpcs --filters Name=tag:Name,Values=msdp-dev-aws-euw1-vpc --query 'Vpcs[].{VpcId:VpcId,CIDR:CidrBlock}' --region eu-west-1
```

- [ ] Private subnets (≥2 AZs) for nodes (Owner: Networking)

Verify:
```bash
aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpcId> Name=tag:Tier,Values=private \
  --query 'Subnets[].{Id:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock}' --region eu-west-1
```

- [ ] Public subnets (if using public ingress/NAT) (Owner: Networking)

Verify:
```bash
aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpcId> Name=tag:Tier,Values=public \
  --query 'Subnets[].SubnetId' --region eu-west-1
```

- [ ] Route tables associated correctly (Owner: Networking)

Verify:
```bash
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpcId> --region eu-west-1
```

- [ ] NAT Gateway(s) for private egress (Owner: Networking)

Verify:
```bash
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<vpcId> --query 'NatGateways[].{Id:NatGatewayId,State:State}' --region eu-west-1
```

- [ ] Internet Gateway attached (if public subnets) (Owner: Networking)

Verify:
```bash
aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=<vpcId> --region eu-west-1
```

- [ ] Security Groups (cluster/node) created (Owner: Security)

Verify:
```bash
aws ec2 describe-security-groups --filters Name=vpc-id,Values=<vpcId> --query 'SecurityGroups[].{Id:GroupId,Name:GroupName}' --region eu-west-1
```

- [ ] IAM OIDC provider (IRSA) present (Owner: Security)

Verify:
```bash
aws iam list-open-id-connect-providers
aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
```

- [ ] IAM roles: cluster role (EKS), nodegroup role (CNI/ECR) (Owner: Security)

Verify:
```bash
aws iam list-attached-role-policies --role-name <clusterRole>
aws iam list-attached-role-policies --role-name <nodeRole>
```

- [ ] Subnet cluster tags set (Owner: Platform)

Verify:
```bash
aws ec2 describe-subnets --subnet-ids <subnetId> --query 'Subnets[].Tags'
# Expect: kubernetes.io/cluster/<clusterName>=shared|owned
```

- [ ] Subnet ELB role tags set (Owner: Platform)

Verify:
```bash
aws ec2 describe-subnets --filters Name=tag:Tier,Values=public --query 'Subnets[].Tags'
# Expect: kubernetes.io/role/elb=1 (public) or kubernetes.io/role/internal-elb=1 (private)
```

- [ ] KMS key for secrets encryption (Owner: Security)

Verify:
```bash
aws kms describe-key --key-id <kmsKeyId> --query 'KeyMetadata.{Enabled:Enabled,Arn:Arn}'
```

- [ ] CloudWatch log group for control plane (Owner: Platform)

Verify:
```bash
aws logs describe-log-groups --log-group-name-prefix /aws/eks/<clusterName>/cluster --query 'logGroups[].logGroupName'
```

- [ ] Route53 zone and IAM for external-dns/cert-manager (Owner: Platform)

Verify:
```bash
aws route53 list-hosted-zones --query 'HostedZones[].{Name:Name,Id:Id}'
aws iam get-policy --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/external-dns-<zoneOrCluster>
aws iam get-policy --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/cert-manager-dns01
```

- [ ] Karpenter discovery tags + instance profile (optional) (Owner: Platform)

Verify:
```bash
aws ec2 describe-subnets --filters Name=tag:karpenter.sh/discovery,Values=<clusterName> --query 'Subnets[].SubnetId'
aws iam get-instance-profile --instance-profile-name <profileName>
```

## Part B — Verification Snippets (Quick Reference)

```bash
# Terraform (plan-only) from environment/dev/aws/eks
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.json -lock=false

# kubectl after cluster ready
kubectl get nodes -o wide
kubectl get pods -n kube-system
```
