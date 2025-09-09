#!/usr/bin/env python3
import os
import subprocess
import json
import argparse
import platform

from functions.check_cpu import check_cpu

vfio_path = "/penguin/desarrollo/vfio-overpower/files"
libvirt_path = "/etc/libvirt"
board_name = subprocess.getoutput("cat /sys/devices/virtual/dmi/id/board_name")

def isolate_iommu(group):
    print("aislando grupo iommu " + str(group))

def intel_gvtg(is_enabled):
    if is_enabled == True and check_cpu == True:
        subprocess.run([vfio_path + "/scripts/intel-gvt-enable.sh"])

def cpufreq_performance(is_enabled):
    if is_enabled == True:
        subprocess.run([vfio_path + "/scripts/cpufreq-performance.sh"])

def vdisk_partition(disk_uuid):
    if os.path.isfile("/dev/disk/by-uuid/" + disk_uuid):
        subprocess.run([vfio_path + "/scripts/vdisk-setup.sh"])

def hugepages(vm_name, is_enabled):
    vm_xml_path = libvirt_path + "/qemu/" + vm_name + ".xml"
    huge_in_xml = False

    if is_enabled == True and os.path.isfile(vm_xml_path):
        with open(vm_xml_path) as xml:
            if '<hugepages/>' in xml.read():
                huge_in_xml = True
                xml.close
    if huge_in_xml == True:
        subprocess.run([vfio_path + "/scripts/hugepages-alloc.sh"])

def vfio_prepare(vm_name):
    data = ""

    with open(os.path.join(vfio_path, "vm-config", vm_name + "_" + board_name + ".json")) as f:
        data = json.load(f)
        f.close

    vm_name = data["vm_name"]
    settings_dict = data["settings"]
    for i in data["iommu"]:
        isolate_iommu(i)

    intel_gvtg(settings_dict["intel_gvtg"])
    #cpufreq_performance(settings_dict["cpufreq_performance"])
    vdisk_partition(settings_dict["vdisk_partition"])
    hugepages(vm_name, settings_dict["hugepages"])

    vm_tcp_forwards = data["tcp_forwards"]

    for i in list(vm_tcp_forwards):
        print(vm_tcp_forwards[i])
