/****************************************************************************
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 - 2017 Vivante Corporation
 * Copyright 2019 NXP
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 *****************************************************************************
 *
 * The GPL License (GPL)
 *
 * Copyright (C) 2014 - 2017 Vivante Corporation
 * Copyright 2019 NXP
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 *****************************************************************************
 *
 * Note: This software is released under dual MIT and GPL licenses. A
 * recipient may use this file under the terms of either the MIT license or
 * GPL License. If you wish to use only one license not the other, you can
 * indicate your decision by deleting one of the above license notices in your
 * version of this file.
 *
 *****************************************************************************/

#include <linux/slab.h>
#include <linux/of_platform.h>
#include <linux/of_gpio.h>
#include <linux/of_address.h>
#include <linux/platform_device.h>

#include "gc_hal_kernel_linux.h"
#include "gc_hal_kernel_platform.h"
#include "gc_hal_kernel_device.h"
#include "gc_hal_driver.h"

#ifndef gcdFSL_CONTIGUOUS_SIZE
#  define gcdFSL_CONTIGUOUS_SIZE (4 << 20)
#endif

static int initgpu3DMinClock = 1;
module_param(initgpu3DMinClock, int, 0644);

static gceSTATUS ls_adjust_param(gcsPLATFORM *platform,
		gcsMODULE_PARAMETERS *args)
{
	struct platform_device *pdev = platform->device;
	struct resource *res;
	struct device_node *node = pdev->dev.of_node;
	int core = gcvCORE_MAJOR;
	struct platform_device *pdev_gpu;
	int irqLine = -1;

	pdev_gpu = of_find_device_by_node(node);
	if (!pdev_gpu)
		return gcvSTATUS_DEVICE;

	of_node_put(node);

	irqLine = platform_get_irq(pdev_gpu, 0);
	if (irqLine < 0)
		return gcvSTATUS_NOT_FOUND;

	res = platform_get_resource(pdev_gpu, IORESOURCE_MEM, 0);
	if (!res)
		return gcvSTATUS_NOT_FOUND;

	args->irqs[core] = irqLine;
	args->registerBases[core] = res->start;
	args->registerSizes[core] = res->end - res->start + 1;

	if (args->compression == -1) {
		const u32 *property;

		args->compression = gcvCOMPRESSION_OPTION_DEFAULT;
		property = of_get_property(pdev->dev.of_node,
				"depth-compression", NULL);

		if (property && *property == 0)
			args->compression &= ~gcvCOMPRESSION_OPTION_DEPTH;
	}

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM,
			"phys_baseaddr");
	if (res && !args->baseAddress && !args->physSize) {
		args->baseAddress = res->start;
		args->physSize = res->end - res->start + 1;
	}

	res = platform_get_resource_byname(pdev, IORESOURCE_MEM,
			"contiguous_mem");
	if (res) {
		if (args->contiguousBase == 0)
			args->contiguousBase = res->start;
		if  (args->contiguousSize == ~0U)
			args->contiguousSize = res->end - res->start + 1;
	}

	if (args->contiguousSize == ~0U) {
		pr_warn("No contiguous memory is reserverd for gpu.\n");
		pr_warn("Will use default value(%d).\n",
				gcdFSL_CONTIGUOUS_SIZE);

		args->contiguousSize = gcdFSL_CONTIGUOUS_SIZE;
	}

	args->gpu3DMinClock = initgpu3DMinClock;

	if (args->physSize == 0) {
		args->baseAddress = LS_PHYS_BASE;
		args->physSize = LS_PHYS_SIZE;
	}

	return gcvSTATUS_OK;
}

static const struct of_device_id gpu_match[] = {
	{ .compatible = "fsl,ls1028a-gpu"},
	{ /* sentinel */ }
};

struct soc_platform_ops ls_platform_ops = {
	.adjustParam  = ls_adjust_param,
};

static struct soc_platform ls_platform = {
	.name = __FILE__,
	.ops  = &ls_platform_ops,
};

int soc_platform_init(struct platform_driver *pdrv,
		struct soc_platform **platform)
{
	pdrv->driver.of_match_table = gpu_match;
	*platform = &ls_platform;

	return 0;
}

int soc_platform_terminate(struct soc_platform *platform)
{
	return 0;
}
