#!/usr/bin/env bash
rootdir=$(dirname "$(realpath $0)")
source "${rootdir}"/vfio.env

source "${VFIO_PATH}"/scripts/iommu_handle.sh
source "${VFIO_PATH}"/scripts/extra/cpufreq.sh
source "${VFIO_PATH}"/scripts/extra/hugepages.sh
source "${VFIO_PATH}"/scripts/extra/intel_gvtg.sh
source "${VFIO_PATH}"/scripts/extra/vdisk.sh
source "${VFIO_PATH}"/scripts/extra/cpu_isolate.sh
source "${VFIO_PATH}"/scripts/aux_/verbose.sh

function set_cpufreq(){
    if [ "$(python3 ${VFIO_PATH}/scripts/aux_/config_utils.py ${1} --cpufreq)" -eq 1 ]; then
        case $2 in
            "prepare") set_ondemand;;
            "release") set_performance;;
            *) true;;
        esac
    else
        echo_info "Ajuste de cpufreq no habilitado para ${1}."
    fi
}

function set_hugepages(){
    if [ "$(python3 ${VFIO_PATH}/scripts/aux_/config_utils.py ${1} --hugepages)" -eq 1 ]; then
        case $2 in
            "prepare") hugepages_allocate ${1};;
            "release") hugepages_deallocate ${1};;
        esac
    else
        echo_info "Ajuste de hugepages no habilitado para ${1}."
    fi
}

function set_intel_gvtg(){
    cpu_name=$(cat /proc/cpuinfo | grep model | grep name | head -n 1 | cut -d":" -f2 | xargs echo -n)
    if echo ${cpu_name} | grep "Intel"; then
        if [ $(python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py "${1}" --gvtg) -eq 1 ]; then
            case $2 in
                "prepare") gvtg_enable "${VFIO_GVTG_ID}";;
                "release") gvtg_disable "${VFIO_GVTG_ID}";;
            esac
        fi
    else
        echo_info "iGPU Intel HD 5-10gen no existente, o ajuste de GVT-g no habilitado para ${1}."
    fi
}

function set_vdisk(){
    unset disk
    disk=$(python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py "${1}" --vdisk)
    if [ -n "${disk}" ] && [ -e "/dev/disk/by-uuid/${disk}" ]; then
        case $2 in
            "prepare") vdisk_setup "${1}";;
            "release") vdisk_unsetup "${1}";;
        esac
    else
        echo_info "Ajuste de partición híbrida no habilitado para ${1}."
    fi
    unset disk
}

function set_cpuisolate(){
    unset cores_isol
    cores_isol=$(python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py "${1}" --cpuisolate)
    if [ -n "${cores_isol}" ]; then
        case $2 in
            "prepare") cpu_isolate "${cores_isol}";;
            "release") cpu_recover "${cores_isol}";;
        esac
    else
        echo_info "Ajuste de cpu-pinning no habilitado para ${1}."
    fi
    unset cores_isol
}


function get_iommu_groups(){
    if [[ "$(python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py ${1} --iommu ${2})" == "1" ]]; then
        echo 1
    else
        echo 0
    fi
}

function iommu_main(){
    cp -r "/etc/libvirt/qemu/${1}.xml" /tmp
    for i in "${KERNEL_IOMMU_PATH}"/*; do
        group=$(basename "$i")
        if [[ "$(get_iommu_groups ${1} ${group})" == "1" ]]; then
            echo ${group} in
            echo_info "(Des)asignando grupo IOMMU ${group} para VM ${1}..."
            case $2 in
                "prepare") isolate_iommu "${group}";;
                "release") recover_iommu "${group}";;
            esac
        else
            echo ${group} out
            # PARAR LA MÁQUINA VIRTUAL SI HAY ALGÚN DISPOSITIVO NO COLOCADO EN LA CONFIG
            if [[ "$2" == "prepare" ]]; then
                for j in "${KERNEL_IOMMU_PATH}/${group}/devices"/*; do
                    domain=$(basename "$j" | cut -d":" -f1)
                    bus=$(basename "$j" | cut -d":" -f2)
                    slot=$(basename "$j" | cut -d":" -f3 | cut -d"." -f1)
                    function1=$(basename "$j" | cut -d":" -f3 | cut -d"." -f2)
                    string="<address domain='0x${domain}' bus='0x${bus}' slot='0x${slot}' function='0x${function1}'/>"

                    if cat "/tmp/${1}.xml" | grep "${string}"; then
                        echo "Se está intentando usar un dispositivo no permitido. Configura IOMMU para esta máquina."
                        exit 1
                    fi
                done
            fi
        fi
    done
    rm /tmp/${1}.xml

}

function set_customhooks(){
    if [ -e "${VFIO_PATH}/custom_hooks/global_$(cat $BOARD_ID_PATH).sh" ]; then
        source "${VFIO_PATH}/custom_hooks/global_$(cat $BOARD_ID_PATH).sh"
        case ${3} in
            "begin")
                case ${2} in
                    "prepare") global_begin_prepare ;;
                    "start") global_begin_start ;;
                    "started") global_begin_started ;;
                esac;;
            "end")
                case ${2} in
                    "stopped") global_end_stopped ;;
                    "release") global_end_release "${4}" ;;
                esac;;
            *)
                echo_error "Parámetros de qemuhooks incorrectos."
                return 1 ;;
        esac
    else
        echo_info "Custom qemuhooks no habilitados de forma global."
    fi

    if [ -e "${VFIO_PATH}/custom_hooks/${1}_$(cat $BOARD_ID_PATH).sh" ]; then
        source "${VFIO_PATH}/custom_hooks/${1}_$(cat $BOARD_ID_PATH).sh"
        case ${3} in
            "begin")
                case ${2} in
                    "prepare") begin_prepare ;;
                    "start") begin_start ;;
                    "started") begin_started ;;
                esac
                ;;
            "end")
                case ${2} in
                    "stopped") end_stopped ;;
                    "release") end_release "${4}" ;;
                esac;;
            *)
                echo_error "Parámetros de qemuhooks incorrectos."
                return 1;;
        esac
    else
        echo_info "Custom qemuhooks no habilitados para ${1}."
    fi
}

function gen_configfiles(){
    echo_info "Comprobando si están creados los archivos de config para ${1}..."
    python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py "${1}" --genconfig keep
    python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py "${1}" --genhook keep
    python3 "${VFIO_PATH}"/scripts/aux_/config_utils.py "global" --genhook keep
}

if [ -z "$1" ] || [ -n "$5" ]; then
    exit 1
fi

mode=""

case "$2" in
    "-p"|"--prepare"|"--on"|"prepare") mode=prepare ;;
    "-s"|"--start"|"start") mode=start ;;
    "-t"|"--started"|"started") mode=started ;;
    "-k"|"--stopped"|"stopped") mode=stopped ;;
    "-r"|"--release"|"--off"|"release") mode=release ;;
    *) exit 1;;
esac

if [[ "$mode" == "prepare" ]] || [[ "$mode" == "release" ]]; then
    echo_info "MÁQUINA VIRTUAL ${1} - modo ${mode}"
    gen_configfiles "${1}"
    iommu_main "${1}" "${mode}"
    set_cpuisolate "${1}" "${mode}"
    set_vdisk "${1}" "${mode}"
    set_intel_gvtg "${1}" "${mode}"
    set_hugepages "${1}" "${mode}"
    set_cpufreq "${1}" "${mode}"
fi

set_customhooks "${1}" "${mode}" "${3}" "${4}"
exit 0
