#!/bin/bash

# Script to add AWS credentials as GitHub secrets
# This script uses GitHub CLI to add the secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# AWS Credentials (replace with your actual credentials)
AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"

# Check if GitHub CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first."
        print_status "Installation instructions: https://cli.github.com/"
        exit 1
    fi
    
    # Check if user is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
}

# Add GitHub secrets
add_secrets() {
    print_status "Adding AWS credentials as GitHub secrets..."
    
    # Add AWS Access Key ID
    print_status "Adding AWS_ACCESS_KEY_ID secret..."
    echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID
    
    # Add AWS Secret Access Key
    print_status "Adding AWS_SECRET_ACCESS_KEY secret..."
    echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY
    
    print_success "GitHub secrets added successfully!"
}

# List secrets
list_secrets() {
    print_status "Current GitHub secrets:"
    gh secret list
}

# Main execution
main() {
    print_status "Setting up GitHub secrets for AWS credentials..."
    
    check_gh_cli
    add_secrets
    list_secrets
    
    print_success "Setup completed successfully!"
    print_status "You can now run the pipeline and External DNS will use these AWS credentials."
    print_warning "Remember to rotate these credentials regularly for security!"
}

# Run main function
main "$@"
