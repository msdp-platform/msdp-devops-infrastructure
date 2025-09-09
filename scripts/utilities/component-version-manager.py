#!/usr/bin/env python3
"""
MSDP Component Version Manager

This script automatically discovers components from global.yaml, checks Helm repositories
for latest versions, and updates configurations accordingly.

Features:
- Discovers components from global configuration
- Connects to Helm repositories to fetch latest versions
- Compares current vs latest versions
- Updates global.yaml with latest versions
- Generates component registry for new pipeline architecture
- Excludes external-dns from processing (as requested)

Usage:
    python3 scripts/utilities/component-version-manager.py [options]

Options:
    --check-only        Only check versions, don't update
    --update-config     Update global.yaml with latest versions
    --generate-registry Generate component registry for new pipeline
    --dry-run          Show what would be changed without making changes
"""

import yaml
import requests
import subprocess
import json
import sys
import argparse
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional
from dataclasses import dataclass, asdict
from datetime import datetime
import re
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class ComponentInfo:
    """Component information structure"""
    name: str
    type: str  # 'platform_components' or 'applications'
    current_version: str
    current_chart_version: str
    latest_version: Optional[str] = None
    latest_chart_version: Optional[str] = None
    image: str = ""
    namespace: str = ""
    helm_repo: str = ""
    helm_chart: str = ""
    needs_update: bool = False

