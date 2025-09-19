#!/usr/bin/env python3
"""
Implementation Validation Script for MSDP DevOps Infrastructure

This script validates that all components of the Phase 1 and Phase 2 
implementation are correctly deployed and functional.
"""

import os
import yaml
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class ImplementationValidator:
    def __init__(self, repo_root: str = "."):
        self.repo_root = Path(repo_root)
        self.results = {
            "phase1": {"passed": 0, "failed": 0, "tests": []},
            "phase2": {"passed": 0, "failed": 0, "tests": []},
            "overall": {"passed": 0, "failed": 0}
        }
    
    def log_test(self, phase: str, test_name: str, passed: bool, details: str = ""):
        """Log a test result."""
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {test_name}")
        if details:
            print(f"    {details}")
        
        self.results[phase]["tests"].append({
            "name": test_name,
            "passed": passed,
            "details": details
        })
        
        if passed:
            self.results[phase]["passed"] += 1
            self.results["overall"]["passed"] += 1
        else:
            self.results[phase]["failed"] += 1
            self.results["overall"]["failed"] += 1
    
    def validate_file_exists(self, file_path: str, description: str = "") -> bool:
        """Validate that a file exists."""
        full_path = self.repo_root / file_path
        exists = full_path.exists()
        desc = description or f"File {file_path}"
        return exists
    
    def validate_yaml_syntax(self, file_path: str) -> Tuple[bool, str]:
        """Validate YAML file syntax."""
        try:
            full_path = self.repo_root / file_path
            with open(full_path, 'r') as f:
                yaml.safe_load(f)
            return True, "Valid YAML syntax"
        except yaml.YAMLError as e:
            return False, f"YAML syntax error: {e}"
        except FileNotFoundError:
            return False, "File not found"
    
    def validate_workflow_structure(self, file_path: str) -> Tuple[bool, str]:
        """Validate GitHub Actions workflow structure."""
        try:
            full_path = self.repo_root / file_path
            with open(full_path, 'r') as f:
                workflow = yaml.safe_load(f)
            
            # Check required fields
            required_fields = ['name', 'on', 'jobs']
            missing_fields = [field for field in required_fields if field not in workflow]
            
            if missing_fields:
                return False, f"Missing required fields: {missing_fields}"
            
            # Check for workflow_dispatch trigger
            on_section = workflow.get('on', {})
            has_workflow_dispatch = 'workflow_dispatch' in on_section
            
            # Check for workflow_call trigger (Phase 2 requirement)
            has_workflow_call = 'workflow_call' in on_section
            
            details = []
            if has_workflow_dispatch:
                details.append("Has workflow_dispatch")
            if has_workflow_call:
                details.append("Has workflow_call")
            
            return True, "; ".join(details) if details else "Basic structure valid"
            
        except Exception as e:
            return False, f"Validation error: {e}"
    
    def validate_shared_actions(self) -> None:
        """Validate shared composite actions."""
        print("\n🔧 Validating Shared Composite Actions...")
        
        actions = [
            "generate-cluster-matrix",
            "generate-terraform-vars"
        ]
        
        for action in actions:
            action_path = f".github/actions/{action}/action.yml"
            
            # Check if action exists
            exists = self.validate_file_exists(action_path)
            self.log_test("phase1", f"Shared action {action} exists", exists)
            
            if exists:
                # Validate YAML syntax
                valid, details = self.validate_yaml_syntax(action_path)
                self.log_test("phase1", f"Shared action {action} YAML valid", valid, details)
                
                # Check action structure
                try:
                    full_path = self.repo_root / action_path
                    with open(full_path, 'r') as f:
                        action_def = yaml.safe_load(f)
                    
                    has_name = 'name' in action_def
                    has_description = 'description' in action_def
                    has_inputs = 'inputs' in action_def
                    has_runs = 'runs' in action_def
                    
                    structure_valid = all([has_name, has_description, has_runs])
                    details = f"Name: {has_name}, Description: {has_description}, Inputs: {has_inputs}, Runs: {has_runs}"
                    
                    self.log_test("phase1", f"Shared action {action} structure", structure_valid, details)
                    
                except Exception as e:
                    self.log_test("phase1", f"Shared action {action} structure", False, str(e))
    
    def validate_phase1_workflows(self) -> None:
        """Validate Phase 1 refactored workflows."""
        print("\n📋 Validating Phase 1 Workflows...")
        
        workflows = [
            "network-infrastructure.yml",
            "kubernetes-clusters.yml"
        ]
        
        for workflow in workflows:
            workflow_path = f".github/workflows/{workflow}"
            
            # Check if workflow exists
            exists = self.validate_file_exists(workflow_path)
            self.log_test("phase1", f"Workflow {workflow} exists", exists)
            
            if exists:
                # Validate YAML syntax
                valid, details = self.validate_yaml_syntax(workflow_path)
                self.log_test("phase1", f"Workflow {workflow} YAML valid", valid, details)
                
                # Validate workflow structure
                valid, details = self.validate_workflow_structure(workflow_path)
                self.log_test("phase1", f"Workflow {workflow} structure", valid, details)
    
    def validate_phase2_workflows(self) -> None:
        """Validate Phase 2 orchestration workflows."""
        print("\n🚀 Validating Phase 2 Orchestration Workflows...")
        
        workflows = [
            "infrastructure-orchestrator.yml",
            "environment-promotion.yml"
        ]
        
        for workflow in workflows:
            workflow_path = f".github/workflows/{workflow}"
            
            # Check if workflow exists
            exists = self.validate_file_exists(workflow_path)
            self.log_test("phase2", f"Workflow {workflow} exists", exists)
            
            if exists:
                # Validate YAML syntax
                valid, details = self.validate_yaml_syntax(workflow_path)
                self.log_test("phase2", f"Workflow {workflow} YAML valid", valid, details)
                
                # Validate workflow structure
                valid, details = self.validate_workflow_structure(workflow_path)
                self.log_test("phase2", f"Workflow {workflow} structure", valid, details)
                
                # Check for orchestration-specific features
                try:
                    full_path = self.repo_root / workflow_path
                    with open(full_path, 'r') as f:
                        workflow_content = f.read()
                    
                    # Check for orchestration features
                    has_dependency_logic = "dependencies" in workflow_content
                    has_matrix_generation = "matrix" in workflow_content
                    has_parallel_execution = "strategy" in workflow_content
                    
                    features = []
                    if has_dependency_logic:
                        features.append("dependency logic")
                    if has_matrix_generation:
                        features.append("matrix generation")
                    if has_parallel_execution:
                        features.append("parallel execution")
                    
                    feature_details = f"Features: {', '.join(features)}" if features else "No advanced features detected"
                    self.log_test("phase2", f"Workflow {workflow} orchestration features", len(features) > 0, feature_details)
                    
                except Exception as e:
                    self.log_test("phase2", f"Workflow {workflow} features", False, str(e))
    
    def validate_orchestration_state_action(self) -> None:
        """Validate the orchestration state manager action."""
        print("\n🎯 Validating Orchestration State Manager...")
        
        action_path = ".github/actions/orchestration-state/action.yml"
        
        # Check if action exists
        exists = self.validate_file_exists(action_path)
        self.log_test("phase2", "Orchestration state action exists", exists)
        
        if exists:
            # Validate YAML syntax
            valid, details = self.validate_yaml_syntax(action_path)
            self.log_test("phase2", "Orchestration state action YAML valid", valid, details)
            
            # Check for state management logic
            try:
                full_path = self.repo_root / action_path
                with open(full_path, 'r') as f:
                    content = f.read()
                
                # Check for key state management features
                has_state_tracking = "state" in content.lower()
                has_dependency_check = "dependency" in content.lower()
                has_component_status = "component" in content.lower()
                
                features = []
                if has_state_tracking:
                    features.append("state tracking")
                if has_dependency_check:
                    features.append("dependency checking")
                if has_component_status:
                    features.append("component status")
                
                feature_details = f"Features: {', '.join(features)}"
                self.log_test("phase2", "Orchestration state features", len(features) >= 2, feature_details)
                
            except Exception as e:
                self.log_test("phase2", "Orchestration state features", False, str(e))
    
    def validate_documentation(self) -> None:
        """Validate documentation completeness."""
        print("\n📚 Validating Documentation...")
        
        docs = [
            ("docs/team-guides/WORKFLOW_USAGE_GUIDE.md", "Team usage guide"),
            ("docs/implementation-notes/FINAL_IMPLEMENTATION_SUMMARY.md", "Implementation summary"),
            ("docs/implementation-notes/COMPLETION_AND_HANDOVER.md", "Completion guide"),
            ("scripts/monitor-workflows.py", "Monitoring script")
        ]
        
        for doc_path, description in docs:
            exists = self.validate_file_exists(doc_path)
            self.log_test("phase2", f"{description} exists", exists)
    
    def validate_terraform_standardization(self) -> None:
        """Validate Terraform version standardization."""
        print("\n🔧 Validating Terraform Standardization...")
        
        # Check workflow files for Terraform version references
        workflow_files = [
            ".github/workflows/network-infrastructure.yml",
            ".github/workflows/kubernetes-clusters.yml",
            ".github/workflows/k8s-addons-terraform.yml",
            ".github/workflows/platform-engineering.yml"
        ]
        
        target_version = "1.9.8"
        standardized_count = 0
        
        for workflow_file in workflow_files:
            try:
                full_path = self.repo_root / workflow_file
                if full_path.exists():
                    with open(full_path, 'r') as f:
                        content = f.read()
                    
                    # Check for Terraform version references
                    if target_version in content:
                        standardized_count += 1
                        self.log_test("phase1", f"Terraform version in {workflow_file}", True, f"Uses {target_version}")
                    else:
                        self.log_test("phase1", f"Terraform version in {workflow_file}", False, f"Does not use {target_version}")
                        
            except Exception as e:
                self.log_test("phase1", f"Terraform version in {workflow_file}", False, str(e))
        
        # Overall standardization check
        total_workflows = len([f for f in workflow_files if self.validate_file_exists(f)])
        standardization_rate = (standardized_count / total_workflows) * 100 if total_workflows > 0 else 0
        
        self.log_test("phase1", "Terraform version standardization", standardization_rate >= 75, 
                     f"{standardization_rate:.1f}% of workflows use {target_version}")
    
    def test_orchestration_logic(self) -> None:
        """Test orchestration logic locally."""
        print("\n🧪 Testing Orchestration Logic...")
        
        test_script = '''
import yaml
import json

# Test dependency resolution
dependencies = {
    "network": [],
    "clusters": ["network"],
    "addons": ["clusters"],
    "platform": ["addons"]
}

def resolve_dependencies(components):
    resolved = []
    to_process = set(components)
    
    while to_process:
        ready = []
        for comp in to_process:
            deps = dependencies.get(comp, [])
            if all(dep in resolved for dep in deps):
                ready.append(comp)
        
        if not ready:
            raise ValueError(f"Circular dependency: {to_process}")
        
        for comp in ready:
            resolved.append(comp)
            to_process.remove(comp)
    
    return resolved

# Test cases
test_cases = [
    (["network"], ["network"]),
    (["network", "clusters"], ["network", "clusters"]),
    (["network", "clusters", "addons"], ["network", "clusters", "addons"]),
    (["clusters", "network"], ["network", "clusters"]),
]

all_passed = True
for inputs, expected in test_cases:
    try:
        result = resolve_dependencies(inputs)
        # Check if dependencies are satisfied
        valid_order = True
        for i, comp in enumerate(result):
            comp_deps = dependencies.get(comp, [])
            for dep in comp_deps:
                if dep in result and result.index(dep) > i:
                    valid_order = False
                    break
        
        if not valid_order:
            all_passed = False
            break
            
    except Exception:
        all_passed = False
        break

print("PASS" if all_passed else "FAIL")
'''
        
        try:
            result = subprocess.run(['python3', '-c', test_script], 
                                  capture_output=True, text=True, timeout=10)
            
            passed = result.returncode == 0 and "PASS" in result.stdout
            details = "Dependency resolution algorithm working correctly" if passed else "Logic test failed"
            
            self.log_test("phase2", "Orchestration logic test", passed, details)
            
        except Exception as e:
            self.log_test("phase2", "Orchestration logic test", False, str(e))
    
    def generate_report(self) -> None:
        """Generate final validation report."""
        print("\n" + "="*60)
        print("🎯 IMPLEMENTATION VALIDATION REPORT")
        print("="*60)
        
        # Phase summaries
        for phase in ["phase1", "phase2"]:
            phase_name = "Phase 1 (Refactoring)" if phase == "phase1" else "Phase 2 (Orchestration)"
            passed = self.results[phase]["passed"]
            failed = self.results[phase]["failed"]
            total = passed + failed
            
            if total > 0:
                success_rate = (passed / total) * 100
                status = "✅ PASS" if success_rate >= 80 else "⚠️  PARTIAL" if success_rate >= 60 else "❌ FAIL"
                
                print(f"\n{phase_name}: {status}")
                print(f"  Tests Passed: {passed}/{total} ({success_rate:.1f}%)")
                
                if failed > 0:
                    print(f"  Failed Tests:")
                    for test in self.results[phase]["tests"]:
                        if not test["passed"]:
                            print(f"    - {test['name']}: {test['details']}")
        
        # Overall summary
        total_passed = self.results["overall"]["passed"]
        total_failed = self.results["overall"]["failed"]
        total_tests = total_passed + total_failed
        
        if total_tests > 0:
            overall_success = (total_passed / total_tests) * 100
            overall_status = "✅ SUCCESS" if overall_success >= 80 else "⚠️  PARTIAL" if overall_success >= 60 else "❌ FAILED"
            
            print(f"\n🎯 OVERALL RESULT: {overall_status}")
            print(f"Total Tests: {total_passed}/{total_tests} passed ({overall_success:.1f}%)")
            
            if overall_success >= 90:
                print("\n🎉 Implementation is ready for production!")
            elif overall_success >= 80:
                print("\n✅ Implementation is substantially complete with minor issues.")
            elif overall_success >= 60:
                print("\n⚠️  Implementation has significant issues that should be addressed.")
            else:
                print("\n❌ Implementation has major issues requiring attention.")
        
        print("\n" + "="*60)
    
    def run_full_validation(self) -> None:
        """Run complete implementation validation."""
        print("🔍 MSDP DevOps Infrastructure Implementation Validation")
        print("="*60)
        
        # Run all validation tests
        self.validate_shared_actions()
        self.validate_phase1_workflows()
        self.validate_terraform_standardization()
        self.validate_phase2_workflows()
        self.validate_orchestration_state_action()
        self.test_orchestration_logic()
        self.validate_documentation()
        
        # Generate final report
        self.generate_report()

def main():
    """Main function."""
    validator = ImplementationValidator()
    validator.run_full_validation()

if __name__ == "__main__":
    main()
