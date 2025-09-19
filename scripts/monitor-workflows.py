#!/usr/bin/env python3
"""
Workflow Monitoring Script for MSDP DevOps Infrastructure

This script monitors the status of GitHub Actions workflows and provides
real-time feedback on deployment progress and issues.
"""

import subprocess
import json
import time
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional

class WorkflowMonitor:
    def __init__(self):
        self.target_workflows = [
            "Infrastructure Orchestrator",
            "Environment Promotion", 
            "Network Infrastructure",
            "Kubernetes Clusters",
            "Kubernetes Add-ons (Terraform)",
            "Platform Engineering Stack (Backstage + Crossplane)"
        ]
    
    def run_gh_command(self, cmd: List[str]) -> Optional[str]:
        """Run a GitHub CLI command and return the output."""
        try:
            result = subprocess.run(
                ['gh'] + cmd, 
                capture_output=True, 
                text=True, 
                check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"❌ Error running gh command: {e}")
            return None
    
    def check_workflow_registration(self) -> Dict[str, bool]:
        """Check which workflows are registered with GitHub."""
        print("🔍 Checking workflow registration status...")
        
        output = self.run_gh_command(['workflow', 'list', '--limit', '50'])
        if not output:
            return {}
        
        registered_workflows = {}
        available_workflows = [line.split('\t')[0] for line in output.split('\n') if line]
        
        for workflow in self.target_workflows:
            is_registered = any(workflow in available for available in available_workflows)
            registered_workflows[workflow] = is_registered
            
            status = "✅ Registered" if is_registered else "❌ Not registered"
            print(f"  {workflow}: {status}")
        
        return registered_workflows
    
    def get_recent_runs(self, workflow_name: str, limit: int = 5) -> List[Dict]:
        """Get recent runs for a specific workflow."""
        output = self.run_gh_command([
            'run', 'list', 
            '--workflow', workflow_name,
            '--limit', str(limit),
            '--json', 'status,conclusion,createdAt,headBranch,event,databaseId'
        ])
        
        if not output:
            return []
        
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return []
    
    def monitor_active_runs(self) -> None:
        """Monitor currently active workflow runs."""
        print("\n🔄 Monitoring active workflow runs...")
        
        output = self.run_gh_command([
            'run', 'list', 
            '--status', 'in_progress',
            '--limit', '20',
            '--json', 'status,name,createdAt,databaseId,headBranch'
        ])
        
        if not output:
            print("  No active runs found")
            return
        
        try:
            runs = json.loads(output)
            if not runs:
                print("  No active runs found")
                return
            
            for run in runs:
                created_time = datetime.fromisoformat(run['createdAt'].replace('Z', '+00:00'))
                duration = datetime.now().astimezone() - created_time
                
                print(f"  🏃 {run['name']}")
                print(f"    Branch: {run['headBranch']}")
                print(f"    Duration: {duration}")
                print(f"    Run ID: {run['databaseId']}")
                print()
        
        except json.JSONDecodeError:
            print("  Error parsing active runs")
    
    def test_workflow_triggers(self) -> None:
        """Test if workflows can be triggered manually."""
        print("\n🧪 Testing workflow triggers...")
        
        # Test Network Infrastructure workflow
        print("  Testing Network Infrastructure workflow...")
        result = self.run_gh_command([
            'workflow', 'run', 'Network Infrastructure',
            '--field', 'cloud_provider=azure',
            '--field', 'action=plan',
            '--field', 'environment=dev'
        ])
        
        if result is not None:
            print("    ✅ Network Infrastructure workflow triggered successfully")
        else:
            print("    ❌ Failed to trigger Network Infrastructure workflow")
    
    def generate_status_report(self) -> None:
        """Generate a comprehensive status report."""
        print("\n📊 Workflow Status Report")
        print("=" * 50)
        print(f"Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Check registration status
        registered = self.check_workflow_registration()
        
        # Count registered vs total
        total_workflows = len(self.target_workflows)
        registered_count = sum(registered.values())
        
        print(f"\n📈 Registration Summary:")
        print(f"  Registered: {registered_count}/{total_workflows}")
        print(f"  Progress: {(registered_count/total_workflows)*100:.1f}%")
        
        if registered_count == total_workflows:
            print("  🎉 All workflows are registered and ready!")
        else:
            missing = [name for name, status in registered.items() if not status]
            print(f"  ⏳ Missing workflows: {', '.join(missing)}")
        
        # Monitor active runs
        self.monitor_active_runs()
        
        # Show recent activity for registered workflows
        print("\n📋 Recent Activity:")
        for workflow_name, is_registered in registered.items():
            if is_registered:
                runs = self.get_recent_runs(workflow_name, 3)
                if runs:
                    print(f"\n  {workflow_name}:")
                    for run in runs:
                        status_icon = {
                            'completed': '✅' if run['conclusion'] == 'success' else '❌',
                            'in_progress': '🔄',
                            'queued': '⏳'
                        }.get(run['status'], '❓')
                        
                        created = datetime.fromisoformat(run['createdAt'].replace('Z', '+00:00'))
                        time_ago = datetime.now().astimezone() - created
                        
                        print(f"    {status_icon} {run['status']} - {time_ago} ago ({run['headBranch']})")
    
    def wait_for_registration(self, timeout_minutes: int = 10) -> bool:
        """Wait for all workflows to be registered."""
        print(f"\n⏰ Waiting for workflow registration (timeout: {timeout_minutes} minutes)...")
        
        start_time = datetime.now()
        timeout = timedelta(minutes=timeout_minutes)
        
        while datetime.now() - start_time < timeout:
            registered = self.check_workflow_registration()
            registered_count = sum(registered.values())
            total_count = len(self.target_workflows)
            
            if registered_count == total_count:
                print("🎉 All workflows are now registered!")
                return True
            
            print(f"⏳ {registered_count}/{total_count} workflows registered. Waiting...")
            time.sleep(30)  # Check every 30 seconds
        
        print("⏰ Timeout reached. Some workflows may still be registering.")
        return False

def main():
    """Main function to run the workflow monitor."""
    monitor = WorkflowMonitor()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "status":
            monitor.generate_status_report()
        elif command == "wait":
            timeout = int(sys.argv[2]) if len(sys.argv) > 2 else 10
            monitor.wait_for_registration(timeout)
        elif command == "test":
            monitor.test_workflow_triggers()
        elif command == "monitor":
            # Continuous monitoring
            try:
                while True:
                    monitor.generate_status_report()
                    print("\n" + "="*50)
                    print("Refreshing in 60 seconds... (Ctrl+C to stop)")
                    time.sleep(60)
            except KeyboardInterrupt:
                print("\n👋 Monitoring stopped.")
        else:
            print(f"Unknown command: {command}")
            print("Usage: python3 monitor-workflows.py [status|wait|test|monitor]")
    else:
        # Default: generate status report
        monitor.generate_status_report()

if __name__ == "__main__":
    main()
