# Python Boolean Syntax Fix

## Problem
The workflow was failing with:
```python
NameError: name 'false' is not defined. Did you mean: 'False'?
```

This happened when GitHub Actions injected JSON directly into Python code using `${{ toJson(matrix) }}`.

## Root Cause
JSON and Python have different boolean representations:
- **JSON**: `true` / `false` (lowercase)
- **Python**: `True` / `False` (capitalized)

When GitHub Actions injects JSON directly into Python code:
```python
# This causes an error:
cluster_config = {"user_spot_enabled": false}  # ❌ 'false' is not valid Python
```

## Solution Applied

### Changed Approach
Instead of injecting JSON directly into Python code, we:
1. Write the JSON to a string
2. Parse it with `json.loads()`
3. Let Python handle the conversion

### Before (Direct Injection - Broken)
```python
# Extract cluster-specific configuration
cluster_config = ${{ toJson(matrix) }}  # ❌ Injects raw JSON with 'false'
```

### After (String Parsing - Fixed)
```python
# Extract cluster-specific configuration from JSON string
cluster_config_json = '''${{ toJson(matrix) }}'''  # JSON as string
cluster_config = json.loads(cluster_config_json)   # ✅ Properly parsed
```

## Why This Works

The `json.loads()` function automatically converts:
- JSON `true` → Python `True`
- JSON `false` → Python `False`
- JSON `null` → Python `None`
- JSON arrays → Python lists
- JSON objects → Python dicts

## Alternative Solutions

### Option 1: Use Environment Variable
```bash
export MATRIX_JSON='${{ toJson(matrix) }}'
```
```python
cluster_config = json.loads(os.environ['MATRIX_JSON'])
```

### Option 2: Write to File
```bash
echo '${{ toJson(matrix) }}' > matrix.json
```
```python
with open('matrix.json') as f:
    cluster_config = json.load(f)
```

### Option 3: Create Script File
The solution we used - write the Python script to a file first, then execute it. This avoids inline code issues.

## Best Practices

### ✅ DO:
- Parse JSON strings with `json.loads()`
- Use environment variables for complex data
- Write scripts to files when they're complex
- Test with boolean values in your data

### ❌ DON'T:
- Inject JSON directly into Python code
- Assume JSON syntax is valid Python
- Mix templating and code execution

## Testing

The workflow should now:
1. Generate the Python script correctly
2. Parse the matrix JSON without boolean errors
3. Create terraform.tfvars.json with proper values
4. Continue with Terraform operations

## Common JSON/Python Conversions

| JSON | Python |
|------|--------|
| `true` | `True` |
| `false` | `False` |
| `null` | `None` |
| `"string"` | `"string"` |
| `123` | `123` |
| `[1, 2, 3]` | `[1, 2, 3]` |
| `{"key": "value"}` | `{"key": "value"}` |

## Next Steps

Run the workflow again:
```bash
gh workflow run aks.yml -f action=plan -f environment=dev
```

The Python script should now execute without boolean syntax errors.