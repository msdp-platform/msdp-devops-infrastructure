#!/bin/bash

# Initialize all repositories with initial commits
echo "🚀 Initializing all MSDP repositories with initial commits..."

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
TEMP_DIR="/tmp/msdp-init"
mkdir -p $TEMP_DIR

for repo in "${repos[@]}"; do
    echo "Initializing $repo..."
    
    # Clone the repository
    cd $TEMP_DIR
    git clone https://github.com/msdp-platform/$repo.git
    cd $repo
    
    # Create initial README
    cat > README.md << REPO_EOF
# $repo

## 📋 Repository Overview

This repository is part of the Multi-Service Delivery Platform (MSDP) ecosystem.

**Repository**: $repo  
**Organization**: [msdp-platform](https://github.com/msdp-platform)  
**Status**: Initialized  
**Last Updated**: $(date)

## 🎯 Purpose

[Repository purpose will be defined during development]

## 🏗️ Structure

[Repository structure will be defined during development]

## 🚀 Getting Started

[Getting started instructions will be added during development]

## 📚 Documentation

[Documentation will be added during development]

## 🤝 Contributing

[Contributing guidelines will be added during development]

---

**Repository Version**: 0.1.0  
**Last Updated**: $(date)  
**Organization**: msdp-platform
REPO_EOF
    
    # Create initial commit
    git add README.md
    git commit -m "Initial commit: $repo

- Repository initialized
- Basic README structure created
- Ready for development

Repository: $repo
Organization: msdp-platform
Status: Initialized"
    
    # Push to main branch
    git push -u origin main
    
    # Create develop branch
    git checkout -b develop
    git push -u origin develop
    
    # Clean up
    cd ..
    rm -rf $repo
    
    echo "✅ $repo initialized"
done

# Clean up temp directory
rm -rf $TEMP_DIR

echo "🎉 All repositories initialized!"
echo "📊 Total repositories: ${#repos[@]} + msdp-devops-infrastructure = 17"
echo "🔗 Organization: https://github.com/msdp-platform"
