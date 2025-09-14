#!/bin/bash
## SCRIPT INDEPENDIENTE PARA EL SETUP DE VFIO EN INTEL
## FECHA: 21 de febrero de 2025

rootdir=$(realpath $(dirname $0))

function install_kabylake(){
  sudo mkdir -p /etc/libvirt/hooks

  ## Creating a GRUB variable equal to current content of grub cmdline.
  GRUB=$(cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT")
  GRUB="${GRUB#\"}"
  GRUB="${GRUB%\"}"

  for i in "intel_iommu=on" "video=efifb:off,vesafb:off" "kvm.ignore_msrs=1" "iommu=no-igfx" "video=vesafb:off" "i915.enable_gvt=1" "i915.enable_guc=0" "iommu=no-igfx" "mitigations=off"; do
    aux="${i#\"}"
    aux="${aux%\"}"
    if ! echo $GRUB | grep "${aux}"; then
      GRUB+=" ${aux}"
    fi
  done
  GRUB+="\""
  sudo sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub

  sudo update-grub

  echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-vfio.rules

  while [ true ]; do
      echo
      echo "Pulsa R y luego Intro para reiniciar..."
      read REBOOT

      if [ $REBOOT = "r" ]; then
          reboot
      fi
  done
}

function uninstall(){
  sudo rm -r /usr/local/etc/vfio
  sudo rm -r /etc/udev/rules.d/10-vfio.rules

  GRUB=$(cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | cut -d "=" -f2-)
  GRUB="${GRUB#\"}"
  GRUB="${GRUB%\"}"
  for i in "intel_iommu=on" "video=efifb:off,vesafb:off" "kvm.ignore_msrs=1" "iommu=no-igfx" "video=vesafb:off" "i915.enable_gvt=1" "i915.enable_guc=0" "iommu=no-igfx" "mitigations=off"; do
    if echo $GRUB | grep "${i}"; then
      GRUB=$(echo $GRUB | sed "s/${i}//")
    fi
  done
  GRUB=$(echo $GRUB | sed 's/ / /g' | sed 's/ $//')
  # Actualiza el archivo /etc/default/grub con las nuevas opciones
  sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB\"/" /etc/default/grub
  for i in ${rootdir}/scripts/*; do
      sudo rm -r /usr/local/bin/$(basename $i)
  done

  while [ true ]; do
      echo
      echo "Pulsa R y luego Intro para reiniciar..."
      read REBOOT

      if [ $REBOOT = "r" ]; then
          reboot
      fi
  done
}


if [[ $1 == "-u" ]] || [[ $1 == "--uninstall" ]]; then
	uninstall
	exit 0
fi

SEL=-1

while [ $SEL -eq -1 ]; do
	clear
	echo $SEL

	echo "SELECCIONA CONFIG DE VFIO"
	echo "01 - intel kaby lake laptop"
	echo "02 - amd rembrandt"
	# añadir configs aquí
	echo "==="
	read -n 2 -p "Número de la opción que quieres: " SEL
done
case $SEL in
	01) install_kabylake;;
#	02) install_amd_rembrandt;;
	*) exit 1;;
esac
