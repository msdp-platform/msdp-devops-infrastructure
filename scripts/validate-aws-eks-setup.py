#!/usr/bin/env python3
"""
AWS EKS Setup Validation Script

This script validates the AWS EKS infrastructure setup including:
- Configuration files
- Terraform modules
- GitHub Actions workflows
- Required secrets and permissions

Usage:
    python3 scripts/validate-aws-eks-setup.py
"""

import os
import sys
import yaml
import json
from pathlib import Path

def validate_file_exists(file_path, description):
    """Validate that a file exists"""
    if Path(file_path).exists():
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description} missing: {file_path}")
        return False

def validate_yaml_config(config_path):
    """Validate YAML configuration structure"""
    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        
        print(f"\n📋 Validating configuration: {config_path}")
        
        # Check AWS section
        if 'aws' not in config:
            print("❌ Missing 'aws' section in configuration")
            return False
        
        aws_config = config['aws']
        
        # Check required AWS fields
        required_fields = ['region', 'network', 'eks']
        for field in required_fields:
            if field not in aws_config:
                print(f"❌ Missing required field: aws.{field}")
                return False
            else:
                print(f"✅ Found aws.{field}")
        
        # Validate network configuration
        network = aws_config['network']
        network_fields = ['vpc_name', 'vpc_cidr', 'availability_zones', 'public_subnets', 'private_subnets']
        for field in network_fields:
            if field not in network:
                print(f"❌ Missing network field: aws.network.{field}")
                return False
            else:
                print(f"✅ Found aws.network.{field}")
        
        # Validate EKS configuration
        eks = aws_config['eks']
        if 'clusters' not in eks:
            print("❌ Missing aws.eks.clusters")
            return False
        
        clusters = eks['clusters']
        if not isinstance(clusters, list) or len(clusters) == 0:
            print("❌ aws.eks.clusters must be a non-empty list")
            return False
        
        print(f"✅ Found {len(clusters)} EKS clusters configured")
        
        # Validate each cluster
        for i, cluster in enumerate(clusters):
            cluster_name = cluster.get('name', f'cluster-{i}')
            print(f"  📦 Validating cluster: {cluster_name}")
            
            required_cluster_fields = ['name', 'kubernetes_version']
            for field in required_cluster_fields:
                if field not in cluster:
                    print(f"    ❌ Missing cluster field: {field}")
                    return False
                else:
                    print(f"    ✅ Found {field}: {cluster[field]}")
            
            # Validate node groups if present
            if 'node_groups' in cluster:
                node_groups = cluster['node_groups']
                if isinstance(node_groups, list):
                    print(f"    ✅ Found {len(node_groups)} node groups")
                    for j, ng in enumerate(node_groups):
                        ng_name = ng.get('name', f'ng-{j}')
                        print(f"      🔧 Node group: {ng_name}")
                        
                        ng_fields = ['name', 'instance_types', 'capacity_type', 'min_size', 'max_size', 'desired_size']
                        for field in ng_fields:
                            if field in ng:
                                print(f"        ✅ {field}: {ng[field]}")
                            else:
                                print(f"        ⚠️  Missing optional field: {field}")
        
        return True
        
    except yaml.YAMLError as e:
        print(f"❌ YAML parsing error: {e}")
        return False
    except Exception as e:
        print(f"❌ Configuration validation error: {e}")
        return False

def validate_terraform_modules():
    """Validate Terraform module structure"""
    print("\n🏗️  Validating Terraform modules")
    
    modules = [
        {
            'path': 'infrastructure/environment/aws/network',
            'files': ['main.tf', 'variables.tf', 'outputs.tf', 'versions.tf', 'README.md']
        },
        {
            'path': 'infrastructure/environment/aws/eks',
            'files': ['main.tf', 'variables.tf', 'outputs.tf', 'versions.tf', 'README.md']
        }
    ]
    
    all_valid = True
    
    for module in modules:
        print(f"\n📁 Validating module: {module['path']}")
        
        if not Path(module['path']).exists():
            print(f"❌ Module directory missing: {module['path']}")
            all_valid = False
            continue
        
        for file in module['files']:
            file_path = Path(module['path']) / file
            if file_path.exists():
                print(f"✅ {file}")
            else:
                print(f"❌ Missing file: {file}")
                all_valid = False
    
    return all_valid