class HelmRepoManager:
    """Manages Helm repository operations"""
    
    def __init__(self):
        self.repos = {}
    
    def add_repo(self, name: str, url: str) -> bool:
        """Add a Helm repository"""
        try:
            cmd = ["helm", "repo", "add", name, url]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info(f"Added Helm repo: {name} -> {url}")
            self.repos[name] = url
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to add Helm repo {name}: {e.stderr}")
            return False
    
    def update_repos(self) -> bool:
        """Update all Helm repositories"""
        try:
            cmd = ["helm", "repo", "update"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info("Updated all Helm repositories")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to update Helm repos: {e.stderr}")
            return False
    
    def search_chart(self, repo_name: str, chart_name: str) -> Optional[Dict]:
        """Search for a chart in a repository"""
        try:
            cmd = ["helm", "search", "repo", f"{repo_name}/{chart_name}", "--output", "json"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            charts = json.loads(result.stdout)
            
            if charts:
                # Return the first (most relevant) result
                chart = charts[0]
                return {
                    'name': chart['name'],
                    'version': chart['version'],
                    'app_version': chart.get('app_version', chart['version'])
                }
            return None
        except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
            logger.error(f"Failed to search chart {repo_name}/{chart_name}: {e}")
            return None

class ComponentVersionManager:
    """Main component version management class"""
    
    def __init__(self, config_path: str = "infrastructure/config/global.yaml"):
        self.config_path = Path(config_path)
        self.helm_manager = HelmRepoManager()
        self.components: List[ComponentInfo] = []
        self.config_data = {}
        
        # Component to Helm chart mapping
        self.chart_mapping = {
            'nginx_ingress': {
                'repo': 'nginx_ingress',
                'chart': 'ingress-nginx'
            },
            'cert_manager': {
                'repo': 'cert_manager', 
                'chart': 'cert-manager'
            },
            'prometheus': {
                'repo': 'prometheus',
                'chart': 'kube-prometheus-stack'
            },
            'grafana': {
                'repo': 'grafana',
                'chart': 'grafana'
            },
            'argocd': {
                'repo': 'argo_cd',
                'chart': 'argo-cd'
            },
            'crossplane': {
                'repo': 'crossplane',
                'chart': 'crossplane'
            },
            'backstage': {
                'repo': 'backstage',
                'chart': 'backstage'
            }
        }
    
    def load_config(self) -> bool:
        """Load the global configuration file"""
        try:
            with open(self.config_path, 'r') as f:
                self.config_data = yaml.safe_load(f)
            logger.info(f"Loaded configuration from {self.config_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            return False
    
    def discover_components(self) -> List[ComponentInfo]:
        """Discover components from global configuration"""
        components = []
        
        # Process platform components
        if 'platform_components' in self.config_data:
            for name, config in self.config_data['platform_components'].items():
                # Skip external-dns as requested
                if name == 'external_dns':
                    logger.info(f"Skipping external-dns as requested")
                    continue
                    
                component = ComponentInfo(
                    name=name,
                    type='platform_components',
                    current_version=config.get('version', ''),
                    current_chart_version=config.get('chart_version', ''),
                    image=config.get('image', ''),
                    namespace=config.get('namespace', '')
                )
                components.append(component)
        
        # Process applications
        if 'applications' in self.config_data:
            for name, config in self.config_data['applications'].items():
                component = ComponentInfo(
                    name=name,
                    type='applications',
                    current_version=config.get('version', ''),
                    current_chart_version=config.get('chart_version', ''),
                    image=config.get('image', ''),
                    namespace=config.get('namespace', '')
                )
                components.append(component)
        
        self.components = components
        logger.info(f"Discovered {len(components)} components")
        return components
    
    def setup_helm_repos(self) -> bool:
        """Setup all required Helm repositories"""
        if 'helm_repos' not in self.config_data:
            logger.error("No helm_repos section found in config")
            return False
        
        success = True
        for repo_name, repo_url in self.config_data['helm_repos'].items():
            if not self.helm_manager.add_repo(repo_name, repo_url):
                success = False
        
        if success:
            success = self.helm_manager.update_repos()
        
        return success
    
    def check_latest_versions(self) -> bool:
        """Check latest versions for all components"""
        logger.info("Checking latest versions from Helm repositories...")
        
        for component in self.components:
            if component.name not in self.chart_mapping:
                logger.warning(f"No chart mapping found for {component.name}")
                continue
            
            mapping = self.chart_mapping[component.name]
            chart_info = self.helm_manager.search_chart(mapping['repo'], mapping['chart'])
            
            if chart_info:
                component.latest_chart_version = chart_info['version']
                component.latest_version = chart_info['app_version']
                component.helm_repo = self.config_data['helm_repos'].get(mapping['repo'], '')
                component.helm_chart = f"{mapping['repo']}/{mapping['chart']}"
                
                # Check if update is needed
                current_chart = self.normalize_version(component.current_chart_version)
                latest_chart = self.normalize_version(component.latest_chart_version)
                
                if current_chart != latest_chart:
                    component.needs_update = True
                
                logger.info(f"{component.name}: {component.current_chart_version} -> {component.latest_chart_version}")
            else:
                logger.warning(f"Could not find chart info for {component.name}")
        
        return True
    
    def normalize_version(self, version: str) -> str:
        """Normalize version string for comparison"""
        if not version:
            return ""
        # Remove 'v' prefix and any non-semantic version parts
        version = re.sub(r'^v', '', version)
        return version
    
    def print_version_report(self):
        """Print a detailed version report"""
        print("\n" + "="*80)
        print("🔍 COMPONENT VERSION REPORT")
        print("="*80)
        
        platform_components = [c for c in self.components if c.type == 'platform_components']
        applications = [c for c in self.components if c.type == 'applications']
        
        def print_component_table(components: List[ComponentInfo], title: str):
            print(f"\n📦 {title}")
            print("-" * 80)
            print(f"{'Component':<15} {'Current':<12} {'Latest':<12} {'Chart Current':<15} {'Chart Latest':<15} {'Update?'}")
            print("-" * 80)
            
            for comp in components:
                update_status = "🔄 YES" if comp.needs_update else "✅ NO"
                current_ver = comp.current_version or "N/A"
                latest_ver = comp.latest_version or "N/A"
                current_chart = comp.current_chart_version or "N/A"
                latest_chart = comp.latest_chart_version or "N/A"
                
                print(f"{comp.name:<15} {current_ver:<12} {latest_ver:<12} {current_chart:<15} {latest_chart:<15} {update_status}")
        
        print_component_table(platform_components, "PLATFORM COMPONENTS")
        print_component_table(applications, "APPLICATIONS")
        
        # Summary
        total_components = len(self.components)
        updates_available = len([c for c in self.components if c.needs_update])
        
        print(f"\n📊 SUMMARY")
        print("-" * 40)
        print(f"Total components: {total_components}")
        print(f"Updates available: {updates_available}")
        print(f"Up to date: {total_components - updates_available}")
    
    def update_global_config(self, dry_run: bool = False) -> bool:
        """Update the global configuration with latest versions"""
        if not any(c.needs_update for c in self.components):
            logger.info("No updates needed")
            return True
        
        logger.info(f"Updating global config {'(DRY RUN)' if dry_run else ''}")
        
        # Update the config data
        for component in self.components:
            if not component.needs_update:
                continue
            
            config_section = self.config_data[component.type][component.name]
            
            if component.latest_version:
                config_section['version'] = component.latest_version
            if component.latest_chart_version:
                config_section['chart_version'] = component.latest_chart_version
            
            logger.info(f"Updated {component.name}: {component.current_chart_version} -> {component.latest_chart_version}")
        
        if not dry_run:
            # Backup original file
            backup_path = f"{self.config_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            subprocess.run(['cp', str(self.config_path), backup_path])
            logger.info(f"Created backup: {backup_path}")
            
            # Write updated config
            with open(self.config_path, 'w') as f:
                yaml.dump(self.config_data, f, default_flow_style=False, sort_keys=False)
            
            logger.info(f"Updated {self.config_path}")
        
        return True
    
    def generate_component_registry(self, output_path: str = ".github/components.yml") -> bool:
        """Generate component registry for new pipeline architecture"""
        registry = {
            'components': {}
        }
        
        for component in self.components:
            # Skip external-dns as requested
            if component.name == 'external_dns':
                continue
            
            registry['components'][component.name] = {
                'type': 'helm',
                'category': 'platform' if component.type == 'platform_components' else 'application',
                'chart': component.helm_chart.split('/')[-1] if component.helm_chart else '',
                'repository': component.helm_repo,
                'namespace': component.namespace,
                'version': component.latest_chart_version or component.current_chart_version,
                'app_version': component.latest_version or component.current_version,
                'dependencies': []  # TODO: Add dependency logic
            }
        
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w') as f:
            yaml.dump(registry, f, default_flow_style=False, sort_keys=False)
        
        logger.info(f"Generated component registry: {output_file}")
        return True

def main():
    parser = argparse.ArgumentParser(description='MSDP Component Version Manager')
    parser.add_argument('--check-only', action='store_true', 
                       help='Only check versions, don\'t update')
    parser.add_argument('--update-config', action='store_true',
                       help='Update global.yaml with latest versions')
    parser.add_argument('--generate-registry', action='store_true',
                       help='Generate component registry for new pipeline')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be changed without making changes')
    parser.add_argument('--config-path', default='infrastructure/config/global.yaml',
                       help='Path to global configuration file')
    
    args = parser.parse_args()
    
    # Initialize manager
    manager = ComponentVersionManager(args.config_path)
    
    # Load configuration
    if not manager.load_config():
        sys.exit(1)
    
    # Discover components
    components = manager.discover_components()
    if not components:
        logger.error("No components found")
        sys.exit(1)
    
    # Setup Helm repositories
    if not manager.setup_helm_repos():
        logger.error("Failed to setup Helm repositories")
        sys.exit(1)
    
    # Check latest versions
    if not manager.check_latest_versions():
        logger.error("Failed to check latest versions")
        sys.exit(1)
    
    # Print report
    manager.print_version_report()
    
    # Perform requested actions
    if args.update_config:
        if not manager.update_global_config(dry_run=args.dry_run):
            logger.error("Failed to update configuration")
            sys.exit(1)
    
    if args.generate_registry:
        if not manager.generate_component_registry():
            logger.error("Failed to generate component registry")
            sys.exit(1)
    
    logger.info("✅ Component version management completed successfully!")

if __name__ == "__main__":
    main()
