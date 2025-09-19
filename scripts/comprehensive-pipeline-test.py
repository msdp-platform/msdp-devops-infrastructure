#!/usr/bin/env python3
"""
Comprehensive Pipeline Test Script

Tests all MSDP DevOps Infrastructure pipelines with plan actions,
monitors results, and identifies any errors that need fixing.
"""

import subprocess
import json
import time
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple

class ComprehensivePipelineTest:
    def __init__(self):
        self.test_pipelines = {
            # Core Infrastructure Pipelines
            "Network Infrastructure": {
                "description": "Unified AWS/Azure network deployment",
                "params": {
                    "cloud_provider": "azure",
                    "action": "plan",
                    "environment": "dev"
                },
                "expected_duration": 5,
                "priority": 1
            },
            
            "Kubernetes Clusters": {
                "description": "Unified AKS/EKS cluster deployment",
                "params": {
                    "cloud_provider": "azure",
                    "action": "plan",
                    "environment": "dev",
                    "cluster_name": "aks-msdp-dev-01"
                },
                "expected_duration": 8,
                "priority": 2
            },
            
            "Kubernetes Add-ons (Terraform)": {
                "description": "Kubernetes addons with Route53 DNS",
                "params": {
                    "cluster_name": "aks-msdp-dev-01",
                    "environment": "dev",
                    "cloud_provider": "azure",
                    "action": "plan",
                    "auto_approve": "false"
                },
                "expected_duration": 10,
                "priority": 3
            },
            
            "Platform Engineering Stack (Backstage + Crossplane)": {
                "description": "Platform engineering components",
                "params": {
                    "action": "plan",
                    "environment": "dev",
                    "component": "all",
                    "cluster_name": "aks-msdp-dev-01"
                },
                "expected_duration": 8,
                "priority": 4
            },
            
            # Orchestration Pipelines
            "Infrastructure Orchestrator": {
                "description": "Master orchestration with dependency resolution",
                "params": {
                    "target_environment": "dev",
                    "components": "network",
                    "action": "plan",
                    "cloud_provider": "azure",
                    "force_sequential": "false"
                },
                "expected_duration": 6,
                "priority": 5
            },
            
            "Environment Promotion": {
                "description": "Environment promotion with validation",
                "params": {
                    "source_environment": "dev",
                    "target_environment": "staging",
                    "components": "network",
                    "cloud_provider": "azure",
                    "auto_approve": "true",
                    "dry_run": "true"
                },
                "expected_duration": 5,
                "priority": 6
            }
        }
        
        self.test_results = {}
        self.errors_found = []
        self.fixes_applied = []
    
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
    
    def trigger_pipeline(self, pipeline_name: str, config: Dict) -> Dict:
        """Trigger a pipeline and return result info."""
        print(f"\n🚀 Testing Pipeline: {pipeline_name}")
        print(f"📝 Description: {config['description']}")
        print(f"⏱️  Expected Duration: ~{config['expected_duration']} minutes")
        print(f"📋 Parameters: {config['params']}")
        
        # Build command
        cmd = ["workflow", "run", pipeline_name]
        for key, value in config['params'].items():
            if value:  # Only add non-empty values
                cmd.extend(["--field", f"{key}={value}"])
        
        # Execute command
        start_time = datetime.now()
        success, output = self.run_gh_command(cmd, timeout=30)
        
        result = {
            "pipeline": pipeline_name,
            "trigger_success": success,
            "trigger_output": output.strip(),
            "start_time": start_time,
            "config": config,
            "run_id": None,
            "execution_result": None
        }
        
        if success:
            print(f"   ✅ Successfully triggered {pipeline_name}")
        else:
            print(f"   ❌ Failed to trigger {pipeline_name}")
            print(f"      Error: {output.strip()}")
            self.errors_found.append({
                "type": "trigger_failure",
                "pipeline": pipeline_name,
                "error": output.strip()
            })
        
        return result
    
    def find_run_id(self, pipeline_name: str, start_time: datetime, timeout_minutes: int = 3) -> Optional[str]:
        """Find the run ID for a recently triggered pipeline."""
        print(f"   🔍 Finding run ID for {pipeline_name}...")
        
        timeout = start_time + timedelta(minutes=timeout_minutes)
        
        while datetime.now() < timeout:
            success, output = self.run_gh_command([
                "run", "list",
                "--workflow", pipeline_name,
                "--limit", "3",
                "--json", "databaseId,status,createdAt"
            ])
            
            if success:
                try:
                    runs = json.loads(output)
                    for run in runs:
                        run_time = datetime.fromisoformat(run['createdAt'].replace('Z', '+00:00'))
                        # Check if this run started after our trigger (with 1 minute buffer)
                        if run_time >= (start_time - timedelta(minutes=1)).replace(tzinfo=run_time.tzinfo):
                            print(f"   🎯 Found run ID: {run['databaseId']}")
                            return run['databaseId']
                except json.JSONDecodeError:
                    pass
            
            time.sleep(10)
        
        print(f"   ⚠️  Could not find run ID for {pipeline_name}")
        return None
    
    def monitor_pipeline_execution(self, pipeline_name: str, run_id: str, timeout_minutes: int = 15) -> Dict:
        """Monitor pipeline execution and return detailed results."""
        print(f"   📊 Monitoring execution of {pipeline_name} (ID: {run_id})")
        
        start_time = datetime.now()
        timeout = start_time + timedelta(minutes=timeout_minutes)
        last_status = None
        
        while datetime.now() < timeout:
            # Get run details
            success, output = self.run_gh_command([
                "run", "view", run_id,
                "--json", "status,conclusion,createdAt,updatedAt,jobs"
            ])
            
            if success:
                try:
                    run_info = json.loads(output)
                    current_status = run_info.get('status')
                    conclusion = run_info.get('conclusion')
                    jobs = run_info.get('jobs', [])
                    
                    # Show status updates
                    if current_status != last_status:
                        print(f"   📈 Status: {current_status}")
                        last_status = current_status
                    
                    # Check if completed
                    if current_status == 'completed':
                        duration = (datetime.now() - start_time).total_seconds() / 60
                        
                        result = {
                            "status": current_status,
                            "conclusion": conclusion,
                            "duration_minutes": round(duration, 1),
                            "jobs": jobs,
                            "run_id": run_id
                        }
                        
                        if conclusion == 'success':
                            print(f"   ✅ Completed successfully in {duration:.1f} minutes")
                        else:
                            print(f"   ❌ Completed with {conclusion} in {duration:.1f} minutes")
                            # Analyze job failures
                            self.analyze_job_failures(pipeline_name, run_id, jobs)
                        
                        return result
                        
                except json.JSONDecodeError:
                    pass
            
            time.sleep(30)  # Check every 30 seconds
        
        # Timeout
        duration = (datetime.now() - start_time).total_seconds() / 60
        print(f"   ⏰ Monitoring timeout after {duration:.1f} minutes")
        
        return {
            "status": "timeout",
            "conclusion": "timeout",
            "duration_minutes": round(duration, 1),
            "run_id": run_id
        }
    
    def analyze_job_failures(self, pipeline_name: str, run_id: str, jobs: List[Dict]) -> None:
        """Analyze job failures and extract error information."""
        print(f"   🔍 Analyzing failures in {pipeline_name}...")
        
        failed_jobs = [job for job in jobs if job.get('conclusion') == 'failure']
        
        for job in failed_jobs:
            job_name = job.get('name', 'Unknown')
            print(f"      ❌ Failed Job: {job_name}")
            
            # Get detailed logs for failed job
            success, logs = self.run_gh_command([
                "run", "view", run_id, "--log-failed"
            ])
            
            if success:
                # Extract key error patterns
                error_patterns = [
                    "Error:",
                    "FAILED:",
                    "FileNotFoundError:",
                    "Permission denied",
                    "Authentication failed",
                    "Terraform plan failed",
                    "No such file or directory"
                ]
                
                relevant_errors = []
                for line in logs.split('\n'):
                    for pattern in error_patterns:
                        if pattern in line:
                            relevant_errors.append(line.strip())
                            break
                
                if relevant_errors:
                    self.errors_found.append({
                        "type": "execution_failure",
                        "pipeline": pipeline_name,
                        "job": job_name,
                        "run_id": run_id,
                        "errors": relevant_errors[:5]  # Top 5 errors
                    })
    
    def run_comprehensive_test(self) -> None:
        """Run comprehensive test of all pipelines."""
        print("🧪 COMPREHENSIVE PIPELINE TEST")
        print("=" * 60)
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Testing {len(self.test_pipelines)} pipelines with plan actions")
        print()
        
        # Sort pipelines by priority
        sorted_pipelines = sorted(
            self.test_pipelines.items(),
            key=lambda x: x[1]['priority']
        )
        
        # Phase 1: Trigger all pipelines
        print("🚀 Phase 1: Triggering All Pipelines")
        print("-" * 40)
        
        for pipeline_name, config in sorted_pipelines:
            result = self.trigger_pipeline(pipeline_name, config)
            self.test_results[pipeline_name] = result
            
            # Brief pause between triggers
            time.sleep(5)
        
        # Phase 2: Find run IDs
        print(f"\n🔍 Phase 2: Finding Run IDs")
        print("-" * 40)
        
        for pipeline_name in self.test_results:
            if self.test_results[pipeline_name]['trigger_success']:
                run_id = self.find_run_id(
                    pipeline_name,
                    self.test_results[pipeline_name]['start_time']
                )
                self.test_results[pipeline_name]['run_id'] = run_id
        
        # Phase 3: Monitor executions
        print(f"\n📊 Phase 3: Monitoring Executions")
        print("-" * 40)
        
        for pipeline_name in self.test_results:
            result = self.test_results[pipeline_name]
            if result['run_id']:
                execution_result = self.monitor_pipeline_execution(
                    pipeline_name,
                    result['run_id'],
                    result['config']['expected_duration'] + 5
                )
                result['execution_result'] = execution_result
        
        # Generate comprehensive report
        self.generate_comprehensive_report()
    
    def generate_comprehensive_report(self) -> None:
        """Generate comprehensive test report with error analysis."""
        print("\n" + "=" * 70)
        print("📊 COMPREHENSIVE PIPELINE TEST REPORT")
        print("=" * 70)
        
        # Summary statistics
        total_pipelines = len(self.test_results)
        triggered_successfully = sum(1 for r in self.test_results.values() if r['trigger_success'])
        executed_successfully = sum(1 for r in self.test_results.values() 
                                  if r.get('execution_result', {}).get('conclusion') == 'success')
        
        print(f"📈 Summary Statistics:")
        print(f"   Total Pipelines: {total_pipelines}")
        print(f"   Successfully Triggered: {triggered_successfully}/{total_pipelines}")
        print(f"   Successfully Executed: {executed_successfully}/{total_pipelines}")
        print(f"   Trigger Success Rate: {(triggered_successfully/total_pipelines)*100:.1f}%")
        print(f"   Overall Success Rate: {(executed_successfully/total_pipelines)*100:.1f}%")
        
        # Detailed results by pipeline
        print(f"\n📋 Detailed Results by Pipeline:")
        print("-" * 50)
        
        for pipeline_name, result in self.test_results.items():
            print(f"\n🔧 {pipeline_name}:")
            print(f"   📝 {result['config']['description']}")
            
            # Trigger status
            if result['trigger_success']:
                print(f"   ✅ Trigger: SUCCESS")
            else:
                print(f"   ❌ Trigger: FAILED")
                continue
            
            # Execution status
            exec_result = result.get('execution_result')
            if exec_result:
                status = exec_result.get('status')
                conclusion = exec_result.get('conclusion')
                duration = exec_result.get('duration_minutes', 0)
                
                if conclusion == 'success':
                    print(f"   ✅ Execution: SUCCESS ({duration} min)")
                elif conclusion == 'timeout':
                    print(f"   ⏰ Execution: TIMEOUT ({duration} min)")
                else:
                    print(f"   ❌ Execution: {conclusion.upper()} ({duration} min)")
                
                print(f"   🔗 Run ID: {exec_result.get('run_id')}")
            else:
                print(f"   ⚠️  Execution: Not monitored")
        
        # Error analysis
        if self.errors_found:
            print(f"\n🐛 Error Analysis ({len(self.errors_found)} errors found):")
            print("-" * 50)
            
            for i, error in enumerate(self.errors_found, 1):
                print(f"\n{i}. {error['type'].replace('_', ' ').title()}")
                print(f"   Pipeline: {error['pipeline']}")
                if 'job' in error:
                    print(f"   Job: {error['job']}")
                if 'errors' in error:
                    print(f"   Errors:")
                    for err in error['errors']:
                        print(f"     - {err}")
                elif 'error' in error:
                    print(f"   Error: {error['error']}")
        
        # Recommendations
        print(f"\n🎯 Recommendations:")
        if executed_successfully == total_pipelines:
            print("   🎉 All pipelines are working perfectly!")
            print("   ✅ Infrastructure orchestration system is production-ready")
            print("   🚀 Ready for actual infrastructure deployment")
        elif triggered_successfully == total_pipelines:
            print("   ✅ All pipelines can be triggered successfully")
            print("   🔧 Some execution issues need to be addressed")
            print("   📚 Review error analysis above for specific fixes needed")
        else:
            print("   ⚠️  Some pipelines failed to trigger")
            print("   🔧 Review trigger failures and fix configuration issues")
        
        print(f"\n🕒 Test completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 70)

def main():
    """Main function."""
    tester = ComprehensivePipelineTest()
    tester.run_comprehensive_test()

if __name__ == "__main__":
    main()
