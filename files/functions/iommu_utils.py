import os
import subprocess
import functions.global_vars as globals
import json

def count_groups() -> int:
    """
    Retorna la cantidad de directorios numéricos en /sys/kernel/iommu_groups,
    que corresponden a cada grupo IOMMU.
    Si el directorio no existe o no hay permisos, devuelve 0.
    """

    try:
        entries = sorted(os.listdir(globals.KERNEL_IOMMU_PATH))
    except (FileNotFoundError, PermissionError):
        return 0

    # Filtrar subdirectorios que sean nombres numéricos
    cnt = 0
    for i in entries:
        dev_path = os.path.join(globals.KERNEL_IOMMU_PATH, i)
        if i.isdigit() and os.path.isdir(dev_path):
            cnt += 1

    return cnt

def get_group_devices(group_id) -> int:
    """
    Devuelve los id vendor:device de los dispositivos que pertenecen al citado grupo iommu
    """

    try:
        entries = sorted(os.listdir(os.path.join(globals.KERNEL_IOMMU_PATH, str(group_id), "devices")))
    except (FileNotFoundError, PermissionError):
        return []

    # Filtrar subdirectorios que sean nombres numéricos
    list = []
    for i in entries:
        vendor_id = subprocess.getoutput(\
            "cat " + os.path.join(globals.KERNEL_IOMMU_PATH, str(group_id), "devices", i, "vendor"))\
            .split("x")[1]
        device_id = subprocess.getoutput(\
            "cat " + os.path.join(globals.KERNEL_IOMMU_PATH, str(group_id), "devices", i, "device"))\
            .split("x")[1]
        list.append(vendor_id + ":" + device_id)
    return list

def get_uevent_data(group_id, uevent_item) -> int:
    """
    Devuelve los id vendor:device de los dispositivos que pertenecen al citado grupo iommu
    """

    try:
        entries = sorted(os.listdir(os.path.join(globals.KERNEL_IOMMU_PATH, str(group_id), "devices")))
    except (FileNotFoundError, PermissionError):
        return []

    # Filtrar subdirectorios que sean nombres numéricos
    list = []
    cnt = 1
    for i in entries:
        with open(os.path.join(globals.KERNEL_IOMMU_PATH, str(group_id), "devices", i, "uevent"), "r") as uevent_file:
            for line in uevent_file:
                if uevent_item + "=" in line:
                    list.append(line.strip().split("=")[1])  # .strip() elimina espacios y saltos de línea
                    uevent_file.close()
                    break  # Si solo quieres la primera coincidencia
            if len(list) < cnt:
                list.append("")
                uevent_file.close()
        cnt = cnt + 1

    return list

def get_dev_name_from_node(node):
    name = " ".join(subprocess.getoutput("lspci -s " + str(node)).split(" ")[1:])
    return name

def generate_group_files():
    """
    Genera ficheros .json con información de cada dispositivo y grupo IOMMU, para su uso posterior.
    """

    try:
        entries = sorted(os.listdir(os.path.join(globals.KERNEL_IOMMU_PATH)))
    except (FileNotFoundError, PermissionError):
        return

    # Filtrar subdirectorios que sean nombres numéricos
    dev_list = []
    nodes_list = []
    drivers_list = []
    cnt = 0
    #if not os.path.exists(globals.IOMMU_DATA_PATH):
    os.makedirs(globals.IOMMU_DATA_PATH, exist_ok=True)
    for i in entries:
        #os.makedirs(os.path.join(globals.IOMMU_DATA_PATH, str(cnt)), exist_ok=True)
        dev_list = get_group_devices(cnt)
        nodes_list = get_uevent_data(cnt, "PCI_SLOT_NAME")
        drivers_list = get_uevent_data(cnt, "DRIVER")

        devices_dict = {}

        for idx in range(len(dev_list)):
            vendor_id, vendor_dev = dev_list[idx].split(":")
            pci_info = ":".join(nodes_list[idx].split(":")[1:])  # "0000:01:00.0" → "01:00.0"
            pci_bus, slot_func = pci_info.split(":")
            pci_slot, pci_func = slot_func.split(".")

            devices_dict[f"device{idx}"] = {
                "device_name": get_dev_name_from_node(pci_info),
                "device_pci_bus": pci_bus,
                "device_pci_slot": pci_slot,
                "device_pci_func": pci_func,
                "device_vendor_id": vendor_id,
                "device_vendor_dev": vendor_dev,
                "default_linux_driver": drivers_list[idx]
            }

        # Guardar en archivo JSON
        with open(os.path.join(globals.IOMMU_DATA_PATH, "iommu_" + str(cnt) + ".json"), "w") as f:
            json.dump(devices_dict, f, indent=4)
            f.close

        cnt = cnt + 1
