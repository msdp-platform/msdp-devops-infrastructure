#!/bin/bash
# verify_s3_backend.sh
# 
# Verifies that all Terraform environment roots have S3 backend configuration.
# This ensures consistent backend usage across all stacks.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Function to check if a directory is a Terraform root
is_terraform_root() {
    local dir="$1"
    
    # Check if directory contains .tf files
    if ! find "$dir" -maxdepth 1 -name "*.tf" -type f | grep -q .; then
        return 1
    fi
    
    # Exclude modules and .terraform directories
    if [[ "$dir" == *"/modules/"* ]] || [[ "$dir" == *"/.terraform"* ]]; then
        return 1
    fi
    
    # Must be under infrastructure/environment/
    if [[ "$dir" != *"infrastructure/environment/"* ]]; then
        return 1
    fi
    
    return 0
}

# Function to check if a directory has S3 backend configuration
has_s3_backend() {
    local dir="$1"
    local found=false
    
    # Check all .tf files in the directory for S3 backend
    while IFS= read -r -d '' file; do
        if grep -q 'backend "s3"' "$file"; then
            found=true
            break
        fi
    done < <(find "$dir" -maxdepth 1 -name "*.tf" -type f -print0)
    
    if [[ "$found" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Main verification logic
main() {
    print_info "Verifying S3 backend configuration in Terraform environment roots..."
    echo
    
    local errors=0
    local checked=0
    local passed=0
    
    # Find all potential Terraform roots under infrastructure/environment/
    while IFS= read -r -d '' dir; do
        if is_terraform_root "$dir"; then
            checked=$((checked + 1))
            print_info "Checking: $dir"
            
            if has_s3_backend "$dir"; then
                print_success "S3 backend found in $dir"
                passed=$((passed + 1))
            else
                print_error "Missing S3 backend in $dir"
                errors=$((errors + 1))
            fi
            echo
        fi
    done < <(find infrastructure/environment -type d -print0 2>/dev/null || true)
    
    # Summary
    echo "=========================================="
    print_info "Verification Summary:"
    echo "  Total directories checked: $checked"
    print_success "Passed: $passed"
    
    if [[ $errors -gt 0 ]]; then
        print_error "Failed: $errors"
        echo
        print_error "The following directories are missing S3 backend configuration:"
        echo "  Add 'backend \"s3\" {}' to a terraform block in one of the .tf files"
        echo "  Example:"
        echo "    terraform {"
        echo "      required_version = \">= 1.3\""
        echo "      backend \"s3\" {}"
        echo "      # ... other configuration"
        echo "    }"
        echo
        exit 1
    else
        print_success "All Terraform environment roots have S3 backend configuration!"
        echo
        exit 0
    fi
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Verifies that all Terraform environment roots have S3 backend configuration.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output

EXAMPLES:
    $0                    # Run verification
    $0 --verbose          # Run with verbose output

DESCRIPTION:
    This script scans all directories under infrastructure/environment/ and
    verifies that each Terraform root has an S3 backend configuration.
    
    A Terraform root is identified by:
    - Contains .tf files
    - Is under infrastructure/environment/
    - Is not a module directory
    - Is not a .terraform directory
    
    S3 backend configuration is found by searching for 'backend "s3"' in
    terraform blocks within .tf files.

EXIT CODES:
    0    All directories have S3 backend configuration
    1    One or more directories are missing S3 backend configuration

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if we're in the right directory
if [[ ! -d "infrastructure/environment" ]]; then
    print_error "infrastructure/environment directory not found"
    print_error "Please run this script from the repository root"
    exit 1
fi

# Run main verification
main
