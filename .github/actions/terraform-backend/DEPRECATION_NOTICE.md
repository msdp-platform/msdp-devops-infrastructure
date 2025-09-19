# Deprecation Notice: terraform-backend Action

⚠️ **This action is deprecated and will be removed in a future release.**

## Migration Required

Please migrate to the **`terraform-backend-enhanced`** action instead.

### Why is this deprecated?

- **Complexity**: 442 lines of complex validation and error handling
- **Maintainability**: Difficult to maintain and extend
- **Duplicate functionality**: `terraform-backend-enhanced` provides the same capabilities with better design

### Migration Guide

#### Old Usage (terraform-backend):
```yaml
- name: Setup Terraform Backend
  uses: ./.github/actions/terraform-backend
  with:
    repo-shortname: "infra"
    project: "msdp"
    env: "dev"
    app: "crossplane"
    function: "tfstate"
    cloud-segment: "aws"
    cloud: "aws"
    aws-region: "eu-west-1"
```

#### New Usage (terraform-backend-enhanced):
```yaml
- name: Setup Terraform Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: "dev"
    platform: "aws"
    component: "crossplane"
    aws_region: "eu-west-1"
```

### Key Differences

| Old Action | New Action |
|------------|------------|
| `repo-shortname` + `project` + `app` | `component` |
| `env` | `environment` |
| `cloud-segment` + `cloud` | `platform` |
| Complex input validation | Simplified, clear inputs |
| 442 lines | 285 lines |

### Benefits of Migration

- **Simpler inputs**: Cleaner, more intuitive parameter names
- **Better maintainability**: Streamlined codebase
- **Organizational standards**: Follows current naming conventions
- **Active support**: New features and bug fixes

### Timeline

- **Now**: Deprecation notice added
- **Next 3 months**: Migration period - both actions supported
- **After 3 months**: Legacy action will be removed

### Need Help?

If you encounter issues during migration, please:
1. Check the `terraform-backend-enhanced` documentation
2. Review the examples in this migration guide
3. Create an issue if you need additional support

---

**Last Updated**: 2025-01-19
**Removal Target**: April 2025
