#!/usr/bin/env python3
"""
Naming Convention Validation Script

This script validates the naming convention implementation and shows examples
of generated names for different scenarios.
"""

import sys
import json
from pathlib import Path

# Add the scripts directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from generate_backend_config import BackendConfigGenerator
except ImportError:
    print("Error: Could not import BackendConfigGenerator")
    print("Make sure generate-backend-config.py is in the same directory")
    sys.exit(1)

def test_naming_scenarios():
    """Test various naming scenarios"""
    
    print("🔍 Testing Terraform Backend Naming Convention")
    print("=" * 60)
    
    generator = BackendConfigGenerator()
    
    # Test scenarios
    scenarios = [
        # (environment, platform, component, instance)
        ("dev", "azure", "network", None),
        ("dev", "azure", "aks", "cluster-01"),
        ("dev", "azure", "aks", "cluster-02"),
        ("staging", "azure", "network", None),
        ("prod", "azure", "network", None),
        ("dev", "aws", "vpc", None),
        ("dev", "aws", "eks", "primary"),
        ("prod", "shared", "monitoring", None),
    ]
    
    results = []
    
    for environment, platform, component, instance in scenarios:
        try:
            config = generator.generate_backend_config(environment, platform, component, instance)
            
            scenario_name = f"{platform}-{component}-{environment}"
            if instance:
                scenario_name += f"-{instance}"
            
            result = {
                "scenario": scenario_name,
                "environment": environment,
                "platform": platform,
                "component": component,
                "instance": instance,
                "bucket": config["bucket"],
                "table": config["dynamodb_table"],
                "key": config["key"],
                "pipeline": config["pipeline_name"]
            }
            
            results.append(result)
            
        except Exception as e:
            print(f"❌ Error testing {environment}/{platform}/{component}: {e}")
    
    return results

def print_results_table(results):
    """Print results in a formatted table"""
    
    print("\n📋 Generated Backend Configurations")
    print("=" * 120)
    
    # Header
    print(f"{'Scenario':<25} {'S3 Bucket':<35} {'DynamoDB Table':<25} {'State Key':<35}")
    print("-" * 120)
    
    # Group by bucket to show sharing
    buckets = {}
    for result in results:
        bucket = result["bucket"]
        if bucket not in buckets:
            buckets[bucket] = []
        buckets[bucket].append(result)
    
    for bucket, bucket_results in buckets.items():
        print(f"\n🪣 Bucket: {bucket}")
        print(f"🔒 Table: {bucket_results[0]['table']}")
        print("-" * 120)
        
        for result in bucket_results:
            print(f"{'  ' + result['scenario']:<25} {'(shared)':<35} {'(shared)':<25} {result['key']:<35}")

def print_naming_analysis(results):
    """Print analysis of naming patterns"""
    
    print("\n🔍 Naming Convention Analysis")
    print("=" * 60)
    
    # Analyze bucket sharing
    buckets = set(result["bucket"] for result in results)
    tables = set(result["table"] for result in results)
    
    print(f"📊 Statistics:")
    print(f"  ��� Total scenarios tested: {len(results)}")
    print(f"  • Unique S3 buckets: {len(buckets)}")
    print(f"  • Unique DynamoDB tables: {len(tables)}")
    print(f"  • Average scenarios per bucket: {len(results) / len(buckets):.1f}")
    
    # Show bucket grouping
    print(f"\n🪣 Bucket Grouping:")
    bucket_groups = {}
    for result in results:
        bucket = result["bucket"]
        if bucket not in bucket_groups:
            bucket_groups[bucket] = []
        bucket_groups[bucket].append(result["scenario"])
    
    for bucket, scenarios in bucket_groups.items():
        print(f"  • {bucket}")
        for scenario in scenarios:
            print(f"    - {scenario}")
    
    # Show state key patterns
    print(f"\n🗝️  State Key Patterns:")
    key_patterns = set()
    for result in results:
        key_parts = result["key"].split("/")
        pattern = "/".join(["<platform>", "<component>", "<environment>"] + 
                          (["<instance>"] if len(key_parts) == 5 else []) + 
                          ["terraform.tfstate"])
        key_patterns.add(pattern)
    
    for pattern in sorted(key_patterns):
        print(f"  • {pattern}")

def validate_naming_rules(results):
    """Validate that naming follows the rules"""
    
    print("\n✅ Validation Checks")
    print("=" * 60)
    
    errors = []
    warnings = []
    
    # Check bucket name constraints
    for result in results:
        bucket = result["bucket"]
        
        # S3 bucket naming rules
        if len(bucket) < 3 or len(bucket) > 63:
            errors.append(f"Bucket name length invalid: {bucket} ({len(bucket)} chars)")
        
        if not bucket.islower():
            errors.append(f"Bucket name not lowercase: {bucket}")
        
        if bucket.startswith("-") or bucket.endswith("-"):
            errors.append(f"Bucket name starts/ends with hyphen: {bucket}")
        
        if ".." in bucket or ".-" in bucket or "-." in bucket:
            errors.append(f"Bucket name has invalid character sequences: {bucket}")
    
    # Check state key uniqueness
    keys = [result["key"] for result in results]
    if len(keys) != len(set(keys)):
        errors.append("Duplicate state keys found")
    
    # Check table name constraints
    for result in results:
        table = result["table"]
        
        # DynamoDB table naming rules
        if len(table) < 3 or len(table) > 255:
            errors.append(f"Table name length invalid: {table} ({len(table)} chars)")
    
    # Print results
    if errors:
        print("❌ Validation Errors:")
        for error in errors:
            print(f"  • {error}")
    else:
        print("✅ All validation checks passed!")
    
    if warnings:
        print("\n⚠️  Warnings:")
        for warning in warnings:
            print(f"  • {warning}")
    
    return len(errors) == 0

def main():
    """Main function"""
    
    try:
        # Test naming scenarios
        results = test_naming_scenarios()
        
        if not results:
            print("❌ No test results generated")
            sys.exit(1)
        
        # Print results
        print_results_table(results)
        print_naming_analysis(results)
        
        # Validate naming rules
        is_valid = validate_naming_rules(results)
        
        # Summary
        print(f"\n🎯 Summary")
        print("=" * 60)
        if is_valid:
            print("✅ Naming convention validation PASSED")
            print("🚀 Ready for implementation!")
        else:
            print("❌ Naming convention validation FAILED")
            print("🔧 Please fix the errors above")
            sys.exit(1)
        
        # Show example usage
        print(f"\n📖 Example Usage:")
        print("=" * 60)
        print("# Generate backend config for Azure network in dev:")
        print("python3 scripts/generate-backend-config.py dev azure network")
        print("")
        print("# Generate backend config for AKS cluster in dev:")
        print("python3 scripts/generate-backend-config.py dev azure aks cluster-01")
        print("")
        print("# Use in GitHub Actions:")
        print("- name: Setup Backend")
        print("  uses: ./.github/actions/terraform-backend-enhanced")
        print("  with:")
        print("    environment: dev")
        print("    platform: azure")
        print("    component: network")
        
    except Exception as e:
        print(f"❌ Error during validation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()