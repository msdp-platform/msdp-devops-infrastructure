#!/bin/bash

# Script to format all Terraform files in the repository

echo "Running terraform fmt on all Terraform files..."

# Find all directories containing .tf files and run terraform fmt
find . -type f -name "*.tf" -exec dirname {} \; | sort -u | while read dir; do
    echo "Formatting files in: $dir"
    terraform fmt "$dir"
done

echo "Terraform formatting complete!"