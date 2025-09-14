#!/bin/bash

rootdir=$(dirname "$(realpath $0)")
source "${rootdir}/vfio.env"
source "${rootdir}/scripts/aux_/functions.sh"

function logout_gui(){
    ## Get display manager on systemd based distros ##
    if [[ -x /run/systemd/system ]]; then
        DISPMGR="$(grep 'ExecStart=' /etc/systemd/system/display-manager.service | awk -F'/' '{print $(NF-0)}')"

        ## Stop display manager using systemd ##
        if systemctl is-active --quiet "$DISPMGR.service"; then
            grep -qsF "$DISPMGR" "/tmp/vfio-store-display-manager" || echo "$DISPMGR" >/tmp/vfio-store-display-manager
            systemctl stop "$DISPMGR.service"
            systemctl isolate multi-user.target
        fi

        while systemctl is-active --quiet "$DISPMGR.service"; do
            sleep 0.5
        done
        return
    fi
}

function logout_gui_kde(){
    ## Stop display manager using systemd ##
    if systemctl is-active --quiet "display-manager.service"; then
        grep -qsF "display-manager" "/tmp/vfio-store-display-manager"  || echo "display-manager" >/tmp/vfio-store-display-manager
        systemctl stop "display-manager.service"
    fi

    while systemctl is-active --quiet "display-manager.service"; do
        sleep 0.5
    done
    return
}

function unbind_gui_and_tty(){
    if pgrep -l "plasma" | grep "plasmashell"; then
        logout_gui_kde
    else
        logout_gui
    fi

    ## Unbind EFI-Framebuffer ##
    if test -e "/tmp/vfio-is-nvidia"; then
        rm -f /tmp/vfio-is-nvidia
    elif test -e "/tmp/vfio-is-amd"; then
        rm -f /tmp/vfio-is-amd
    fi

    sleep 0.5

    if test -e "/tmp/vfio-bound-consoles"; then
        rm -f /tmp/vfio-bound-consoles
    fi

    for (( i = 0; i < 16; i++)); do
        if test -x /sys/class/vtconsole/vtcon"${i}"; then
            if [ "$(grep -c "frame buffer" /sys/class/vtconsole/vtcon"${i}"/name)" = 1 ]; then
                echo 0 > /sys/class/vtconsole/vtcon"${i}"/bind
                echo "$i" >> /tmp/vfio-bound-consoles
            fi
        fi
    done

    sleep "1"
}

function nvidia_bind(){
    echo "Deteniendo procesos auxiliares y residuales de NVIDIA..."
    systemctl stop nvidia-persistenced.service
    systemctl stop "systemd-backlight@backlight:nvidia_0.service"
    kill_proc nvidia
    kill_proc_fuser /dev/nvidia0

    echo "Deteniendo framebuffer efi..."
    grep -qsF "true" "/tmp/vfio-is-nvidia" || echo "true" >/tmp/vfio-is-nvidia
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
    systemctl stop "systemd-backlight@backlight:nvidia_0.service"

    ## Unload NVIDIA GPU drivers ##
    echo "Liberando módulos de NVIDIA..."
    modprobe -r nvidia_uvm
    modprobe -r nvidia_drm
    modprobe -r nvidia_modeset
    modprobe -r nvidia
    modprobe -r i2c_nvidia_gpu
    modprobe -r drm_kms_helper
    modprobe -r drm
}

function amd_bind(){
    grep -qsF "true" "/tmp/vfio-is-amd" || echo "true" >/tmp/vfio-is-amd
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

    ## Unload AMD GPU drivers ##
    modprobe -r drm_kms_helper
    modprobe -r amdgpu
    modprobe -r radeon
    modprobe -r drm
}

function intel_bind(){
    kill_proc i915
    #kill_proc_fuser /dev/nvidia0
}

function list_vga(){
    lspci -nn | grep -e VGA
}

function count_vga(){
    list_vga | wc -l
}

function check_single_pt(){
    if [ $(count_vga) -ne 1 ]; then
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

