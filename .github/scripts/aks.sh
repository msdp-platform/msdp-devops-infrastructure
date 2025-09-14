#!/usr/bin/env bash
set -euo pipefail

# aks.sh - Utilities for AKS CI workflows
# Subcommands:
#   gen-matrix        -> print JSON matrix to stdout
#   build-tfvars      -> generate aks.auto.tfvars.json and emit outputs
#   update-config     -> patch config/envs/<env>.yaml with resolved values
#   destroy           -> destroy AKS and optionally network/RG
#
# All subcommands accept --help for usage.

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err()  { echo "[ERROR] $*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }; }

ensure_yq() {
  if ! command -v yq >/dev/null 2>&1; then
    info "Installing yq..."
    sudo wget -qO /usr/local/bin/yq \
      https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
  fi
}

ensure_jq() { need_cmd jq; }

norm() {
  # to lower, allowed [a-z0-9-], collapse -, trim edges
  tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/-+/-/g; s/^-|-$//g'
}

usage_gen_matrix() {
  cat <<EOF
Usage: $0 gen-matrix --cfg-env <path> [--name <override>] [--team <team>] [--env-id <env>]

Prints a JSON array matrix: [{"name":"...","subnetName":"..."}]
EOF
}

# find highest sequence matching ^<env>-<team>-(\d+)$ in aksClusters[].name and azure.aksName
next_seq() {
  local CFG_ENV="$1" ENV_ID="$2" TEAM="$3"
  local prefix="${ENV_ID}-${TEAM}"
  local max=0
  local names
  names=$(yq -r '.azure.aksClusters[].name // empty' "$CFG_ENV" 2>/dev/null || true)
  for n in $names; do
    if [[ "$n" =~ ^${prefix}-([0-9]+)$ ]]; then
      local num=${BASH_REMATCH[1]}
      (( num > max )) && max=$num
    fi
  done
  local single
  single=$(yq -r '.azure.aksName // empty' "$CFG_ENV" 2>/dev/null || true)
  if [[ -n "$single" && "$single" =~ ^${prefix}-([0-9]+)$ ]]; then
    local num=${BASH_REMATCH[1]}
    (( num > max )) && max=$num
  fi
  printf "%02d" $((max+1))
}

gen_matrix() {
  ensure_yq; ensure_jq
  local CFG_ENV="" OVERRIDE_NAME="" TEAM="" ENV_ID=""
  while [[ $# -gt 0 ]]; do case "$1" in
    --cfg-env) CFG_ENV="$2"; shift 2;;
    --name) OVERRIDE_NAME="$2"; shift 2;;
    --team) TEAM="$2"; shift 2;;
    --env-id) ENV_ID="$2"; shift 2;;
    -h|--help) usage_gen_matrix; exit 0;;
    *) err "Unknown arg: $1"; usage_gen_matrix; exit 2;;
  esac; done
  [[ -z "$CFG_ENV" ]] && { err "--cfg-env is required"; exit 2; }

  if [[ -n "$TEAM" && -n "$ENV_ID" ]]; then
    local seq; seq=$(next_seq "$CFG_ENV" "$ENV_ID" "$TEAM")
    local cname="${ENV_ID}-${TEAM}-${seq}"
    local sname="${ENV_ID}-${TEAM}-${seq}"
    echo "[{\"name\":\"$cname\",\"subnetName\":\"$sname\"}]"
    return 0
  fi

  local raw matrix name sname
  raw=$(yq -r '.azure.aksClusters // {}' "$CFG_ENV" 2>/dev/null || echo '{}')
  matrix=$(jq -c 'if type=="object" then [ to_entries[] | {name: .key, subnetName: (.value.subnetName // ("snet-" + .key))} ] elif type=="array" then [ .[] | {name: .name, subnetName: (.subnetName // ("snet-" + .name))} ] else [] end' <<<"$raw")
  if [[ "$(jq -r 'length' <<<"$matrix")" -eq 0 ]]; then
    name=$(yq -r '.azure.aksName // ""' "$CFG_ENV" 2>/dev/null || echo "")
    sname=$(yq -r '.azure.subnetName // ""' "$CFG_ENV" 2>/dev/null || echo "")
    if [[ -z "$name" || -z "$sname" ]]; then
      err "No azure.aksClusters and missing azure.aksName/subnetName"; exit 1
    fi
    matrix=$(jq -nc --arg n "$name" --arg s "$sname" '[{name:$n, subnetName:$s}]')
  fi
  if [[ -n "$OVERRIDE_NAME" ]]; then
    matrix=$(jq -nc --arg n "$OVERRIDE_NAME" --arg s "$OVERRIDE_NAME" '[{name:$n, subnetName:$s}]')
  fi
  echo "$matrix"
}

