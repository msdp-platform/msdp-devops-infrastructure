#!/usr/bin/env python3
"""
Platform Engineering Configuration Validator
Validates Backstage + Crossplane + ArgoCD configuration following MSDP patterns
"""

import argparse
import os
import sys
from pathlib import Path

import yaml


def load_yaml_file(file_path):
    """Load and parse YAML file"""
    try:
        with open(file_path, "r") as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"ERROR: Configuration file not found: {file_path}")
        return None
    except yaml.YAMLError as e:
        print(f"ERROR: Invalid YAML in {file_path}: {e}")
        return None


def validate_versions(config):
    """Validate component versions are specified"""
    print("🔍 Validating component versions...")

    versions = config.get("versions", {})
    required_components = ["backstage", "crossplane"]  # ArgoCD managed separately

    for component in required_components:
        if component not in versions:
            print(f"❌ Missing version configuration for {component}")
            return False

        component_versions = versions[component]
        required_fields = ["chart_version", "app_version"]

        for field in required_fields:
            if field not in component_versions:
                print(f"❌ Missing {field} for {component}")
                return False

        print(
            f"✅ {component}: chart={component_versions['chart_version']}, app={component_versions['app_version']}"
        )

    return True


def validate_component_config(config, component_name):
    """Validate specific component configuration"""
    print(f"🔍 Validating {component_name} configuration...")

    components = config.get("components", {})
    if component_name not in components:
        print(f"❌ Component {component_name} not found in configuration")
        return False

    component = components[component_name]

    # Common required fields
    required_fields = ["enabled", "namespace", "chart_version", "repository"]
    for field in required_fields:
        if field not in component:
            print(f"❌ Missing required field '{field}' for {component_name}")
            return False

    # Component-specific validations
    if component_name == "crossplane":
        if not validate_crossplane_config(component):
            return False
    elif component_name == "backstage":
        if not validate_backstage_config(component):
            return False
    elif component_name == "argocd":
        if not validate_argocd_config(component):
            return False

    print(f"✅ {component_name} configuration valid")
    return True


def validate_crossplane_config(config):
    """Validate Crossplane-specific configuration"""
    # Check providers configuration
    if "providers" not in config:
        print("❌ Crossplane providers configuration missing")
        return False

    providers = config["providers"]
    required_providers = ["azure", "aws"]

    for provider in required_providers:
        if provider not in providers:
            print(f"❌ Missing provider configuration: {provider}")
            return False

        provider_config = providers[provider]
        if not provider_config.get("enabled", False):
            print(f"⚠️  Provider {provider} is disabled")
        else:
            if "version" not in provider_config:
                print(f"❌ Missing version for provider {provider}")
                return False

    return True


def validate_backstage_config(config):
    """Validate Backstage-specific configuration"""
    # Check app_config
    if "app_config" not in config:
        print("❌ Backstage app_config missing")
        return False

    app_config = config["app_config"]
    required_sections = ["app", "backend", "auth", "catalog"]

    for section in required_sections:
        if section not in app_config:
            print(f"❌ Missing app_config section: {section}")
            return False

    # Validate proxy configuration for MSDP services
    if "proxy" in app_config:
        proxy_config = app_config["proxy"]
        msdp_services = [
            "/api/location",
            "/api/merchant",
            "/api/user",
            "/api/order",
            "/api/payment",
        ]

        for service in msdp_services:
            if service not in proxy_config:
                print(f"⚠️  Missing proxy configuration for {service}")

    return True


def validate_argocd_config(config):
    """Validate ArgoCD-specific configuration"""
    # Check values configuration
    if "values" not in config:
        print("❌ ArgoCD values configuration missing")
        return False

    values = config["values"]

    # Check server configuration
    if "server" not in values:
        print("❌ ArgoCD server configuration missing")
        return False

    server_config = values["server"]
    if "ingress" not in server_config:
        print("❌ ArgoCD ingress configuration missing")
        return False

    # Check repository configuration
    if "configs" not in values or "repositories" not in values["configs"]:
        print("❌ ArgoCD repository configuration missing")
        return False

    return True


def validate_environment_config(env_config, environment):
    """Validate environment-specific configuration"""
    print(f"🔍 Validating environment configuration for {environment}...")

    if not env_config:
        print(f"❌ Environment configuration file not found for {environment}")
        return False

    # Check Azure configuration
    azure_config = env_config.get("azure", {})
    if not azure_config:
        print("❌ Azure configuration missing")
        return False

    # Check AKS clusters
    aks_config = azure_config.get("aks", {})
    clusters = aks_config.get("clusters", [])

    if not clusters:
        print("❌ No AKS clusters configured")
        return False

    print(f"✅ Found {len(clusters)} AKS clusters configured")

    # Validate cluster configuration
    for cluster in clusters:
        if "name" not in cluster:
            print("❌ Cluster missing name")
            return False
        print(f"✅ Cluster: {cluster['name']}")

    return True


def validate_naming_conventions(naming_config):
    """Validate naming conventions are properly configured"""
    print("🔍 Validating naming conventions...")

    if not naming_config:
        print("❌ Naming configuration not found")
        return False

    required_sections = [
        "organization",
        "naming_conventions",
        "platforms",
        "components",
        "environments",
    ]

    for section in required_sections:
        if section not in naming_config:
            print(f"❌ Missing naming configuration section: {section}")
            return False

    # Validate organization
    org = naming_config["organization"]
    if "name" not in org or org["name"] != "msdp":
        print(
            f"❌ Organization name should be 'msdp', found: {org.get('name', 'missing')}"
        )
        return False

    print(f"✅ Organization: {org['name']} - {org['full_name']}")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Validate Platform Engineering Configuration"
    )
    parser.add_argument("--environment", required=True, help="Environment to validate")
    parser.add_argument(
        "--component",
        default="all",
        help="Component to validate (all, crossplane, backstage, argocd)",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    print("🚀 MSDP Platform Engineering Configuration Validator")
    print("=" * 55)
    print(f"Environment: {args.environment}")
    print(f"Component: {args.component}")
    print()

    # Load configurations
    platform_config = load_yaml_file("config/platform-engineering.yaml")
    env_config = load_yaml_file(f"config/{args.environment}.yaml")
    naming_config = load_yaml_file("config/global/naming.yaml")

    if not all([platform_config, env_config, naming_config]):
        print("❌ Failed to load required configuration files")
        sys.exit(1)

    # Validate naming conventions
    if not validate_naming_conventions(naming_config):
        print("❌ Naming convention validation failed")
        sys.exit(1)

    # Validate environment configuration
    if not validate_environment_config(env_config, args.environment):
        print("❌ Environment configuration validation failed")
        sys.exit(1)

    # Validate versions
    if not validate_versions(platform_config):
        print("❌ Version validation failed")
        sys.exit(1)

    # Validate component configurations
    components_to_validate = (
        ["crossplane", "backstage"]  # ArgoCD managed separately
        if args.component == "all"
        else [args.component]
    )

    for component in components_to_validate:
        if not validate_component_config(platform_config, component):
            print(f"❌ {component} configuration validation failed")
            sys.exit(1)

    print()
    print("🎉 VALIDATION SUCCESSFUL!")
    print("=" * 25)
    print("✅ All configurations are valid")
    print("✅ Ready for platform engineering deployment")
    print("✅ Following MSDP naming conventions")
    print("✅ Environment configuration complete")
    print()
    print("🚀 Next steps:")
    print("1. Deploy via GitHub Actions workflow")
    print("2. Monitor deployment progress")
    print("3. Validate platform functionality")
    print("4. Configure platform integrations")


if __name__ == "__main__":
    main()
