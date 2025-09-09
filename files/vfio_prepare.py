#!/usr/bin/env python3
import os
import subprocess
import json
import argparse

def isolate_iommu(group):
    print("aislando grupo iommu " + str(group))

def intel_gvtg(is_enabled):
    if is_enabled == True:
        print("habilitar gráfica virtual gvtg")
        print("o poner un mensajito si la cpu no es soportada (intel con F, intel <5 gen, intel >10 gen, amd, otros)")

def cpufreq_performance(is_enabled):
    if is_enabled == True:
        print("habilitar modo performnace")
        print("aprovecharse de asusctl en lo posible")

def vdisk_partition(disk_uuid):
    if os.path.isfile("/dev/disk/by-uuid/" + disk_uuid):
        subprocess.run(["/usr/local/etc/vfio/bin/vfio-vdisk-setup"])

def hugepages(vm_name, is_enabled):
    vm_xml_path = "/etc/libvirt/qemu/" + vm_name + ".xml"
    huge_in_xml = False

    if is_enabled == True and os.path.isfile(vm_xml_path):
        with open(vm_xml_path) as xml:
            if '<hugepages/>' in xml.read():
                huge_in_xml = True
                xml.close
    if huge_in_xml == True:
        subprocess.run(["/usr/local/etc/vfio/bin/vfio-alloc-hugepages"])


if __name__ == '__main__':
    parser = argparse.ArgumentParser("simple_example")
    parser.add_argument("file", help="File name", type=str)
    args = parser.parse_args()

    data = ""
    with open(args.file) as f:
        data = json.load(f)
        f.close

    vm_name = data["vm_name"]
    settings_dict = data["settings"]
    for i in data["iommu"]:
        isolate_iommu(i)

    intel_gvtg(settings_dict["intel_gvtg"])
    cpufreq_performance(settings_dict["cpufreq_performance"])
    vdisk_partition(settings_dict["vdisk_partition"])
    hugepages(vm_name, settings_dict["hugepages"])

    vm_tcp_forwards = data["tcp_forwards"]

    for i in list(vm_tcp_forwards):
        print(vm_tcp_forwards[i])