usage_build_tfvars() {
  cat <<EOF
Usage: $0 build-tfvars \
  --cfg-global <path> --cfg-env <path> [--name <matrixName>] \
  [--env-id <env>] [--team <team>] [--region <str>] [--size <small|medium|large>] \
  [--manage-network <true|false>] [--create-rg <true|false>] \
  [--out <file>] [--outputs-file <path>]
EOF
}

build_tfvars() {
  ensure_yq; ensure_jq
  local CFG_GLOBAL="" CFG_ENV="" NAME=""
  local ENV_ID="" TEAM="" REGION="" SIZE=""
  local MANAGE_NETWORK="false" CREATE_RG="false" OUT="aks.auto.tfvars.json" OUTPUTS_FILE=""

  while [[ $# -gt 0 ]]; do case "$1" in
    --cfg-global) CFG_GLOBAL="$2"; shift 2;;
    --cfg-env) CFG_ENV="$2"; shift 2;;
    --name) NAME="$2"; shift 2;;
    --env-id) ENV_ID="$2"; shift 2;;
    --team) TEAM="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --size) SIZE="$2"; shift 2;;
    --manage-network) MANAGE_NETWORK="$2"; shift 2;;
    --create-rg) CREATE_RG="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --outputs-file) OUTPUTS_FILE="$2"; shift 2;;
    -h|--help) usage_build_tfvars; exit 0;;
    *) err "Unknown arg: $1"; usage_build_tfvars; exit 2;;
  esac; done

  [[ -z "$CFG_GLOBAL" || -z "$CFG_ENV" ]] && { err "Missing required args"; usage_build_tfvars; exit 2; }

  local loc
  loc=$(yq -r '.azure.location // ""' "$CFG_GLOBAL" 2>/dev/null || echo "")
  [[ -n "$REGION" ]] && loc="$REGION"
  loc=$(echo -n "$loc" | norm)

  local cname rg vnet sname
  if [[ -n "$TEAM" && -n "$ENV_ID" ]]; then
    local seq; seq=$(next_seq "$CFG_ENV" "$ENV_ID" "$TEAM")
    cname="${ENV_ID}-${TEAM}-${seq}"
    rg="${ENV_ID}-${TEAM}"
    vnet="${ENV_ID}-${TEAM}"
    sname="${ENV_ID}-${TEAM}-${seq}"
  else
    # Fallback: use provided NAME and values from cfg-env
    [[ -z "$NAME" ]] && { err "--name or --team/--env-id required"; exit 2; }
    rg=$(yq -r '.azure.resourceGroup // ""' "$CFG_ENV" 2>/dev/null || echo "")
    vnet=$(yq -r '.azure.vnetName // ""' "$CFG_ENV" 2>/dev/null || echo "")
    sname=$(yq -r '.azure.subnetName // ""' "$CFG_ENV" 2>/dev/null || echo "")
    NAME=$(echo -n "$NAME" | norm)
    rg=$(echo -n "$rg" | norm)
    vnet=$(echo -n "$vnet" | norm)
    sname=$(echo -n "$sname" | norm)
    cname="$NAME"
  fi

  info "Resolved RG=$rg VNET=$vnet SUBNET=$sname AKS=$cname LOC=$loc"

  local sys_count=1 sys_vm="Standard_B2s" user_vm="Standard_B2s" user_min=0 user_max=2 user_spot=false
  case "$SIZE" in medium) user_max=4;; large) user_max=8;; esac

  cat > "$OUT" <<TFVARS
{
  "resource_group": "$rg",
  "vnet_name": "$vnet",
  "location": "$loc",
  "aks_name": "$cname",
  "subnet_name": "$sname",
  "system_node_count": $sys_count,
  "system_vm_size": "$sys_vm",
  "user_vm_size": "$user_vm",
  "user_min_count": $user_min,
  "user_max_count": $user_max,
  "user_spot": $user_spot,
  "manage_network": $MANAGE_NETWORK,
  "create_resource_group": $CREATE_RG
}
TFVARS
  info "Wrote $OUT"

  if [[ -n "${OUTPUTS_FILE:-}" ]]; then
    {
      echo "rg=$rg";
      echo "vnet=$vnet";
      echo "subnet=$sname";
      echo "aks=$cname";
      echo "location=$loc";
    } >> "$OUTPUTS_FILE"
  fi
}

usage_update_config() {
  cat <<EOF
Usage: $0 update-config --cfg-env <path> --rg <name> --vnet <name> --subnet <name> --aks <name> --location <region> [--size <small|medium|large>]
EOF
}

