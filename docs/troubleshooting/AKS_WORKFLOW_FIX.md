# AKS Workflow Fix - Matrix Generation

## Problem
The AKS workflow was failing with:
```
Error when evaluating 'if' for job 'deploy': could not get operand for index access: Error from function 'fromJson': empty input
```

This happened because the matrix generation was failing silently and returning invalid JSON.

## Root Causes
1. **No error handling**: The matrix generation script didn't handle missing config files or invalid structures
2. **Silent failures**: Errors weren't properly reported, resulting in empty/invalid JSON
3. **Poor validation**: The workflow tried to parse invalid JSON without checking first

## Solutions Applied

### 1. Enhanced Error Handling
- Added try/catch blocks to handle exceptions
- Added file existence checks
- Added graceful fallbacks for missing configuration sections
- Return empty but valid matrix on errors: `{"include": []}`

### 2. Better Logging
- Added detailed logging to show what's being processed
- Show configuration structure validation
- Report specific errors when they occur

### 3. Matrix Validation Job
- Added `check-matrix` job to validate the matrix before using it
- Only run deploy job if clusters are found
- Prevents the `fromJson` error on empty matrices

### 4. Default Values
- Added defaults for all cluster configuration fields
- Prevents missing field errors during deployment
- Ensures consistent behavior

## Testing the Fix

### Test Matrix Generation Locally
```bash
# Test the matrix generation script
python3 scripts/test-aks-matrix.py

# This will show:
# - If config file exists
# - Configuration structure validation
# - Number of clusters found
# - Generated matrix JSON
```

### Expected Output (Success)
```
✅ Found configuration file: config/dev.yaml
✅ Found 2 clusters in configuration:
  1. aks-msdp-dev-01
  2. aks-msdp-dev-02
📊 Generated matrix with 2 clusters
```

### Expected Output (No Clusters)
```
⚠️ WARNING: No AKS clusters defined in config/dev.yaml
📊 Generated matrix with 0 clusters
```

## Workflow Behavior

### With Clusters
1. `prepare` job generates matrix with clusters
2. `check-matrix` job confirms clusters exist
3. `deploy` job runs for each cluster

### Without Clusters
1. `prepare` job generates empty matrix `{"include": []}`
2. `check-matrix` job detects no clusters
3. `deploy` job is skipped (no error)

## Configuration Requirements

Ensure your `config/dev.yaml` has the correct structure:

```yaml
azure:
  location: uksouth
  
  network:
    resource_group_name: rg-msdp-network-dev
    vnet_name: vnet-msdp-dev
    
  aks:
    clusters:  # This section is required!
      - name: aks-msdp-dev-01
        subnet_name: snet-aks-system-dev
        kubernetes_version: "1.29.7"
```

## Next Steps

1. **Test locally**: Run `python3 scripts/test-aks-matrix.py`
2. **Check configuration**: Ensure `config/dev.yaml` has AKS clusters defined
3. **Run workflow**: `gh workflow run aks.yml -f action=plan -f environment=dev`

The workflow should now:
- Handle missing configurations gracefully
- Skip deployment if no clusters are defined
- Provide clear error messages when issues occur