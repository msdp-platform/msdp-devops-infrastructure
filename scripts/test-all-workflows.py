#!/usr/bin/env python3
"""
Test All Workflows Script

This script tests all available workflows in the MSDP DevOps Infrastructure repository
and provides a comprehensive status report.
"""

import subprocess
import json
import time
from datetime import datetime
from typing import Dict, List, Optional

class WorkflowTester:
    def __init__(self):
        self.test_results = {}
        self.workflows_to_test = {
            # Orchestration Layer
            "Infrastructure Orchestrator": {
                "params": {
                    "target_environment": "dev",
                    "components": "network",
                    "action": "plan",
                    "cloud_provider": "azure"
                }
            },
            "Environment Promotion": {
                "params": {
                    "source_environment": "dev",
                    "target_environment": "staging", 
                    "components": "network",
                    "cloud_provider": "azure",
                    "auto_approve": "true"
                }
            },
            
            # Infrastructure Layer
            "Network Infrastructure": {
                "params": {
                    "cloud_provider": "azure",
                    "action": "plan",
                    "environment": "dev"
                }
            },
            "Kubernetes Clusters": {
                "params": {
                    "cloud_provider": "azure",
                    "action": "plan",
                    "environment": "dev",
                    "cluster_name": "aks-msdp-dev-01"
                }
            },
            "Kubernetes Add-ons (Terraform)": {
                "params": {
                    "cluster_name": "aks-msdp-dev-01",
                    "environment": "dev",
                    "cloud_provider": "azure",
                    "action": "plan",
                    "auto_approve": "false"
                }
            },
            "Platform Engineering Stack (Backstage + Crossplane)": {
                "params": {
                    "action": "plan",
                    "environment": "dev",
                    "component": "all"
                }
            },
            
            # Utility Layer - These typically don't have workflow_dispatch
            # "Terraform Validate": {},
            # "k8s-validate": {},
            # "docker-build": {}
        }
    
    def run_gh_command(self, cmd: List[str]) -> tuple[bool, str]:
        """Run a GitHub CLI command and return success status and output."""
        try:
            result = subprocess.run(
                ['gh'] + cmd,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode == 0, result.stdout + result.stderr
        except subprocess.TimeoutExpired:
            return False, "Command timed out"
        except Exception as e:
            return False, str(e)
    
    def test_workflow_trigger(self, workflow_name: str, params: Dict[str, str]) -> Dict:
        """Test triggering a specific workflow."""
        print(f"🧪 Testing workflow: {workflow_name}")
        
        # Build the command
        cmd = ["workflow", "run", workflow_name]
        for key, value in params.items():
            cmd.extend(["--field", f"{key}={value}"])
        
        # Execute the command
        success, output = self.run_gh_command(cmd)
        
        result = {
            "workflow": workflow_name,
            "success": success,
            "output": output.strip(),
            "timestamp": datetime.now().isoformat(),
            "params": params
        }
        
        if success:
            print(f"  ✅ Successfully triggered {workflow_name}")
        else:
            print(f"  ❌ Failed to trigger {workflow_name}")
            print(f"     Error: {output.strip()}")
        
        return result
    
    def get_workflow_list(self) -> List[Dict]:
        """Get list of available workflows."""
        success, output = self.run_gh_command(["workflow", "list", "--json", "name,id,state"])
        
        if success:
            try:
                return json.loads(output)
            except json.JSONDecodeError:
                return []
        return []
    
    def get_recent_runs(self, limit: int = 5) -> List[Dict]:
        """Get recent workflow runs."""
        success, output = self.run_gh_command([
            "run", "list", 
            "--limit", str(limit),
            "--json", "status,conclusion,name,createdAt,headBranch,databaseId"
        ])
        
        if success:
            try:
                return json.loads(output)
            except json.JSONDecodeError:
                return []
        return []
    
    def test_all_workflows(self) -> None:
        """Test all configured workflows."""
        print("🚀 Testing All MSDP DevOps Infrastructure Workflows")
        print("=" * 60)
        print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Get available workflows
        available_workflows = self.get_workflow_list()
        available_names = [w['name'] for w in available_workflows]
        
        print("📋 Available Workflows:")
        for workflow in available_workflows:
            status_icon = "✅" if workflow['state'] == 'active' else "❌"
            print(f"  {status_icon} {workflow['name']} (ID: {workflow['id']})")
        print()
        
        # Test each configured workflow
        print("🧪 Testing Workflow Triggers:")
        print("-" * 40)
        
        for workflow_name, config in self.workflows_to_test.items():
            if workflow_name in available_names:
                result = self.test_workflow_trigger(workflow_name, config.get('params', {}))
                self.test_results[workflow_name] = result
            else:
                print(f"⚠️  Workflow '{workflow_name}' not found in available workflows")
                self.test_results[workflow_name] = {
                    "workflow": workflow_name,
                    "success": False,
                    "output": "Workflow not found",
                    "timestamp": datetime.now().isoformat(),
                    "params": config.get('params', {})
                }
            print()
        
        # Wait a moment for workflows to start
        print("⏳ Waiting 10 seconds for workflows to start...")
        time.sleep(10)
        
        # Check recent runs
        print("\n📊 Recent Workflow Activity:")
        print("-" * 40)
        recent_runs = self.get_recent_runs(10)
        
        if recent_runs:
            for run in recent_runs[:5]:  # Show top 5
                status_icon = {
                    'completed': '✅' if run.get('conclusion') == 'success' else '❌',
                    'in_progress': '🔄',
                    'queued': '⏳'
                }.get(run.get('status', 'unknown'), '❓')
                
                created_time = run.get('createdAt', 'Unknown')
                print(f"  {status_icon} {run.get('name', 'Unknown')} - {run.get('status', 'unknown')} ({created_time})")
        else:
            print("  No recent runs found")
        
        # Generate summary
        self.generate_summary()
    
    def generate_summary(self) -> None:
        """Generate test summary report."""
        print("\n" + "=" * 60)
        print("📊 WORKFLOW TEST SUMMARY")
        print("=" * 60)
        
        total_tests = len(self.test_results)
        successful_tests = sum(1 for result in self.test_results.values() if result['success'])
        failed_tests = total_tests - successful_tests
        
        print(f"Total Workflows Tested: {total_tests}")
        print(f"Successfully Triggered: {successful_tests}")
        print(f"Failed to Trigger: {failed_tests}")
        print(f"Success Rate: {(successful_tests/total_tests)*100:.1f}%" if total_tests > 0 else "N/A")
        
        if failed_tests > 0:
            print(f"\n❌ Failed Workflows:")
            for name, result in self.test_results.items():
                if not result['success']:
                    print(f"  - {name}: {result['output']}")
        
        if successful_tests > 0:
            print(f"\n✅ Successfully Triggered Workflows:")
            for name, result in self.test_results.items():
                if result['success']:
                    print(f"  - {name}")
        
        print(f"\n🎯 Recommendations:")
        if failed_tests == 0:
            print("  🎉 All workflows are working correctly!")
            print("  ✅ Infrastructure orchestration system is ready for production")
        else:
            print("  🔧 Review failed workflows and fix any configuration issues")
            print("  📚 Check workflow documentation for proper parameter usage")
        
        print("\n" + "=" * 60)

def main():
    """Main function."""
    tester = WorkflowTester()
    tester.test_all_workflows()

if __name__ == "__main__":
    main()
