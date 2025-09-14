#!/usr/bin/env bash

rootdir=$(dirname "$(realpath $0)")
source "${rootdir}"/vfio.env
source "${rootdir}"/scripts/iommu_handle.sh
source "${rootdir}"/scripts/extra/cpufreq.sh
source "${rootdir}"/scripts/extra/hugepages.sh
source "${rootdir}"/scripts/extra/intel_gvtg.sh
source "${rootdir}"/scripts/extra/vdisk.sh
source "${rootdir}"/scripts/extra/cpu_isolate.sh

function set_cpufreq(){
    if [ "$(python3 ${rootdir}/scripts/aux_/config_utils.py ${1} --cpufreq)" -eq 1 ]; then
        case $2 in
            "prepare") set_ondemand;;
            "release") set_performance;;
            *) true;;
        esac
    else
        true
        #echo "null"
    fi
}

function set_hugepages(){
    if [ "$(python3 ${rootdir}/scripts/aux_/config_utils.py ${1} --hugepages)" -eq 1 ]; then
        case $2 in
            "prepare") hugepages_allocate ${1};;
            "release") hugepages_deallocate ${1};;
        esac
    else
        true
        #echo "null"
    fi
}

function set_intel_gvtg(){
    cpu_name=$(cat /proc/cpuinfo | grep model | grep name | head -n 1 | cut -d":" -f2 | xargs echo -n)
    if echo ${cpu_name} | grep "Intel"; then
        if [ $(python3 "${rootdir}"/scripts/aux_/config_utils.py "${1}" --gvtg) -eq 1 ]; then
            case $2 in
                "prepare") gvtg_enable "${1}";;
                "release") gvtg_disable "${1}";;
            esac
        fi
    else
        true
        #echo "null"
    fi
}

function set_vdisk(){
    unset disk
    disk=$(python3 "${rootdir}"/scripts/aux_/config_utils.py "${1}" --vdisk)
    if [ -n "${disk}" ] && [ -e "/dev/disk/by-uuid/${disk}" ]; then
        case $2 in
            "prepare") vdisk_setup "${1}";;
            "release") vdisk_unsetup "${1}";;
        esac
    else
        true
        #echo "null"
    fi
    unset disk
}

function set_cpuisolate(){
    unset cores_isol
    cores_isol=$(python3 "${rootdir}"/scripts/aux_/config_utils.py "${1}" --cpuisolate)
    if [ -n "${cores_isol}" ]; then
        case $2 in
            "prepare") cpu_isolate "${cores_isol}";;
            "release") cpu_recover "${cores_isol}";;
        esac
    else
        true
        #echo "null"
    fi
    unset cores_isol
}


function get_iommu_groups(){
    if [[ "$(python3 "${rootdir}"/scripts/aux_/config_utils.py ${1} --iommu ${2})" == "1" ]]; then
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

function set_customhooks(){
    if [ -e "${rootdir}/custom_hooks/${1}_$(cat $BOARD_ID_PATH).sh" ]; then
        source "${rootdir}/custom_hooks/global_$(cat $BOARD_ID_PATH).sh"
        source "${rootdir}/custom_hooks/${1}_$(cat $BOARD_ID_PATH).sh"
        case ${3} in
            "begin")
                case ${2} in
                    "prepare") 
                        global_begin_prepare
                        begin_prepare
                        ;;
                    "start") 
                        global_begin_start
                        begin_start
                        ;;
                    "started") 
                        global_begin_started
                        begin_started
                        ;;
                esac
                ;;
            "end")
                case ${2} in
                    "stopped")
                        global_end_stopped;
                        end_stopped
                        ;;
                    "release")
                        global_end_release "${4}"
                        end_release "${4}"
                        ;;
                esac
                ;;
            *)
                #echo "null"
                true
                ;;
        esac
    else
        #echo "null"
        true
    fi
}

function gen_configfiles(){
    python3 "${rootdir}"/scripts/aux_/config_utils.py "${1}" --genconfig keep
    python3 "${rootdir}"/scripts/aux_/config_utils.py "${1}" --genhook keep
    python3 "${rootdir}"/scripts/aux_/config_utils.py "global" --genhook keep
}

if [ -z "$1" ] || [ -n "$5" ]; then
    exit 1
fi
 
gen_configfiles "${1}"

mode=""

case "$2" in
    "-p"|"--prepare"|"--on"|"prepare") mode=prepare ;;
    "-s"|"--start"|"start") mode=start ;;
    "-t"|"--started"|"started") mode=started ;;
    "-k"|"--stopped"|"stopped") mode=stopped ;;
    "-r"|"--release"|"--off"|"release") mode=release ;;
    *) exit 1;;
esac

iommu_main "${1}" "${mode}" 
echo "======== cpu_isolate"
set_cpuisolate "${1}" "${mode}"
echo "======== vdisk"
set_vdisk "${1}" "${mode}"
echo "======== intel_gvtg"
set_intel_gvtg "${1}" "${mode}"
echo "======== hugepages"
set_hugepages "${1}" "${mode}"
echo "======== cpufreq"
set_cpufreq "${1}" "${mode}"
echo "======== customhooks"
set_customhooks "${1}" "${mode}" "${3}" "${4}"
exit 0