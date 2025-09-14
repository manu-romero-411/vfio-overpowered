#!/bin/bash
## CONVERTIR LA PARTICIÓN DE WINDOWS EN UN DISCO VIRTUAL PARA MÁQUINA VIRTUAL.
## FECHA: 17 de marzo de 2024

function vdisk_setup(){
	[[ -z $1 ]] && return 1
	[[ ! -z $2 ]] && return 1

	MAQUINA_VM="$1"
	LIBVIRT_DIR="/home/manuel/.libvirt"
	WIN_PART_ID="/dev/disk/by-id/usb-SanDisk_SSD_PLUS_240GB_012345678999-0:0-part3"
	if [ $(id -u) -ne 0 ]; then
		echo "[ERROR] Se necesitan privilegios de administrador"
		return 1
	fi

	if ! losetup -a | grep "$LIBVIRT_DIR/virtual-raid/${MAQUINA_VM}_efi"; then
		losetup -f "$LIBVIRT_DIR/virtual-raid/${MAQUINA_VM}_efi1.img"
		LOOP1=$(/sbin/losetup -a | grep "${MAQUINA_VM}_efi1.img" | awk '{print $1}' | cut -d ":" -f 1)
		losetup -f "$LIBVIRT_DIR/virtual-raid/${MAQUINA_VM}_efi2.img"
		LOOP2=$(/sbin/losetup -a | grep "${MAQUINA_VM}_efi2.img" | awk '{print $1}' | cut -d ":" -f 1)
		mdadm --build --verbose /dev/md0 --chunk=512 --level=linear --raid-devices=3 "$LOOP1" "$WIN_PART_ID" "$LOOP2"
	#else
	#	return 1
	fi
	return
}

function vdisk_unsetup(){
	LIBVIRT_LOCAL_DIR="/home/manuel/.libvirt"

	mdadm --stop /dev/md0

	# Encuentra todos los archivos montados que coinciden con el patrón
	for file in $(losetup -a | grep "$LIBVIRT_LOCAL_DIR/virtual-raid/${MAQUINA_VM}_" | cut -d ':' -f 1); do
		echo "Desmontando $file"

		# Desmonta cada archivo encontrado
		losetup -d $file
	done
}