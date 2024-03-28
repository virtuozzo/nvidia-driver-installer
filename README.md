# NVIDIA Driver Installer for Kubernetes Based on Fedora CoreOS

## Daemonsets

Each worker node needs to install a container with NVIDIA GPU drivers and expose the
GPU as a resource to the Kubernetes cluster. This setup is done with a daemonset consists of two containers:

1. nvidia-driver-installer
2. nvidia-gpu-dev-plugin

## Nvidia GPU driver installer container

The nvidia-driver-installer container for FCOS is built from this repo.
It installs the nvidia driver in the container with the official nvidia
installer, including kmods and libs. Some pieces are omitted, including 32bit
compatibility libraries and the drm kmod (graphics).
It then copies over the installation to a 2nd stage (no kmod build deps).
When this is run on a minion, it will load the nvidia kmods, make the nvidia
device files and copy the driver bins and libs to a place on the host that
the k8s device plugin knows.
