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

def generate_group_file(group):
    #os.makedirs(os.path.join(globals.IOMMU_DATA_PATH, str(cnt)), exist_ok=True)
    dev_list = get_group_devices(group)
    nodes_list = get_uevent_data(group, "PCI_SLOT_NAME")
    drivers_list = get_uevent_data(group, "DRIVER")

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
    with open(os.path.join(globals.IOMMU_DATA_PATH, "iommu_" + str(group) + ".json"), "w") as f:
        json.dump(devices_dict, f, indent=4)
        f.close

def generate_all_group_files():
    """
    Genera ficheros .json con información de cada dispositivo y grupo IOMMU, para su uso posterior.
    """

    try:
        entries = sorted(os.listdir(os.path.join(globals.KERNEL_IOMMU_PATH)))
    except (FileNotFoundError, PermissionError):
        return

    os.makedirs(globals.IOMMU_DATA_PATH, exist_ok=True)
    for i in entries:
        generate_group_file(i)


def get_all_nodes():
    """
    Genera ficheros .json con información de cada dispositivo y grupo IOMMU, para su uso posterior.
    """

    try:
        entries = sorted(os.listdir(os.path.join(globals.KERNEL_IOMMU_PATH)))
    except (FileNotFoundError, PermissionError):
        return

    result = []
    os.makedirs(globals.IOMMU_DATA_PATH, exist_ok=True)
    for i in entries:
        nodes_list = get_uevent_data(i, "PCI_SLOT_NAME")
        for idx in range(len(nodes_list)):
            result.append(":".join(nodes_list[idx].split(":")[1:]))
    
    return result

def get_all_dev_names():
    ids = get_all_nodes()
    result = []
    for i in ids:
        result.append(get_dev_name_from_node(i))

    return result


def find_vga_gpus():
    vga_devices = []

    if not os.path.exists(globals.KERNEL_IOMMU_PATH):
        return vga_devices

    for group_path in sorted(os.listdir(os.path.join(globals.KERNEL_IOMMU_PATH))):
        devices_path = os.path.join(globals.KERNEL_IOMMU_PATH, group_path, "devices")
        if not os.path.exists(devices_path):
            continue
            
        if group_path == 14:
            print("")
        for dev_path in sorted(os.listdir(devices_path)):
            class_file = os.path.join(devices_path, dev_path, 'class')
            try:
                # lee código de clase PCI (hex) y lo convierte a entero
                with open(class_file, "r") as file:
                    cls = int(file.read().strip(), 16)
            
            except (FileNotFoundError, ValueError):
                continue

            # el byte alto 0x03 indica VGA/Display controller
            if (cls >> 16) == 0x03:
                vga_devices.append(dev_path)

    return vga_devices
