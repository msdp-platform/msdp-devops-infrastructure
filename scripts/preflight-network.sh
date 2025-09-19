#!/usr/bin/env bash
set -euo pipefail
az account show >/dev/null || { echo "Azure login missing"; exit 1; }
