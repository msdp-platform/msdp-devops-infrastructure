# Terraform Action Consolidation Analysis

## Current State

### terraform-init Action Usage
The `terraform-init` action is used in **9 workflows** across **10 instances**:

1. `azure-network.yml` - Network infrastructure setup
2. `platform-engineering.yml` - Platform engineering components
3. `tf-validate.yml` - Terraform validation workflow
4. `aws-network.yml` - AWS network infrastructure
5. `k8s-addons-terraform.yml` - Kubernetes addons deployment
6. `shared-terraform.yaml` - Shared Terraform resources
7. `aks.yml` - Azure AKS cluster management
8. `eks.yml` - AWS EKS cluster management (2 instances)

### terraform-checks Action Usage
The `terraform-checks` action is **not currently used** in any workflows.

## Analysis

### terraform-init Action
**Current Implementation**: 69 lines
- Installs Terraform at specified version
- Initializes backend with config file
- Runs terraform validate

**Usage Pattern**: Consistently used across all major infrastructure workflows
**Value**: High - provides standardized Terraform setup

**Recommendation**: **KEEP** - This action provides significant value through:
- Consistent Terraform version management
- Standardized backend initialization
- Error handling and validation
- Reusability across multiple workflows

### terraform-checks Action
**Current Implementation**: 34 lines (recently refactored from Python to bash)
- Runs `terraform fmt -check -recursive`
- Runs `terraform validate`

**Usage Pattern**: Not currently used in any workflows
**Value**: Low - functionality duplicated in terraform-init and workflow-level commands

**Recommendation**: **REMOVE** - This action is redundant because:
- `terraform validate` is already handled by `terraform-init`
- `terraform fmt -check` can be done at workflow level
- No current usage indicates low adoption
- Simple operations don't justify separate action

## Consolidation Opportunities

### Option 1: Remove terraform-checks (Recommended)
- **Action**: Delete `terraform-checks` action
- **Rationale**: No current usage, duplicates terraform-init functionality
- **Impact**: None - no workflows currently use it
- **Benefit**: Reduces maintenance overhead

### Option 2: Enhance terraform-init with formatting checks
- **Action**: Add optional formatting check to `terraform-init`
- **Implementation**: Add `format-check` input parameter (default: false)
- **Benefit**: Single action for all Terraform setup needs
- **Drawback**: Increases complexity of terraform-init

### Option 3: Keep both actions
- **Action**: No changes
- **Rationale**: Separation of concerns
- **Drawback**: Maintenance overhead for unused action

## Recommendation: Option 1

**Remove terraform-checks action** for the following reasons:

1. **Zero current usage** - No workflows use it
2. **Functional duplication** - terraform validate covered by terraform-init
3. **Simple operations** - terraform fmt can be done inline in workflows
4. **Maintenance reduction** - One less action to maintain
5. **Clear separation** - terraform-init focuses on setup, workflows handle checks

## Implementation Plan

1. **Verify no external usage** of terraform-checks
2. **Remove terraform-checks directory**
3. **Update documentation** to reflect removal
4. **Add inline terraform fmt checks** to workflows if needed

## Workflow-Level Alternative

For workflows needing format checks, use inline commands:

```yaml
- name: Terraform Format Check
  run: |
    cd ${{ env.WORKING_DIRECTORY }}
    terraform fmt -check -recursive
```

This approach:
- Reduces action complexity
- Provides more flexibility
- Eliminates unused action maintenance
- Keeps terraform-init focused on its core purpose

## Conclusion

The terraform-init action provides significant value and should be retained. The terraform-checks action should be removed due to lack of usage and functional duplication. This consolidation will reduce maintenance overhead while maintaining all necessary functionality.
