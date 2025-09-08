#!/bin/bash

# Setup all repositories for MSDP platform
# This script adds all repositories to the platform-engineering team and sets up branch protection

echo "🚀 Setting up all MSDP repositories..."

# List of all repositories
repos=(
    "msdp-platform-core"
    "msdp-security"
    "msdp-monitoring"
    "msdp-food-delivery"
    "msdp-grocery-delivery"
    "msdp-cleaning-services"
    "msdp-repair-services"
    "msdp-customer-app"
    "msdp-provider-app"
    "msdp-admin-dashboard"
    "msdp-analytics-services"
    "msdp-ui-components"
    "msdp-api-sdk"
    "msdp-testing-utils"
    "msdp-shared-libs"
    "msdp-documentation"
)

# Team ID for platform-engineering
TEAM_ID="14090617"

echo "📋 Adding repositories to platform-engineering team..."

for repo in "${repos[@]}"; do
    echo "Adding $repo to team..."
    gh api teams/$TEAM_ID/repos/msdp-platform/$repo -X PUT -f permission=admin
done

echo "✅ All repositories added to platform-engineering team!"

echo "🔒 Setting up branch protection for all repositories..."

for repo in "${repos[@]}"; do
    echo "Setting up branch protection for $repo..."
    gh api repos/msdp-platform/$repo/branches/main/protection -X PUT --input - << 'PROTECTION_EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
PROTECTION_EOF
done

echo "✅ Branch protection configured for all repositories!"

echo "🎉 All repositories setup complete!"
echo "📊 Total repositories: ${#repos[@]} + msdp-devops-infrastructure = 17"
echo "🔗 Organization: https://github.com/msdp-platform"
