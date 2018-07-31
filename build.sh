#!/bin/bash

########################################################
# establish build environment and build options value
# Please modify the following items according your build environment

# make the script bail on first error (behave like make)
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set these variables
if [[ -z $KERNEL_DIR ]]; then
	export KERNEL_DIR=
fi
if [[ -z $TOOLCHAIN ]]; then
	export TOOLCHAIN=
fi


if [[ -z $KERNEL_DIR ]]; then
	echo "Please set the KERNEL_DIR environment variable."
	exit
fi
if [[ ! -x $KERNEL_DIR/scripts/mod/modpost ]]; then
	echo "Please run \"make scripts\" inside the kernel dir ($KERNEL_DIR)."
	exit
fi
if [[ -z $TOOLCHAIN ]]; then
	echo "Please set the TOOLCHAIN environment variable."
	exit
fi

if echo "$PATH" | grep -q "^$TOOLCHAIN/bin" ; then
	:
else
	export PATH=$TOOLCHAIN/bin:$PATH
fi

export ARCH=arm64
export ARCH_TYPE=$ARCH

export AQROOT=$DIR
export SDK_DIR=$AQROOT/build/sdk

export CPU_TYPE=cortex-a53
export CPU_ARCH=armv8-a

export CROSS_COMPILE=$TOOLCHAIN/bin/aarch64-linux-gnu-
export SOC_PLATFORM=freescale-s32v234

########################################################
# build results will save to $SDK_DIR/
########################################################

if [ "clean" == "$1" ]; then
	# do extra cleaning
	rm -f ./hal/os/linux/kernel/gc_hal_kernel_iommu.o || true
	rm -f ./galcore.o || true
	rm -f ./.galcore.o.cmd || true
	rm -f ./galcore.mod.c || true
	rm -f ./.galcore.mod.o.cmd || true
	rm -f ./galcore.mod.o || true
	rm -f ./galcore.ko || true
	rm -f ./.galcore.ko.cmd || true
	rm -rf ./build || true
fi

if [ "clean" == "$1" ]; then
	make --makefile=Kbuild clean -C $DIR
else
	BUILD_OPTIONS=" NO_DMA_COHERENT=0 USE_VDK=1 GC355_MEM_PRINT=0 GC355_PROFILER=0 MXC_FBDEV=1 EGL_API_FB=1 EGL_API_DFB=0 EGL_API_DRI=0 X11_DRI3=0 EGL_API_WL=0 EGL_API_GBM=0 EGL_API_NULLWS=0 gcdSTATIC_LINK=0 ABI=0 LINUX_OABI=0 DEBUG=0 CUSTOM_PIXMAP=0 USE_OPENCL=1 USE_OPENVX=1 USE_VULKAN=0 USE_FB_DOUBLE_BUFFER=0 USE_PLATFORM_DRIVER=1 ENABLE_GPU_CLOCK_BY_DRIVER=0 CONFIG_DOVEXC5_BOARD=0 FPGA_BUILD=0 VIVANTE_ENABLE_VG=1 VIVANTE_ENABLE_3D=1 VIVANTE_ENABLE_2D=1 DIRECTFB_MAJOR_VERSION=1 DIRECTFB_MINOR_VERSION=7 DIRECTFB_MICRO_VERSION=4 YOCTO_DRI_BUILD=1 X11_DRI3=0 VIVANTE_ENABLE_DRM=0 -j4 USE_KMS=0 install"
	make -C $DIR --makefile=Kbuild $BUILD_OPTIONS
fi
