#!/bin/bash

echo -e "\n[INFO]: BUILD STARTED..!\n"

#init submodules
git submodule update --init --recursive || true

export KERNEL_ROOT="$(pwd)"
export MAGISKBOOT="${KERNEL_ROOT}/prebuilts/magiskboot"
export ARCH=arm64
export KBUILD_BUILD_USER="@ravindu644"

mkdir -p "${KERNEL_ROOT}/out" "${KERNEL_ROOT}/build" "${HOME}/toolchains"

# init clang-r383902b
if [ ! -d "${HOME}/toolchains/clang-r383902b" ]; then
    echo -e "\n[INFO] Cloning clang-r383902b...\n"
    mkdir -p "${HOME}/toolchains/clang-r383902b" && cd "${HOME}/toolchains/clang-r383902b"
    curl -LO "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0e9e7035bf8ad42437c6156e5950eab13655b26c/clang-r383902b.tar.gz"
    tar -xf clang-r383902b.tar.gz && rm clang-r383902b.tar.gz
    cd "${KERNEL_ROOT}"
fi

# init aarch64-linux-android-4.9-Linux-5.4/
if [ ! -d "${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4" ]; then
    echo -e "\n[INFO] Cloning aarch64-linux-android-4.9-Linux-5.4\n"
    mkdir -p "${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4" && cd "${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4"
    curl -LO "https://github.com/ravindu644/Android-Kernel-Tutorials/releases/download/toolchains/aarch64-linux-android-4.9-Linux-5.4.tar.gz"
    tar -xf aarch64-linux-android-4.9-Linux-5.4.tar.gz && \
        rm aarch64-linux-android-4.9-Linux-5.4.tar.gz
    cd "${KERNEL_ROOT}"
fi

# Export toolchain paths
export PATH="${HOME}/toolchains/clang-r383902b/bin:${PATH}"
export LD_LIBRARY_PATH="${HOME}/clang-r383902b/lib:${HOME}/clang-r383902b/lib64:${LD_LIBRARY_PATH}"

# Set cross-compile environment variables
export BUILD_CROSS_COMPILE="${HOME}/toolchains/aarch64-linux-android-4.9-Linux-5.4/bin/aarch64-linux-android-"
export BUILD_CC="${HOME}/toolchains/clang-r383902b/bin/clang"

# Build options for the kernel
export BUILD_OPTIONS=(
    HOSTLDLIBS="-lyaml"
    -C "${KERNEL_ROOT}"
    O="${KERNEL_ROOT}/out"
    -j"$(nproc)"
    ARCH=arm64
    CROSS_COMPILE="${BUILD_CROSS_COMPILE}"
    CC="${BUILD_CC}"
    CLANG_TRIPLE=aarch64-linux-gnu-
)

build_kernel(){
    # Cleanup
    # make "${BUILD_OPTIONS[@]}" clean && make "${BUILD_OPTIONS[@]}" mrproper
    
    # Make default configuration.
    make "${BUILD_OPTIONS[@]}" beyond1qlte_jpn_kdi_defconfig custom.config

    # Configure the kernel (GUI)
    make "${BUILD_OPTIONS[@]}" menuconfig

    # Build the kernel
    make "${BUILD_OPTIONS[@]}" Image || exit 1

    # Copy the built kernel to the build directory
    cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image" "${KERNEL_ROOT}/build"

    echo -e "\n[INFO]: BUILD FINISHED..!"
}

build_boot(){
    # unpack, replace, pack
    cd "${KERNEL_ROOT}/prebuilts"
    "${MAGISKBOOT}" unpack boot.img && \
        cp "${KERNEL_ROOT}/build/Image" kernel && \
        "${MAGISKBOOT}" repack boot.img && \
        mv new-boot.img "${KERNEL_ROOT}/build/boot.img" && \
        rm kernel kernel_dtb
    cd "${KERNEL_ROOT}"
}

build_tar(){
    cd "${KERNEL_ROOT}/build"
    tar -cvf "Droidspaces-KSUN-Samsung-SCV41.tar" boot.img && \
        echo -e "\n[INFO]: TAR BUILT SUCCESSFULLY..!\n"
    cd "${KERNEL_ROOT}"
}

build_kernel && \
    build_boot && \
    build_tar
