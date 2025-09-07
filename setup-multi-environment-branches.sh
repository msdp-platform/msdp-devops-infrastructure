#!/bin/bash

# Setup multi-environment branches (dev, test, prod) for all MSDP repositories
echo "🌿 Setting up multi-environment branches for all MSDP repositories..."

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

# Create temporary directory
TEMP_DIR="/tmp/msdp-branches"
mkdir -p $TEMP_DIR

for repo in "${repos[@]}"; do
    echo "Setting up branches for $repo..."
    
    # Clone the repository
    cd $TEMP_DIR
    git clone https://github.com/msdp-platform/$repo.git
    cd $repo
    
    # Create dev branch
    git checkout -b dev
    git push -u origin dev
    
    # Create test branch
    git checkout develop
    git checkout -b test
    git push -u origin test
    
    # Create prod branch
    git checkout main
    git checkout -b prod
    git push -u origin prod
    
    # Clean up
    cd ..
    rm -rf $repo
    
    echo "✅ $repo: dev, test, prod branches created"
done

# Clean up temp directory
rm -rf $TEMP_DIR

echo "🎉 Multi-environment branches setup complete!"
echo "📊 Total repositories: ${#repos[@]} + msdp-devops-infrastructure = 17"
echo "🌿 Each repository now has: main, develop, dev, test, prod branches"
echo "🔗 Organization: https://github.com/msdp-platform"
