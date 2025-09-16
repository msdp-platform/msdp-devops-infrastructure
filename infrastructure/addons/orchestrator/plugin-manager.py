#!/usr/bin/env python3
"""
Kubernetes Add-ons Plugin Manager

A pluggable system for managing Kubernetes add-ons across multiple clouds.
Supports dependency resolution, health checking, and rollback capabilities.
"""

import yaml
import subprocess
import sys
import os
import time
import json
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging
from datetime import datetime

class PluginManager:
    def __init__(self, config_file: str, environment: str, cloud_provider: str, dry_run: bool = False):
        self.config_file = config_file
        self.environment = environment
        self.cloud_provider = cloud_provider
        self.dry_run = dry_run
        self.plugins_dir = Path("infrastructure/addons/plugins")
        self.config = self.load_config()
        self.setup_logging()
        
    def load_config(self) -> Dict:
        """Load and merge plugin configurations"""
        # Load global configuration
        with open(self.config_file, 'r') as f:
            global_config = yaml.safe_load(f)
            
        # Load environment-specific config
        env_config_file = f"infrastructure/addons/config/{self.cloud_provider}/{self.environment}.yaml"
        if Path(env_config_file).exists():
            with open(env_config_file, 'r') as f:
                env_config = yaml.safe_load(f)
        else:
            logging.warning(f"Environment config not found: {env_config_file}")
            env_config = {}
            
        # Merge configurations
        merged_config = self.merge_configs(global_config, env_config)
        
        # Resolve template variables
        merged_config = self.resolve_template_variables(merged_config)
        
        return merged_config
    
    def merge_configs(self, global_config: Dict, env_config: Dict) -> Dict:
        """Merge global and environment-specific configurations"""
        merged = global_config.copy()
        
        # Merge plugin configurations
        if 'plugins' in env_config:
            for plugin_name, env_plugin_config in env_config['plugins'].items():
                if plugin_name in merged['plugins']:
                    # Merge plugin config
                    if 'config' in env_plugin_config:
                        if 'config' not in merged['plugins'][plugin_name]:
                            merged['plugins'][plugin_name]['config'] = {}
                        merged['plugins'][plugin_name]['config'].update(env_plugin_config['config'])
                    
                    # Override other plugin settings
                    for key, value in env_plugin_config.items():
                        if key != 'config':
                            merged['plugins'][plugin_name][key] = value
        
        # Add environment-specific settings
        for key, value in env_config.items():
            if key not in ['plugins']:
                merged[key] = value
                
        return merged
    
    def resolve_template_variables(self, config: Dict) -> Dict:
        """Resolve template variables in configuration"""
        # This is a simplified template resolver
        # In production, you might want to use a more sophisticated templating system
        config_str = json.dumps(config)
        
        # Replace common template variables
        replacements = {
            "{{ VPC_ID }}": os.environ.get('VPC_ID', ''),
            "{{ PRIVATE_SUBNET_IDS }}": os.environ.get('PRIVATE_SUBNET_IDS', ''),
            "{{ PUBLIC_SUBNET_IDS }}": os.environ.get('PUBLIC_SUBNET_IDS', ''),
            "{{ GRAFANA_ADMIN_PASSWORD }}": os.environ.get('GRAFANA_ADMIN_PASSWORD', 'admin123'),
            "{{ ARGOCD_ADMIN_PASSWORD }}": os.environ.get('ARGOCD_ADMIN_PASSWORD', 'admin123'),
            "{{ AZURE_TENANT_ID }}": os.environ.get('AZURE_TENANT_ID', ''),
            "{{ ROUTE53_HOSTED_ZONE_ID }}": os.environ.get('ROUTE53_HOSTED_ZONE_ID', ''),
        }
        
        for template, value in replacements.items():
            config_str = config_str.replace(template, value)
            
        return json.loads(config_str)
    
    def get_enabled_plugins(self, specific_plugins: Optional[List[str]] = None) -> List[Dict]:
        """Get list of enabled plugins sorted by priority"""
        enabled_plugins = []
        
        for plugin_name, plugin_config in self.config['plugins'].items():
            # If specific plugins are requested, only include those
            if specific_plugins and plugin_name not in specific_plugins:
                continue
                
            if plugin_config.get('enabled', False):
                # Check cloud provider compatibility
                if 'cloud_provider' in plugin_config:
                    if plugin_config['cloud_provider'] != self.cloud_provider:
                        logging.info(f"Skipping {plugin_name}: not compatible with {self.cloud_provider}")
                        continue
                
                plugin_config['name'] = plugin_name
                enabled_plugins.append(plugin_config)
        
        # Sort by priority
        return sorted(enabled_plugins, key=lambda x: x.get('priority', 999))
    
    def resolve_dependencies(self, plugins: List[Dict]) -> List[Dict]:
        """Resolve plugin dependencies and return installation order"""
        resolved = []
        remaining = plugins.copy()
        max_iterations = len(plugins) * 2  # Prevent infinite loops
        iterations = 0
        
        while remaining and iterations < max_iterations:
            progress = False
            iterations += 1
            
            for plugin in remaining[:]:
                dependencies = plugin.get('dependencies', [])
                
                # Check if all dependencies are resolved
                if all(dep in [p['name'] for p in resolved] for dep in dependencies):
                    resolved.append(plugin)
                    remaining.remove(plugin)
                    progress = True
                    logging.debug(f"Resolved plugin: {plugin['name']}")
            
            if not progress:
                # Check for circular dependencies or missing dependencies
                missing_deps = []
                for plugin in remaining:
                    for dep in plugin.get('dependencies', []):
                        if dep not in [p['name'] for p in resolved + remaining]:
                            missing_deps.append(f"{plugin['name']} -> {dep} (missing)")
                        elif dep in [p['name'] for p in remaining]:
                            missing_deps.append(f"{plugin['name']} -> {dep} (circular)")
                
                if missing_deps:
                    raise Exception(f"Dependency resolution failed: {missing_deps}")
                else:
                    # No progress but no missing deps - might be circular
                    remaining_names = [p['name'] for p in remaining]
                    raise Exception(f"Circular dependency detected among: {remaining_names}")
        
        return resolved
    
    def validate_plugin(self, plugin_name: str) -> bool:
        """Validate plugin structure and requirements"""
        plugin_dir = self.plugins_dir / plugin_name
        
        if not plugin_dir.exists():
            logging.error(f"Plugin directory not found: {plugin_dir}")
            return False
        
        required_files = ['plugin.yaml', 'install.sh']
        for file in required_files:
            if not (plugin_dir / file).exists():
                logging.error(f"Required file missing: {plugin_dir / file}")
                return False
        
        # Validate plugin.yaml
        try:
            with open(plugin_dir / 'plugin.yaml', 'r') as f:
                plugin_spec = yaml.safe_load(f)
                
            required_fields = ['plugin', 'plugin.name', 'plugin.version']
            for field in required_fields:
                if not self.get_nested_value(plugin_spec, field.split('.')):
                    logging.error(f"Required field missing in plugin.yaml: {field}")
                    return False
                    
        except Exception as e:
            logging.error(f"Error validating plugin.yaml: {e}")
            return False
        
        return True
    
    def get_nested_value(self, data: Dict, keys: List[str]):
        """Get nested value from dictionary"""
        for key in keys:
            if isinstance(data, dict) and key in data:
                data = data[key]
            else:
                return None
        return data
    
    def install_plugin(self, plugin: Dict) -> bool:
        """Install a single plugin"""
        plugin_name = plugin['name']
        
        if not self.validate_plugin(plugin_name):
            return False
            
        plugin_dir = self.plugins_dir / plugin_name
        
        logging.info(f"{'[DRY-RUN] ' if self.dry_run else ''}Installing plugin: {plugin_name}")
        
        if self.dry_run:
            logging.info(f"[DRY-RUN] Would install {plugin_name} with config: {plugin.get('config', {})}")
            return True
        
        # Set environment variables for the plugin
        env = os.environ.copy()
        env.update({
            'PLUGIN_NAME': plugin_name,
            'CLOUD_PROVIDER': self.cloud_provider,
            'ENVIRONMENT': self.environment,
            'CLUSTER_NAME': self.config.get('cluster_name', ''),
            'DRY_RUN': str(self.dry_run).lower(),
        })
        
        # Add plugin-specific configuration
        if plugin_name in self.config.get('plugins', {}):
            plugin_config = self.config['plugins'][plugin_name].get('config', {})
            for key, value in plugin_config.items():
                env_key = key.upper().replace('-', '_').replace('.', '_')
                env[env_key] = str(value)
        
        # Add cloud-specific environment variables
        if self.cloud_provider == 'aws' and 'aws' in self.config:
            for key, value in self.config['aws'].items():
                env[f'AWS_{key.upper()}'] = str(value)
        elif self.cloud_provider == 'azure' and 'azure' in self.config:
            for key, value in self.config['azure'].items():
                env[f'AZURE_{key.upper()}'] = str(value)
        
        # Execute installation script
        install_script = plugin_dir / "install.sh"
        try:
            logging.info(f"Executing installation script: {install_script}")
            result = subprocess.run(
                [str(install_script)],
                env=env,
                cwd=plugin_dir,
                capture_output=True,
                text=True,
                timeout=self.config.get('settings', {}).get('installation_timeout', 600)
            )
            
            if result.returncode == 0:
                logging.info(f"✅ Plugin {plugin_name} installed successfully")
                logging.debug(f"Installation output: {result.stdout}")
                return True
            else:
                logging.error(f"❌ Plugin {plugin_name} installation failed (exit code: {result.returncode})")
                logging.error(f"Error output: {result.stderr}")
                if result.stdout:
                    logging.error(f"Standard output: {result.stdout}")
                return False
                
        except subprocess.TimeoutExpired:
            logging.error(f"❌ Plugin {plugin_name} installation timed out")
            return False
        except Exception as e:
            logging.error(f"❌ Plugin {plugin_name} installation error: {e}")
            return False
    
    def uninstall_plugin(self, plugin_name: str) -> bool:
        """Uninstall a single plugin"""
        plugin_dir = self.plugins_dir / plugin_name
        uninstall_script = plugin_dir / "uninstall.sh"
        
        logging.info(f"{'[DRY-RUN] ' if self.dry_run else ''}Uninstalling plugin: {plugin_name}")
        
        if self.dry_run:
            logging.info(f"[DRY-RUN] Would uninstall {plugin_name}")
            return True
        
        if uninstall_script.exists():
            env = os.environ.copy()
            env.update({
                'PLUGIN_NAME': plugin_name,
                'CLOUD_PROVIDER': self.cloud_provider,
                'ENVIRONMENT': self.environment,
                'CLUSTER_NAME': self.config.get('cluster_name', ''),
            })
            
            try:
                result = subprocess.run(
                    [str(uninstall_script)],
                    env=env,
                    cwd=plugin_dir,
                    capture_output=True,
                    text=True,
                    timeout=300
                )
                
                if result.returncode == 0:
                    logging.info(f"✅ Plugin {plugin_name} uninstalled successfully")
                    return True
                else:
                    logging.error(f"❌ Plugin {plugin_name} uninstallation failed:")
                    logging.error(result.stderr)
                    return False
                    
            except Exception as e:
                logging.error(f"❌ Plugin {plugin_name} uninstallation error: {e}")
                return False
        else:
            logging.warning(f"⚠️ Uninstall script not found for plugin: {plugin_name}")
            return True
    
    def health_check_plugin(self, plugin_name: str) -> bool:
        """Perform health check for a plugin"""
        plugin_dir = self.plugins_dir / plugin_name
        health_script = plugin_dir / "health-check.sh"
        
        if health_script.exists():
            try:
                env = os.environ.copy()
                env.update({
                    'PLUGIN_NAME': plugin_name,
                    'CLOUD_PROVIDER': self.cloud_provider,
                    'ENVIRONMENT': self.environment,
                })
                
                result = subprocess.run(
                    [str(health_script)],
                    env=env,
                    cwd=plugin_dir,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode == 0:
                    logging.info(f"✅ Plugin {plugin_name} health check passed")
                    return True
                else:
                    logging.warning(f"⚠️ Plugin {plugin_name} health check failed:")
                    logging.warning(result.stderr)
                    return False
                    
            except Exception as e:
                logging.error(f"❌ Plugin {plugin_name} health check error: {e}")
                return False
        else:
            logging.info(f"ℹ️ No health check script for plugin: {plugin_name}")
            return True  # No health check script means healthy
    
    def install_all_plugins(self, specific_plugins: Optional[List[str]] = None) -> bool:
        """Install all enabled plugins or specific plugins"""
        logging.info("🚀 Starting plugin installation process")
        
        # Get enabled plugins
        enabled_plugins = self.get_enabled_plugins(specific_plugins)
        logging.info(f"Found {len(enabled_plugins)} plugins to install")
        
        if not enabled_plugins:
            logging.warning("No plugins to install")
            return True
        
        # Resolve dependencies
        try:
            ordered_plugins = self.resolve_dependencies(enabled_plugins)
            logging.info("✅ Dependencies resolved successfully")
            
            # Log installation order
            plugin_names = [p['name'] for p in ordered_plugins]
            logging.info(f"Installation order: {' -> '.join(plugin_names)}")
            
        except Exception as e:
            logging.error(f"❌ Dependency resolution failed: {e}")
            return False
        
        # Install plugins in order
        failed_plugins = []
        installed_plugins = []
        
        for plugin in ordered_plugins:
            plugin_name = plugin['name']
            
            if self.install_plugin(plugin):
                installed_plugins.append(plugin_name)
                
                # Perform health check after installation
                if not self.dry_run:
                    time.sleep(5)  # Wait a bit before health check
                    if not self.health_check_plugin(plugin_name):
                        logging.warning(f"⚠️ Plugin {plugin_name} failed health check after installation")
                        
            else:
                failed_plugins.append(plugin_name)
                
                if self.config.get('settings', {}).get('rollback_on_failure', True):
                    logging.warning("🔄 Rolling back due to failure...")
                    self.rollback_plugins(installed_plugins)
                    return False
        
        if failed_plugins:
            logging.error(f"❌ Failed to install plugins: {failed_plugins}")
            return False
        
        logging.info("🎉 All plugins installed successfully!")
        return True
    
    def uninstall_plugins(self, plugin_names: List[str]) -> bool:
        """Uninstall specific plugins"""
        logging.info(f"🗑️ Uninstalling plugins: {plugin_names}")
        
        failed_plugins = []
        
        # Uninstall in reverse dependency order
        for plugin_name in reversed(plugin_names):
            if not self.uninstall_plugin(plugin_name):
                failed_plugins.append(plugin_name)
        
        if failed_plugins:
            logging.error(f"❌ Failed to uninstall plugins: {failed_plugins}")
            return False
        
        logging.info("✅ All plugins uninstalled successfully!")
        return True
    
    def rollback_plugins(self, plugin_names: List[str]) -> None:
        """Rollback installed plugins"""
        logging.info("🔄 Rolling back plugins...")
        
        # Uninstall in reverse order
        for plugin_name in reversed(plugin_names):
            self.uninstall_plugin(plugin_name)
    
    def health_check_all_plugins(self, specific_plugins: Optional[List[str]] = None) -> bool:
        """Perform health check on all plugins"""
        logging.info("🔍 Performing health check on plugins")
        
        enabled_plugins = self.get_enabled_plugins(specific_plugins)
        failed_plugins = []
        
        for plugin in enabled_plugins:
            plugin_name = plugin['name']
            if not self.health_check_plugin(plugin_name):
                failed_plugins.append(plugin_name)
        
        if failed_plugins:
            logging.error(f"❌ Health check failed for plugins: {failed_plugins}")
            return False
        
        logging.info("✅ All plugins passed health check!")
        return True
    
    def list_plugins(self) -> None:
        """List all available plugins with their status"""
        logging.info("📋 Available Plugins:")
        logging.info("=" * 80)
        
        categories = {}
        
        for plugin_name, plugin_config in self.config['plugins'].items():
            category = plugin_config.get('category', 'other')
            if category not in categories:
                categories[category] = []
            
            status = "✅ enabled" if plugin_config.get('enabled', False) else "❌ disabled"
            
            # Check cloud compatibility
            if 'cloud_provider' in plugin_config:
                if plugin_config['cloud_provider'] != self.cloud_provider:
                    status += f" (not compatible with {self.cloud_provider})"
            
            categories[category].append({
                'name': plugin_name,
                'status': status,
                'description': plugin_config.get('description', 'No description'),
                'priority': plugin_config.get('priority', 999),
                'dependencies': plugin_config.get('dependencies', [])
            })
        
        for category, plugins in categories.items():
            logging.info(f"\n📂 {category.upper()}")
            logging.info("-" * 40)
            
            for plugin in sorted(plugins, key=lambda x: x['priority']):
                deps_str = f" (deps: {', '.join(plugin['dependencies'])})" if plugin['dependencies'] else ""
                logging.info(f"  {plugin['status']} {plugin['name']}{deps_str}")
                logging.info(f"    {plugin['description']}")
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_level = self.config.get('settings', {}).get('log_level', 'info').upper()
        
        logging.basicConfig(
            level=getattr(logging, log_level),
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

def main():
    parser = argparse.ArgumentParser(description='Kubernetes Add-ons Plugin Manager')
    parser.add_argument('config_file', help='Path to plugins configuration file')
    parser.add_argument('environment', help='Target environment (dev, staging, prod)')
    parser.add_argument('cloud_provider', help='Cloud provider (aws, azure)')
    parser.add_argument('--action', choices=['install', 'uninstall', 'health-check', 'list'], 
                       default='install', help='Action to perform')
    parser.add_argument('--plugins', help='Comma-separated list of specific plugins')
    parser.add_argument('--dry-run', action='store_true', help='Dry run mode')
    
    args = parser.parse_args()
    
    specific_plugins = None
    if args.plugins:
        specific_plugins = [p.strip() for p in args.plugins.split(',')]
    
    try:
        manager = PluginManager(args.config_file, args.environment, args.cloud_provider, args.dry_run)
        
        if args.action == 'install':
            success = manager.install_all_plugins(specific_plugins)
        elif args.action == 'uninstall':
            if not specific_plugins:
                logging.error("--plugins is required for uninstall action")
                sys.exit(1)
            success = manager.uninstall_plugins(specific_plugins)
        elif args.action == 'health-check':
            success = manager.health_check_all_plugins(specific_plugins)
        elif args.action == 'list':
            manager.list_plugins()
            success = True
        else:
            logging.error(f"Unknown action: {args.action}")
            sys.exit(1)
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        logging.error(f"Plugin manager error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()