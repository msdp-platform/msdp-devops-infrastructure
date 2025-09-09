#!/bin/bash

# Setup kubectl aliases for different environments
# This script creates convenient aliases for switching between AKS environments

# Colors for output
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

print_status "Setting up kubectl aliases for MSDP environments..."

# Create aliases
ALIASES="
# MSDP AKS Environment Aliases
alias kubectl-dev='KUBECONFIG=\"\$HOME/.kube/config-msdp-dev\" kubectl'
alias kubectl-test='KUBECONFIG=\"\$HOME/.kube/config-msdp-test\" kubectl'
alias kubectl-prod='KUBECONFIG=\"\$HOME/.kube/config-msdp-prod\" kubectl'

# Quick environment switching
alias use-dev='export KUBECONFIG=\"\$HOME/.kube/config-msdp-dev\"'
alias use-test='export KUBECONFIG=\"\$HOME/.kube/config-msdp-test\"'
alias use-prod='export KUBECONFIG=\"\$HOME/.kube/config-msdp-prod\"'
alias use-default='unset KUBECONFIG'

# Show current environment
alias kubectl-env='echo \"Current KUBECONFIG: \${KUBECONFIG:-\$HOME/.kube/config}\"'
"

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    print_warning "Unknown shell, defaulting to .bashrc"
    SHELL_RC="$HOME/.bashrc"
fi

print_status "Adding aliases to $SHELL_RC..."

# Check if aliases already exist
if grep -q "MSDP AKS Environment Aliases" "$SHELL_RC" 2>/dev/null; then
    print_warning "Aliases already exist in $SHELL_RC"
    print_status "Updating existing aliases..."
    
    # Remove old aliases
    sed -i.backup '/# MSDP AKS Environment Aliases/,/^$/d' "$SHELL_RC"
fi

# Add new aliases
echo "$ALIASES" >> "$SHELL_RC"

print_success "Aliases added to $SHELL_RC"

echo ""
print_status "Available commands after reloading shell:"
echo "  kubectl-dev      # Use dev environment"
echo "  kubectl-test     # Use test environment" 
echo "  kubectl-prod     # Use prod environment"
echo "  use-dev          # Switch to dev environment"
echo "  use-test         # Switch to test environment"
echo "  use-prod         # Switch to prod environment"
echo "  use-default      # Switch back to default kubeconfig"
echo "  kubectl-env      # Show current environment"

echo ""
print_warning "To activate aliases in current session, run:"
echo "source $SHELL_RC"

echo ""
print_status "Example usage:"
echo "  ./scripts/utilities/connect-aks.sh dev    # Connect to dev"
echo "  kubectl-dev get pods                      # Use dev cluster"
echo "  use-dev                                   # Switch to dev"
echo "  kubectl get nodes                         # Now uses dev cluster"
