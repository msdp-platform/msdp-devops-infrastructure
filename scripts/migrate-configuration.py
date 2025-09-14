#!/usr/bin/env python3
"""
Configuration Migration Script

This script migrates from the old configuration structure to the new standardized structure.
It consolidates configuration files and updates references.

Usage:
    python3 scripts/migrate-configuration.py [--dry-run] [--backup]
"""

import yaml
import json
import sys
import shutil
from pathlib import Path
from datetime import datetime

class ConfigurationMigrator:
    def __init__(self, dry_run=False, backup=True):
        self.dry_run = dry_run
        self.backup = backup
        self.changes = []
        
    def log_change(self, action, details):
        """Log a change that was made or would be made"""
        self.changes.append(f"{action}: {details}")
        if self.dry_run:
            print(f"[DRY RUN] {action}: {details}")
        else:
            print(f"{action}: {details}")
    
    def backup_file(self, file_path):
        """Create a backup of a file"""
        if not self.backup or not file_path.exists():
            return
        
        backup_dir = Path("backups") / datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Preserve directory structure in backup
        relative_path = file_path.relative_to(Path.cwd())
        backup_file = backup_dir / relative_path
        backup_file.parent.mkdir(parents=True, exist_ok=True)
        
        if not self.dry_run:
            shutil.copy2(file_path, backup_file)
        
        self.log_change("BACKUP", f"{file_path} -> {backup_file}")
    
    def migrate_globals_config(self):
        """Migrate infrastructure/config/globals.yaml to new structure"""
        old_globals = Path("infrastructure/config/globals.yaml")
        
        if not old_globals.exists():
            self.log_change("SKIP", "infrastructure/config/globals.yaml not found")
            return
        
        self.backup_file(old_globals)
        
        with open(old_globals) as f:
            old_config = yaml.safe_load(f)
        
        # Create new naming.yaml
        naming_config = {
            "organization": {
                "name": old_config.get("org", "msdp"),
                "full_name": "Microsoft Developer Platform"
            },
            "naming_conventions": {
                "s3_bucket": {
                    "prefix": "tf-state",
                    "pattern": "{prefix}-{org}-{account_type}-{region_code}-{suffix}",
                    "max_length": 63
                },
                "dynamodb_table": {
                    "prefix": "tf-locks",
                    "pattern": "{prefix}-{org}-{account_type}-{region_code}"
                },
                "state_key": {
                    "pattern": "{platform}/{component}/{environment}/{region?}/{instance?}/terraform.tfstate"
                },
                "pipeline": {
                    "pattern": "{platform}-{component}-{environment}"
                }
            },
            "platforms": ["azure", "aws", "gcp", "shared"],
            "components": {
                "azure": ["network", "aks", "storage", "keyvault"],
                "aws": ["vpc", "eks", "s3", "iam"],
                "shared": ["monitoring", "dns", "backup", "security"]
            },
            "environments": ["dev", "staging", "prod", "sandbox"],
            "account_types": ["dev", "staging", "prod", "shared", "sandbox"],
            "region_codes": {
                "eu-west-1": "euw1",
                "eu-west-2": "euw2",
                "eu-central-1": "euc1",
                "us-east-1": "use1",
                "us-east-2": "use2",
                "uksouth": "uks",
                "ukwest": "ukw"
            }
        }
        
        # Create new accounts.yaml
        accounts_config = {
            "accounts": {
                "aws": {
                    "dev": {
                        "account_id": old_config.get("accounts", {}).get("aws_account_id", ""),
                        "region": "eu-west-1",
                        "purpose": "Development and testing workloads",
                        "cost_center": "engineering"
                    }
                },
                "azure": {
                    "dev": {
                        "subscription_id": old_config.get("accounts", {}).get("azure_subscription_id", ""),
                        "tenant_id": "{{ AZURE_TENANT_ID }}",
                        "region": old_config.get("azure", {}).get("location", "uksouth"),
                        "purpose": "Development and testing workloads",
                        "cost_center": "engineering"
                    }
                }
            },
            "environment_account_mapping": {
                "dev": "dev",
                "staging": "staging",
                "prod": "prod",
                "sandbox": "dev"
            }
        }
        
        # Write new files
        new_naming_file = Path("config/global/naming.yaml")
        new_accounts_file = Path("config/global/accounts.yaml")
        
        new_naming_file.parent.mkdir(parents=True, exist_ok=True)
        new_accounts_file.parent.mkdir(parents=True, exist_ok=True)
        
        if not self.dry_run:
            with open(new_naming_file, 'w') as f:
                yaml.dump(naming_config, f, default_flow_style=False, sort_keys=False)
            
            with open(new_accounts_file, 'w') as f:
                yaml.dump(accounts_config, f, default_flow_style=False, sort_keys=False)
        
        self.log_change("CREATE", f"config/global/naming.yaml")
        self.log_change("CREATE", f"config/global/accounts.yaml")
    
    def migrate_env_config(self):
        """Migrate config/envs/dev.yaml to new consolidated structure"""
        old_env_file = Path("config/envs/dev.yaml")
        
        if not old_env_file.exists():
            self.log_change("SKIP", "config/envs/dev.yaml not found")
            return
        
        self.backup_file(old_env_file)
        
        with open(old_env_file) as f:
            old_env_config = yaml.safe_load(f)
        
        # Load old globals for merging
        old_globals_file = Path("infrastructure/config/globals.yaml")
        old_globals = {}
        if old_globals_file.exists():
            with open(old_globals_file) as f:
                old_globals = yaml.safe_load(f)
        
        # Create consolidated environment config
        new_env_config = {
            "environment": {
                "name": "dev",
                "full_name": "Development",
                "account_type": "dev"
            },
            "backend": {
                "aws": {
                    "account_id": old_globals.get("accounts", {}).get("aws_account_id", ""),
                    "region": "eu-west-1"
                }
            },
            "azure": {
                "subscription_id": old_env_config.get("azure", {}).get("subscriptionId", ""),
                "tenant_id": "{{ AZURE_TENANT_ID }}",
                "location": old_env_config.get("azure", {}).get("location", "uksouth"),
                "resource_group": old_env_config.get("azure", {}).get("resourceGroup", ""),
                "vnet_name": old_env_config.get("azure", {}).get("vnetName", ""),
                "vnet_cidr": old_env_config.get("azure", {}).get("vnetCidr", ""),
                "subnet_name": old_env_config.get("azure", {}).get("subnetName", ""),
                "subnet_cidr": old_env_config.get("azure", {}).get("subnetCidr", ""),
                "aks_name": old_env_config.get("azure", {}).get("aksName", ""),
                "aks_clusters": old_env_config.get("azure", {}).get("aksClusters", []),
                "kubernetes_version": old_globals.get("azure", {}).get("kubernetesVersion", "1.29.7")
            },
            "global": {
                "org": old_globals.get("org", "msdp"),
                "base_domain": old_globals.get("base_domain", ""),
                "git_org": old_globals.get("git_org", "msdp-platform")
            },
            "tags": {
                "Environment": "dev",
                "Project": "msdp",
                "ManagedBy": "terraform",
                "Owner": "platform-team"
            }
        }
        
        # Write new consolidated config
        new_env_file = Path("config/environments/dev.yaml")
        new_env_file.parent.mkdir(parents=True, exist_ok=True)
        
        if not self.dry_run:
            with open(new_env_file, 'w') as f:
                yaml.dump(new_env_config, f, default_flow_style=False, sort_keys=False)
        
        self.log_change("CREATE", f"config/environments/dev.yaml")
    
    def update_workflow_references(self):
        """Update workflow files to use new configuration paths"""
        workflow_files = [
            ".github/workflows/aks.yml",
            ".github/workflows/azure-network.yml"
        ]
        
        for workflow_file in workflow_files:
            workflow_path = Path(workflow_file)
            if not workflow_path.exists():
                continue
            
            self.backup_file(workflow_path)
            
            with open(workflow_path) as f:
                content = f.read()
            
            # Update references to old config paths
            updated_content = content.replace(
                "infrastructure/config/globals.yaml",
                "config/global/naming.yaml"
            )
            
            if updated_content != content:
                if not self.dry_run:
                    with open(workflow_path, 'w') as f:
                        f.write(updated_content)
                
                self.log_change("UPDATE", f"{workflow_file} - updated config paths")
    
    def cleanup_old_files(self):
        """Mark old files for cleanup (don't delete automatically)"""
        old_files = [
            "infrastructure/config/globals.yaml",
            "config/envs/dev.yaml"  # Keep original as backup
        ]
        
        cleanup_script = Path("scripts/cleanup-old-config.sh")
        
        cleanup_content = "#!/bin/bash\n"
        cleanup_content += "# Cleanup script for old configuration files\n"
        cleanup_content += "# Run this after verifying the migration was successful\n\n"
        
        for old_file in old_files:
            if Path(old_file).exists():
                cleanup_content += f"# mv {old_file} {old_file}.old\n"
        
        if not self.dry_run:
            with open(cleanup_script, 'w') as f:
                f.write(cleanup_content)
            cleanup_script.chmod(0o755)
        
        self.log_change("CREATE", "scripts/cleanup-old-config.sh")
    
    def run_migration(self):
        """Run the complete migration process"""
        print("🚀 Starting configuration migration...")
        print(f"Mode: {'DRY RUN' if self.dry_run else 'LIVE'}")
        print(f"Backup: {'ENABLED' if self.backup else 'DISABLED'}")
        print()
        
        # Step 1: Migrate global configuration
        print("📋 Step 1: Migrating global configuration...")
        self.migrate_globals_config()
        print()
        
        # Step 2: Migrate environment configuration
        print("🌍 Step 2: Migrating environment configuration...")
        self.migrate_env_config()
        print()
        
        # Step 3: Update workflow references
        print("⚙️  Step 3: Updating workflow references...")
        self.update_workflow_references()
        print()
        
        # Step 4: Create cleanup script
        print("🧹 Step 4: Creating cleanup script...")
        self.cleanup_old_files()
        print()
        
        # Summary
        print("📊 Migration Summary:")
        for change in self.changes:
            print(f"  • {change}")
        
        print()
        if self.dry_run:
            print("✅ Dry run completed. No files were modified.")
            print("Run without --dry-run to apply changes.")
        else:
            print("✅ Migration completed successfully!")
            print("Next steps:")
            print("  1. Test the new configuration")
            print("  2. Run scripts/cleanup-old-config.sh to remove old files")
            print("  3. Update any remaining references")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Migrate configuration to new structure")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")
    parser.add_argument("--no-backup", action="store_true", help="Skip creating backups")
    
    args = parser.parse_args()
    
    migrator = ConfigurationMigrator(
        dry_run=args.dry_run,
        backup=not args.no_backup
    )
    
    try:
        migrator.run_migration()
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()