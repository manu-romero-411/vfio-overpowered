#!/bin/bash

function vfio_bind(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${vendor_id} ${device_id}" | tee /sys/bus/pci/drivers/vfio-pci/new_id
    echo "${pci_node}" | tee "/sys/bus/pci/drivers/${driver_name}/unbind"
    #sleep 0.5
    echo "${pci_node}" | tee "/sys/bus/pci/drivers/vfio-pci/bind"
}

# Se utiliza cuando se ha apagado el módulo original (por ejemplo para GPU Nvidia)
function vfio_bind_alt(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${vendor_id} ${device_id}" > "/sys/bus/pci/drivers/vfio-pci/new_id"
    echo "${pci_node}" > "/sys/bus/pci/drivers/vfio-pci/bind"
}


function vfio_unbind(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${pci_node}" | tee "/sys/bus/pci/drivers/vfio-pci/unbind"
    echo "${vendor_id} ${device_id}" | tee /sys/bus/pci/drivers/vfio-pci/remove_id
    echo "${pci_node}" | tee "/sys/bus/pci/drivers/${driver_name}/bind"
}

function vfio_unbind_alt(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${pci_node}" > "/sys/bus/pci/drivers/${driver_name}/bind"
    #echo "${vendor_id} ${device_id}" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
}
