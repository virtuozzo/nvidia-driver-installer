# NVIDIA Driver Installer for Kubernetes Based on Fedora CoreOS

## Daemonset

Each worker node needs to install a container with NVIDIA GPU drivers and expose the
GPU as a resource to the Kubernetes cluster. This setup is done with a daemonset consists of two containers:

1. nvidia-driver-installer
2. nvidia-gpu-dev-plugin

## Nvidia GPU Driver Installer Container

The nvidia-driver-installer container for FCOS is built from this repo.
It installs the nvidia driver in the container with the official nvidia
installer, including kmods and libs. Some pieces are omitted, including 32bit
compatibility libraries and the drm kmod (graphics).
It then copies over the installation to a 2nd stage (no kmod build deps).
When this is run on a minion, it will load the nvidia kmods, make the nvidia
device files and copy the driver bins and libs to a place on the host that
the k8s device plugin knows.

The NVIDIA driver deployer leverages
[node-feature-discovery](https://github.com/NVIDIA/gpu-feature-discovery/tree/main/deployments/static)
(NFD) to detect the GPU nodes for the GPU driver container to rollout.

## Installation

```
# deploy NFD
kubectl apply -f daemonsets/node-feature-discovery.yaml

# deploy GPU driver
kubectl apply -f daemonsets/nvidia-gpu-driver.yaml
```

To test the usability of GPUs after deploying both DaemonSets, there is a
CUDA sample set with several cases.\
Check the `test` subdirectory for more details.

## How To Build Your Own

Clone this repo to your own machine:

    git clone https://github.com/virtuozzo/nvidia-driver-installer.git

Open the Makefile and edit the following variables:

    NVIDIA_DRIVER_VERSION=<nvidia_driver_version>
    CONTAINER_TAG ?= <your_dockerhub_account>/nvidia-driver-installer:$(FEDORA_VERSION)-$(KERNEL_VERSION)-$(NVIDIA_DRIVER_VERSION)

Build a docker image:
    
    make build

Push the image to DockerHub:
    
    make push

Update the daemonsets/nvidia-gpu-driver.yaml daemonset. Find the following image name:

    - image: "virtuozzo/nvidia-driver-installer:39-6.5.11-300.fc39.x86_64-550.54.15"

and update it:

    - image: "<your_dockerhub_account>/nvidia-driver-installer:39-6.5.11-300.fc39.x86_64-<driver_version>"
    


