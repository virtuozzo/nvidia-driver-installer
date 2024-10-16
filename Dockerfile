# Nvidia driver installer for Fedora Atomic

ARG FEDORA_VERSION=39

FROM fedora:${FEDORA_VERSION} as kmod_builder

ARG KERNEL_VERSION=6.5.11-300.fc39.x86_64
ARG KERNEL_SHORT=6.5.11
ARG KERNEL_BUILD=300.fc39
ARG KERNEL_ARCH=x86_64
ARG NVIDIA_DRIVER_VERSION=550.54.15
ARG IMAGE_VERSION=1.0

LABEL maintainer="Virtuozzo <dfateyev@virtuozzo.com>" \
      name="nvidia-driver-installer" \
      version="${IMAGE_VERSION}" \
      atomic.type="system" \
      architecture="${KERNEL_ARCH}"

RUN dnf -y update

RUN dnf -y install curl git binutils cpp gcc koji bc make pkgconfig pciutils unzip \
      elfutils-libelf-devel openssl-devel module-init-tools

RUN echo "curl -O https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_SHORT}/${KERNEL_BUILD}/${KERNEL_ARCH}/kernel-devel-${KERNEL_VERSION}.rpm"

RUN curl -O https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_SHORT}/${KERNEL_BUILD}/${KERNEL_ARCH}/kernel-devel-${KERNEL_VERSION}.rpm && \
    curl -O https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_SHORT}/${KERNEL_BUILD}/${KERNEL_ARCH}/kernel-core-${KERNEL_VERSION}.rpm && \
    curl -O https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_SHORT}/${KERNEL_BUILD}/${KERNEL_ARCH}/kernel-modules-${KERNEL_VERSION}.rpm && \
    curl -O https://kojipkgs.fedoraproject.org//packages/kernel/${KERNEL_SHORT}/${KERNEL_BUILD}/${KERNEL_ARCH}/kernel-modules-core-${KERNEL_VERSION}.rpm && \
    dnf localinstall -y kernel-*.rpm && \
    dnf clean all

ENV NVIDIA_DRIVER_URL "https://us.download.nvidia.com/XFree86/Linux-${KERNEL_ARCH}/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-${KERNEL_ARCH}-${NVIDIA_DRIVER_VERSION}.run"

ENV KERNEL_PATH /usr/src/kernels
ENV NVIDIA_PATH /opt/nvidia
ENV NVIDIA_BUILD_PATH ${NVIDIA_PATH}/build
ENV NVIDIA_DL_PATH ${NVIDIA_PATH}/download

# NVIDIA driver
WORKDIR ${NVIDIA_DL_PATH}

RUN curl ${NVIDIA_DRIVER_URL} -o nv_driver_installer.run && \
    chmod +x nv_driver_installer.run

RUN ${NVIDIA_PATH}/download/nv_driver_installer.run \
      -z \
      --accept-license \
      --no-questions \
      --ui=none \
      --no-precompiled-interface \
      --kernel-source-path=/lib/modules/${KERNEL_VERSION}/build \
      --kernel-name=${KERNEL_VERSION} \
      --no-nvidia-modprobe \
      --no-drm \
      --x-prefix=/usr \
      --no-install-compat32-libs \
      --installer-prefix=${NVIDIA_BUILD_PATH} \
      --utility-prefix=${NVIDIA_BUILD_PATH} \
      --opengl-prefix=${NVIDIA_BUILD_PATH} && \
      mv ${NVIDIA_BUILD_PATH}/lib ${NVIDIA_BUILD_PATH}/lib64

RUN mkdir -p ${NVIDIA_BUILD_PATH}/lib/modules/ && \
    cp -rf /lib/modules/${KERNEL_VERSION} ${NVIDIA_BUILD_PATH}/lib/modules/${KERNEL_VERSION}

# Cleanup
RUN rm -rf ${NVIDIA_BUILD_PATH}/bin/nvidia-installer \
      ${NVIDIA_BUILD_PATH}/bin/nvidia-uninstall \
      ${NVIDIA_BUILD_PATH}/bin/nvidia-xconfig \
      ${NVIDIA_BUILD_PATH}/share

###   DEPLOY   ###
FROM fedora:${FEDORA_VERSION}

ARG KERNEL_VERSION=6.5.11-300.fc39.x86_64
ARG NVIDIA_DRIVER_VERSION=550.54.15
ARG KERNEL_ARCH=x86_64
ARG IMAGE_VERSION=1.0

LABEL maintainer="Virtuozzo <dfateyev@virtuozzo.com>" \
      name="nvidia-driver-installer" \
      version="${IMAGE_VERSION}" \
      atomic.type="system" \
      architecture="${KERNEL_ARCH}"

RUN dnf -y update && \
    dnf -y install module-init-tools pciutils && \
    dnf -y autoremove && \
    dnf clean all && \
    rm -rf /var/cache/yum

ENV NVIDIA_DRIVER_VERSION ${NVIDIA_DRIVER_VERSION}
ENV KERNEL_VERSION ${KERNEL_VERSION}

ENV NVIDIA_PATH /opt/nvidia
ENV NVIDIA_BIN_PATH ${NVIDIA_PATH}/bin
ENV NVIDIA_LIB_PATH ${NVIDIA_PATH}/lib
ENV NVIDIA_MODULES_PATH ${NVIDIA_LIB_PATH}/modules/${KERNEL_VERSION}/kernel/drivers/video

COPY --from=kmod_builder /opt/nvidia/build ${NVIDIA_PATH}
COPY scripts/nvidia-mkdevs.sh ${NVIDIA_BIN_PATH}/nvidia-mkdevs
COPY scripts/nvidia-driver.sh ${NVIDIA_BIN_PATH}/nvidia-driver

RUN mkdir -p /lib/modules && \
    ln -s ${NVIDIA_PATH}/lib/modules/${KERNEL_VERSION} /lib/modules/${KERNEL_VERSION}

ENV PATH $PATH:${NVIDIA_BIN_PATH}
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NVIDIA_LIB_PATH}

CMD depmod -a && \
    modprobe -r nouveau && \
    modprobe nvidia && \
    modprobe nvidia-uvm && \
    nvidia-mkdevs && \
    cp -rf ${NVIDIA_PATH}/bin /opt/nvidia-host && \
    cp -rf ${NVIDIA_PATH}/lib64 /opt/nvidia-host

