#!/usr/bin/env python3
"""
Terraform Backend Configuration Generator

This script generates Terraform backend configurations following organizational
naming conventions and standards.

Usage:
    python3 generate-backend-config.py <environment> <platform> <component> [instance]

Examples:
    python3 generate-backend-config.py dev azure network
    python3 generate-backend-config.py dev azure aks cluster-01
    python3 generate-backend-config.py prod aws vpc
"""

import yaml
import json
import hashlib
import sys
import os
from pathlib import Path

class BackendConfigGenerator:
    def __init__(self, config_dir="config"):
        self.config_dir = Path(config_dir)
        self.load_global_config()
    
    def load_global_config(self):
        """Load global configuration files"""
        try:
            with open(self.config_dir / "global" / "naming.yaml") as f:
                self.naming = yaml.safe_load(f)
            
            with open(self.config_dir / "global" / "accounts.yaml") as f:
                self.accounts = yaml.safe_load(f)
                
        except FileNotFoundError as e:
            print(f"Error: Configuration file not found: {e}")
            print("Please ensure config/global/naming.yaml and config/global/accounts.yaml exist")
            sys.exit(1)
    
    def validate_inputs(self, environment, platform, component):
        """Validate input parameters against configuration"""
        errors = []
        
        if environment not in self.naming["environments"]:
            errors.append(f"Invalid environment '{environment}'. Valid options: {self.naming['environments']}")
        
        if platform not in self.naming["platforms"]:
            errors.append(f"Invalid platform '{platform}'. Valid options: {self.naming['platforms']}")
        
        if platform in self.naming["components"] and component not in self.naming["components"][platform]:
            errors.append(f"Invalid component '{component}' for platform '{platform}'. Valid options: {self.naming['components'][platform]}")
        
        if errors:
            for error in errors:
                print(f"Error: {error}")
            sys.exit(1)
    
    def generate_bucket_name(self, org, account_type, region):
        """Generate S3 bucket name following convention"""
        region_code = self.get_region_code(region)
        
        # Generate deterministic suffix based on org, account_type, and region
        suffix_input = f"{org}-{account_type}-{region_code}-terraform-state"
        suffix = hashlib.sha256(suffix_input.encode()).hexdigest()[:8]
        
        pattern = self.naming["naming_conventions"]["s3_bucket"]["pattern"]
        bucket_name = pattern.format(
            prefix=self.naming["naming_conventions"]["s3_bucket"]["prefix"],
            org=org,
            account_type=account_type,
            region_code=region_code,
            suffix=suffix
        )
        
        # Ensure bucket name is valid (lowercase, no underscores)
        bucket_name = bucket_name.lower().replace("_", "-")
        
        # Ensure bucket name doesn't exceed max length
        max_length = self.naming["naming_conventions"]["s3_bucket"]["max_length"]
        if len(bucket_name) > max_length:
            # Truncate and add suffix to maintain uniqueness
            truncate_length = max_length - 9  # Leave room for -suffix
            bucket_name = bucket_name[:truncate_length] + "-" + suffix[:8]
        
        return bucket_name
    
    def generate_table_name(self, org, account_type, region):
        """Generate DynamoDB table name following convention"""
        region_code = self.get_region_code(region)
        
        pattern = self.naming["naming_conventions"]["dynamodb_table"]["pattern"]
        table_name = pattern.format(
            prefix=self.naming["naming_conventions"]["dynamodb_table"]["prefix"],
            org=org,
            account_type=account_type,
            region_code=region_code
        )
        
        return table_name
    
    def generate_state_key(self, platform, component, environment, region=None, instance=None):
        """Generate state key following convention"""
        key_parts = [platform, component, environment]
        
        if region:
            key_parts.append(region)
        if instance:
            key_parts.append(instance)
            
        key_parts.append("terraform.tfstate")
        return "/".join(key_parts)
    
    def get_region_code(self, region):
        """Convert AWS region to short code"""
        region_codes = self.naming.get("region_codes", {})
        return region_codes.get(region, region.replace("-", ""))
    
    def get_account_type(self, environment):
        """Get account type for environment"""
        mapping = self.accounts.get("environment_account_mapping", {})
        return mapping.get(environment, environment)
    
    def generate_pipeline_name(self, platform, component, environment, instance=None):
        """Generate pipeline name following convention"""
        pattern = self.naming["naming_conventions"]["pipeline"]["pattern"]
        pipeline_name = pattern.format(
            platform=platform,
            component=component,
            environment=environment
        )
        
        if instance:
            pipeline_name += f"-{instance}"
        
        return pipeline_name
    
    def generate_backend_config(self, environment, platform, component, instance=None):
        """Generate complete backend configuration"""
        
        # Validate inputs
        self.validate_inputs(environment, platform, component)
        
        # Get account type and details
        account_type = self.get_account_type(environment)
        
        # Get AWS account details for backend storage
        try:
            aws_account = self.accounts["accounts"]["aws"][account_type]
            account_id = aws_account["account_id"]
            region = aws_account["region"]
        except KeyError:
            print(f"Error: AWS account configuration not found for account type '{account_type}'")
            sys.exit(1)
        
        # Generate names
        org = self.naming["organization"]["name"]
        bucket_name = self.generate_bucket_name(org, account_type, region)
        table_name = self.generate_table_name(org, account_type, region)
        state_key = self.generate_state_key(platform, component, environment, instance=instance)
        pipeline_name = self.generate_pipeline_name(platform, component, environment, instance)
        
        # Generate configuration
        config = {
            "bucket": bucket_name,
            "key": state_key,
            "region": region,
            "dynamodb_table": table_name,
            "encrypt": True,
            "pipeline_name": pipeline_name,
            "metadata": {
                "org": org,
                "environment": environment,
                "platform": platform,
                "component": component,
                "instance": instance,
                "account_type": account_type,
                "account_id": account_id,
                "generated_by": "generate-backend-config.py",
                "naming_convention_version": "1.0"
            }
        }
        
        return config
    
    def save_config(self, config, environment, platform, component):
        """Save configuration to file"""
        backend_dir = Path(f"infrastructure/environment/{environment}/backend")
        backend_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"backend-config-{platform}-{component}.json"
        config_file = backend_dir / filename
        
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        return str(config_file)

def print_usage():
    """Print usage information"""
    print("Usage: generate-backend-config.py <environment> <platform> <component> [instance]")
    print("")
    print("Arguments:")
    print("  environment  Environment name (dev, staging, prod, sandbox)")
    print("  platform     Platform name (azure, aws, shared)")
    print("  component    Component name (network, aks, eks, etc.)")
    print("  instance     Optional instance identifier")
    print("")
    print("Examples:")
    print("  python3 generate-backend-config.py dev azure network")
    print("  python3 generate-backend-config.py dev azure aks cluster-01")
    print("  python3 generate-backend-config.py prod aws vpc")
    print("")

def main():
    if len(sys.argv) < 4:
        print_usage()
        sys.exit(1)
    
    environment = sys.argv[1]
    platform = sys.argv[2]
    component = sys.argv[3]
    instance = sys.argv[4] if len(sys.argv) > 4 else None
    
    try:
        generator = BackendConfigGenerator()
        config = generator.generate_backend_config(environment, platform, component, instance)
        
        # Print configuration to stdout
        print(json.dumps(config, indent=2))
        
        # Optionally save to file if --save flag is provided
        if "--save" in sys.argv:
            config_file = generator.save_config(config, environment, platform, component)
            print(f"\nConfiguration saved to: {config_file}", file=sys.stderr)
            
    except Exception as e:
        print(f"Error generating backend configuration: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()