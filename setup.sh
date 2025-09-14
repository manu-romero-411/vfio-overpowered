#!/bin/bash
set -e

if [ $(id -u) -ne 0 ]; then
    echo "You need root access for setting up this project. Leaving..."
    exit 1
fi

if [ -d "/usr/local/etc/vfio" ]; then
    rm -r "/usr/local/etc/vfio/{scripts,vfio.env,vfio_overpower.sh}"
    cp -r ./files/* "/usr/local/etc/vfio/"
fi

mkdir -p "/usr/local/bin" "/usr/local/etc"
cp "./external/vfio-edit-conf" "/usr/local/bin"
cp "./external/qemu" "/etc/libvirt/hooks/qemu"
chmod 755 "/etc/libvirt/hooks/qemu" "/usr/local/bin/vfio-edit-conf"

exit 0
