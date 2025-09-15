#!/bin/bash

function return_gui(){
    echo_info "Reiniciando consolas virtuales..."
    input2="/tmp/vfio-bound-consoles"
    while read -r consoleNumber; do
    if test -x /sys/class/vtconsole/vtcon"${consoleNumber}"; then
        if [ "$(grep -c "frame buffer" "/sys/class/vtconsole/vtcon${consoleNumber}/name")" \
            = 1 ]; then
            echo 1 > /sys/class/vtconsole/vtcon"${consoleNumber}"/bind
        fi
    fi
    done < "$input2"

    echo_info "Reiniciando sesión de escritorio..."
    input="/tmp/vfio-store-display-manager"
    while read -r DISPMGR; do
    if command -v systemctl > /dev/null; then
        ## Make sure the variable got collected ##
        systemctl start "$DISPMGR.service"
    else
        if command -v sv; then
        sv start "$DISPMGR"
        fi
    fi
    done < "$input"       
}

function nvidia_unbind(){
    if grep -q "true" "/tmp/vfio-is-nvidia" ; then
        echo_info "Reiniciando drivers de NVIDIA..."
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
        echo_info "Reiniciando drivers de AMD Radeon..."
        modprobe drm
        modprobe amdgpu
        modprobe radeon
        modprobe drm_kms_helper
    fi
    rm "/tmp/vfio-is-amd"
}

function i915_unbind(){
    if grep -q "true" "/tmp/vfio-is-i915" ; then
        echo_info "Restaurando nivel de brillo de la pantalla..."
        sleep 0.5
        echo $(cat "/tmp/brilloPantalla") > /sys/class/backlight/intel_backlight/brightness
    fi
    rm "/tmp/vfio-is-i915"
}

