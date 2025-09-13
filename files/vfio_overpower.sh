#!/usr/bin/env bash

realpath=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${realpath}/vfio.env
source ${realpath}/scripts/iommu_handle.sh
source ${realpath}/scripts/extra/cpufreq.sh
source ${realpath}/scripts/extra/hugepages.sh
source ${realpath}/scripts/extra/intel_gvtg.sh
source ${realpath}/scripts/extra/vdisk.sh

function set_cpufreq(){
    if [ $(vfio_json_parser "${1}" --cpufreq) -eq 1 ]; then
        case $2 in:
            "prepare") set_ondemand;;
            "release") set_performance;;
            *) true;;
        esac
    fi
}

function set_hugepages(){
    if [ $(vfio_json_parser "${1}" --hugepages) -eq 1 ]; then
        case $2 in:
            "prepare") hugepages_allocate ${group};;
            "release") hugepages_deallocate ${group};;
        esac
    fi
}

function set_intel_gvtg(){
    #cpu_name=$(cat /proc/cpuinfo | grep model | grep name | head -n 1 | cut -d":" -f2 | xargs echo -n)
    #if echo ${cpu_name} | grep "Intel"; then
    if [ $(vfio_json_parser "${1}" --gvtg) -eq 1 ]; then
        case $2 in:
            "prepare") vdisk_setup ${group};;
            "release") vdisk_unsetup ${group};;
        esac
    fi
    #fi
}

function set_vdisk(){
    disk=$(vfio_json_parser "${1}" --vdisk)
    if [ ! -z ${disk} ] && [ -e "/dev/disk/by-uuid/${disk}"]; then
        case $2 in:
            "prepare") vdisk_setup ${group};;
            "release") vdisk_unsetup ${group};;
        esac
    fi
}

function get_iommu_groups(){
    if [ $(vfio_json_parser "${1}" --iommu "${2}") -eq 1 ]; then
        echo 1
    fi
    echo 0
}

function iommu_main(){
    for i in "${KERNEL_IOMMU_PATH}"/*; do
        group=$(basename "$i")
        if [ $(get_iommu_groups ${1} ${group}) -eq 1 ]; then
            case $2 in:
                "prepare") isolate_iommu ${group};;
                "release") release_iommu ${group};;
            esac
        fi
    done
}

if [ -z $1 ] || [ ! -z $3 ]; then
    exit 1
fi
 
mode=""

case "$2" in
    "-p"|"--prepare"|"--on") mode=prepare ;;
    "-r"|"--release"|"--off") mode=release ;;
    *) exit 1;;
esac

iommu_main "${1}" "${mode}"
set_vdisk "${1}" "${mode}"
set_intel_gvtg "${1}" "${mode}"
set_hugepages "${1}" "${mode}"
set_cpufreq "${1}" "${mode}"

exit 0