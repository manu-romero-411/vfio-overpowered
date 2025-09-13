#!/bin/bash

rootdir=$(dirname "$(realpath $0)")
source "${rootdir}/vfio.env"
source "${rootdir}/scripts/single_gpu_prepare.sh"
source "${rootdir}/scripts/single_gpu_release.sh"
source "${rootdir}/scripts/vfio_bind_handle.sh"

function isolate_iommu(){
    modprobe vfio
    modprobe vfio_pci
    modprobe vfio_iommu_type1

    iommu_act=$1
    num_iommu_total=$(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 | wc -l)
    if [ "${iommu_act}" -ge "${num_iommu_total}" ] || [ "${iommu_act}" -lt 0 ]; then
        return 1
    fi

    for i in "${KERNEL_IOMMU_PATH}/${iommu_act}/devices/"*; do
        vendor_id=$(cat "${i}/vendor" | cut -d "x" -f2)
        device_id=$(cat "${i}/device" | cut -d "x" -f2)
        driver_name=$(cat "${i}/uevent" | grep "DRIVER" | cut -d "=" -f2)
        pci_node=$(cat "${i}/uevent" | grep "PCI_SLOT_NAME" | cut -d "=" -f2)

        mkdir -p /tmp/vfio/devices
        if [ ! -f "/tmp/vfio/devices/${vendor_id}-${device_id}" ]; then
            echo "${driver_name}" | tee "/tmp/vfio/devices/${vendor_id}-${device_id}"
        fi

        single_vga_pt=$(check_single_pt "${vendor_id}" "${device_id}")

        if [ -z "${single_vga_pt}" ]; then
            ## CASO GENERAL: CUALQUIER DISPOSITIVO
            vfio_bind "${pci_node}" "${vendor_id}" "${device_id}" "${driver_name}"
        else
            case "${single_vga_pt}" in
                "nvidia")
                    # GPU NVIDIA
                    unbind_gui_and_tty
                    nvidia_bind
                    vfio_bind_alt "${pci_node}" "${vendor_id}" "${device_id}" "${driver_name}"
                    ;;
                "amd")
                    # GPU AMD
                    unbind_gui_and_tty
                    amd_bind
                    vfio_bind_alt ${pci_node} ${vendor_id} ${device_id} ${driver_name}
                    ;;
                "intel")
                    # GPU INTEL
                    unbind_gui_and_tty
                    intel_bind
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
    modprobe -r vfio_pci
    modprobe -r vfio_iommu_type1
    modprobe -r vfio

    iommu_act=$1
    num_iommu_total=$(ls /sys/kernel/iommu_groups/ | tr " " "\n" | wc -l)
    if [ ${iommu_act} -ge ${num_iommu_total} ] || [ ${iommu_act} -lt 0 ]; then
        return 1
    fi

    for i in "${KERNEL_IOMMU_PATH}/${iommu_act}/devices/"*; do
        vendor_id=$(cat "${i}/vendor" | cut -d "x" -f2)
        device_id=$(cat "${i}/device" | cut -d "x" -f2)
        driver_name=$(cat "/tmp/vfio/devices/${vendor_id}-${device_id}")
        pci_node=$(cat "${i}/uevent" | grep PCI_SLOT_NAME | cut -d "=" -f2)

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
                    return_gui
                    ;;
                *)
                    true
                    ;;
            esac
        fi
    done
}