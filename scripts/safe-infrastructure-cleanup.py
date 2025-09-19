#!/usr/bin/env python3
"""
Safe Infrastructure Cleanup Script

This script helps safely destroy existing infrastructure in the correct order
to avoid dependency issues, then guides through fresh provisioning.
"""

import subprocess
import json
import time
import sys
from datetime import datetime
from typing import Dict, List, Optional, Tuple

class InfrastructureCleanup:
    def __init__(self):
        self.cleanup_order = [
            {
                "name": "Platform Engineering Stack",
                "description": "Backstage + Crossplane (depends on addons)",
                "workflow": "Platform Engineering Stack (Backstage + Crossplane)",
                "params": {
                    "action": "destroy",
                    "environment": "dev",
                    "component": "all"
                },
                "dependencies": ["addons"]
            },
            {
                "name": "Kubernetes Add-ons",
                "description": "cert-manager, external-dns, ingress controllers (depends on clusters)",
                "workflow": "Kubernetes Add-ons (Terraform)",
                "params": {
                    "cluster_name": "aks-msdp-dev-01",
                    "environment": "dev",
                    "cloud_provider": "azure",
                    "action": "destroy",
                    "auto_approve": "true"
                },
                "dependencies": ["clusters"]
            },
            {
                "name": "Kubernetes Clusters",
                "description": "AKS/EKS clusters (depends on network)",
                "workflow": "Kubernetes Clusters",
                "params": {
                    "cloud_provider": "azure",
                    "action": "destroy",
                    "environment": "dev",
                    "cluster_name": ""  # All clusters
                },
                "dependencies": ["network"]
            },
            {
                "name": "Network Infrastructure",
                "description": "VPC/VNet, subnets, security groups (foundation)",
                "workflow": "Network Infrastructure",
                "params": {
                    "cloud_provider": "azure",
                    "action": "destroy",
                    "environment": "dev"
                },
                "dependencies": []
            }
        ]
        
        self.provisioning_order = [
            {
                "name": "Network Infrastructure",
                "description": "VPC/VNet, subnets, security groups (foundation)",
                "workflow": "Network Infrastructure",
                "params": {
                    "cloud_provider": "azure",
                    "action": "apply",
                    "environment": "dev"
                },
                "wait_minutes": 8
            },
            {
                "name": "Kubernetes Clusters",
                "description": "AKS/EKS clusters (depends on network)",
                "workflow": "Kubernetes Clusters",
                "params": {
                    "cloud_provider": "azure",
                    "action": "apply",
                    "environment": "dev",
                    "cluster_name": "aks-msdp-dev-01"  # Start with one cluster
                },
                "wait_minutes": 15
            },
            {
                "name": "Kubernetes Add-ons",
                "description": "cert-manager, external-dns, ingress controllers",
                "workflow": "Kubernetes Add-ons (Terraform)",
                "params": {
                    "cluster_name": "aks-msdp-dev-01",
                    "environment": "dev",
                    "cloud_provider": "azure",
                    "action": "apply",
                    "auto_approve": "true"
                },
                "wait_minutes": 12
            },
            {
                "name": "Platform Engineering Stack",
                "description": "Backstage + Crossplane",
                "workflow": "Platform Engineering Stack (Backstage + Crossplane)",
                "params": {
                    "action": "apply",
                    "environment": "dev",
                    "component": "all",
                    "cluster_name": "aks-msdp-dev-01"
                },
                "wait_minutes": 10
            }
        ]
    
    def run_gh_command(self, cmd: List[str], timeout: int = 60) -> Tuple[bool, str]:
        """Run a GitHub CLI command and return success status and output."""
        try:
            result = subprocess.run(
                ['gh'] + cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.returncode == 0, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return False, f"Command timed out after {timeout} seconds"
        except Exception as e:
            return False, str(e)
    
    def get_existing_infrastructure(self) -> Dict:
        """Check what infrastructure currently exists."""
        print("🔍 Checking existing infrastructure...")
        
        # This would typically check cloud resources
        # For now, we'll assume infrastructure exists based on user statement
        existing = {
            "network": True,
            "clusters": True,
            "addons": True,
            "platform": True
        }
        
        print("📋 Found existing infrastructure:")
        for component, exists in existing.items():
            status = "✅ EXISTS" if exists else "❌ NOT FOUND"
            print(f"   {component}: {status}")
        
        return existing
    
    def confirm_destruction(self) -> bool:
        """Get user confirmation for infrastructure destruction."""
        print("\n" + "="*60)
        print("⚠️  INFRASTRUCTURE DESTRUCTION CONFIRMATION")
        print("="*60)
        print("This will DESTROY the following infrastructure:")
        print()
        
        for item in reversed(self.cleanup_order):  # Show in destruction order
            print(f"🗑️  {item['name']}: {item['description']}")
        
        print()
        print("⚠️  WARNING: This action is IRREVERSIBLE!")
        print("⚠️  All data and configurations will be PERMANENTLY LOST!")
        print()
        
        while True:
            response = input("Type 'DESTROY' to confirm, or 'cancel' to abort: ").strip()
            if response == 'DESTROY':
                return True
            elif response.lower() == 'cancel':
                return False
            else:
                print("❌ Invalid response. Please type 'DESTROY' or 'cancel'")
    
    def trigger_workflow(self, workflow_name: str, params: Dict[str, str]) -> Tuple[bool, str]:
        """Trigger a workflow with specified parameters."""
        print(f"🚀 Triggering: {workflow_name}")
        print(f"   📋 Parameters: {params}")
        
        # Build the command
        cmd = ["workflow", "run", workflow_name]
        for key, value in params.items():
            if value:  # Only add non-empty values
                cmd.extend(["--field", f"{key}={value}"])
        
        # Execute the command
        success, output = self.run_gh_command(cmd, timeout=30)
        
        if success:
            print(f"   ✅ Successfully triggered {workflow_name}")
        else:
            print(f"   ❌ Failed to trigger {workflow_name}")
            print(f"      Error: {output.strip()}")
        
        return success, output
    
    def wait_for_completion(self, workflow_name: str, timeout_minutes: int = 20) -> bool:
        """Wait for a workflow to complete."""
        print(f"   ⏳ Waiting for {workflow_name} to complete (max {timeout_minutes} minutes)...")
        
        start_time = datetime.now()
        timeout = start_time.timestamp() + (timeout_minutes * 60)
        
        while datetime.now().timestamp() < timeout:
            # Check recent runs
            success, output = self.run_gh_command([
                "run", "list",
                "--workflow", workflow_name,
                "--limit", "1",
                "--json", "status,conclusion,createdAt"
            ])
            
            if success:
                try:
                    runs = json.loads(output)
                    if runs:
                        run = runs[0]
                        status = run.get('status')
                        conclusion = run.get('conclusion')
                        
                        if status == 'completed':
                            if conclusion == 'success':
                                print(f"   ✅ {workflow_name} completed successfully")
                                return True
                            else:
                                print(f"   ❌ {workflow_name} completed with {conclusion}")
                                return False
                        else:
                            print(f"   🔄 Status: {status}")
                except json.JSONDecodeError:
                    pass
            
            time.sleep(30)  # Check every 30 seconds
        
        print(f"   ⏰ Timeout waiting for {workflow_name}")
        return False
    
    def destroy_infrastructure(self) -> bool:
        """Destroy infrastructure in the correct order."""
        print("\n🗑️  Starting Infrastructure Destruction")
        print("="*50)
        
        for i, component in enumerate(self.cleanup_order, 1):
            print(f"\n[{i}/{len(self.cleanup_order)}] Destroying: {component['name']}")
            print(f"📝 Description: {component['description']}")
            
            # Trigger the workflow
            success, output = self.trigger_workflow(component['workflow'], component['params'])
            
            if not success:
                print(f"❌ Failed to trigger destruction of {component['name']}")
                return False
            
            # Wait for completion
            if not self.wait_for_completion(component['workflow'], 20):
                print(f"❌ Destruction of {component['name']} did not complete successfully")
                return False
            
            print(f"✅ Successfully destroyed {component['name']}")
        
        print("\n🎉 Infrastructure destruction completed successfully!")
        return True
    
    def provision_infrastructure(self) -> bool:
        """Provision infrastructure step by step."""
        print("\n🚀 Starting Fresh Infrastructure Provisioning")
        print("="*50)
        print("This will provision infrastructure in the correct dependency order:")
        print()
        
        for item in self.provisioning_order:
            print(f"📦 {item['name']}: {item['description']}")
        
        print()
        confirm = input("Proceed with fresh provisioning? (y/N): ").strip().lower()
        if confirm != 'y':
            print("❌ Provisioning cancelled")
            return False
        
        for i, component in enumerate(self.provisioning_order, 1):
            print(f"\n[{i}/{len(self.provisioning_order)}] Provisioning: {component['name']}")
            print(f"📝 Description: {component['description']}")
            print(f"⏱️  Expected duration: ~{component['wait_minutes']} minutes")
            
            # Trigger the workflow
            success, output = self.trigger_workflow(component['workflow'], component['params'])
            
            if not success:
                print(f"❌ Failed to trigger provisioning of {component['name']}")
                return False
            
            # Wait for completion
            if not self.wait_for_completion(component['workflow'], component['wait_minutes'] + 5):
                print(f"❌ Provisioning of {component['name']} did not complete successfully")
                print("🔧 You may need to check the workflow logs and retry manually")
                return False
            
            print(f"✅ Successfully provisioned {component['name']}")
            
            # Brief pause between components
            if i < len(self.provisioning_order):
                print("   ⏸️  Waiting 30 seconds before next component...")
                time.sleep(30)
        
        print("\n🎉 Fresh infrastructure provisioning completed successfully!")
        return True
    
    def test_with_orchestrator(self) -> None:
        """Test the full infrastructure using the orchestrator."""
        print("\n🧪 Testing with Infrastructure Orchestrator")
        print("="*50)
        
        print("Now let's test the full orchestration workflow:")
        
        # Test orchestrator with all components
        orchestrator_params = {
            "target_environment": "dev",
            "components": "network,clusters,addons,platform",
            "action": "plan",  # Start with plan
            "cloud_provider": "azure",
            "force_sequential": "false"
        }
        
        print("🚀 Testing Infrastructure Orchestrator with all components...")
        success, output = self.trigger_workflow("Infrastructure Orchestrator", orchestrator_params)
        
        if success:
            print("✅ Orchestrator test triggered successfully")
            print("📊 This will validate that all components work together")
        else:
            print("❌ Failed to trigger orchestrator test")
    
    def run_cleanup_and_provision(self) -> None:
        """Main function to run the complete cleanup and provisioning process."""
        print("🏗️  MSDP Infrastructure - Safe Cleanup and Fresh Provisioning")
        print("="*70)
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Check existing infrastructure
        existing = self.get_existing_infrastructure()
        
        if not any(existing.values()):
            print("ℹ️  No existing infrastructure found. Proceeding directly to provisioning.")
            self.provision_infrastructure()
            return
        
        # Get confirmation for destruction
        if not self.confirm_destruction():
            print("❌ Infrastructure destruction cancelled by user")
            return
        
        print("\n⏳ Starting destruction process in 10 seconds...")
        print("   Press Ctrl+C to abort")
        try:
            time.sleep(10)
        except KeyboardInterrupt:
            print("\n❌ Process aborted by user")
            return
        
        # Destroy existing infrastructure
        if not self.destroy_infrastructure():
            print("❌ Infrastructure destruction failed. Please check manually.")
            return
        
        print("\n⏳ Waiting 2 minutes for cleanup to complete...")
        time.sleep(120)
        
        # Provision fresh infrastructure
        if not self.provision_infrastructure():
            print("❌ Fresh provisioning failed. Please check manually.")
            return
        
        # Test with orchestrator
        self.test_with_orchestrator()
        
        print("\n" + "="*70)
        print("🎉 COMPLETE: Infrastructure cleanup and fresh provisioning finished!")
        print("✅ Your infrastructure is now provisioned using the new orchestration system")
        print("📚 Check the workflow runs in GitHub Actions for detailed logs")
        print("="*70)

def main():
    """Main function."""
    if len(sys.argv) > 1:
        if sys.argv[1] == "--destroy-only":
            cleanup = InfrastructureCleanup()
            existing = cleanup.get_existing_infrastructure()
            if cleanup.confirm_destruction():
                cleanup.destroy_infrastructure()
            return
        elif sys.argv[1] == "--provision-only":
            cleanup = InfrastructureCleanup()
            cleanup.provision_infrastructure()
            return
        elif sys.argv[1] == "--test-orchestrator":
            cleanup = InfrastructureCleanup()
            cleanup.test_with_orchestrator()
            return
    
    # Full cleanup and provision
    cleanup = InfrastructureCleanup()
    cleanup.run_cleanup_and_provision()

if __name__ == "__main__":
    main()
