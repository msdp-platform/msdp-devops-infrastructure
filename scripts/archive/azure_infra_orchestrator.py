#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Azure Infrastructure Orchestrator

Smart, generic orchestrator that drives Terraform for Azure network and AKS.
- Reads config/{env}.yaml
- Checks/creates network (plan/apply)
- Generates terraform.tfvars.json files
- Generates backend config (via scripts/generate-backend-config.py if present)
- Runs Terraform for network and AKS

Usage examples:
  python3 scripts/azure_infra_orchestrator.py --env dev --action plan --component network
  python3 scripts/azure_infra_orchestrator.py --env dev --action apply --component aks --auto-provision-network
  python3 scripts/azure_infra_orchestrator.py --env dev --action apply --component aks --cluster aks-msdp-dev-01 --auto-provision-network

Notes:
- Requires Azure CLI (az), Terraform, and jq available in PATH when running locally/CI.
- Assumes Azure login already established (e.g., via azure/login action in CI).
- Backend config is auto-generated if scripts/generate-backend-config.py exists.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import yaml  # PyYAML
except Exception:
    print("PyYAML is required. Install with: pip install PyYAML", file=sys.stderr)
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = REPO_ROOT / "config"
NETWORK_DIR = REPO_ROOT / "infrastructure/environment/azure/network"
AKS_DIR = REPO_ROOT / "infrastructure/environment/azure/aks"
BACKEND_GEN = REPO_ROOT / "scripts/generate-backend-config.py"


def run(cmd, cwd=None, env=None, check=True):
    print(f"$ {' '.join(cmd)}")
    proc = subprocess.run(cmd, cwd=cwd, env=env)
    if check and proc.returncode != 0:
        raise RuntimeError(f"Command failed with exit code {proc.returncode}: {' '.join(cmd)}")
    return proc.returncode


def run_capture(cmd, cwd=None, env=None, check=True):
    proc = subprocess.run(cmd, cwd=cwd, env=env, text=True, capture_output=True)
    if check and proc.returncode != 0:
        print(proc.stdout)
        print(proc.stderr, file=sys.stderr)
        raise RuntimeError(f"Command failed with exit code {proc.returncode}: {' '.join(cmd)}")
    return proc.stdout


def load_config(env_name: str) -> dict:
    cfg_path = CONFIG_DIR / f"{env_name}.yaml"
    if not cfg_path.exists():
        raise FileNotFoundError(f"Configuration file not found: {cfg_path}")
    with open(cfg_path, "r") as f:
        return yaml.safe_load(f)


def ensure_az_login():
    try:
        run(["az", "account", "show"], check=True)
    except Exception:
        raise RuntimeError("Azure CLI is not logged in. Please login first (e.g., via azure/login action or 'az login').")


