# Preflight – AKS Prerequisites

## Part A — Checklist

- [ ] Resource Group layout: network RG and AKS RG (Owner: Platform)

Verify:
```bash
az group show -n msdp-dev-azr-uks-network -o table
az group show -n msdp-dev-azr-uks-aks -o table
```

- [ ] VNet + dedicated AKS subnet (Owner: Networking)

Verify:
```bash
az network vnet show -g <networkRG> -n <vnet> -o table
az network vnet subnet show -g <networkRG> --vnet-name <vnet> -n <aksSubnet> -o jsonc
```

- [ ] NSG associated to AKS subnet (Owner: Networking)

Verify:
```bash
az network vnet subnet show -g <networkRG> --vnet-name <vnet> -n <aksSubnet> --query networkSecurityGroup.id -o tsv
az network nsg rule list -g <networkRG> --nsg-name <nsgName> -o table
```

- [ ] UDR associated (if custom egress) (Owner: Networking)

Verify:
```bash
az network vnet subnet show -g <networkRG> --vnet-name <vnet> -n <aksSubnet> --query routeTable.id -o tsv
az network route-table show -g <networkRG> -n <routeTable> -o jsonc
```

- [ ] Outbound type decided: LoadBalancer or NAT Gateway (Owner: Networking)

Verify:
```bash
az aks show -g <aksRG> -n <cluster> --query networkProfile.outboundType -o tsv
az network nat gateway show -g <networkRG> -n <natGatewayName> -o jsonc
```

- [ ] Managed Identity configured (SystemAssigned or UserAssigned) (Owner: Security)

Verify:
```bash
az aks show -g <aksRG> -n <cluster> --query identity -o jsonc
```

- [ ] Role assignment: Network Contributor on AKS subnet (Owner: Security)

Verify:
```bash
az role assignment list --assignee <principalId> --scope <subnetId> -o table
```

- [ ] Role assignment: Reader on AKS RG (Owner: Security)

Verify:
```bash
az role assignment list --assignee <principalId> --scope /subscriptions/<subId>/resourceGroups/<aksRG> -o table
```

- [ ] Role assignment: AcrPull on ACR (Owner: Security)

Verify:
```bash
ACR_ID=$(az acr show -n <acrName> -g <acrRG> --query id -o tsv)
az role assignment list --assignee <principalId> --scope $ACR_ID --role AcrPull -o table
```

- [ ] Network plugin selected: Azure CNI (recommended) or kubenet (Owner: Platform)

Verify:
```bash
az aks show -g <aksRG> -n <cluster> --query networkProfile.networkPlugin -o tsv
```

- [ ] Public DNS zone and external-dns role (Owner: Platform)

Verify:
```bash
az network dns zone show -g <dnsRG> -n <base_domain> -o table
DNS_ID=$(az network dns zone show -g <dnsRG> -n <base_domain> --query id -o tsv)
az role assignment list --assignee <principalId> --scope $DNS_ID --role "DNS Zone Contributor" -o table
```

- [ ] cert-manager issuer ready (HTTP‑01 or DNS‑01) (Owner: Platform)

Verify:
```bash
kubectl get clusterissuer -A
```

- [ ] Key Vault + CSI (optional) (Owner: Security)

Verify:
```bash
az keyvault show -g <secRG> -n <kvName> -o table
az aks show -g <aksRG> -n <cluster> --query addonProfiles.azureKeyvaultSecretsProvider.enabled -o tsv
```

## Part B — Verification Snippets (Quick Reference)

```bash
# Terraform (plan-only) from infrastructure/environment/dev/azure/aks
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.json -lock=false

# kubectl after cluster ready
kubectl get nodes -o wide
kubectl get pods -n kube-system
```
