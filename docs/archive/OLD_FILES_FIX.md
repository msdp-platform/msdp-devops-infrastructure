# Old Files Fix - Terraform Modules

## Problem
Old Terraform files from the previous implementation were causing errors because they referenced variables that don't exist in the fresh, clean implementation.

## Errors Fixed
```
Error: Reference to undeclared input variable
│ on locals.tf line 2, in locals:
│ 2: use_explicit = length(var.address_space) > 0 && length(var.subnets) > 0
```

## Solution Applied
Replaced the content of old files with empty placeholders to prevent Terraform from processing old logic:

### Network Module
- `locals.tf` - Replaced with empty file (old logic not needed)
- Original saved as `locals.tf.old` for reference

### AKS Module  
- `locals.tf` - Replaced with empty file (old logic not needed)
- `network.tf` - Replaced with empty file (network lookups now in main.tf)

## Clean Structure
The fresh implementation uses a much simpler approach:

### Old (Complex) Variables:
- `address_space`, `base_cidr`, `subnet_count`, `subnet_newbits`
- `computed_subnets_spec`, `subnet_names`, `nsg_prefix`
- Complex locals for subnet calculation

### New (Simple) Variables:
- `resource_group_name` - Simple string
- `vnet_name` - Simple string
- `vnet_cidr` - Simple CIDR string
- `subnets` - Simple list of subnet objects

## To Fully Clean Up
Run this script to remove all old files:
```bash
chmod +x scripts/cleanup-old-terraform-files.sh
./scripts/cleanup-old-terraform-files.sh
```

Or manually remove:
```bash
# Network module
rm -f infrastructure/environment/azure/network/locals.tf
rm -f infrastructure/environment/azure/network/locals.tf.old
rm -f infrastructure/environment/azure/network/terraform.tfvars.example

# AKS module
rm -f infrastructure/environment/azure/aks/locals.tf
rm -f infrastructure/environment/azure/aks/network.tf
rm -f infrastructure/environment/azure/aks/cleanup.sh
```

## Result
After this fix, Terraform should:
1. ✅ Successfully initialize without variable errors
2. ✅ Process only the clean, fresh implementation
3. ✅ Use the simple configuration from config/dev.yaml

## Next Step
Run the workflow again:
```bash
gh workflow run azure-network.yml -f action=plan -f environment=dev
```

The terraform init and plan should now work correctly!