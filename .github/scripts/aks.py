#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def info(msg):
    print(f"[INFO] {msg}")

def warn(msg):
    print(f"[WARN] {msg}")

def err(msg):
    print(f"[ERROR] {msg}", file=sys.stderr)


def ensure_pyyaml():
    try:
        import yaml  # noqa: F401
    except ImportError:
        info("Installing PyYAML...")
        subprocess.run([sys.executable, "-m", "pip", "install", "--user", "PyYAML"], check=True)


def load_yaml(path):
    ensure_pyyaml()
    import yaml
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}


def dump_yaml(path, data):
    ensure_pyyaml()
    import yaml
    with open(path, "w") as f:
        yaml.safe_dump(data, f, sort_keys=False)


def norm(s: str) -> str:
    s = s.lower()
    s = re.sub(r"[^a-z0-9-]+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def next_seq(cfg_env_path: str, env_id: str, team: str) -> str:
    cfg = load_yaml(cfg_env_path)
    prefix = f"{env_id}-{team}"
    max_n = 0
    # aksClusters list
    clusters = (((cfg.get("azure") or {}).get("aksClusters")) or [])
    for item in clusters or []:
        name = (item or {}).get("name") or ""
        m = re.match(rf"^{re.escape(prefix)}-(\d+)$", name)
        if m:
            n = int(m.group(1))
            if n > max_n:
                max_n = n
    # single aksName
    single = ((cfg.get("azure") or {}).get("aksName")) or ""
    m = re.match(rf"^{re.escape(prefix)}-(\d+)$", single)
    if m:
        n = int(m.group(1))
        if n > max_n:
            max_n = n
    return f"{max_n+1:02d}"


def gen_matrix(args):
    cfg_env = args.cfg_env
    override_name = args.name
    team = args.team
    env_id = args.env_id

    if team and env_id:
        seq = next_seq(cfg_env, env_id, team)
        cname = f"{env_id}-{team}-{seq}"
        sname = f"{env_id}-{team}-{seq}"
        print(json.dumps([{ "name": cname, "subnetName": sname }]))
        return

    cfg = load_yaml(cfg_env)
    azure = cfg.get("azure") or {}
    clusters = azure.get("aksClusters")
    matrix = []
    if isinstance(clusters, dict):
        for k, v in clusters.items():
            name = k
            subnet = (v or {}).get("subnetName") or f"snet-{name}"
            matrix.append({"name": name, "subnetName": subnet})
    elif isinstance(clusters, list) and clusters:
        for item in clusters:
            name = (item or {}).get("name")
            if not name:
                continue
            subnet = (item or {}).get("subnetName") or f"snet-{name}"
            matrix.append({"name": name, "subnetName": subnet})

    if not matrix:
        name = azure.get("aksName") or ""
        subnet = azure.get("subnetName") or ""
        if not name or not subnet:
            err("No azure.aksClusters and missing azure.aksName/subnetName in env config")
            sys.exit(1)
        matrix = [{"name": name, "subnetName": subnet}]

    if override_name:
        matrix = [{"name": override_name, "subnetName": override_name}]

    print(json.dumps(matrix))


def build_tfvars(args):
    cfg_global = args.cfg_global
    cfg_env = args.cfg_env
    name = args.name
    env_id = args.env_id
    team = args.team
    region = args.region
    size = args.size or "small"
    manage_network = str(args.manage_network).lower() in ("1", "true", "yes")
    create_rg = str(args.create_rg).lower() in ("1", "true", "yes")
    out = args.out
    outputs_file = args.outputs_file

    g = load_yaml(cfg_global)
    e = load_yaml(cfg_env)

    location = region or ((g.get("azure") or {}).get("location") or "")
    location = norm(location)

    if team and env_id:
        seq = next_seq(cfg_env, env_id, team)
        cname = f"{env_id}-{team}-{seq}"
        rg = f"{env_id}-{team}"
        vnet = f"{env_id}-{team}"
        subnet = f"{env_id}-{team}-{seq}"
    else:
        if not name:
            err("--name or --team/--env-id is required")
            sys.exit(2)
        azure = e.get("azure") or {}
        cname = norm(name)
        rg = norm(azure.get("resourceGroup") or "")
        vnet = norm(azure.get("vnetName") or "")
        subnet = norm(azure.get("subnetName") or "")

    code = {"small": "s", "medium": "m", "large": "l"}.get(size, "s")
    if not vnet:
        vnet = f"vnet-{cname}-{code}"
    if not subnet:
        subnet = f"snet-{cname}-{code}"

    info(f"Resolved RG={rg} VNET={vnet} SUBNET={subnet} AKS={cname} LOC={location}")

    sys_count = 1
    sys_vm = "Standard_B2s"
    user_vm = "Standard_B2s"
    user_min = 0
    user_max = 2 if size == "small" else (4 if size == "medium" else 8)
    user_spot = False

    tfvars = {
        "resource_group": rg,
        "vnet_name": vnet,
        "location": location,
        "aks_name": cname,
        "subnet_name": subnet,
        "system_node_count": sys_count,
        "system_vm_size": sys_vm,
        "user_vm_size": user_vm,
        "user_min_count": user_min,
        "user_max_count": user_max,
        "user_spot": user_spot,
        "manage_network": manage_network,
        "create_resource_group": create_rg,
    }
    with open(out, "w") as f:
        json.dump(tfvars, f, indent=2)
    info(f"Wrote {out}")

    if outputs_file:
        with open(outputs_file, "a") as f:
            f.write(f"rg={rg}\n")
            f.write(f"vnet={vnet}\n")
            f.write(f"subnet={subnet}\n")
            f.write(f"aks={cname}\n")
            f.write(f"location={location}\n")


def update_config(args):
    cfg_env = args.cfg_env
    rg = args.rg
    vnet = args.vnet
    subnet = args.subnet
    aks = args.aks
    location = args.location
    size = args.size

    cfg = load_yaml(cfg_env)
    azure = cfg.setdefault("azure", {})

    # Ensure aksClusters exists
    clusters = azure.get("aksClusters")
    if clusters is None:
        azure["aksClusters"] = []
        clusters = azure["aksClusters"]

    # Append new cluster if not present
    found = False
    for item in clusters:
        if (item or {}).get("name") == aks:
            found = True
            break
    if not found:
        entry = {"name": aks}
        if size:
            entry["size"] = size
        clusters.append(entry)

    azure["resourceGroup"] = rg
    azure["vnetName"] = vnet
    azure["location"] = location

    dump_yaml(cfg_env, cfg)
    info(f"Updated {cfg_env}")


def run(cmd, check=True):
    info("$ " + " ".join(cmd))
    return subprocess.run(cmd, check=check)


def tf_state_list():
    try:
        res = subprocess.run(["terraform", "state", "list"], check=False, capture_output=True, text=True)
        if res.returncode != 0:
            return []
        return [line.strip() for line in res.stdout.splitlines() if line.strip()]
    except FileNotFoundError:
        return []


def destroy(args):
    rg = args.rg or ""
    vnet = args.vnet or ""
    subnet = args.subnet or ""
    delete_rg = str(args.delete_rg).lower() in ("1", "true", "yes")
    delete_network = str(args.delete_network).lower() in ("1", "true", "yes")

    if delete_rg:
        if not rg:
            err("--rg is required when --delete-rg=true")
            sys.exit(2)
        run(["az", "group", "delete", "--name", rg, "--yes", "--no-wait"], check=False)
        # Clean TF state
        for addr in tf_state_list():
            run(["terraform", "state", "rm", addr], check=False)
        return

    # Destroy AKS only (targeted)
    run(["terraform", "destroy", "-auto-approve",
         "-target=azurerm_kubernetes_cluster_node_pool.apps",
         "-target=azurerm_kubernetes_cluster.this"], check=False)

    if delete_network:
        if not (rg and vnet and subnet):
            err("--rg, --vnet, --subnet required when --delete-network=true")
            sys.exit(2)
        run(["az", "network", "vnet", "subnet", "delete", "--name", subnet, "--vnet-name", vnet, "--resource-group", rg], check=False)
        run(["az", "network", "vnet", "delete", "--name", vnet, "--resource-group", rg], check=False)
        # Detach network resources from TF state
        for addr in tf_state_list():
            if re.search(r"module\\.network_auto_create(\\[[0-9]+\\])?\\.azurerm_(subnet|virtual_network)\\.this(\\[[0-9]+\\])?$", addr):
                run(["terraform", "state", "rm", addr], check=False)
    else:
        # Preserve network: detach network-related from state to avoid prevent_destroy
        for addr in tf_state_list():
            if re.search(r"module\\.network_auto_create(\\[[0-9]+\\])?\\.azurerm_(subnet|virtual_network|resource_group)\\.this(\\[[0-9]+\\])?$", addr):
                run(["terraform", "state", "rm", addr], check=False)


def main():
    parser = argparse.ArgumentParser(description="AKS CI utility (Python)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("gen-matrix")
    p.add_argument("--cfg-env", required=True)
    p.add_argument("--name")
    p.add_argument("--team")
    p.add_argument("--env-id")
    p.set_defaults(func=gen_matrix)

    p = sub.add_parser("build-tfvars")
    p.add_argument("--cfg-global", required=True)
    p.add_argument("--cfg-env", required=True)
    p.add_argument("--name")
    p.add_argument("--env-id")
    p.add_argument("--team")
    p.add_argument("--region")
    p.add_argument("--size")
    p.add_argument("--manage-network", default="false")
    p.add_argument("--create-rg", default="false")
    p.add_argument("--out", default="aks.auto.tfvars.json")
    p.add_argument("--outputs-file")
    p.set_defaults(func=build_tfvars)

    p = sub.add_parser("update-config")
    p.add_argument("--cfg-env", required=True)
    p.add_argument("--rg", required=True)
    p.add_argument("--vnet", required=True)
    p.add_argument("--subnet", required=True)
    p.add_argument("--aks", required=True)
    p.add_argument("--location", required=True)
    p.add_argument("--size")
    p.set_defaults(func=update_config)

    p = sub.add_parser("destroy")
    p.add_argument("--rg")
    p.add_argument("--vnet")
    p.add_argument("--subnet")
    p.add_argument("--delete-rg", default="false")
    p.add_argument("--delete-network", default="false")
    p.set_defaults(func=destroy)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
