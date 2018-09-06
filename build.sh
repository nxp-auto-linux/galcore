#!/bin/bash

# Copyright 2017-2018 NXP

########################################################
# establish build environment and build options value
# Please modify the following items according your build environment

# make the script bail on first error (behave like make)
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z $KERNEL_DIR ]; then
	export KERNEL_DIR="${KERNEL_DIR:-$KERNEL_SRC}"
fi

if [ -z $TOOLCHAIN ]; then
	echo "Please set the TOOLCHAIN environment variable."
	echo "e.g. export TOOLCHAIN=/space/workspaces/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu"
fi

if [ -z $CROSS_COMPILE ]; then
	export CROSS_COMPILE="${CROSS_COMPILE:-${CROSS_COMPILE-${TARGET_PREFIX}}}"
fi


if [ -z $KERNEL_DIR ]; then
	echo "Please set KERNEL_DIR. It will point to your Linux Kernel folder"
	echo "e.g. export KERNEL_DIR=/space/workspaces/linux"
	exit
fi

if [ -z $CROSS_COMPILE ]; then
	echo "Please set the CROSS_COMPILE environment variable."
	echo "e.g. export CROSS_COMPILE=/space/workspaces/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
	echo "No CROSS_COMPILE detected, using system default."
fi

export ARCH="${ARCH:-arm64}"
export ARCH_TYPE="${ARCH_TYPE:-$ARCH}"

export AQROOT="${AQROOT:-$DIR}"
export SDK_DIR="${SDK_DIR:-$AQROOT/build/sdk}"

export CPU_TYPE="${CPU_TYPE:-cortex-a53}"
export CPU_ARCH="${CPU_ARCH:-armv8-a}"

export SOC_PLATFORM="${SOC_PLATFORM:-freescale-s32v234}"

########################################################
# build results will save to $SDK_DIR/
########################################################

if [ "clean" == "$1" ]; then
	make --makefile=Kbuild clean -C $DIR
	# do extra cleaning
	rm -f ./hal/os/linux/kernel/gc_hal_kernel_sync.o || true
	rm -f ./hal/os/linux/kernel/gc_hal_kernel_iommu.o || true
	rm -f ./hal/os/linux/kernel/allocator/default/gc_hal_kernel_allocator_dmabuf.o || true
	rm -f ./galcore.o || true
	rm -f ./.galcore.o.cmd || true
	rm -f ./galcore.mod.c || true
	rm -f ./.galcore.mod.o.cmd || true
	rm -f ./galcore.mod.o || true
	rm -f ./galcore.ko || true
	rm -f ./.galcore.ko.cmd || true
	rm -rf ./build || true
else
	BUILD_OPTIONS=" NO_DMA_COHERENT=0 USE_VDK=1 GC355_MEM_PRINT=0 GC355_PROFILER=0 MXC_FBDEV=1 EGL_API_FB=1 EGL_API_DFB=0 EGL_API_DRI=0 X11_DRI3=0 EGL_API_WL=0 EGL_API_GBM=0 EGL_API_NULLWS=0 gcdSTATIC_LINK=0 ABI=0 LINUX_OABI=0 DEBUG=0 CUSTOM_PIXMAP=0 USE_OPENCL=1 USE_OPENVX=1 USE_VULKAN=0 USE_FB_DOUBLE_BUFFER=0 USE_PLATFORM_DRIVER=1 ENABLE_GPU_CLOCK_BY_DRIVER=0 CONFIG_DOVEXC5_BOARD=0 FPGA_BUILD=0 VIVANTE_ENABLE_VG=1 VIVANTE_ENABLE_3D=1 VIVANTE_ENABLE_2D=1 DIRECTFB_MAJOR_VERSION=1 DIRECTFB_MINOR_VERSION=7 DIRECTFB_MICRO_VERSION=4 YOCTO_DRI_BUILD=1 X11_DRI3=0 VIVANTE_ENABLE_DRM=0 -j4 USE_KMS=0 install"
	make -C $DIR --makefile=Kbuild $BUILD_OPTIONS
fi
