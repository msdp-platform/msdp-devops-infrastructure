# DynamoDB Naming Convention Alignment Analysis 🔍

## 🎯 **Issue Identified:**

There's a discrepancy between your **naming conventions** and your **existing infrastructure**:

### **Naming Convention (from naming.yaml):**
```yaml
dynamodb_table:
  prefix: "tf-locks"
  pattern: "{prefix}-{org}-{account_type}-{region_code}"
```

**Should generate**: `tf-locks-msdp-dev-euw1`

### **Existing Infrastructure (from backend-config.json):**
```json
{
  "dynamodb_table": "msdp-terraform-locks-dev"
}
```

**Currently using**: `msdp-terraform-locks-dev`

## 🔍 **Analysis:**

### **Option 1: Follow Strict Naming Convention**
- **Pros**: Follows documented standards
- **Cons**: Would create a **new DynamoDB table**, separate from existing infrastructure
- **Risk**: State isolation, additional costs, management complexity

### **Option 2: Align with Existing Infrastructure** ✅
- **Pros**: Uses **same DynamoDB table** as existing AKS/network infrastructure
- **Pros**: Consistent with current operational setup
- **Pros**: No additional costs or management overhead
- **Cons**: Doesn't follow strict naming convention

## 🎯 **Recommendation: Option 2 (Align with Existing)**

### **Reasons:**
1. **Operational Consistency** - Your AKS and network workflows already use `msdp-terraform-locks-dev`
2. **Cost Efficiency** - Single DynamoDB table for all dev environment state locking
3. **Management Simplicity** - One table to monitor, backup, and manage
4. **State Isolation** - Different state keys provide isolation while sharing lock table

### **Current State Structure:**
```
DynamoDB Table: msdp-terraform-locks-dev
├── State Locks for: azure/network/dev/uksouth/terraform.tfstate
├── State Locks for: azure/aks/dev/uksouth/aks-msdp-dev-01/terraform.tfstate
└── State Locks for: azure/addons/dev/uksouth/terraform.tfstate  # ✅ NEW
```

## 🔧 **Implementation:**

### **Current Add-ons Workflow:**
```yaml
- name: Setup Terraform Backend
  uses: ./.github/actions/terraform-backend-enhanced
  with:
    environment: ${{ env.ENVIRONMENT }}
    platform: ${{ env.CLOUD_PROVIDER }}
    component: addons
    aws_region: eu-west-1
    create_resources: "true"
```

### **Expected Behavior:**
The `terraform-backend-enhanced` action should:
1. **Call** `generate-backend-config.py dev azure addons`
2. **Generate** backend config following your conventions
3. **Use** the same DynamoDB table as existing infrastructure

## 🎯 **Verification Needed:**

### **Check what generate-backend-config.py actually produces:**
```bash
python3 scripts/generate-backend-config.py dev azure addons
```

### **Expected Output:**
```json
{
  "bucket": "tf-state-msdp-dev-euw1-xxxxxxxx",
  "dynamodb_table": "tf-locks-msdp-dev-euw1",  # Following convention
  "key": "azure/addons/dev/terraform.tfstate"
}
```

### **But Existing Infrastructure Uses:**
```json
{
  "bucket": "msdp-terraform-state-dev",
  "dynamodb_table": "msdp-terraform-locks-dev"  # Legacy pattern
}
```

## 🚀 **Resolution Options:**

### **Option A: Update generate-backend-config.py** 
Add legacy compatibility mode to match existing infrastructure

### **Option B: Migrate Existing Infrastructure**
Update existing infrastructure to follow strict naming conventions

### **Option C: Override in terraform-backend-enhanced**
Add logic to use existing table names for consistency

## 🎯 **Recommended Action:**

**Use Option A** - Add legacy compatibility to ensure add-ons use the same DynamoDB table as existing infrastructure:

```python
# In generate-backend-config.py
def generate_table_name(self, org, account_type, region):
    # Check for existing legacy table first
    legacy_table = f"{org}-terraform-locks-{account_type}"
    if self.table_exists(legacy_table):
        return legacy_table
    
    # Otherwise use new convention
    region_code = self.get_region_code(region)
    pattern = self.naming["naming_conventions"]["dynamodb_table"]["pattern"]
    return pattern.format(...)
```

This ensures:
- ✅ **Consistency** with existing infrastructure
- ✅ **Same DynamoDB table** for all dev environment resources
- ✅ **No breaking changes** to existing workflows
- ✅ **Cost efficiency** and operational simplicity

**The add-ons should use the same `msdp-terraform-locks-dev` table as your existing AKS and network infrastructure.** 🎯