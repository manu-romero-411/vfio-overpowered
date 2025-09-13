#!/bin/bash

function return_gui(){
    input="/tmp/vfio-store-display-manager"
    while read -r DISPMGR; do
    if command -v systemctl; then
        ## Make sure the variable got collected ##
        systemctl start "$DISPMGR.service"
    else
        if command -v sv; then
        sv start "$DISPMGR"
        fi
    fi
    done < "$input"

    input2="/tmp/vfio-bound-consoles"
    while read -r consoleNumber; do
    if test -x /sys/class/vtconsole/vtcon"${consoleNumber}"; then
        if [ "$(grep -c "frame buffer" "/sys/class/vtconsole/vtcon${consoleNumber}/name")" \
            = 1 ]; then
            echo 1 > /sys/class/vtconsole/vtcon"${consoleNumber}"/bind
        fi
    fi
    done < "$input2"
}

function nvidia_unbind(){
    if grep -q "true" "/tmp/vfio-is-nvidia" ; then
        ## Load NVIDIA drivers ##
        echo "Cargando módulos de NVIDIA..."
        modprobe drm
        modprobe drm_kms_helper
        modprobe i2c_nvidia_gpu
        modprobe nvidia
        modprobe nvidia_modeset
        modprobe nvidia_drm
        modprobe nvidia_uvm
    fi
    rm "/tmp/vfio-is-nvidia"
}

function amd_unbind(){
    if  grep -q "true" "/tmp/vfio-is-amd" ; then
        ## Load AMD drivers ##
        modprobe drm
        modprobe amdgpu
        modprobe radeon
        modprobe drm_kms_helper
    fi
    rm "/tmp/vfio-is-amd"
}


function intel_unbind(){
    kill_proc i915
    #kill_proc_fuser /dev/nvidia0
}

function list_vga(){
    lspci -nn | grep -e VGA
}

function check_single_pt(){
    if [ $(list_vga | wc -l) -ne 1 ]; then
        return
    fi

    if list_vga | grep "${1}:${2}" > /dev/null 2>&1; then
        if list_vga | grep NVIDIA > /dev/null 2>&1; then
            echo nvidia
        elif list_vga | grep AMD > /dev/null 2>&1; then
            echo amd
        elif list_vga | grep Intel > /dev/null 2>&1; then
            echo intel
        else
            echo ""
        fi
    else
        echo ""
    fi
}

function single_gpu_passthrough(){
    unbind_gui_and_tty
    case $1 in
        "nvidia") nvidia_bind;;
        "amd") amd_bind;;
        *) true;;
    esac
}

