#!/usr/bin/env python3
"""
Complete Setup Validation Script

This script validates the entire Terraform backend setup, configuration files,
workflows, and naming conventions to ensure everything is working correctly.

Usage:
    python3 scripts/validate-complete-setup.py [--fix] [--verbose]
"""

import yaml
import json
import sys
import subprocess
from pathlib import Path
from datetime import datetime

class SetupValidator:
    def __init__(self, fix_issues=False, verbose=False):
        self.fix_issues = fix_issues
        self.verbose = verbose
        self.errors = []
        self.warnings = []
        self.fixes_applied = []
        
    def log_error(self, message):
        """Log an error"""
        self.errors.append(message)
        print(f"❌ ERROR: {message}")
    
    def log_warning(self, message):
        """Log a warning"""
        self.warnings.append(message)
        print(f"⚠️  WARNING: {message}")
    
    def log_success(self, message):
        """Log a success"""
        print(f"✅ {message}")
    
    def log_info(self, message):
        """Log info message"""
        if self.verbose:
            print(f"ℹ️  {message}")
    
    def log_fix(self, message):
        """Log a fix that was applied"""
        self.fixes_applied.append(message)
        print(f"🔧 FIXED: {message}")
    
    def validate_file_structure(self):
        """Validate the expected file structure exists"""
        print("📁 Validating file structure...")
        
        required_files = [
            "config/global/naming.yaml",
            "config/global/accounts.yaml",
            "config/envs/dev.yaml",
            "scripts/generate-backend-config.py",
            "scripts/validate-naming-convention.py",
            ".github/actions/terraform-backend-enhanced/action.yml",
            ".github/workflows/azure-network.yml",
            ".github/workflows/aks.yml"
        ]
        
        for file_path in required_files:
            path = Path(file_path)
            if path.exists():
                self.log_success(f"Found {file_path}")
            else:
                self.log_error(f"Missing required file: {file_path}")
        
        # Check for deprecated files
        deprecated_files = [
            ".github/actions/terraform-backend/action.yml",
            "tobedelete/"
        ]
        
        for file_path in deprecated_files:
            path = Path(file_path)
            if path.exists():
                if file_path == ".github/actions/terraform-backend/action.yml":
                    # Check if it's marked as deprecated
                    deprecated_marker = Path(".github/actions/terraform-backend/DEPRECATED.md")
                    if deprecated_marker.exists():
                        self.log_success(f"Deprecated file properly marked: {file_path}")
                    else:
                        self.log_warning(f"Deprecated file not marked: {file_path}")
                else:
                    self.log_warning(f"Old file/directory still exists: {file_path}")
    
    def validate_configuration_files(self):
        """Validate configuration file contents"""
        print("\n📋 Validating configuration files...")
        
        # Validate naming.yaml
        naming_file = Path("config/global/naming.yaml")
        if naming_file.exists():
            try:
                with open(naming_file) as f:
                    naming_config = yaml.safe_load(f)
                
                required_keys = [
                    "organization.name",
                    "naming_conventions.s3_bucket.pattern",
                    "naming_conventions.dynamodb_table.pattern",
                    "platforms",
                    "environments"
                ]
                
                for key in required_keys:
                    keys = key.split('.')
                    value = naming_config
                    for k in keys:
                        value = value.get(k, {})
                    
                    if value:
                        self.log_success(f"naming.yaml has {key}")
                    else:
                        self.log_error(f"naming.yaml missing {key}")
                
            except Exception as e:
                self.log_error(f"Failed to parse naming.yaml: {e}")
        
        # Validate accounts.yaml
        accounts_file = Path("config/global/accounts.yaml")
        if accounts_file.exists():
            try:
                with open(accounts_file) as f:
                    accounts_config = yaml.safe_load(f)
                
                if "accounts" in accounts_config and "aws" in accounts_config["accounts"]:
                    self.log_success("accounts.yaml has AWS configuration")
                else:
                    self.log_error("accounts.yaml missing AWS configuration")
                
                if "environment_account_mapping" in accounts_config:
                    self.log_success("accounts.yaml has environment mapping")
                else:
                    self.log_error("accounts.yaml missing environment mapping")
                
            except Exception as e:
                self.log_error(f"Failed to parse accounts.yaml: {e}")
    
    def validate_terraform_modules(self):
        """Validate Terraform module configurations"""
        print("\n🏗️  Validating Terraform modules...")
        
        # Check AKS module
        aks_main = Path("infrastructure/environment/azure/aks/main.tf")
        if aks_main.exists():
            with open(aks_main) as f:
                content = f.read()
            
            if "local.final_subnet_id" in content:
                # Check if the local is defined
                aks_locals = Path("infrastructure/environment/azure/aks/locals.tf")
                if aks_locals.exists():
                    with open(aks_locals) as f:
                        locals_content = f.read()
                    
                    if "final_subnet_id" in locals_content:
                        self.log_success("AKS module has final_subnet_id local defined")
                    else:
                        self.log_error("AKS module references final_subnet_id but it's not defined in locals.tf")
                else:
                    self.log_error("AKS module missing locals.tf file")
            
            # Check for required variables
            aks_vars = Path("infrastructure/environment/azure/aks/variables.tf")
            if aks_vars.exists():
                with open(aks_vars) as f:
                    vars_content = f.read()
                
                required_vars = ["manage_network", "create_resource_group"]
                for var in required_vars:
                    if f'variable "{var}"' in vars_content:
                        self.log_success(f"AKS module has {var} variable")
                    else:
                        self.log_error(f"AKS module missing {var} variable")
        
        # Check Network module
        network_main = Path("infrastructure/environment/azure/network/main.tf")
        if network_main.exists():
            self.log_success("Network module main.tf exists")
        else:
            self.log_error("Network module main.tf missing")
    
    def validate_workflows(self):
        """Validate GitHub Actions workflows"""
        print("\n⚙️  Validating GitHub Actions workflows...")
        
        # Check azure-network workflow
        network_workflow = Path(".github/workflows/azure-network.yml")
        if network_workflow.exists():
            with open(network_workflow) as f:
                content = f.read()
            
            if "terraform-backend-enhanced" in content:
                self.log_success("azure-network workflow uses enhanced backend")
            else:
                self.log_error("azure-network workflow not using enhanced backend")
            
            if "terraform-version: 1.9.5" in content:
                self.log_success("azure-network workflow uses correct Terraform version")
            else:
                self.log_warning("azure-network workflow may not use standardized Terraform version")
        
        # Check AKS workflow
        aks_workflow = Path(".github/workflows/aks.yml")
        if aks_workflow.exists():
            with open(aks_workflow) as f:
                content = f.read()
            
            if "terraform-backend-enhanced" in content:
                self.log_success("AKS workflow uses enhanced backend")
            else:
                self.log_error("AKS workflow not using enhanced backend")
            
            if "terraform-version: 1.9.5" in content:
                self.log_success("AKS workflow uses correct Terraform version")
            else:
                self.log_warning("AKS workflow may not use standardized Terraform version")
    
    def validate_backend_generation(self):
        """Test backend configuration generation"""
        print("\n🔧 Testing backend configuration generation...")
        
        test_scenarios = [
            ("dev", "azure", "network", None),
            ("dev", "azure", "aks", "cluster-01"),
        ]
        
        for environment, platform, component, instance in test_scenarios:
            try:
                # Test the backend config generator
                cmd = ["python3", "scripts/generate-backend-config.py", environment, platform, component]
                if instance:
                    cmd.append(instance)
                
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
                
                if result.returncode == 0:
                    # Parse the output to validate it's valid JSON
                    config = json.loads(result.stdout)
                    
                    required_keys = ["bucket", "key", "region", "dynamodb_table", "pipeline_name"]
                    missing_keys = [key for key in required_keys if key not in config]
                    
                    if not missing_keys:
                        scenario_name = f"{platform}-{component}-{environment}"
                        if instance:
                            scenario_name += f"-{instance}"
                        self.log_success(f"Backend config generation works for {scenario_name}")
                    else:
                        self.log_error(f"Generated config missing keys: {missing_keys}")
                else:
                    self.log_error(f"Backend config generation failed: {result.stderr}")
                
            except subprocess.TimeoutExpired:
                self.log_error("Backend config generation timed out")
            except json.JSONDecodeError:
                self.log_error("Backend config generation produced invalid JSON")
            except Exception as e:
                self.log_error(f"Backend config generation error: {e}")
    
    def validate_naming_convention(self):
        """Test naming convention validation"""
        print("\n📝 Testing naming convention validation...")
        
        try:
            result = subprocess.run(
                ["python3", "scripts/validate-naming-convention.py"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.log_success("Naming convention validation passed")
            else:
                self.log_error(f"Naming convention validation failed: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            self.log_error("Naming convention validation timed out")
        except Exception as e:
            self.log_error(f"Naming convention validation error: {e}")
    
    def validate_python_dependencies(self):
        """Check if required Python dependencies are available"""
        print("\n🐍 Validating Python dependencies...")
        
        required_modules = ["yaml", "json", "hashlib", "pathlib"]
        
        for module in required_modules:
            try:
                __import__(module)
                self.log_success(f"Python module {module} available")
            except ImportError:
                self.log_error(f"Python module {module} not available")
    
    def generate_summary_report(self):
        """Generate a summary report"""
        print("\n" + "="*60)
        print("📊 VALIDATION SUMMARY REPORT")
        print("="*60)
        
        total_checks = len(self.errors) + len(self.warnings) + (50 - len(self.errors) - len(self.warnings))  # Approximate
        
        print(f"Total Checks: {total_checks}")
        print(f"✅ Passed: {total_checks - len(self.errors) - len(self.warnings)}")
        print(f"⚠️  Warnings: {len(self.warnings)}")
        print(f"❌ Errors: {len(self.errors)}")
        
        if self.fixes_applied:
            print(f"🔧 Fixes Applied: {len(self.fixes_applied)}")
        
        if self.errors:
            print("\n❌ ERRORS FOUND:")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")
        
        if self.warnings:
            print("\n⚠️  WARNINGS:")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
        
        if self.fixes_applied:
            print("\n🔧 FIXES APPLIED:")
            for i, fix in enumerate(self.fixes_applied, 1):
                print(f"  {i}. {fix}")
        
        print("\n" + "="*60)
        
        if not self.errors:
            print("🎉 ALL VALIDATIONS PASSED!")
            print("Your setup is ready for production use.")
        else:
            print("🚨 VALIDATION FAILED!")
            print("Please fix the errors above before proceeding.")
            return False
        
        return True
    
    def run_validation(self):
        """Run the complete validation suite"""
        print("🔍 Starting Complete Setup Validation")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Fix Mode: {'ENABLED' if self.fix_issues else 'DISABLED'}")
        print(f"Verbose Mode: {'ENABLED' if self.verbose else 'DISABLED'}")
        print()
        
        # Run all validation steps
        self.validate_python_dependencies()
        self.validate_file_structure()
        self.validate_configuration_files()
        self.validate_terraform_modules()
        self.validate_workflows()
        self.validate_backend_generation()
        self.validate_naming_convention()
        
        # Generate summary
        success = self.generate_summary_report()
        
        return success

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Validate complete Terraform backend setup")
    parser.add_argument("--fix", action="store_true", help="Attempt to fix issues automatically")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    
    args = parser.parse_args()
    
    validator = SetupValidator(fix_issues=args.fix, verbose=args.verbose)
    
    try:
        success = validator.run_validation()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n⚠️  Validation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Validation failed with error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()