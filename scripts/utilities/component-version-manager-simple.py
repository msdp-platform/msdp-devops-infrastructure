#!/usr/bin/env python3
"""
MSDP Component Version Manager (Simple Version)

This script uses only Python standard library to manage component versions.
It reads global.yaml and interacts with Helm CLI to get latest versions.

Usage:
    python3 scripts/utilities/component-version-manager-simple.py [--check-only] [--update]
"""

import json
import subprocess
import sys
import re
from pathlib import Path

def run_command(cmd):
    """Run a shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip(), True
    except subprocess.CalledProcessError as e:
        print(f"Error running command '{cmd}': {e.stderr}")
        return "", False

def load_yaml_simple(file_path):
    """Simple YAML loader using yq"""
    output, success = run_command(f"yq eval '.' {file_path} -o json")
    if success:
        try:
            return json.loads(output)
        except json.JSONDecodeError as e:
            print(f"Error parsing YAML as JSON: {e}")
            return None
    return None

def save_yaml_simple(data, file_path):
    """Simple YAML saver using yq"""
    # Convert back to YAML
    json_str = json.dumps(data, indent=2)
    temp_file = "/tmp/temp_config.json"
    with open(temp_file, 'w') as f:
        f.write(json_str)
    
    # Convert JSON to YAML
    cmd = f"yq eval '.' {temp_file} -o yaml > {file_path}"
    _, success = run_command(cmd)
    run_command(f"rm {temp_file}")
    return success

def setup_helm_repos(config_data):
    """Setup Helm repositories"""
    if 'helm_repos' not in config_data:
        print("No helm_repos found in config")
        return False
    
    print("Setting up Helm repositories...")
    for name, url in config_data['helm_repos'].items():
        print(f"Adding repo: {name} -> {url}")
        run_command(f"helm repo add {name} {url}")
    
    print("Updating Helm repositories...")
    run_command("helm repo update")
    return True

def get_latest_chart_version(repo_name, chart_name):
    """Get latest version of a Helm chart"""
    cmd = f"helm search repo {repo_name}/{chart_name} --output json"
    output, success = run_command(cmd)
    
    if success and output:
        try:
            charts = json.loads(output)
            if charts:
                chart = charts[0]  # First result is usually the latest
                return {
                    'chart_version': chart['version'],
                    'app_version': chart.get('app_version', chart['version'])
                }
        except json.JSONDecodeError:
            pass
    
    return None

def normalize_version(version):
    """Normalize version for comparison"""
    if not version:
        return ""
    return re.sub(r'^v', '', str(version))

def main():
    config_path = "infrastructure/config/global.yaml"
    
    # Check if we have required tools
    tools = ['yq', 'helm']
    for tool in tools:
        _, success = run_command(f"which {tool}")
        if not success:
            print(f"Error: {tool} is not installed. Please install it first.")
            sys.exit(1)
    
    # Load configuration
    print(f"Loading configuration from {config_path}...")
    config_data = load_yaml_simple(config_path)
    if not config_data:
        print("Failed to load configuration")
        sys.exit(1)
    
    # Setup Helm repositories
    if not setup_helm_repos(config_data):
        print("Failed to setup Helm repositories")
        sys.exit(1)
    
    # Chart mapping
    chart_mapping = {
        'nginx_ingress': {'repo': 'nginx_ingress', 'chart': 'ingress-nginx'},
        'cert_manager': {'repo': 'cert_manager', 'chart': 'cert-manager'},
        'prometheus': {'repo': 'prometheus', 'chart': 'kube-prometheus-stack'},
        'grafana': {'repo': 'grafana', 'chart': 'grafana'},
        'argocd': {'repo': 'argo_cd', 'chart': 'argo-cd'},
        'crossplane': {'repo': 'crossplane', 'chart': 'crossplane'},
        'backstage': {'repo': 'backstage', 'chart': 'backstage'}
    }
    
    print("\n" + "="*80)
    print("🔍 COMPONENT VERSION REPORT")
    print("="*80)
    
    updates_needed = []
    
    # Check platform components
    if 'platform_components' in config_data:
        print("\n📦 PLATFORM COMPONENTS")
        print("-" * 80)
        print(f"{'Component':<15} {'Current Chart':<15} {'Latest Chart':<15} {'Current App':<12} {'Latest App':<12} {'Update?'}")
        print("-" * 80)
        
        for name, component_config in config_data['platform_components'].items():
            # Skip external-dns as requested
            if name == 'external_dns':
                print(f"{name:<15} {'SKIPPED':<15} {'(requested)':<15} {'N/A':<12} {'N/A':<12} {'➖'}")
                continue
            
            current_chart = component_config.get('chart_version', 'N/A')
            current_app = component_config.get('version', 'N/A')
            
            if name in chart_mapping:
                mapping = chart_mapping[name]
                latest_info = get_latest_chart_version(mapping['repo'], mapping['chart'])
                
                if latest_info:
                    latest_chart = latest_info['chart_version']
                    latest_app = latest_info['app_version']
                    
                    # Check if update needed
                    needs_update = (normalize_version(current_chart) != normalize_version(latest_chart))
                    update_status = "🔄 YES" if needs_update else "✅ NO"
                    
                    if needs_update:
                        updates_needed.append({
                            'name': name,
                            'type': 'platform_components',
                            'current_chart': current_chart,
                            'latest_chart': latest_chart,
                            'current_app': current_app,
                            'latest_app': latest_app
                        })
                    
                    print(f"{name:<15} {current_chart:<15} {latest_chart:<15} {current_app:<12} {latest_app:<12} {update_status}")
                else:
                    print(f"{name:<15} {current_chart:<15} {'ERROR':<15} {current_app:<12} {'ERROR':<12} {'❌'}")
            else:
                print(f"{name:<15} {current_chart:<15} {'NO MAPPING':<15} {current_app:<12} {'N/A':<12} {'⚠️'}")
    
    # Check applications
    if 'applications' in config_data:
        print("\n📦 APPLICATIONS")
        print("-" * 80)
        print(f"{'Component':<15} {'Current Chart':<15} {'Latest Chart':<15} {'Current App':<12} {'Latest App':<12} {'Update?'}")
        print("-" * 80)
        
        for name, component_config in config_data['applications'].items():
            current_chart = component_config.get('chart_version', 'N/A')
            current_app = component_config.get('version', 'N/A')
            
            if name in chart_mapping:
                mapping = chart_mapping[name]
                latest_info = get_latest_chart_version(mapping['repo'], mapping['chart'])
                
                if latest_info:
                    latest_chart = latest_info['chart_version']
                    latest_app = latest_info['app_version']
                    
                    # Check if update needed
                    needs_update = (normalize_version(current_chart) != normalize_version(latest_chart))
                    update_status = "🔄 YES" if needs_update else "✅ NO"
                    
                    if needs_update:
                        updates_needed.append({
                            'name': name,
                            'type': 'applications',
                            'current_chart': current_chart,
                            'latest_chart': latest_chart,
                            'current_app': current_app,
                            'latest_app': latest_app
                        })
                    
                    print(f"{name:<15} {current_chart:<15} {latest_chart:<15} {current_app:<12} {latest_app:<12} {update_status}")
                else:
                    print(f"{name:<15} {current_chart:<15} {'ERROR':<15} {current_app:<12} {'ERROR':<12} {'❌'}")
            else:
                print(f"{name:<15} {current_chart:<15} {'NO MAPPING':<15} {current_app:<12} {'N/A':<12} {'⚠️'}")
    
    # Summary
    print(f"\n📊 SUMMARY")
    print("-" * 40)
    total_components = len([c for c in config_data.get('platform_components', {}).keys() if c != 'external_dns']) + len(config_data.get('applications', {}))
    print(f"Total components: {total_components}")
    print(f"Updates available: {len(updates_needed)}")
    print(f"Up to date: {total_components - len(updates_needed)}")
    
    # Check if we should update
    if "--update" in sys.argv and updates_needed:
        print(f"\n🔄 UPDATING CONFIGURATION...")
        print("=" * 40)
        
        # Create backup
        backup_path = f"{config_path}.backup.{subprocess.run(['date', '+%Y%m%d_%H%M%S'], capture_output=True, text=True).stdout.strip()}"
        run_command(f"cp {config_path} {backup_path}")
        print(f"Created backup: {backup_path}")
        
        # Update configuration
        for update in updates_needed:
            section = config_data[update['type']][update['name']]
            section['chart_version'] = update['latest_chart']
            section['version'] = update['latest_app']
            print(f"Updated {update['name']}: {update['current_chart']} -> {update['latest_chart']}")
        
        # Save updated configuration
        if save_yaml_simple(config_data, config_path):
            print(f"✅ Updated {config_path}")
        else:
            print(f"❌ Failed to update {config_path}")
    elif updates_needed and "--check-only" not in sys.argv:
        print(f"\n💡 To update configuration, run:")
        print(f"   python3 {sys.argv[0]} --update")
    
    print(f"\n✅ Component version check completed!")

if __name__ == "__main__":
    main()
