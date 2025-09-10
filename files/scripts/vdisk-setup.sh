#!/bin/bash
## CONVERTIR LA PARTICIÓN DE WINDOWS EN UN DISCO VIRTUAL PARA MÁQUINA VIRTUAL.
## FECHA: 17 de marzo de 2024

[[ -z $1 ]] && exit 1
[[ ! -z $2 ]] && exit 1

MAQUINA_VM="$1"
LIBVIRT_DIR="/home/manuel/.libvirt"
WIN_PART_ID="/dev/disk/by-id/usb-SanDisk_SSD_PLUS_240GB_012345678999-0:0-part3"
if [ $(id -u) -ne 0 ]; then
	echo "[ERROR] Se necesitan privilegios de administrador"
	exit 1
fi

if ! losetup -a | grep "$LIBVIRT_DIR/virtual-raid/${MAQUINA_VM}_efi"; then
	losetup -f "$LIBVIRT_DIR/virtual-raid/${MAQUINA_VM}_efi1.img"
	LOOP1=$(/sbin/losetup -a | grep "${MAQUINA_VM}_efi1.img" | awk '{print $1}' | cut -d ":" -f 1)
	losetup -f "$LIBVIRT_DIR/virtual-raid/${MAQUINA_VM}_efi2.img"
	LOOP2=$(/sbin/losetup -a | grep "${MAQUINA_VM}_efi2.img" | awk '{print $1}' | cut -d ":" -f 1)
	mdadm --build --verbose /dev/md0 --chunk=512 --level=linear --raid-devices=3 "$LOOP1" "$WIN_PART_ID" "$LOOP2"
#else
#	exit 1
fi
exit
