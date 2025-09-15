#!/usr/bin/env python3
"""
Test AKS Matrix Generation

This script tests the AKS workflow matrix generation locally.
"""

import yaml
import json
import os
import sys

def test_matrix_generation(env='dev', cluster_filter=''):
    """Test matrix generation for AKS workflow"""
    
    print(f"🔍 Testing AKS matrix generation for environment: {env}")
    
    try:
        config_file = f'config/{env}.yaml'
        
        if not os.path.exists(config_file):
            print(f"❌ ERROR: Configuration file not found: {config_file}")
            return {"include": []}
        
        print(f"✅ Found configuration file: {config_file}")
        
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)
        
        print(f"📋 Configuration structure:")
        print(f"  - azure: {'✅' if 'azure' in config else '❌'}")
        if 'azure' in config:
            print(f"    - location: {config['azure'].get('location', 'NOT SET')}")
            print(f"    - network: {'✅' if 'network' in config['azure'] else '❌'}")
            if 'network' in config['azure']:
                network = config['azure']['network']
                print(f"      - resource_group_name: {network.get('resource_group_name', 'NOT SET')}")
                print(f"      - vnet_name: {network.get('vnet_name', 'NOT SET')}")
            print(f"    - aks: {'✅' if 'aks' in config['azure'] else '❌'}")
            if 'aks' in config['azure']:
                print(f"      - clusters: {'✅' if 'clusters' in config['azure']['aks'] else '❌'}")
        
        # Extract AKS clusters
        clusters = config.get('azure', {}).get('aks', {}).get('clusters', [])
        
        if not clusters:
            print(f"⚠️  WARNING: No AKS clusters defined in {config_file}")
            return {"include": []}
        
        print(f"✅ Found {len(clusters)} clusters in configuration:")
        for i, cluster in enumerate(clusters, 1):
            print(f"  {i}. {cluster.get('name', 'UNNAMED')}")
        
        # Filter by cluster name if specified
        if cluster_filter:
            original_count = len(clusters)
            clusters = [c for c in clusters if c.get('name') == cluster_filter]
            print(f"🔍 Filtered from {original_count} to {len(clusters)} clusters matching '{cluster_filter}'")
        
        # Add environment and network info to each cluster
        network_config = config.get('azure', {}).get('network', {})
        
        for cluster in clusters:
            cluster['environment'] = env
            cluster['location'] = config.get('azure', {}).get('location', 'uksouth')
            cluster['network_resource_group_name'] = network_config.get('resource_group_name', '')
            cluster['vnet_name'] = network_config.get('vnet_name', '')
            cluster['tenant_id'] = "PLACEHOLDER_TENANT_ID"
            
            # Ensure all required fields have defaults
            cluster.setdefault('kubernetes_version', '1.29.7')
            cluster.setdefault('system_node_count', 2)
            cluster.setdefault('system_vm_size', 'Standard_D2s_v3')
            cluster.setdefault('user_vm_size', 'Standard_D4s_v3')
            cluster.setdefault('user_min_count', 1)
            cluster.setdefault('user_max_count', 5)
            cluster.setdefault('user_spot_enabled', False)
        
        matrix = {"include": clusters}
        
        print(f"\n📊 Generated matrix with {len(clusters)} clusters")
        
        return matrix
        
    except Exception as e:
        print(f"❌ ERROR generating matrix: {e}")
        import traceback
        traceback.print_exc()
        return {"include": []}

def main():
    """Main test function"""
    
    print("🚀 Testing AKS Matrix Generation")
    print("=" * 50)
    
    # Test for dev environment
    matrix = test_matrix_generation('dev')
    
    print("\n📋 Matrix Output:")
    print(json.dumps(matrix, indent=2))
    
    if matrix['include']:
        print(f"\n✅ Matrix generation successful!")
        print(f"   {len(matrix['include'])} clusters will be deployed")
        
        for cluster in matrix['include']:
            print(f"\n   Cluster: {cluster['name']}")
            print(f"     - Subnet: {cluster.get('subnet_name', 'NOT SET')}")
            print(f"     - K8s Version: {cluster['kubernetes_version']}")
            print(f"     - System Nodes: {cluster['system_node_count']}x {cluster['system_vm_size']}")
            print(f"     - User Nodes: {cluster['user_min_count']}-{cluster['user_max_count']}x {cluster['user_vm_size']}")
            print(f"     - Spot: {cluster['user_spot_enabled']}")
    else:
        print("\n⚠️  WARNING: Empty matrix generated!")
        print("   Check your configuration file for AKS clusters")
        
        # Show example configuration
        print("\n📖 Example configuration (config/dev.yaml):")
        print("""
azure:
  location: uksouth
  network:
    resource_group_name: rg-msdp-network-dev
    vnet_name: vnet-msdp-dev
  aks:
    clusters:
      - name: aks-msdp-dev-01
        subnet_name: snet-aks-system-dev
        kubernetes_version: "1.29.7"
        system_node_count: 2
        """)
    
    return len(matrix['include']) > 0

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)