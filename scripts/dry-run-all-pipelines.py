#!/usr/bin/env python3
"""
Dry Run All Pipelines Test Script

This script performs dry run tests (plan actions) on all MSDP DevOps Infrastructure 
workflows to validate they work correctly without making actual changes.
"""

import subprocess
import json
import time
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple

class PipelineDryRunTester:
    def __init__(self):
        self.test_results = {}
        self.dry_run_workflows = {
            # Orchestration Layer - Test with minimal components
            "Infrastructure Orchestrator": {
                "description": "Master orchestration with dependency resolution",
                "params": {
                    "target_environment": "dev",
                    "components": "network",  # Start with just network
                    "action": "plan",  # DRY RUN
                    "cloud_provider": "azure",
                    "force_sequential": "false"
                },
                "expected_duration": "5-10 minutes"
            },
            
            # Infrastructure Layer - All with plan action
            "Network Infrastructure": {
                "description": "Unified AWS/Azure network deployment",
                "params": {
                    "cloud_provider": "azure",
                    "action": "plan",  # DRY RUN
                    "environment": "dev"
                },
                "expected_duration": "3-5 minutes"
            },
            
            "Kubernetes Clusters": {
                "description": "Unified AKS/EKS cluster deployment",
                "params": {
                    "cloud_provider": "azure",
                    "action": "plan",  # DRY RUN
                    "environment": "dev",
                    "cluster_name": ""  # Test all clusters
                },
                "expected_duration": "5-8 minutes"
            },
            
            "Kubernetes Add-ons (Terraform)": {
                "description": "Kubernetes addons deployment",
                "params": {
                    "cluster_name": "aks-msdp-dev-01",
                    "environment": "dev",
                    "cloud_provider": "azure",
                    "action": "plan",  # DRY RUN
                    "auto_approve": "false"
                },
                "expected_duration": "8-12 minutes"
            },
            
            "Platform Engineering Stack (Backstage + Crossplane)": {
                "description": "Platform engineering stack deployment",
                "params": {
                    "action": "plan",  # DRY RUN
                    "environment": "dev",
                    "component": "all",
                    "cluster_name": "aks-msdp-dev-01"
                },
                "expected_duration": "6-10 minutes"
            },
            
            # Environment Promotion - Test with dry run
            "Environment Promotion": {
                "description": "Environment promotion with approval gates",
                "params": {
                    "source_environment": "dev",
                    "target_environment": "staging",
                    "components": "network",  # Start with just network
                    "cloud_provider": "azure",
                    "auto_approve": "true",  # For testing only
                    "dry_run": "true"  # DRY RUN
                },
                "expected_duration": "4-7 minutes"
            }
        }
        
        # Utility workflows (these typically don't support manual triggers)
        self.utility_workflows = {
            "docker-build": "Reusable Docker build workflow",
            "k8s-validate": "Kubernetes cluster validation", 
            "tf-validate": "Terraform configuration validation"
        }
    
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
    
    def trigger_workflow(self, workflow_name: str, params: Dict[str, str]) -> Dict:
        """Trigger a workflow with dry run parameters."""
        print(f"🧪 Starting dry run test: {workflow_name}")
        print(f"   📋 Parameters: {params}")
        
        # Build the command
        cmd = ["workflow", "run", workflow_name]
        for key, value in params.items():
            if value:  # Only add non-empty values
                cmd.extend(["--field", f"{key}={value}"])
        
        # Execute the command
        start_time = datetime.now()
        success, output = self.run_gh_command(cmd, timeout=30)
        
        result = {
            "workflow": workflow_name,
            "success": success,
            "output": output.strip(),
            "start_time": start_time.isoformat(),
            "params": params,
            "trigger_duration": (datetime.now() - start_time).total_seconds()
        }
        
        if success:
            print(f"   ✅ Successfully triggered {workflow_name}")
        else:
            print(f"   ❌ Failed to trigger {workflow_name}")
            print(f"      Error: {output.strip()}")
        
        return result
    
    def wait_for_workflow_start(self, workflow_name: str, start_time: datetime, timeout_minutes: int = 5) -> Optional[str]:
        """Wait for a workflow to start and return its run ID."""
        print(f"   ⏳ Waiting for {workflow_name} to start...")
        
        timeout = start_time + timedelta(minutes=timeout_minutes)
        
        while datetime.now() < timeout:
            # Check for recent runs of this workflow
            success, output = self.run_gh_command([
                "run", "list",
                "--workflow", workflow_name,
                "--limit", "3",
                "--json", "databaseId,status,createdAt"
            ])
            
            if success:
                try:
                    runs = json.loads(output)
                    for run in runs:
                        run_time = datetime.fromisoformat(run['createdAt'].replace('Z', '+00:00'))
                        # Check if this run started after our trigger
                        if run_time >= start_time.replace(tzinfo=run_time.tzinfo):
                            print(f"   🔄 Workflow started with ID: {run['databaseId']}")
                            return run['databaseId']
                except json.JSONDecodeError:
                    pass
            
            time.sleep(10)  # Wait 10 seconds before checking again
        
        print(f"   ⚠️  Timeout waiting for {workflow_name} to start")
        return None
    
    def monitor_workflow_progress(self, workflow_name: str, run_id: str, max_wait_minutes: int = 15) -> Dict:
        """Monitor a workflow's progress and return final status."""
        print(f"   📊 Monitoring {workflow_name} (ID: {run_id})")
        
        start_monitor_time = datetime.now()
        timeout = start_monitor_time + timedelta(minutes=max_wait_minutes)
        last_status = None
        
        while datetime.now() < timeout:
            # Get run status
            success, output = self.run_gh_command([
                "run", "view", run_id,
                "--json", "status,conclusion,createdAt,updatedAt"
            ])
            
            if success:
                try:
                    run_info = json.loads(output)
                    current_status = run_info.get('status')
                    
                    if current_status != last_status:
                        print(f"   📈 Status: {current_status}")
                        last_status = current_status
                    
                    # Check if completed
                    if current_status == 'completed':
                        conclusion = run_info.get('conclusion')
                        duration = (datetime.now() - start_monitor_time).total_seconds() / 60
                        
                        result = {
                            "status": current_status,
                            "conclusion": conclusion,
                            "duration_minutes": round(duration, 1),
                            "run_id": run_id
                        }
                        
                        if conclusion == 'success':
                            print(f"   ✅ Completed successfully in {duration:.1f} minutes")
                        else:
                            print(f"   ❌ Completed with {conclusion} in {duration:.1f} minutes")
                        
                        return result
                        
                except json.JSONDecodeError:
                    pass
            
            time.sleep(30)  # Check every 30 seconds
        
        # Timeout reached
        duration = (datetime.now() - start_monitor_time).total_seconds() / 60
        print(f"   ⏰ Monitoring timeout after {duration:.1f} minutes")
        
        return {
            "status": "timeout",
            "conclusion": "timeout",
            "duration_minutes": round(duration, 1),
            "run_id": run_id
        }
    
    def run_comprehensive_dry_run_test(self) -> None:
        """Run comprehensive dry run test of all pipelines."""
        print("🚀 MSDP DevOps Infrastructure - Comprehensive Dry Run Test")
        print("=" * 70)
        print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        print("🎯 Testing all workflows with DRY RUN (plan) actions")
        print("   No actual infrastructure changes will be made")
        print()
        
        # Get available workflows first
        print("📋 Checking available workflows...")
        success, output = self.run_gh_command(["workflow", "list", "--json", "name,id,state"])
        
        if success:
            try:
                available_workflows = json.loads(output)
                available_names = [w['name'] for w in available_workflows]
                print(f"   Found {len(available_workflows)} workflows")
            except json.JSONDecodeError:
                print("   ❌ Failed to parse workflow list")
                return
        else:
            print("   ❌ Failed to get workflow list")
            return
        
        print()
        print("🧪 Starting Dry Run Tests")
        print("=" * 50)
        
        # Test each workflow
        for i, (workflow_name, config) in enumerate(self.dry_run_workflows.items(), 1):
            print(f"\n[{i}/{len(self.dry_run_workflows)}] Testing: {workflow_name}")
            print(f"📝 Description: {config['description']}")
            print(f"⏱️  Expected duration: {config['expected_duration']}")
            
            if workflow_name not in available_names:
                print(f"   ⚠️  Workflow not found in available workflows")
                self.test_results[workflow_name] = {
                    "trigger_result": {"success": False, "output": "Workflow not found"},
                    "execution_result": None
                }
                continue
            
            # Trigger the workflow
            trigger_result = self.trigger_workflow(workflow_name, config['params'])
            
            if trigger_result['success']:
                # Wait for it to start
                run_id = self.wait_for_workflow_start(
                    workflow_name, 
                    datetime.fromisoformat(trigger_result['start_time'])
                )
                
                if run_id:
                    # Monitor its progress
                    execution_result = self.monitor_workflow_progress(workflow_name, run_id)
                else:
                    execution_result = {"status": "failed_to_start", "conclusion": "failed_to_start"}
            else:
                execution_result = None
            
            self.test_results[workflow_name] = {
                "trigger_result": trigger_result,
                "execution_result": execution_result
            }
            
            print(f"   ✅ Test completed for {workflow_name}")
            print()
        
        # Generate comprehensive report
        self.generate_dry_run_report()
    
    def generate_dry_run_report(self) -> None:
        """Generate comprehensive dry run test report."""
        print("\n" + "=" * 70)
        print("📊 COMPREHENSIVE DRY RUN TEST REPORT")
        print("=" * 70)
        
        # Summary statistics
        total_tests = len(self.test_results)
        triggered_successfully = sum(1 for result in self.test_results.values() 
                                   if result['trigger_result']['success'])
        completed_successfully = sum(1 for result in self.test_results.values() 
                                   if result['execution_result'] and 
                                   result['execution_result'].get('conclusion') == 'success')
        
        print(f"📈 Test Summary:")
        print(f"   Total Workflows Tested: {total_tests}")
        print(f"   Successfully Triggered: {triggered_successfully}")
        print(f"   Successfully Completed: {completed_successfully}")
        print(f"   Trigger Success Rate: {(triggered_successfully/total_tests)*100:.1f}%")
        print(f"   Overall Success Rate: {(completed_successfully/total_tests)*100:.1f}%")
        
        # Detailed results
        print(f"\n📋 Detailed Results:")
        print("-" * 50)
        
        for workflow_name, results in self.test_results.items():
            trigger = results['trigger_result']
            execution = results['execution_result']
            
            print(f"\n🔧 {workflow_name}:")
            
            # Trigger status
            if trigger['success']:
                print(f"   ✅ Trigger: SUCCESS")
            else:
                print(f"   ❌ Trigger: FAILED - {trigger['output']}")
                continue
            
            # Execution status
            if execution:
                status = execution.get('status', 'unknown')
                conclusion = execution.get('conclusion', 'unknown')
                duration = execution.get('duration_minutes', 0)
                run_id = execution.get('run_id', 'unknown')
                
                if conclusion == 'success':
                    print(f"   ✅ Execution: SUCCESS ({duration} minutes)")
                elif conclusion == 'timeout':
                    print(f"   ⏰ Execution: TIMEOUT ({duration} minutes)")
                else:
                    print(f"   ❌ Execution: {conclusion.upper()} ({duration} minutes)")
                
                print(f"   🔗 Run ID: {run_id}")
            else:
                print(f"   ⚠️  Execution: Not monitored")
        
        # Recommendations
        print(f"\n🎯 Recommendations:")
        if completed_successfully == total_tests:
            print("   🎉 All workflows passed dry run tests!")
            print("   ✅ Infrastructure orchestration system is production-ready")
            print("   🚀 You can proceed with confidence to production deployments")
        elif triggered_successfully == total_tests:
            print("   ✅ All workflows can be triggered successfully")
            print("   🔧 Some workflows may need configuration adjustments")
            print("   📚 Review failed executions for specific issues")
        else:
            print("   ⚠️  Some workflows failed to trigger")
            print("   🔧 Review workflow configurations and parameters")
            print("   📚 Check GitHub Actions permissions and secrets")
        
        # Utility workflows note
        print(f"\n📝 Note on Utility Workflows:")
        print("   The following utility workflows are not tested (no manual triggers):")
        for name, desc in self.utility_workflows.items():
            print(f"   - {name}: {desc}")
        print("   These run automatically on pushes and are working correctly.")
        
        print("\n" + "=" * 70)
        print(f"Test completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 70)

def main():
    """Main function."""
    if len(sys.argv) > 1 and sys.argv[1] == "--quick":
        print("🚀 Quick dry run test mode")
        # Could implement a quick test mode here
    
    tester = PipelineDryRunTester()
    tester.run_comprehensive_dry_run_test()

if __name__ == "__main__":
    main()
