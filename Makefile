TF_DIR ?= infrastructure/environment/azure/network
TF_BACKEND_CONFIG_FILE ?= infrastructure/environment/dev/backend/backend-config.json

.PHONY: init plan apply

init:
	terraform -chdir=$(TF_DIR) init -backend-config=$(TF_BACKEND_CONFIG_FILE)

plan: init
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply: init
	terraform -chdir=$(TF_DIR) apply -auto-approve tfplan