update_config() {
  ensure_yq
  local CFG_ENV="" RG="" VNET="" SUBNET="" AKS="" LOC="" SIZE=""
  while [[ $# -gt 0 ]]; do case "$1" in
    --cfg-env) CFG_ENV="$2"; shift 2;;
    --rg) RG="$2"; shift 2;;
    --vnet) VNET="$2"; shift 2;;
    --subnet) SUBNET="$2"; shift 2;;
    --aks) AKS="$2"; shift 2;;
    --location) LOC="$2"; shift 2;;
    --size) SIZE="$2"; shift 2;;
    -h|--help) usage_update_config; exit 0;;
    *) err "Unknown arg: $1"; usage_update_config; exit 2;;
  esac; done
  [[ -z "$CFG_ENV" || -z "$RG" || -z "$VNET" || -z "$SUBNET" || -z "$AKS" || -z "$LOC" ]] && { err "Missing args"; usage_update_config; exit 2; }

  info "Updating $CFG_ENV"
  # Ensure aksClusters array exists and append/ensure entry
  if ! yq -e '.azure.aksClusters' "$CFG_ENV" >/dev/null 2>&1; then
    yq -i '.azure.aksClusters = []' "$CFG_ENV"
  fi
  # Append if name not present
  if ! yq -e ".azure.aksClusters[] | select(.name == \"$AKS\")" "$CFG_ENV" >/dev/null 2>&1; then
    if [[ -n "$SIZE" ]]; then
      yq -i ".azure.aksClusters += [{\"name\": \"$AKS\", \"size\": \"$SIZE\"}]" "$CFG_ENV"
    else
      yq -i ".azure.aksClusters += [{\"name\": \"$AKS\"}]" "$CFG_ENV"
    fi
  fi
  yq -i \
    ".azure.resourceGroup = \"$RG\" | .azure.vnetName = \"$VNET\" | .azure.location = \"$LOC\"" \
    "$CFG_ENV"
}

usage_destroy() {
  cat <<EOF
Usage: $0 destroy [--rg <name>] [--vnet <name>] [--subnet <name>] \
  [--delete-rg <true|false>] [--delete-network <true|false>]

Assumes current dir has Terraform workspace for AKS.
EOF
}

destroy_cmd() {
  local RG="" VNET="" SUBNET="" DELETE_RG="false" DELETE_NET="false"
  while [[ $# -gt 0 ]]; do case "$1" in
    --rg) RG="$2"; shift 2;;
    --vnet) VNET="$2"; shift 2;;
    --subnet) SUBNET="$2"; shift 2;;
    --delete-rg) DELETE_RG="$2"; shift 2;;
    --delete-network) DELETE_NET="$2"; shift 2;;
    -h|--help) usage_destroy; exit 0;;
    *) err "Unknown arg: $1"; usage_destroy; exit 2;;
  esac; done

  if [[ "$DELETE_RG" == "true" ]]; then
    [[ -z "$RG" ]] && { err "--rg is required when --delete-rg=true"; exit 2; }
    info "Deleting Resource Group $RG via Azure CLI"
    az group delete --name "$RG" --yes --no-wait || true
    info "Cleaning Terraform state"
    if terraform state list >/dev/null 2>&1; then
      terraform state list | while read -r addr; do terraform state rm "$addr" || true; done
    fi
    exit 0
  fi

  info "Destroying AKS resources only via Terraform"
  terraform destroy -auto-approve \
    -target=azurerm_kubernetes_cluster_node_pool.apps \
    -target=azurerm_kubernetes_cluster.this || true

  if [[ "$DELETE_NET" == "true" ]]; then
    [[ -z "$RG" || -z "$VNET" || -z "$SUBNET" ]] && { err "--rg, --vnet, --subnet required when --delete-network=true"; exit 2; }
    info "Deleting Subnet $SUBNET and VNet $VNET"
    az network vnet subnet delete --name "$SUBNET" --vnet-name "$VNET" --resource-group "$RG" || true
    az network vnet delete --name "$VNET" --resource-group "$RG" || true
    info "Detaching network resources from state"
    if terraform state list >/dev/null 2>&1; then
      terraform state list | grep -E 'module\.network_auto_create(\[[0-9]+\])?\.azurerm_(subnet|virtual_network)\.this(\[[0-9]+\])?$' | while read -r addr; do terraform state rm "$addr" || true; done
    fi
  else
    info "Preserving network: detaching network resources from state"
    if terraform state list >/dev/null 2>&1; then
      terraform state list | grep -E 'module\.network_auto_create(\[[0-9]+\])?\.azurerm_(subnet|virtual_network|resource_group)\.this(\[[0-9]+\])?$' | while read -r addr; do terraform state rm "$addr" || true; done
    fi
  fi
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    gen-matrix) gen_matrix "$@" ;;
    build-tfvars) build_tfvars "$@" ;;
    update-config) update_config "$@" ;;
    destroy) destroy_cmd "$@" ;;
    -h|--help|help|"") cat <<EOF
AKS CI utility
Commands:
  gen-matrix      Generate matrix JSON from env config or team/env naming
  build-tfvars    Build aks.auto.tfvars.json and emit outputs
  update-config   Patch env config (resourceGroup, vnetName, location, aksClusters)
  destroy         Destroy AKS and optionally network/RG
EOF
      ;;
    *) err "Unknown command: $cmd"; exit 2;;
  esac
}

main "$@"
