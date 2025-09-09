#!/bin/bash

# Test Azure Key Vault Access Script
# Tests if the current service principal has access to Key Vault

set -euo pipefail

KEY_VAULT_NAME="${1:-msdp-certificates-kv}"

echo "🔍 Testing Azure Key Vault access for: $KEY_VAULT_NAME"

# Check current Azure context
echo "📋 Current Azure context:"
az account show --query "{name: name, tenantId: tenantId, subscriptionId: id}" -o table

# Test Key Vault access
echo "🔐 Testing Key Vault access..."

# Try to list secrets (this will fail if no access)
if az keyvault secret list --vault-name "$KEY_VAULT_NAME" >/dev/null 2>&1; then
    echo "✅ Key Vault access: SUCCESS"
    echo "📋 Available secrets:"
    az keyvault secret list --vault-name "$KEY_VAULT_NAME" --query "[].name" -o table
else
    echo "❌ Key Vault access: FAILED"
    echo "🔧 Service principal needs Key Vault access permissions"
    
    # Check Key Vault policies
    echo "📋 Current Key Vault access policies:"
    az keyvault show --name "$KEY_VAULT_NAME" --query "properties.accessPolicies[].{objectId: objectId, permissions: permissions}" -o table 2>/dev/null || echo "  No access policies found"
fi

echo "✅ Key Vault access test complete"
