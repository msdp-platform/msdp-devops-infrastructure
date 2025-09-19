# Obsolete Scripts Evaluation

## Scripts Under Review

### 1. `migrate-configuration.py` - **KEEP (Archive Ready)**
**Status**: Functional but may be obsolete after migration completion
**Usage**: Referenced in documentation, used for config structure migration
**Recommendation**: Keep for now, archive after confirming all migrations complete

**Analysis**:
- Well-written migration script for old → new config structure
- Has dry-run and backup capabilities
- Still referenced in README.md and documentation
- May be needed for future config migrations

**Action**: Keep until migration phase is fully complete

### 2. `cleanup-old-terraform-files.sh` - **ARCHIVE**
**Status**: One-time cleanup script, likely obsolete
**Usage**: Referenced only in archived documentation
**Recommendation**: Move to archive or remove

**Analysis**:
- Specific cleanup for old Terraform files
- Only referenced in archived docs (`docs/archive/OLD_FILES_FIX.md`)
- Appears to be one-time use script
- Files it cleans up likely no longer exist

**Action**: Move to `scripts/archive/` directory

### 3. `rerun-pipelines.sh` - **KEEP**
**Status**: Active utility script
**Usage**: Pipeline management utility
**Recommendation**: Keep - provides valuable functionality

**Analysis**:
- Provides convenient GitHub CLI wrapper for workflow management
- Good error handling and user experience
- Interactive features for monitoring runs
- Still relevant for operational tasks
- No replacement functionality in workflows

**Action**: Keep - this is a useful operational tool

## Summary

| Script | Action | Reason |
|--------|--------|---------|
| `migrate-configuration.py` | **KEEP** | Still referenced, may be needed for future migrations |
| `cleanup-old-terraform-files.sh` | **ARCHIVE** | One-time use, only in archived docs |
| `rerun-pipelines.sh` | **KEEP** | Active operational utility |

## Recommended Actions

1. **Create archive directory**: `scripts/archive/`
2. **Move cleanup script**: `cleanup-old-terraform-files.sh` → `scripts/archive/`
3. **Keep migration script**: Until all config migrations confirmed complete
4. **Keep pipeline script**: Active operational tool

## Implementation

```bash
# Create archive directory
mkdir -p scripts/archive

# Move obsolete cleanup script
mv scripts/cleanup-old-terraform-files.sh scripts/archive/

# Add README to archive
cat > scripts/archive/README.md << 'EOF'
# Archived Scripts

This directory contains scripts that are no longer actively used but are kept for historical reference.

## Scripts

- `cleanup-old-terraform-files.sh` - One-time cleanup script for old Terraform files (used during refactoring)

These scripts should not be used in production workflows.
EOF
```
