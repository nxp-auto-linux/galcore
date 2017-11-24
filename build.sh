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
