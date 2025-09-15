#!/bin/bash

for i in /sys/kernel/iommu_groups/*; do
	echo "=== IOMMU $(basename $i) ==="
	for j in $(find "${i}" -maxdepth 2 -mindepth 1 | grep "devices/" | rev | cut -d"/" -f1 | rev | cut -d":" -f2-); do
		lspci -nns "${j}"
	done
	echo ""
done
