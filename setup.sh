#!/bin/bash
set -e

VFIO_INSTALL="/usr/local/etc/vfio"

if [ $(id -u) -ne 0 ]; then
    echo "You need root access for setting up this project. Leaving..."
    exit 1
fi

mkdir -p "/usr/local/bin" "${VFIO_INSTALL}"

if [ -d "${VFIO_INSTALL}" ]; then
    rm -r "${VFIO_INSTALL}/{scripts,vfio.env,vfio_overpower.sh}"
    cp -r ./files/* "${VFIO_INSTALL}"
fi

cp "./external/vfio-edit-conf" "/usr/local/bin"
cp "./external/qemu" "/etc/libvirt/hooks/qemu"
cp "./external/hugepages.conf" "/etc/libvirt/hooks/qemu"
chmod 755 "/etc/libvirt/hooks/qemu" "/usr/local/bin/vfio-edit-conf"

echo "VFIO_PATH=\"${VFIO_INSTALL}\"" >> "${VFIO_INSTALL}/vfio.env"

exit 0
