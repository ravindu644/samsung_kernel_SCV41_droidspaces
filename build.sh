#!/bin/bash

echo -e "\n[INFO]: BUILD STARTED..!\n"

#init submodules
git submodule update --init --recursive || true

export KERNEL_ROOT="$(pwd)"
export MAGISKBOOT="${KERNEL_ROOT}/prebuilts/magiskboot"
export ARCH=arm64
export KBUILD_BUILD_USER="@ravindu644"

mkdir -p "${KERNEL_ROOT}/out" "${KERNEL_ROOT}/build"

# Export toolchain paths
export PATH="${KERNEL_ROOT}/prebuilts/toolchain/llvm-arm-toolchain-ship/10.0.9/bin:${PATH}"
export LD_LIBRARY_PATH="${KERNEL_ROOT}/prebuilts/toolchain/llvm-arm-toolchain-ship/10.0.9/lib:${LD_LIBRARY_PATH}"

# Set cross-compile environment variables
export BUILD_CROSS_COMPILE="${KERNEL_ROOT}/prebuilts/toolchain/gcc-cfp/gcc-cfp-single/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
export BUILD_CC="${KERNEL_ROOT}/prebuilts/toolchain/llvm-arm-toolchain-ship/10.0.9/bin/clang"

# Build options for the kernel
export BUILD_OPTIONS=(
    -C "${KERNEL_ROOT}"
    O="${KERNEL_ROOT}/out"
    -j"$(nproc)"
    ARCH=arm64
    DTC_EXT="${KERNEL_ROOT}/tools/dtc"
    CONFIG_BUILD_ARM64_DT_OVERLAY=y
    CROSS_COMPILE="${BUILD_CROSS_COMPILE}"
    CC="${BUILD_CC}"
    CLANG_TRIPLE=aarch64-linux-gnu-
)

build_kernel(){
    # Cleanup
    make "${BUILD_OPTIONS[@]}" clean && make "${BUILD_OPTIONS[@]}" mrproper
    
    # Make default configuration.
    make "${BUILD_OPTIONS[@]}" beyond1qlte_jpn_kdi_defconfig custom.config droidspaces.config

    # Configure the kernel (TUI)
    if [ -z "${GITHUB_ACTIONS}" ]; then
        make "${BUILD_OPTIONS[@]}" menuconfig
    fi

    # Build the kernel
    make "${BUILD_OPTIONS[@]}" || exit 1

    # Copy the built kernel to the build directory
    # cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image" "${KERNEL_ROOT}/build"

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
