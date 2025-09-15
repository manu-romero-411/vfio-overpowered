#!/bin/bash

function vfio_bind(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo_info "Enlazando ${vendor_id}:${device_id} a vfio_pci..."
    
    echo "${vendor_id} ${device_id}" | tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null \
    || echo_error "No se ha podido registrar ${vendor_id}:${device_id} en el módulo vfio_pci."

    echo "${pci_node}" | tee "/sys/bus/pci/drivers/${driver_name}/unbind" > /dev/null \
    || echo_error "No se ha podido desvincular ${vendor_id}:${device_id} del módulo ${driver_name}."
    
    echo "${pci_node}" | tee "/sys/bus/pci/drivers/vfio-pci/bind" > /dev/null \
    || echo_error "No se ha podido vincular ${vendor_id}:${device_id} al vfio-pci."
}

# Se utiliza cuando se ha apagado el módulo original (por ejemplo para GPU Nvidia)
function vfio_bind_alt(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${vendor_id} ${device_id}" | tee "/sys/bus/pci/drivers/vfio-pci/new_id" > /dev/null \
    || echo_error "No se ha podido registrar ${vendor_id}:${device_id} en el módulo vfio_pci."
    echo "${pci_node}" | tee "/sys/bus/pci/drivers/vfio-pci/bind" > /dev/null \
    || echo_error "No se ha podido vincular ${vendor_id}:${device_id} al vfio_pci."
}


function vfio_unbind(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${pci_node}" | tee "/sys/bus/pci/drivers/vfio-pci/unbind" > /dev/null \
    || echo_error "No se ha podido desvincular ${vendor_id}:${device_id} del vfio-pci."

    echo "${vendor_id} ${device_id}" | tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null \
    || echo_error "No se ha podido deregistrar ${vendor_id}:${device_id} del módulo vfio_pci."

    vfio_unbind_alt ${@}
}

function vfio_unbind_alt(){
    pci_node=$1
    vendor_id=$2
    device_id=$3
    driver_name=$4

    echo "${pci_node}" | tee "/sys/bus/pci/drivers/${driver_name}/bind" > /dev/null \
    || echo_error "No se ha podido vincular ${vendor_id}:${device_id} al módulo ${driver_name}."
}
