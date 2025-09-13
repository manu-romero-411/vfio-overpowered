#!/bin/bash

function gvtg_disable(){
    echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/${1}/remove"
}

function gvtg_enable(){
    modprobe kvmgt mdev vfio-iommu-type1
    #echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/$VFIO_GVTG_ID/remove"
    echo "${1}" > "/sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
}