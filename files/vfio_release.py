#!/usr/bin/env python3
import os
import time
import subprocess
import json
import functions.global_vars as globals
from functions.check_cpu import check_cpu
from functions import iommu_utils as iommu

def login_gui():
    subprocess.run(["systemctl", "start", "sddm"])

def nvidia_bind():
   # subprocess.run(["systemctl", "stop", "nvidia-persistenced.service"])
    modules = ("nvidia_uvm", "nvidia_drm", "nvidia_modeset",\
            "nvidia", "i2c_nvidia_gpu", "drm_kms_helper", "drm")
    for i in reversed(modules):
        subprocess.run(["modprobe", i])
        time.sleep(1)

def restore_iommu(group):
    if group > iommu.count_groups() - 1:
        return
    if group < 0:
        return
    dev_list = iommu.get_group_devices(group)
    nodes_list = iommu.get_uevent_data(group, "PCI_SLOT_NAME")
    drivers_list = iommu.get_uevent_data(group, "DRIVER")
    gpu_list = iommu.find_vga_gpus()

    for i in range(len(dev_list)):
        print("vfio newid")
        with open("/sys/bus/pci/drivers/vfio-pci/remove_id", "w") as new_id:
            subprocess.run(["echo " + " ".join(dev_list[i].split(":"))], stdout=new_id, shell=True)
            new_id.close

        time.sleep(1)
        print("vfio bind" + nodes_list[i])
        with open("/sys/bus/pci/drivers/vfio-pci/unbind", "w") as bind:
            subprocess.run(["echo " + nodes_list[i]], stdout=bind, shell=True)
            bind.close

        time.sleep(1)
        print("driver unbind")
        if os.path.exists(os.path.join("/sys/bus/pci/drivers", drivers_list[i], "bind")):
            with open("/sys/bus/pci/drivers/" + drivers_list[i] + "/unbind", "w") as unbind:
                subprocess.run(["echo " + nodes_list[i]], stdout=unbind, shell=True)
                unbind.close

        if drivers_list[i] == "nvidia":
            nvidia_bind()

    if len(gpu_list) == 1:
        login_gui()

def intel_gvtg(is_enabled):
    if is_enabled == True and check_cpu == True:
        subprocess.run([globals.VFIO_PATH + "/scripts/intel-gvt-disable.sh"])

def cpufreq_performance(is_enabled):
    if is_enabled == True:
        subprocess.run([globals.VFIO_PATH + "/scripts/cpufreq-ondemand.sh"])

def vdisk_partition(disk_uuid):
    if os.path.isfile("/dev/disk/by-uuid/" + disk_uuid):
        subprocess.run([globals.VFIO_PATH + "/scripts/vdisk-unsetup.sh"])

def hugepages(vm_name, is_enabled):
    vm_xml_path = globals.LIBVIRT_PATH + "/qemu/" + vm_name + ".xml"
    huge_in_xml = False

    if is_enabled == True and os.path.isfile(vm_xml_path):
        with open(vm_xml_path) as xml:
            if '<hugepages/>' in xml.read():
                huge_in_xml = True
                xml.close
    if huge_in_xml == True:
        subprocess.run([globals.VFIO_PATH + "/scripts/hugepages-dealloc.sh"])

def vfio_release(vm_name):
    data = ""

    with open(os.path.join(globals.VFIO_PATH, "vm-config", vm_name + "_" + globals.BOARD_ID + ".json")) as f:
        data = json.load(f)
        f.close

    vm_name = data["vm_name"]
    settings_dict = data["settings"]

    intel_gvtg(settings_dict["intel_gvtg"])
    cpufreq_performance(settings_dict["cpufreq_performance"])
    vdisk_partition(settings_dict["vdisk_partition"])
    hugepages(vm_name, settings_dict["hugepages"])

    vm_name = data["vm_name"]
    settings_dict = data["settings"]
    for i in data["iommu"]:
        restore_iommu(i)


    vm_tcp_forwards = data["tcp_forwards"]

    for i in list(vm_tcp_forwards):
        print(vm_tcp_forwards[i])
