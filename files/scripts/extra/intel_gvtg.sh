#!/bin/bash

function gvtg_disable(){
    echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/${1}/remove" \
    || (echo_error "Fallo al eliminar vGPU." && return 1)
    echo_success "vGPU eliminada."
    return 0
}

function gvtg_enable(){
    modprobe kvmgt mdev vfio-iommu-type1
    gvtg_gpu="/sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
    #echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/$VFIO_GVTG_ID/remove"
    echo "${1}" > "${gvtg_gpu}" \
    || (echo_error "Fallo al establecer vGPU en modo GVT-g." && return 1)
    echo_success "vGPU en modo GVT-g en ${gvtg_gpu}."
    return 0
}