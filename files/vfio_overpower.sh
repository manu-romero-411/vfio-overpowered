#!/usr/bin/env bash

rootdir=$(dirname "$(realpath $0)")
source "${rootdir}"/vfio.env
source "${rootdir}"/scripts/iommu_handle.sh
source "${rootdir}"/scripts/extra/cpufreq.sh
source "${rootdir}"/scripts/extra/hugepages.sh
source "${rootdir}"/scripts/extra/intel_gvtg.sh
source "${rootdir}"/scripts/extra/vdisk.sh

function set_cpufreq(){
    if [ $(python3 "${rootdir}"/scripts/aux_/vfio_parse_json.py "${1}" --cpufreq) -eq 1 ]; then
        case $2 in
            "prepare") set_ondemand;;
            "release") set_performance;;
            *) true;;
        esac
    fi
}

function set_hugepages(){
    if [ $(python3 "${rootdir}"/scripts/aux_/vfio_parse_json.py "${1}" --hugepages) -eq 1 ]; then
        case $2 in
            "prepare") hugepages_allocate ${1};;
            "release") hugepages_deallocate ${1};;
        esac
    fi
}

function set_intel_gvtg(){
    #cpu_name=$(cat /proc/cpuinfo | grep model | grep name | head -n 1 | cut -d":" -f2 | xargs echo -n)
    #if echo ${cpu_name} | grep "Intel"; then
    if [ $(python3 "${rootdir}"/scripts/aux_/vfio_parse_json.py "${1}" --gvtg) -eq 1 ]; then
        case $2 in
            "prepare") vdisk_setup "${1}";;
            "release") vdisk_unsetup "${1}";;
        esac
    fi
    #fi
}

function set_vdisk(){
    disk=$(python3 "${rootdir}"/scripts/aux_/vfio_parse_json.py "${1}" --vdisk)
    echo "intentando tocar el disco ${disk}" 
    if [ ! -z ${disk} ] && [ -e "/dev/disk/by-uuid/${disk}" ]; then
        case $2 in
            "prepare") vdisk_setup "${1}";;
            "release") vdisk_unsetup "${1}";;
        esac
    fi
}

function get_iommu_groups(){
    if [[ "$(python3 "${rootdir}"/scripts/aux_/vfio_parse_json.py ${1} --iommu ${2})" == "1" ]]; then
        echo 1
    else 
        echo 0
    fi
}

function iommu_main(){
    for i in "${KERNEL_IOMMU_PATH}"/*; do
        group=$(basename "$i")
        #echo $(get_iommu_groups ${1} ${group}) ${group}
        if [[ "$(get_iommu_groups ${1} ${group})" == "1" ]]; then
            #echo "$1 $2 ${group}"
            case $2 in
                "prepare") isolate_iommu "${group}";;
                "release") recover_iommu "${group}";;
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