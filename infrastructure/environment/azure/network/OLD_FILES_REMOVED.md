# Old Files Removed from Network Module

The following old files have been identified and should be removed as they conflict with the fresh implementation:

## Files to Remove:
- `locals.tf` - Old complex logic for subnet calculation, not needed in fresh setup
- `terraform.tfvars.example` - Old example file, configuration now comes from config/dev.yaml
- `README.md` - Old documentation, may contain outdated information

## Clean Structure Should Be:
```
infrastructure/environment/azure/network/
├── main.tf        # Resource definitions
├── variables.tf   # Input variables
├── outputs.tf     # Output values
└── versions.tf    # Terraform and provider configuration
```

## Why These Files Cause Issues:
The old `locals.tf` references variables that don't exist in the new clean implementation:
- `address_space` (replaced with simple `vnet_cidr`)
- `subnet_count`, `subnet_names`, `subnet_newbits` (replaced with simple `subnets` list)
- `computed_subnets_spec`, `base_cidr`, `nsg_prefix` (old complex logic removed)
- `resource_group` (renamed to `resource_group_name`)

The fresh implementation uses a much simpler approach with just the essential variables.