#!/usr/bin/env python3
"""
Validate Terraform Modules

This script validates that the Terraform modules are properly configured
and don't have duplicate configurations.
"""

import os
import sys
from pathlib import Path

def check_terraform_files(module_path):
    """Check Terraform files in a module for common issues"""
    print(f"🔍 Checking {module_path}...")
    
    issues = []
    
    # Check for required files
    required_files = ['main.tf', 'variables.tf', 'outputs.tf', 'versions.tf']
    for file in required_files:
        file_path = module_path / file
        if file_path.exists():
            print(f"  ✅ Found {file}")
        else:
            issues.append(f"Missing required file: {file}")
    
    # Check for duplicate terraform blocks
    terraform_blocks = 0
    provider_blocks = 0
    
    for tf_file in module_path.glob('*.tf'):
        with open(tf_file, 'r') as f:
            content = f.read()
            
        # Count terraform blocks
        terraform_blocks += content.count('terraform {')
        
        # Count provider blocks (azurerm specifically)
        provider_blocks += content.count('provider "azurerm" {')
    
    if terraform_blocks > 1:
        issues.append(f"Multiple terraform blocks found ({terraform_blocks})")
    elif terraform_blocks == 1:
        print(f"  ✅ Found 1 terraform block")
    else:
        issues.append("No terraform block found")
    
    if provider_blocks > 1:
        issues.append(f"Multiple azurerm provider blocks found ({provider_blocks})")
    elif provider_blocks == 1:
        print(f"  ✅ Found 1 azurerm provider block")
    else:
        issues.append("No azurerm provider block found")
    
    # Check for old files that might cause conflicts
    old_files = ['locals.tf', 'network.tf', 'cleanup.sh']
    for old_file in old_files:
        old_file_path = module_path / old_file
        if old_file_path.exists():
            issues.append(f"Old file still exists: {old_file} (may cause conflicts)")
    
    return issues

def main():
    """Main validation function"""
    print("🔧 Validating Terraform Modules")
    print("=" * 40)
    
    # Check network module
    network_path = Path("infrastructure/environment/azure/network")
    network_issues = check_terraform_files(network_path)
    
    print()
    
    # Check AKS module
    aks_path = Path("infrastructure/environment/azure/aks")
    aks_issues = check_terraform_files(aks_path)
    
    print()
    print("📊 Validation Summary")
    print("=" * 40)
    
    total_issues = len(network_issues) + len(aks_issues)
    
    if network_issues:
        print("❌ Network module issues:")
        for issue in network_issues:
            print(f"  • {issue}")
    else:
        print("✅ Network module: No issues found")
    
    if aks_issues:
        print("❌ AKS module issues:")
        for issue in aks_issues:
            print(f"  • {issue}")
    else:
        print("✅ AKS module: No issues found")
    
    print()
    
    if total_issues == 0:
        print("🎉 All modules validated successfully!")
        print("Ready to run terraform init and plan.")
        return True
    else:
        print(f"⚠️  Found {total_issues} issues that need to be fixed.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)