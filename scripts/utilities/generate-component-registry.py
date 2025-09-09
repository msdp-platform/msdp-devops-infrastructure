#!/usr/bin/env python3
"""
Component Registry Generator

Generates a component registry file for the new modular pipeline architecture
based on the global configuration and latest Helm chart information.

Usage:
    python3 scripts/utilities/generate-component-registry.py [--output path]
"""

import json
import subprocess
import sys
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
    json_str = json.dumps(data, indent=2)
    temp_file = "/tmp/temp_registry.json"
    with open(temp_file, 'w') as f:
        f.write(json_str)
    
    cmd = f"yq eval '.' {temp_file} -o yaml > {file_path}"
    _, success = run_command(cmd)
    run_command(f"rm {temp_file}")
    return success

def main():
    output_path = ".github/components.yml"
    if "--output" in sys.argv:
        idx = sys.argv.index("--output")
        if idx + 1 < len(sys.argv):
            output_path = sys.argv[idx + 1]
    
    config_path = "infrastructure/config/global.yaml"
    
    print(f"Loading configuration from {config_path}...")
    config_data = load_yaml_simple(config_path)
    if not config_data:
        print("Failed to load configuration")
        sys.exit(1)
    
    # Chart mapping with deployment strategies
    chart_mapping = {
        'nginx_ingress': {
            'type': 'helm',
            'chart': 'ingress-nginx',
            'repo': 'nginx_ingress',
            'category': 'networking'
        },
        'cert_manager': {
            'type': 'helm', 
            'chart': 'cert-manager',
            'repo': 'cert_manager',
            'category': 'networking'
        },
        'prometheus': {
            'type': 'helm',
            'chart': 'kube-prometheus-stack',
            'repo': 'prometheus',
            'category': 'monitoring'
        },
        'grafana': {
            'type': 'helm',
            'chart': 'grafana',
            'repo': 'grafana',
            'category': 'monitoring'
        },
        'argocd': {
            'type': 'helm',
            'chart': 'argo-cd',
            'repo': 'argo_cd',
            'category': 'gitops'
        },
        'crossplane': {
            'type': 'helm',
            'chart': 'crossplane',
            'repo': 'crossplane',
            'category': 'infrastructure'
        },
        'backstage': {
            'type': 'yaml',  # Backstage is typically deployed via YAML
            'path': 'infrastructure/applications/backstage',
            'category': 'platform'
        },
        'external_dns': {
            'type': 'yaml',
            'path': 'infrastructure/platforms/networking/external-dns',
            'category': 'networking'
        }
    }
    
    # Dependency mapping
    dependencies = {
        'grafana': ['prometheus'],
        'backstage': ['argocd'],
        'argocd': ['nginx_ingress', 'cert_manager']
    }
    
    registry = {
        'metadata': {
            'name': 'msdp-components',
            'description': 'Component registry for MSDP DevOps Infrastructure',
            'version': '1.0.0',
            'generated': subprocess.run(['date', '-u', '+%Y-%m-%dT%H:%M:%SZ'], 
                                      capture_output=True, text=True).stdout.strip()
        },
        'components': {}
    }
    
    print("Generating component registry...")
    
    # Process platform components
    if 'platform_components' in config_data:
        for name, component_config in config_data['platform_components'].items():
            if name in chart_mapping:
                mapping = chart_mapping[name]
                
                component_entry = {
                    'type': mapping['type'],
                    'category': mapping['category'],
                    'namespace': component_config.get('namespace', name),
                    'version': component_config.get('version', ''),
                    'dependencies': dependencies.get(name, [])
                }
                
                if mapping['type'] == 'helm':
                    component_entry.update({
                        'chart': mapping['chart'],
                        'repository': config_data['helm_repos'].get(mapping['repo'], ''),
                        'chart_version': component_config.get('chart_version', '')
                    })
                elif mapping['type'] == 'yaml':
                    component_entry['path'] = mapping['path']
                
                registry['components'][name] = component_entry
    
    # Process applications
    if 'applications' in config_data:
        for name, component_config in config_data['applications'].items():
            if name in chart_mapping:
                mapping = chart_mapping[name]
                
                component_entry = {
                    'type': mapping['type'],
                    'category': mapping['category'],
                    'namespace': component_config.get('namespace', name),
                    'version': component_config.get('version', ''),
                    'dependencies': dependencies.get(name, [])
                }
                
                if mapping['type'] == 'helm':
                    component_entry.update({
                        'chart': mapping['chart'],
                        'repository': config_data['helm_repos'].get(mapping['repo'], ''),
                        'chart_version': component_config.get('chart_version', '')
                    })
                elif mapping['type'] == 'yaml':
                    component_entry['path'] = mapping['path']
                
                registry['components'][name] = component_entry
    
    # Create output directory if it doesn't exist
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Save registry
    if save_yaml_simple(registry, output_path):
        print(f"✅ Generated component registry: {output_path}")
        
        # Print summary
        print(f"\n📊 REGISTRY SUMMARY")
        print("-" * 40)
        print(f"Total components: {len(registry['components'])}")
        
        helm_components = [c for c in registry['components'].values() if c['type'] == 'helm']
        yaml_components = [c for c in registry['components'].values() if c['type'] == 'yaml']
        
        print(f"Helm components: {len(helm_components)}")
        print(f"YAML components: {len(yaml_components)}")
        
        categories = {}
        for comp in registry['components'].values():
            cat = comp['category']
            categories[cat] = categories.get(cat, 0) + 1
        
        print(f"\nBy category:")
        for cat, count in categories.items():
            print(f"  {cat}: {count}")
        
        print(f"\nRegistry file: {output_path}")
    else:
        print(f"❌ Failed to generate registry: {output_path}")
        sys.exit(1)

if __name__ == "__main__":
    main()
