#!/bin/bash
set -e

VFIO_INSTALL="/usr/local/etc/vfio"

if [ $(id -u) -ne 0 ]; then
    echo "You need root access for setting up this project. Leaving..."
    exit 1
fi

mkdir -p "/usr/local/bin" "${VFIO_INSTALL}"

if [ -d "${VFIO_INSTALL}" ]; then
    for i in scripts vfio.env vfio_overpower.sh; do
        if [ -e "${VFIO_INSTALL}/${i}" ]; then
            rm -r "${VFIO_INSTALL}/${i}"
        fi
    done
    if [ -e "/usr/local/bin/vfio-list-iommu" ]; then
        rm -r "/usr/local/bin/vfio-list-iommu"
    fi
    cp -r ./files/* "${VFIO_INSTALL}"
fi

cp "./external/vfio-edit-conf" "/usr/local/bin"
cp "./external/qemu" "/etc/libvirt/hooks/qemu"
cp "./external/hugepages.conf" "${VFIO_INSTALL}/hugepages.conf"
ln -s "${VFIO_INSTALL}/scripts/aux_/list_iommu_groups.sh" "/usr/local/bin/vfio-list-iommu"
chmod 755 "/etc/libvirt/hooks/qemu" "/usr/local/bin/vfio-edit-conf"

echo "VFIO_PATH=\"${VFIO_INSTALL}\"" >> "${VFIO_INSTALL}/vfio.env"

echo "[INFO] Instalado correctamente."
exit 0
