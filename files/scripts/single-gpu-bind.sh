#!/bin/bash

#############################################################################
##     ______  _                _  _______         _                 _     ##
##    (_____ \(_)              | |(_______)       | |               | |    ##
##     _____) )_  _   _  _____ | | _    _   _   _ | |__   _____   __| |    ##
##    |  ____/| |( \ / )| ___ || || |  | | | | | ||  _ \ | ___ | / _  |    ##
##    | |     | | ) X ( | ____|| || |__| | | |_| || |_) )| ____|( (_| |    ##
##    |_|     |_|(_/ \_)|_____) \_)\______)|____/ |____/ |_____) \____|    ##
##                                                                         ##
#############################################################################
###################### Credits ###################### ### Update PCI ID'S ###
## Lily (PixelQubed) for editing the scripts       ## ##                   ##
## RisingPrisum for providing the original scripts ## ##   update-pciids   ##
## Void for testing and helping out in general     ## ##                   ##
## .Chris. for testing and helping out in general  ## ## Run this command  ##
## WORMS for helping out with testing              ## ## if you dont have  ##
##################################################### ## names in you're   ##
## The VFIO community for using the scripts and    ## ## lspci feedback    ##
## testing them for us!                            ## ## in your terminal  ##
##################################################### #######################

################################# Variables #################################

## Adds current time to var for use in echo for a cleaner log and script ##
DATE=$(date +"%m/%d/%Y %R:%S :")

## Sets dispmgr var as null ##
DISPMGR="null"

################################## Script ###################################

echo "$DATE Beginning of Startup!"

function kill_proc(){
        systemctl --user -M 1000@ stop sunshine.service
        lsof -n | grep "$1" | awk '{print $2}' | awk '!seen[$0]++' | xargs -I {} kill -9 {}
        sleep 2
}

function kill_proc_fuser(){
        fuser -v "$1" | nl -b n | tail -n 1 | xargs -I {} kill -9 {}
}

function stop_display_manager_if_running {
    ## Get display manager on systemd based distros ##
    if [[ -x /run/systemd/system ]] && echo "$DATE Distro is using Systemd"; then
        DISPMGR="$(grep 'ExecStart=' /etc/systemd/system/display-manager.service | awk -F'/' '{print $(NF-0)}')"
        echo "$DATE Display Manager = $DISPMGR"

        ## Stop display manager using systemd ##
        if systemctl is-active --quiet "$DISPMGR.service"; then
            grep -qsF "$DISPMGR" "/tmp/vfio-store-display-manager" || echo "$DISPMGR" >/tmp/vfio-store-display-manager
            systemctl stop "$DISPMGR.service"
            systemctl isolate multi-user.target
        fi

        while systemctl is-active --quiet "$DISPMGR.service"; do
            sleep "1"
        done

        return

    fi
}

function kde-clause {

    echo "$DATE Display Manager = display-manager"

    ## Stop display manager using systemd ##
    if systemctl is-active --quiet "display-manager.service"; then
        grep -qsF "display-manager" "/tmp/vfio-store-display-manager"  || echo "display-manager" >/tmp/vfio-store-display-manager
        systemctl stop "display-manager.service"
    fi

        while systemctl is-active --quiet "display-manager.service"; do
                sleep 2
        done

    return

}

function vfio_load(){
    modprobe vfio
    modprobe vfio_pci
    modprobe vfio_iommu_type1

    echo $1
    echo $2
    echo $3

    VENDOR=$(echo $1 | cut -d: -f1)
    DEVICE=$(echo $1 | cut -d: -f2)
    DRIVER=$3

    echo "$VENDOR $DEVICE" > "/sys/bus/pci/drivers/vfio-pci/new_id"
    echo "$2" > "/sys/bus/pci/drivers/$DRIVER/unbind"
    echo "$2" > "/sys/bus/pci/drivers/vfio-pci/bind"
}

####################################################################################################################
## Checks to see if your running KDE. If not it will run the function to collect your display manager.            ##
## Have to specify the display manager because kde is weird and uses display-manager even though it returns sddm. ##
####################################################################################################################

if pgrep -l "plasma" | grep "plasmashell"; then
    echo "$DATE Display Manager is KDE, running KDE clause!"
    kde-clause
    else
        echo "$DATE Display Manager is not KDE!"
        stop_display_manager_if_running
fi

## Unbind EFI-Framebuffer ##
if test -e "/tmp/vfio-is-nvidia"; then
    rm -f /tmp/vfio-is-nvidia
    else
        test -e "/tmp/vfio-is-amd"
        rm -f /tmp/vfio-is-amd
fi

sleep "1"

##############################################################################################################################
## Unbind VTconsoles if currently bound (adapted and modernised from https://www.kernel.org/doc/Documentation/fb/fbcon.txt) ##
##############################################################################################################################
if test -e "/tmp/vfio-bound-consoles"; then
    rm -f /tmp/vfio-bound-consoles
fi
for (( i = 0; i < 16; i++))
do
  if test -x /sys/class/vtconsole/vtcon"${i}"; then
      if [ "$(grep -c "frame buffer" /sys/class/vtconsole/vtcon"${i}"/name)" = 1 ]; then
	       echo 0 > /sys/class/vtconsole/vtcon"${i}"/bind
           echo "$DATE Unbinding Console ${i}"
           echo "$i" >> /tmp/vfio-bound-consoles
      fi
  fi
done
sleep "1"

if lspci -nn | grep -e VGA | grep -s NVIDIA ; then
    systemctl stop nvidia-persistenced.service
    systemctl stop "systemd-backlight@backlight:nvidia_0.service"
    kill_proc nvidia
    kill_proc_fuser /dev/nvidia0

    echo "$DATE System has an NVIDIA GPU"
    grep -qsF "true" "/tmp/vfio-is-nvidia" || echo "true" >/tmp/vfio-is-nvidia
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
    systemctl stop "systemd-backlight@backlight:nvidia_0.service"

    ## Unload NVIDIA GPU drivers ##
    modprobe -r nvidia_uvm
    ps -aux | grep nvidia | grep backlight | awk '{print $2}' | xargs --no-run-if-empty kill -9 && modprobe -r nvidia_drm
    modprobe -r nvidia_modeset
    modprobe -r nvidia
    modprobe -r i2c_nvidia_gpu
    modprobe -r drm_kms_helper
    modprobe -r drm

    vfio_load "$@"
    echo "$DATE NVIDIA GPU Drivers Unloaded"
fi

if lspci -nn | grep -e VGA | grep -s AMD ; then
    echo "$DATE System has an AMD GPU"
    grep -qsF "true" "/tmp/vfio-is-amd" || echo "true" >/tmp/vfio-is-amd
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

    ## Unload AMD GPU drivers ##
    modprobe -r drm_kms_helper
    modprobe -r amdgpu
    modprobe -r radeon
    modprobe -r drm

    vfio_load "$@"
    echo "$DATE AMD GPU Drivers Unloaded"
fi

## Load VFIO-PCI driver ##

echo "$DATE End of Startup!"
