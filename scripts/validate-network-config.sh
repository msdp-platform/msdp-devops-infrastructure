#!/bin/bash
set -euo pipefail

# Validate Network Configuration Script
# This script validates that the network configuration is properly set up
# and that the azure-network workflow can generate valid tfvars

echo "🔍 Validating Network Configuration..."

# Check required files exist
echo "📁 Checking configuration files..."
required_files=(
    "infrastructure/config/globals.yaml"
    "config/envs/dev.yaml"
    "infrastructure/environment/azure/network/main.tf"
    "infrastructure/environment/azure/network/variables.tf"
    "infrastructure/environment/azure/network/outputs.tf"
    ".github/actions/network-tfvars/action.yml"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    else
        echo "✅ Found: $file"
    fi
done

# Test network tfvars generation
echo ""
echo "🔧 Testing network tfvars generation..."
cd "$(dirname "$0")/.."

# Install Python dependencies if needed
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "📦 Installing Python dependencies..."
    pip3 install pyyaml
fi

# Generate network tfvars
echo "🏗️  Generating network.auto.tfvars.json..."
python3 .github/scripts/generate_network_tfvars.py

if [ -f "network.auto.tfvars.json" ]; then
    echo "✅ Generated network.auto.tfvars.json successfully"
    echo ""
    echo "📋 Generated configuration:"
    cat network.auto.tfvars.json | python3 -m json.tool
    
    # Validate JSON structure
    echo ""
    echo "🔍 Validating configuration structure..."
    
    # Check required fields
    required_fields=("resource_group" "location" "vnet_name")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" network.auto.tfvars.json >/dev/null; then
            echo "❌ Missing required field: $field"
            exit 1
        else
            echo "✅ Found required field: $field"
        fi
    done
    
    # Check if we have either computed_subnets_spec or subnets
    if jq -e '.computed_subnets_spec' network.auto.tfvars.json >/dev/null; then
        echo "✅ Using computed subnets mode"
        subnet_count=$(jq '.computed_subnets_spec | length' network.auto.tfvars.json)
        echo "   Subnet count: $subnet_count"
    elif jq -e '.subnets' network.auto.tfvars.json >/dev/null; then
        echo "✅ Using explicit subnets mode"
        subnet_count=$(jq '.subnets | length' network.auto.tfvars.json)
        echo "   Subnet count: $subnet_count"
    else
        echo "❌ No subnet configuration found (need either computed_subnets_spec or subnets)"
        exit 1
    fi
    
    # Clean up
    rm -f network.auto.tfvars.json
    
else
    echo "❌ Failed to generate network.auto.tfvars.json"
    exit 1
fi

echo ""
echo "🎉 Network configuration validation completed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Run the azure-network workflow with action=plan"
echo "   2. Review the Terraform plan output"
echo "   3. If plan looks good, run with action=apply"
echo ""
echo "🔗 Workflow URL: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/actions/workflows/azure-network.yml"