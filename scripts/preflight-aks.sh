#!/usr/bin/env bash
set -euo pipefail
: "${TFSTATE_CONTAINER:?missing}"
: "${TFSTATE_SA:?missing}"
: "${NETWORK_STATE_KEY:?missing}"
az storage blob show \
  --container-name "${TFSTATE_CONTAINER}" \
  --name "${NETWORK_STATE_KEY}" \
  --account-name "${TFSTATE_SA}" \
  --auth-mode login >/dev/null || {
    echo "Network remote state not found: ${NETWORK_STATE_KEY}"; exit 2;
}
