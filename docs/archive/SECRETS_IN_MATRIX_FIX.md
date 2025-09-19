# GitHub Actions Secrets in Matrix Fix

## Problem
GitHub Actions was refusing to set the matrix output with the message:
```
Skip output 'matrix' since it may contain secret.
```

This happened because we were including `tenant_id` with a secret value (`${{ secrets.AZURE_TENANT_ID }}`) directly in the matrix JSON.

## Why This Happens
GitHub Actions has security measures to prevent secrets from being exposed in logs or outputs. When it detects that an output might contain a secret value, it refuses to set it to prevent accidental exposure.

## Solution Applied

### 1. Remove Secrets from Matrix
**Before:**
```python
cluster['tenant_id'] = "${{ secrets.AZURE_TENANT_ID }}"  # ❌ Secret in matrix
```

**After:**
```python
# Don't include secrets in the matrix - they'll be accessed directly in the job
```

### 2. Access Secrets Directly in Job
Instead of passing the tenant ID through the matrix, we access it directly from the environment in the deploy job:

```python
# Get tenant ID from environment (set by GitHub secrets)
tenant_id = os.environ.get('ARM_TENANT_ID', '')
```

The `ARM_TENANT_ID` environment variable is already set in the deploy job:
```yaml
env:
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

### 3. Mask Secrets in Logs
When displaying the generated tfvars, we mask the tenant ID:
```python
# Don't print tenant_id in logs
tfvars_display = tfvars.copy()
tfvars_display['tenant_id'] = '***'
print(json.dumps(tfvars_display, indent=2))
```

## Best Practices for Secrets

### ✅ DO:
- Access secrets directly in the job where they're needed
- Use environment variables to pass secrets to scripts
- Mask sensitive values when logging
- Use GitHub's built-in secret masking

### ❌ DON'T:
- Include secrets in matrix or other outputs
- Pass secrets through intermediate steps
- Log secret values
- Include secrets in artifact files

## How It Works Now

1. **Matrix Generation**: Creates matrix with cluster configuration (no secrets)
2. **Deploy Job**: Sets secrets as environment variables
3. **Terraform Variables**: Script reads secrets from environment
4. **Terraform Apply**: Uses the secrets without exposing them

## Testing

The workflow should now:
1. Successfully generate and set the matrix output
2. Pass cluster configuration through the matrix
3. Access secrets directly in the deploy job
4. Generate correct terraform.tfvars.json with tenant_id

## Security Benefits

- **No Secret Exposure**: Secrets never appear in matrix or logs
- **GitHub Protection**: Leverages GitHub's built-in secret masking
- **Audit Trail**: Clear separation of configuration and secrets
- **Minimal Surface**: Secrets only available where needed

## Next Steps

Run the workflow again:
```bash
gh workflow run aks.yml -f action=plan -f environment=dev
```

The matrix should now be set successfully without the "may contain secret" warning.