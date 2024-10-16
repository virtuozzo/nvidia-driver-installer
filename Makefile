# Update your variables here
FEDORA_VERSION = 39
KERNEL_VERSION = "6.6.13-200.fc39.x86_64"
KERNEL_SHORT = "6.6.13"
KERNEL_BUILD = "200.fc39"
KERNEL_ARCH = "x86_64"
NVIDIA_DRIVER_VERSION = "550.107.02"
IMAGE_VERSION = "1.0"

CONTAINER_TAG ?= virtuozzo/nvidia-driver-installer:$(FEDORA_VERSION)-$(KERNEL_VERSION)-$(NVIDIA_DRIVER_VERSION)

validate:
	@if [ -z "$(NVIDIA_DRIVER_VERSION)" ]; then \
		echo "NVIDIA_DRIVER_VERSION cannot be empty, automatic detection has failed."; \
		exit 1; \
	fi;
	@if [ -z "$(KERNEL_VERSION)" ]; then \
		echo "KERNEL_VERSION cannot be empty, automatic detection has failed."; \
		exit 1; \
	fi;

build: validate
	echo "Building Docker Image ... " && \
	docker build \
		--rm=false \
		--network=host \
		--build-arg FEDORA_VERSION=$(FEDORA_VERSION) \
		--build-arg KERNEL_VERSION=$(KERNEL_VERSION) \
		--build-arg KERNEL_SHORT=$(KERNEL_SHORT) \
		--build-arg KERNEL_BUILD=$(KERNEL_BUILD) \
		--build-arg KERNEL_ARCH=$(KERNEL_ARCH) \
		--build-arg IMAGE_VERSION=$(IMAGE_VERSION) \
		--build-arg NVIDIA_DRIVER_VERSION=$(NVIDIA_DRIVER_VERSION) \
		--tag $(CONTAINER_TAG) \
		--file Dockerfile .

push: build
	if [ "$(DOCKER_USERNAME)" != "" ]; then \
		echo "$(DOCKER_PASSWORD)" | docker login --username="$(DOCKER_USERNAME)" --password-stdin; \
	fi; \
	docker push $(CONTAINER_TAG)

.PHONY: validate build push