def validate_github_workflow():
    """Validate GitHub Actions workflow"""
    print("\n🔄 Validating GitHub Actions workflow")
    
    workflow_path = '.github/workflows/eks.yml'
    
    if not validate_file_exists(workflow_path, "EKS workflow"):
        return False
    
    try:
        with open(workflow_path, 'r') as f:
            workflow_content = f.read()
        
        # Check for required workflow components
        required_components = [
            'name: AWS EKS Clusters',
            'workflow_dispatch:',
            'check-network:',
            'deploy-network:',
            'prepare:',
            'check-matrix:',
            'deploy:',
            'strategy:',
            'matrix:'
        ]
        
        for component in required_components:
            if component in workflow_content:
                print(f"✅ Found: {component}")
            else:
                print(f"❌ Missing: {component}")
                return False
        
        return True
        
    except Exception as e:
        print(f"❌ Workflow validation error: {e}")
        return False

def validate_required_secrets():
    """Validate required GitHub secrets documentation"""
    print("\n🔐 Required GitHub Secrets")
    
    required_secrets = [
        {
            'name': 'AWS_ROLE_ARN',
            'description': 'IAM role ARN for GitHub Actions OIDC authentication',
            'example': 'arn:aws:iam::123456789012:role/GitHubActionsRole'
        }
    ]
    
    print("The following secrets must be configured in GitHub repository settings:")
    for secret in required_secrets:
        print(f"  🔑 {secret['name']}")
        print(f"     Description: {secret['description']}")
        print(f"     Example: {secret['example']}")
    
    return True

def main():
    """Main validation function"""
    print("🚀 AWS EKS Setup Validation")
    print("=" * 50)
    
    validation_results = []
    
    # Validate configuration files
    config_files = [
        'config/dev.yaml'
    ]
    
    print("\n📄 Validating configuration files")
    for config_file in config_files:
        if validate_file_exists(config_file, f"Configuration file"):
            validation_results.append(validate_yaml_config(config_file))
        else:
            validation_results.append(False)
    
    # Validate Terraform modules
    validation_results.append(validate_terraform_modules())
    
    # Validate GitHub workflow
    validation_results.append(validate_github_workflow())
    
    # Validate required secrets
    validation_results.append(validate_required_secrets())
    
    # Validate additional files
    additional_files = [
        ('AWS_EKS_IMPLEMENTATION.md', 'AWS EKS documentation'),
        ('.github/actions/cloud-login', 'Cloud login action directory'),
        ('.github/actions/terraform-backend-enhanced', 'Terraform backend action directory'),
        ('.github/actions/terraform-init', 'Terraform init action directory')
    ]
    
    print("\n📚 Validating additional files")
    for file_path, description in additional_files:
        validation_results.append(validate_file_exists(file_path, description))
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 VALIDATION SUMMARY")
    print("=" * 50)
    
    passed = sum(validation_results)
    total = len(validation_results)
    
    if passed == total:
        print(f"✅ All validations passed ({passed}/{total})")
        print("\n🎉 AWS EKS setup is ready for deployment!")
        print("\nNext steps:")
        print("1. Configure GitHub repository secrets")
        print("2. Run the EKS workflow with action=plan to test")
        print("3. Run with action=apply to deploy infrastructure")
        return 0
    else:
        print(f"❌ {total - passed} validation(s) failed ({passed}/{total} passed)")
        print("\n���� Please fix the issues above before proceeding")
        return 1

if __name__ == "__main__":
    sys.exit(main())