def azure_rg_exists(name: str) -> bool:
    rc = subprocess.run(["az", "group", "show", "--name", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return rc.returncode == 0


def azure_vnet_exists(rg: str, vnet: str) -> bool:
    rc = subprocess.run(["az", "network", "vnet", "show", "--resource-group", rg, "--name", vnet], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return rc.returncode == 0


def write_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"Wrote {path}")


def generate_network_tfvars(cfg: dict) -> dict:
    net = cfg["azure"]["network"]
    res = {
        "resource_group_name": net["resource_group_name"],
        "location": cfg["azure"]["location"],
        "vnet_name": net["vnet_name"],
        "vnet_cidr": net["vnet_cidr"],
        "subnets": net["subnets"],
        "tags": cfg.get("tags", {}),
    }
    return res


def generate_aks_tfvars(cfg: dict, cluster: dict, tenant_id: str) -> dict:
    net = cfg["azure"]["network"]
    res = {
        "cluster_name": cluster["name"],
        "kubernetes_version": cluster.get("kubernetes_version", "1.29.7"),
        "network_resource_group_name": net["resource_group_name"],
        "vnet_name": net["vnet_name"],
        "subnet_name": cluster["subnet_name"],
        "tenant_id": tenant_id,
        "system_node_count": cluster.get("system_node_count", 2),
        "system_vm_size": cluster.get("system_vm_size", "Standard_D2s_v3"),
        "user_vm_size": cluster.get("user_vm_size", "Standard_D4s_v3"),
        "user_min_count": cluster.get("user_min_count", 1),
        "user_max_count": cluster.get("user_max_count", 5),
        "user_spot_enabled": cluster.get("user_spot_enabled", False),
        "tags": cfg.get("tags", {}),
    }
    return res


def generate_backend_config(env: str, platform: str, component: str, instance: str | None = None) -> Path | None:
    if not BACKEND_GEN.exists():
        print("Warning: Backend generator script not found. Using local backend (not recommended).", file=sys.stderr)
        return None
    args = [sys.executable, str(BACKEND_GEN), env, platform, component]
    if instance:
        args.append(instance)
    out = run_capture(args, check=True)
    try:
        data = json.loads(out)
    except Exception:
        # Some versions may print the JSON but also logs; try last line
        last = out.strip().splitlines()[-1]
        data = json.loads(last)
    out_path = Path.cwd() / "backend-config.json"
    write_json(out_path, data)
    return out_path


def terraform_init(workdir: Path, backend_cfg: Path | None):
    cmd = ["terraform", "init", "-input=false"]
    if backend_cfg and backend_cfg.exists():
        cmd.extend(["-backend-config", str(backend_cfg)])
    run(cmd, cwd=workdir)


def terraform_plan(workdir: Path, plan_out: str = "tfplan"):
    run(["terraform", "plan", "-input=false", f"-out={plan_out}"], cwd=workdir)


def terraform_apply(workdir: Path, plan_file: str | None = None):
    if plan_file and (workdir / plan_file).exists():
        run(["terraform", "apply", "-input=false", "-auto-approve", plan_file], cwd=workdir)
    else:
        run(["terraform", "apply", "-input=false", "-auto-approve"], cwd=workdir)


def terraform_destroy(workdir: Path):
    run(["terraform", "destroy", "-input=false", "-auto-approve"], cwd=workdir)


def handle_network(cfg: dict, env: str, action: str):
    print("== Network ==")
    tfvars = generate_network_tfvars(cfg)
    write_json(NETWORK_DIR / "terraform.tfvars.json", tfvars)

    backend_cfg = generate_backend_config(env, "azure", "network")
    terraform_init(NETWORK_DIR, backend_cfg)

    if action == "plan":
        terraform_plan(NETWORK_DIR)
    elif action == "apply":
        terraform_plan(NETWORK_DIR)
        terraform_apply(NETWORK_DIR, "tfplan")
    elif action == "destroy":
        terraform_destroy(NETWORK_DIR)
    else:
        raise ValueError(f"Unknown action: {action}")


def handle_aks(cfg: dict, env: str, action: str, cluster_name: str | None, auto_provision_network: bool):
    print("== AKS ==")
    # Ensure Azure login
    ensure_az_login()

    # Check network presence
    rg = cfg["azure"]["network"]["resource_group_name"]
    vnet = cfg["azure"]["network"]["vnet_name"]

    net_exists = azure_rg_exists(rg) and azure_vnet_exists(rg, vnet)
    print(f"Network exists: {net_exists} (RG={rg}, VNet={vnet})")

    if not net_exists:
        if auto_provision_network:
            if action == "plan":
                print("Network missing. Running network plan (no changes) before AKS plan...")
                handle_network(cfg, env, "plan")
                print("Cannot complete AKS plan without existing network data sources. Apply the network first.")
                return
            elif action in ("apply", "destroy"):
                print("Network missing. Applying network first...")
                handle_network(cfg, env, "apply")
            else:
                raise ValueError(f"Unsupported action: {action}")
        else:
            raise RuntimeError("Network is required for AKS. Re-run with --auto-provision-network or deploy network first.")

    # Select clusters
    clusters = cfg.get("azure", {}).get("aks", {}).get("clusters", [])
    if cluster_name:
        clusters = [c for c in clusters if c.get("name") == cluster_name]
    if not clusters:
        print("No AKS clusters found for the given filter.")
        return

    tenant_id = os.environ.get("ARM_TENANT_ID", "")

    for c in clusters:
        name = c["name"]
        print(f"-- Cluster: {name}")
        # tfvars
        tfvars = generate_aks_tfvars(cfg, c, tenant_id)
        write_json(AKS_DIR / "terraform.tfvars.json", tfvars)

        # backend
        backend_cfg = generate_backend_config(env, "azure", "aks", instance=name)
        terraform_init(AKS_DIR, backend_cfg)

        if action == "plan":
            terraform_plan(AKS_DIR)
        elif action == "apply":
            terraform_plan(AKS_DIR)
            terraform_apply(AKS_DIR, "tfplan")
        elif action == "destroy":
            terraform_destroy(AKS_DIR)
        else:
            raise ValueError(f"Unknown action: {action}")


def main():
    p = argparse.ArgumentParser(description="Azure infra orchestrator (network + AKS)")
    p.add_argument("--env", required=True, help="Environment name (e.g., dev)")
    p.add_argument("--action", required=True, choices=["plan", "apply", "destroy"], help="Action to perform")
    p.add_argument("--component", required=True, choices=["network", "aks", "all"], help="Component to operate on")
    p.add_argument("--cluster", help="Specific cluster name for AKS (optional)")
    p.add_argument("--auto-provision-network", action="store_true", help="If missing, automatically plan/apply network as needed")
    args = p.parse_args()

    cfg = load_config(args.env)

    if args.component in ("network", "all"):
        handle_network(cfg, args.env, args.action)

    if args.component in ("aks", "all"):
        handle_aks(cfg, args.env, args.action, args.cluster, args.auto_provision_network)

    print("\n✅ Orchestration completed")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
