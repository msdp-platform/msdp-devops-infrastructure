# DEPRECATED: terraform-backend

⚠️ **This action is deprecated and will be removed in a future version.**

## Migration Path

Please use `.github/actions/terraform-backend-enhanced` instead.

### Old Usage:
```yaml
- name: Terraform Backend (AWS)
  uses: ./.github/actions/terraform-backend
  with:
    repo-shortname: infra
    project: msdp
    env: dev
    cloud: aws
    cloud-segment: azure
    app: aks
    function: tfstate
    key-salt: infrastructure/environment/azure/aks
    aws-region: eu-west-1
    use-shared-lock-table: "true"
    pipeline-name: aks-cluster-01
```

### New Usage:
```yaml
- name: Setup Terraform Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: dev
    platform: azure
    component: aks
    instance: cluster-01
    aws_region: eu-west-1
    create_resources: "true"
```

## Benefits of Enhanced Version

1. **Consistent Naming**: Uses organizational naming conventions
2. **Simplified Interface**: Fewer required parameters
3. **Better Validation**: Comprehensive input validation
4. **Improved Security**: Enhanced security configurations
5. **Better Documentation**: Clear examples and error messages

## Timeline

- **Deprecated**: Current version
- **Removal**: Will be removed after all workflows are migrated
- **Support**: No new features will be added to this version

Please update your workflows to use the enhanced version.