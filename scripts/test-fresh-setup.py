#!/usr/bin/env python3
"""
Test Fresh Setup

This script tests the new clean Azure infrastructure setup.
"""

import yaml
import json
import sys
from pathlib import Path

def test_configuration():
    """Test the configuration file"""
    print("🔍 Testing configuration file...")
    
    config_file = Path("config/dev.yaml")
    if not config_file.exists():
        print("❌ Configuration file not found: config/dev.yaml")
        return False
    
    try:
        with open(config_file) as f:
            config = yaml.safe_load(f)
        
        # Test required sections
        required_sections = [
            'environment',
            'azure.location',
            'azure.network.resource_group_name',
            'azure.network.vnet_name',
            'azure.network.vnet_cidr',
            'azure.network.subnets',
            'azure.aks.clusters',
            'tags'
        ]
        
        for section in required_sections:
            keys = section.split('.')
            value = config
            for key in keys:
                value = value.get(key, {})
            
            if not value:
                print(f"❌ Missing configuration section: {section}")
                return False
            else:
                print(f"✅ Found configuration section: {section}")
        
        # Test subnets
        subnets = config['azure']['network']['subnets']
        if len(subnets) < 1:
            print("❌ No subnets configured")
            return False
        
        for subnet in subnets:
            if not all(key in subnet for key in ['name', 'cidr']):
                print(f"❌ Invalid subnet configuration: {subnet}")
                return False
        
        print(f"✅ Found {len(subnets)} subnets configured")
        
        # Test AKS clusters
        clusters = config['azure']['aks']['clusters']
        if len(clusters) < 1:
            print("❌ No AKS clusters configured")
            return False
        
        for cluster in clusters:
            required_cluster_keys = ['name', 'subnet_name', 'kubernetes_version']
            if not all(key in cluster for key in required_cluster_keys):
                print(f"❌ Invalid cluster configuration: {cluster}")
                return False
        
        print(f"✅ Found {len(clusters)} AKS clusters configured")
        
        return True
        
    except Exception as e:
        print(f"❌ Error parsing configuration: {e}")
        return False

def test_terraform_modules():
    """Test Terraform module files"""
    print("\n🏗️  Testing Terraform modules...")
    
    # Test network module
    network_files = [
        "infrastructure/environment/azure/network/main.tf",
        "infrastructure/environment/azure/network/variables.tf",
        "infrastructure/environment/azure/network/outputs.tf"
    ]
    
    for file_path in network_files:
        if Path(file_path).exists():
            print(f"✅ Found network module file: {file_path}")
        else:
            print(f"❌ Missing network module file: {file_path}")
            return False
    
    # Test AKS module
    aks_files = [
        "infrastructure/environment/azure/aks/main.tf",
        "infrastructure/environment/azure/aks/variables.tf",
        "infrastructure/environment/azure/aks/outputs.tf"
    ]
    
    for file_path in aks_files:
        if Path(file_path).exists():
            print(f"✅ Found AKS module file: {file_path}")
        else:
            print(f"❌ Missing AKS module file: {file_path}")
            return False
    
    return True

def test_workflows():
    """Test GitHub Actions workflows"""
    print("\n⚙️  Testing GitHub Actions workflows...")
    
    workflow_files = [
        ".github/workflows/azure-network.yml",
        ".github/workflows/aks.yml"
    ]
    
    for file_path in workflow_files:
        if Path(file_path).exists():
            print(f"✅ Found workflow file: {file_path}")
        else:
            print(f"❌ Missing workflow file: {file_path}")
            return False
    
    return True

def test_backend_generation():
    """Test backend configuration generation"""
    print("\n🔧 Testing backend configuration generation...")
    
    try:
        # Test network backend
        import subprocess
        result = subprocess.run([
            "python3", "scripts/generate-backend-config.py", 
            "dev", "azure", "network"
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            config = json.loads(result.stdout)
            if all(key in config for key in ['bucket', 'key', 'region', 'dynamodb_table']):
                print("✅ Network backend configuration generation works")
            else:
                print("❌ Network backend configuration missing required keys")
                return False
        else:
            print(f"❌ Network backend configuration generation failed: {result.stderr}")
            return False
        
        # Test AKS backend
        result = subprocess.run([
            "python3", "scripts/generate-backend-config.py", 
            "dev", "azure", "aks", "cluster-01"
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            config = json.loads(result.stdout)
            if all(key in config for key in ['bucket', 'key', 'region', 'dynamodb_table']):
                print("✅ AKS backend configuration generation works")
            else:
                print("❌ AKS backend configuration missing required keys")
                return False
        else:
            print(f"❌ AKS backend configuration generation failed: {result.stderr}")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Backend configuration generation error: {e}")
        return False

def test_tfvars_generation():
    """Test Terraform variables generation"""
    print("\n📝 Testing Terraform variables generation...")
    
    try:
        # Load configuration
        with open("config/dev.yaml") as f:
            config = yaml.safe_load(f)
        
        # Test network tfvars generation
        network_config = config['azure']['network']
        tags = config.get('tags', {})
        
        network_tfvars = {
            'resource_group_name': network_config['resource_group_name'],
            'location': config['azure']['location'],
            'vnet_name': network_config['vnet_name'],
            'vnet_cidr': network_config['vnet_cidr'],
            'subnets': network_config['subnets'],
            'tags': tags
        }
        
        print("✅ Network tfvars generation works")
        print(f"   Resource Group: {network_tfvars['resource_group_name']}")
        print(f"   VNet: {network_tfvars['vnet_name']}")
        print(f"   Subnets: {len(network_tfvars['subnets'])}")
        
        # Test AKS tfvars generation
        cluster = config['azure']['aks']['clusters'][0]
        aks_tfvars = {
            'cluster_name': cluster['name'],
            'kubernetes_version': cluster['kubernetes_version'],
            'network_resource_group_name': network_config['resource_group_name'],
            'vnet_name': network_config['vnet_name'],
            'subnet_name': cluster['subnet_name'],
            'tags': tags
        }
        
        print("✅ AKS tfvars generation works")
        print(f"   Cluster: {aks_tfvars['cluster_name']}")
        print(f"   Kubernetes Version: {aks_tfvars['kubernetes_version']}")
        print(f"   Subnet: {aks_tfvars['subnet_name']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Tfvars generation error: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Testing Fresh Azure Infrastructure Setup")
    print("=" * 50)
    
    tests = [
        test_configuration,
        test_terraform_modules,
        test_workflows,
        test_backend_generation,
        test_tfvars_generation
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        else:
            print()
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your fresh setup is ready.")
        print("\n📋 Next steps:")
        print("1. Run: gh workflow run azure-network.yml -f action=plan")
        print("2. If plan looks good: gh workflow run azure-network.yml -f action=apply")
        print("3. Then run: gh workflow run aks.yml -f action=plan")
        print("4. If plan looks good: gh workflow run aks.yml -f action=apply")
        return True
    else:
        print("❌ Some tests failed. Please fix the issues above.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)