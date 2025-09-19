#!/bin/bash
set -euo pipefail

echo "🧹 Cleaning up old Terraform files from fresh setup"
echo "===================================================="

# Network module old files
NETWORK_OLD_FILES=(
    "infrastructure/environment/azure/network/locals.tf"
    "infrastructure/environment/azure/network/terraform.tfvars.example"
    "infrastructure/environment/azure/network/README.md"
)

# AKS module old files
AKS_OLD_FILES=(
    "infrastructure/environment/azure/aks/locals.tf"
    "infrastructure/environment/azure/aks/network.tf"
    "infrastructure/environment/azure/aks/cleanup.sh"
    "infrastructure/environment/azure/aks/README.md"
)

echo "📁 Network Module Cleanup:"
for file in "${NETWORK_OLD_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ❌ Removing old file: $file"
        rm -f "$file"
    else
        echo "  ✅ Already removed: $file"
    fi
done

echo ""
echo "📁 AKS Module Cleanup:"
for file in "${AKS_OLD_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ❌ Removing old file: $file"
        rm -f "$file"
    else
        echo "  ✅ Already removed: $file"
    fi
done

echo ""
echo "🔍 Verifying clean structure..."

# Check Network module
echo ""
echo "Network module files:"
ls -la infrastructure/environment/azure/network/*.tf 2>/dev/null || echo "No .tf files found"

# Check AKS module
echo ""
echo "AKS module files:"
ls -la infrastructure/environment/azure/aks/*.tf 2>/dev/null || echo "No .tf files found"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "The modules should now have only these files:"
echo "  - main.tf        (resource definitions)"
echo "  - variables.tf   (input variables)"
echo "  - outputs.tf     (output values)"
echo "  - versions.tf    (terraform/provider config)"
echo ""
echo "Next step: Run the workflow again to test the clean setup"