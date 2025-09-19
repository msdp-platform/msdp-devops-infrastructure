IMAGE_REGISTRY ?= ghcr.io/example
IMAGE_NAME ?= msdp/sample-service
TAGS ?= latest
PLATFORMS ?= linux/amd64,linux/arm64
DOCKERFILE ?= Dockerfile.service
CONTEXT ?= .

.PHONY: build push publish sbom sign

build:
	docker buildx build --platform $(PLATFORMS) -f $(DOCKERFILE) $(CONTEXT) -t $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(TAGS) --load

push:
	docker buildx build --platform $(PLATFORMS) -f $(DOCKERFILE) $(CONTEXT) -t $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(TAGS) --push

publish: push

sbom:
	syft $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(TAGS) -o spdx-json > sbom-$(subst /,-,$(IMAGE_NAME)).json

sign:
	COSIGN_EXPERIMENTAL=1 cosign sign --yes $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(TAGS)

