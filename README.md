# NVIDIA Driver Installer for Kubernetes Based on FCOS

## Daemonsets

Each GPU Fedora Atomic minion needs to install the GPU drivers and expose the
GPU as a resource to kubernetes. This setup is done with 2 daemonsets:

1. nvidia-driver-installer
2. nvidia-gpu-dev-plugin

## Nvidia GPU driver installer container

The nvidia-driver-installer container for Fedora Atomic is built from this repo.
It installs the nvidia driver in the container with the official nvidia
installer, including kmods and libs. Some pieces are omitted, including 32bit
compatibility libraries and the drm kmod (graphics).
It then copies over the installation to a 2nd stage (no kmod build deps).
When this is run on a minion, it will load the nvidia kmods, make the nvidia
device files and copy the driver bins and libs to a place on the host that
the k8s device plugin knows.

The k8s nvidia device plugin is fetched from upstream google; its daemonset
is slightly modified, because the upstream is made for GCP.

To test the usability of GPUs after deploying both daemonsets, there is a
CUDA sample pod that runs an nbody simulation. Check the results with
  kubectl logs cuda-sample-nbody
