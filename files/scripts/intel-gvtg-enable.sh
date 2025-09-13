#!/bin/bash

VFIO_GVTG_ID="af5972fb-5530-41a7-0000-fd836204445b"

modprobe kvmgt mdev vfio-iommu-type1
#echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/$VFIO_GVTG_ID/remove"
echo "$VFIO_GVTG_ID" > "/sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"

