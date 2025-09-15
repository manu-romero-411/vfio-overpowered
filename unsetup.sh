#!/bin/bash
set -e
if [ $(id -u) -ne 0 ]; then
    echo "You need root access for setting up this project. Leaving..."
    exit 1
fi

if [ -d "/usr/local/etc/vfio" ]; then
    rm -r "/usr/local/etc/vfio/"
fi

rm "/etc/libvirt/hooks/qemu"
rm "/usr/local/bin/vfio-edit-conf"
rm "/usr/local/bin/vfio-list-iommu"

exit 0
