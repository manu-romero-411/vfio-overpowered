#!/bin/bash

LIBVIRT_LOCAL_DIR="/home/manuel/.libvirt"

mdadm --stop /dev/md0

# Encuentra todos los archivos montados que coinciden con el patrón
for file in $(losetup -a | grep "$LIBVIRT_LOCAL_DIR/virtual-raid/${MAQUINA_VM}_" | cut -d ':' -f 1); do
    echo "Desmontando $file"

    # Desmonta cada archivo encontrado
    losetup -d $file
done
