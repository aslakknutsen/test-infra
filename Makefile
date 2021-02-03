HUB ?= quay.io/maistra-dev
BUILD_IMAGE_PREFIX = istio-workspace
BUILD_IMAGE_TAG ?= latest
BUILD_IMAGES = $(BUILD_IMAGE_PREFIX)-builder-base $(BUILD_IMAGE_PREFIX)-image-builder $(BUILD_IMAGE_PREFIX)-tester $(BUILD_IMAGE_PREFIX)-smee-client

IMG_BUILDER:=docker

## Prefer to use podman
 ifneq (, $(shell which podman))
	IMG_BUILDER=podman
 endif

.PHONY: images
images: $(BUILD_IMAGES)

${BUILD_IMAGE_PREFIX}-%:
	$(eval IMAGE := ${BUILD_IMAGE_PREFIX}-$*:${BUILD_IMAGE_TAG})

	$(IMG_BUILDER) build -t ${HUB}/${IMAGE} \
				 -f docker/$@.Dockerfile docker
	$(IMG_BUILDER) push ${HUB}/${IMAGE}

.PHONY: gen-check
gen-check: gen check-clean-repo

.PHONY: gen
gen:
	(cd prow; sh gen-config.sh)

.PHONY: check-clean-repo
check-clean-repo:
	@if [[ -n $$(git status --porcelain) ]]; then git status; git diff; echo "ERROR: Some files need to be updated, please run 'make gen' and include any changed files in your PR"; exit 1;	fi

.PHONY: update-prow-cluster
update-prow-cluster: gen
	sh prow/update.sh

.PHONY: update-prow-version
update-prow-version:
	sh prow/bump-version.sh
