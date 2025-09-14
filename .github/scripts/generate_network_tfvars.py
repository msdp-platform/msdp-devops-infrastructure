#!/usr/bin/env python3
import os
import sys
import yaml
import json

def get_yaml(file_path, key):
    try:
        with open(file_path, 'r') as f:
            data = yaml.safe_load(f)
        for part in key.split('.'):
            data = data.get(part)
            if data is None:
                return None
        return data
    except Exception:
        return None

def map_size(size):
    return {'large': 8, 'medium': 9, 'small': 10}.get(size, 9)

def main():
    cfg_global = os.environ.get('TF_VAR_global_config_path', 'infrastructure/config/globals.yaml')
    cfg_env = os.environ.get('TF_VAR_env_config_path', 'config/envs/dev.yaml')
    size_in = os.environ.get('INPUT_SIZE', '')

    cfg_loc = get_yaml(cfg_global, 'azure.location')
    cfg_rg = get_yaml(cfg_env, 'azure.resourceGroup')
    cfg_vnet = get_yaml(cfg_env, 'azure.vnetName')
    cfg_vnet_cidr = get_yaml(cfg_env, 'azure.vnetCidr')
    clusters_json = get_yaml(cfg_env, 'azure.aksClusters')

    if clusters_json:
        clusters_arr = []
        if isinstance(clusters_json, dict):
            for k, v in clusters_json.items():
                clusters_arr.append({
                    'name': k,
                    'subnetName': v.get('subnetName', f'snet-{k}'),
                    'size': v.get('size', 'medium')
                })
        elif isinstance(clusters_json, list):
            for v in clusters_json:
                clusters_arr.append({
                    'name': v.get('name'),
                    'subnetName': v.get('subnetName', f"snet-{v.get('name')}") if v.get('name') else None,
                    'size': v.get('size', 'medium')
                })
        spec = []
        for row in clusters_arr:
            sname = row['subnetName']
            size = size_in if size_in else row['size']
            nb = map_size(size)
            spec.append({'name': sname, 'newbits': nb})
        result = {
            'resource_group': cfg_rg,
            'location': cfg_loc,
            'vnet_name': cfg_vnet,
            'base_cidr': cfg_vnet_cidr,
            'computed_subnets_spec': spec
        }
        with open('network.auto.tfvars.json', 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Wrote {os.path.abspath('network.auto.tfvars.json')} (computed_subnets_spec from aksClusters)")
    else:
        cfg_subnet = get_yaml(cfg_env, 'azure.subnetName')
        cfg_subnet_cidr = get_yaml(cfg_env, 'azure.subnetCidr')
        if not all([cfg_rg, cfg_loc, cfg_vnet, cfg_vnet_cidr, cfg_subnet, cfg_subnet_cidr]):
            print("::error ::Missing required config values for network (resourceGroup, location, vnetName, vnetCidr, subnetName, subnetCidr).", file=sys.stderr)
            sys.exit(1)
        subnets = [{'name': cfg_subnet, 'cidr': cfg_subnet_cidr}]
        result = {
            'resource_group': cfg_rg,
            'location': cfg_loc,
            'vnet_name': cfg_vnet,
            'address_space': [cfg_vnet_cidr],
            'subnets': subnets
        }
        with open('network.auto.tfvars.json', 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Wrote {os.path.abspath('network.auto.tfvars.json')} (single subnet)")

if __name__ == "__main__":
    main()
