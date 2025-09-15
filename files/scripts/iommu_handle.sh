#!/bin/bash

source "${VFIO_PATH}/scripts/single_gpu_prepare.sh"
source "${VFIO_PATH}/scripts/single_gpu_release.sh"
source "${VFIO_PATH}/scripts/vfio_bind_handle.sh"

function isolate_iommu(){
    modprobe vfio
    modprobe vfio_pci
    modprobe vfio_iommu_type1

    iommu_act=$1
    num_iommu_total=$(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 | wc -l)
    if [ "${iommu_act}" -ge "${num_iommu_total}" ] || [ "${iommu_act}" -lt 0 ]; then
        echo_error "Grupo IOMMU inválido en este sistema: ${iommu_act}."
        return 1
    fi

    for i in "${KERNEL_IOMMU_PATH}/${iommu_act}/devices/"*; do
        vendor_id=$(cat "${i}/vendor" | cut -d "x" -f2)
        device_id=$(cat "${i}/device" | cut -d "x" -f2)
        driver_name=$(cat "${i}/uevent" | grep "DRIVER" | cut -d "=" -f2)
        pci_node=$(cat "${i}/uevent" | grep "PCI_SLOT_NAME" | cut -d "=" -f2)

        echo_info "IOMMU ${iommu_act} - ${vendor_id}:${device_id} (${pci_node}) - ${driver_name}"
        mkdir -p /tmp/vfio/devices
        if [ ! -f "/tmp/vfio/devices/${vendor_id}-${device_id}" ]; then
            echo "${driver_name}" | tee "/tmp/vfio/devices/${vendor_id}-${device_id}" > /dev/null
        fi
        
        single_vga_pt=$(check_single_pt "${vendor_id}" "${device_id}")

        if [ -z "${single_vga_pt}" ]; then
            ## CASO GENERAL: CUALQUIER DISPOSITIVO
            vfio_bind "${pci_node}" "${vendor_id}" "${device_id}" "${driver_name}"
        else
            unbind_gui_and_tty
            case "${single_vga_pt}" in
                "nvidia")
                    # GPU NVIDIA
                    nvidia_bind
                    vfio_bind_alt "${pci_node}" "${vendor_id}" "${device_id}" "${driver_name}"
                    ;;
                "amd")
                    # GPU AMD
                    amd_bind
                    vfio_bind_alt ${pci_node} ${vendor_id} ${device_id} ${driver_name}
                    ;;
                "intel")
                    # GPU INTEL
                    if [[ "${driver_name}" == "i915" ]]; then
                        i915_bind
                    else
                        sleep 2 # Alguna buena forma habrá de gestionar el driver de las Intel ARC
                    fi
                    vfio_bind ${pci_node} ${vendor_id} ${device_id} ${driver_name}
                    ;;
                *)
                    true
                    ;;
            esac
        fi
    done
}

function recover_iommu(){
    echo_info "Deteniendo módulos de VFIO..."
    modprobe -r vfio_pci
    modprobe -r vfio_iommu_type1
    modprobe -r vfio

    iommu_act=$1
    num_iommu_total=$(ls /sys/kernel/iommu_groups/ | tr " " "\n" | wc -l)
    if [ ${iommu_act} -ge ${num_iommu_total} ] || [ ${iommu_act} -lt 0 ]; then
        echo_error "Grupo IOMMU inválido en este sistema: ${iommu_act}."
        return 1
    fi

    for i in "${KERNEL_IOMMU_PATH}/${iommu_act}/devices/"*; do
        vendor_id=$(cat "${i}/vendor" | cut -d "x" -f2)
        device_id=$(cat "${i}/device" | cut -d "x" -f2)
        driver_name=$(cat "/tmp/vfio/devices/${vendor_id}-${device_id}")
        pci_node=$(cat "${i}/uevent" | grep PCI_SLOT_NAME | cut -d "=" -f2)
        
        echo_info "IOMMU ${iommu_act} - ${vendor_id}:${device_id} (${pci_node}) - ${driver_name}"

        single_vga_pt=$(check_single_pt "${vendor_id}" "${device_id}")

        if [ -z "${single_vga_pt}" ]; then
            ## CASO GENERAL: CUALQUIER DISPOSITIVO
            vfio_unbind_alt "${pci_node}" "${vendor_id}" "${device_id}" "${driver_name}"
        else
            case "${single_vga_pt}" in
                "nvidia")
                    # GPU NVIDIA
                    nvidia_unbind
                    return_gui
                    ;;
                "amd")
                    # GPU AMD
                    amd_unbind
                    return_gui
                    ;;
                "intel")
                    # GPU INTEL
                    vfio_unbind_alt "${pci_node}" "${vendor_id}" "${device_id}" "${driver_name}"
                    i915_unbind
                    return_gui
                    ;;
                *)
                    true
                    ;;
            esac
        fi
    done
}