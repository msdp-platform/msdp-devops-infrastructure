#!/usr/bin/env python3
"""Quick validation script for AWS EKS setup"""

import yaml
import json
from pathlib import Path

def main():
    print("🚀 Quick AWS EKS Setup Validation")
    print("=" * 40)
    
    # Test YAML parsing
    try:
        with open('config/dev.yaml', 'r') as f:
            config = yaml.safe_load(f)
        print("✅ YAML configuration is valid")
        
        # Check AWS section
        if 'aws' in config and 'eks' in config['aws']:
            clusters = config['aws']['eks']['clusters']
            print(f"✅ Found {len(clusters)} EKS clusters configured")
        else:
            print("❌ AWS EKS configuration missing")
            
    except Exception as e:
        print(f"❌ YAML validation failed: {e}")
        return 1
    
    # Check file structure
    required_files = [
        'infrastructure/environment/aws/network/main.tf',
        'infrastructure/environment/aws/network/variables.tf',
        'infrastructure/environment/aws/network/outputs.tf',
        'infrastructure/environment/aws/eks/main.tf',
        'infrastructure/environment/aws/eks/variables.tf',
        'infrastructure/environment/aws/eks/outputs.tf',
        '.github/workflows/eks.yml'
    ]
    
    missing_files = []
    for file_path in required_files:
        if Path(file_path).exists():
            print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path}")
            missing_files.append(file_path)
    
    if missing_files:
        print(f"\n❌ {len(missing_files)} files missing")
        return 1
    else:
        print(f"\n✅ All {len(required_files)} required files present")
        print("\n🎉 AWS EKS setup validation passed!")
        print("\nNext steps:")
        print("1. Configure GitHub secrets (AWS_ROLE_ARN)")
        print("2. Test with: workflow_dispatch -> action=plan")
        print("3. Deploy with: workflow_dispatch -> action=apply")
        return 0

if __name__ == "__main__":
    exit(main())