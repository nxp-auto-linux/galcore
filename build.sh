#!/bin/bash

# Copyright 2017 NXP

########################################################
# establish build environment and build options value
# Please modify the following items according your build environment

# make the script bail on first error (behave like make)
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


if [ -z $KERNEL_DIR ]
then
	echo "Please set KERNEL_DIR. It will point to your Linux Kernel folder"
	echo "e.g. export KERNEL_DIR=/space/workspaces/linux"
	export KERNEL_DIR="${KERNEL_DIR:-$KERNEL_SRC}"
fi

if ! [ -d $KERNEL_DIR ]
then
	echo "Invalid Linux Kernel folder"
	echo "KERNEL_DIR=$KERNEL_DIR"
	exit 1
fi

TEST_CROSS_COMPILE=${GCC_BIN%gcc}
if [ -z $CROSS_COMPILE ] || ! ${CROSS_COMPILE}gcc --version &> /dev/null
then
	if ${TEST_CROSS_COMPILE}gcc --version &> /dev/null
	then
		export CROSS_COMPILE=$TEST_CROSS_COMPILE

	fi
else
	if [ -z $TOOLCHAIN ]
	then
		echo "Please set TOOLCHAIN variable. It should point to your toolchain folder."
		echo "e.g. export TOOLCHAIN=/space/toolchains/gcc-linaro-4.9-2014.11-x86_64_aarch64-linux-gnu/"
		exit 1
		export CROSS_COMPILE="${CROSS_COMPILE:-$TOOLCHAIN/bin/aarch64-linux-gnu-}"
	fi
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
	# do extra cleaning
	rm ./hal/os/linux/kernel/gc_hal_kernel_iommu.o || true
	rm ./galcore.o || true
	rm ./.galcore.o.cmd || true
	rm ./galcore.mod.c || true
	rm ./.galcore.mod.o.cmd || true
	rm ./galcore.mod.o || true
	rm ./galcore.ko || true
	rm ./.galcore.ko.cmd || true
	rm -rf ./build || true
fi

if [ "clean" == "$1" ]; then
	make --makefile=Kbuild clean -C $DIR
else
	make --makefile=Kbuild install -j4 -C $DIR
fi
