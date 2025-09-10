import os
import subprocess

VFIO_PATH = "/penguin/desarrollo/vfio-overpower/files"
LIBVIRT_PATH = "/etc/libvirt"
BOARD_ID = subprocess.getoutput("cat /sys/devices/virtual/dmi/id/board_name")
KERNEL_IOMMU_PATH = "/sys/kernel/iommu_groups"
IOMMU_DATA_PATH = "/tmp/vfio/iommu_groups"