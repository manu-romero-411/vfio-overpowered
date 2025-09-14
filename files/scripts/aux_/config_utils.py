#!/usr/bin/env python3
import json
import os
import argparse
import re
import subprocess

import json

import os
import stat

def generate_customhook(name: str, path: str):
    banner_start = ""
    global_func_name = ""

    if name == "global":
        banner_start = "CUSTOM GLOBAL QEMU HOOKS"
        global_func_name = "global_"
    else:
        banner_start = f"CUSTOM QEMU HOOKS FOR {name}"

    content = f"""#!/bin/bash
## {banner_start}
## MORE INFO AT https://libvirt.org/hooks.html

# Before libvirt allocates resources
function {global_func_name}begin_prepare(){{
    true
}}

# Before libvirt starts VM
function {global_func_name}begin_start(){{
    true
}}

# After libvirt starts VM (the VM may have not fully booted)
function {global_func_name}begin_started(){{
    true
}}

# After VM stops, before libvirt restores any labels
function {global_func_name}end_stopped(){{
    true
}}

# After libvirt releases resources
function {global_func_name}end_release(){{
    case $1 in
        shutdown)
            true
            ;;
        destroyed)
            true
            ;;
        crashed)
            true
            ;;
        migrated)
            true
            ;;
        saved)
            true
            ;;
        failed)
            true
            ;;
        daemon)
            true
            ;;
        *)
            true
            ;;
    esac
}}
"""
    # Asegurarse de que el directorio existe
    dir = os.path.dirname(path)
    if dir and not os.path.exists(dir):
        os.makedirs(dir, exist_ok=True)

    # Escribir el contenido en el archivo
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

    # Añadir permiso de ejecución
    permissions = os.stat(path).st_mode
    os.chmod(path, permissions | stat.S_IEXEC)
    print(f"[INFO] Archivo de config para la VM {name} generado correctamente.")

def edit_qemuhook(name: str, path: str):
    if not os.path.exists(path):
        generate_customhook(name, path)

    subprocess.run(["editor", path])

def generate_vm_json(vm_name, json_file):
    # Valores por defecto
    iommu = []
    cpu_isolated = []
    settings = {
        "hugepages": False,
        "intel_gvtg": False,
        "cpufreq_performance": False,
        "vdisk_partition": "none",
    }
    udp_forwards = {
        "forward1": {"host": 49990, "guest": 49990},
        "forward2": {"host": "49991-50000", "guest": "49991-50000"},
    }
    tcp_forwards = {
        "forward1": {"host": 49990, "guest": 49990},
        "forward2": {"host": "49991-50000", "guest": "49991-50000"},
    }

    template = {
        "vm_name": vm_name,
        "iommu": iommu,
        "cpu_isolated": cpu_isolated,
        "settings": settings,
        "udp_forwards": udp_forwards,
        "tcp_forwards": tcp_forwards,
    }

    dir = os.path.dirname(json_file)
    if dir and not os.path.exists(dir):
        os.makedirs(dir, exist_ok=True)

    with open(json_file, "w", encoding="utf-8") as f:
        json.dump(template, f, indent=2, ensure_ascii=False)
        f.close
    
    print(f"[INFO] Archivo de hooks custom para la VM {vm_name} generado correctamente.")

def edit_vm_config(vm_name, json_file):
    if not os.path.exists(json_file):
        generate_vm_json(vm_name)
    
    subprocess.run(["editor", json_file])

def main():
    parser = argparse.ArgumentParser(
        description="Configura una VM con una opción: cpu-freq, hugepages, gvtg, vdisk o iommu."
    )

    # Argumento posicional obligatorio
    parser.add_argument(
        "vm_name",
        help="Nombre de la máquina virtual a configurar"
    )

    # Grupo mutualmente excluyente y obligatorio
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--cpufreq", action="store_true",
        help="Ajustar frecuencia de CPU")
    
    group.add_argument("--hugepages", action="store_true",
        help="Configurar hugepages")
    
    group.add_argument("--gvtg", action="store_true",
        help="Activar GVT-g")
    
    group.add_argument("--vdisk", action="store_true",
        help="Asignar disco virtual (UUID)")

    group.add_argument("--iommu", metavar="GROUP_ID",
        help="Configurar IOMMU (grupo)")

    group.add_argument("--cpuisolate", action="store_true",
        help="Obtener cores de CPU destinados a uso exclusivo de la VM")

    group.add_argument("--genconfig", metavar="genconfig_ifnot",
        help="Generar archivo de configuración para una VM nueva")

    group.add_argument("--genhook", metavar="genhook_ifnot",
        help="Generar archivo de hooks para una VM nueva")

    group.add_argument("--editconfig", action="store_true",
        help="Editar archivo de configuración de una VM")

    group.add_argument("--edithook", action="store_true",
        help="Editar archivo de hooks de una VM")

    args = parser.parse_args()

    rootdir = os.path.realpath(\
        os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", ".."))
    board_id = subprocess.getoutput("cat /sys/devices/virtual/dmi/id/board_name")
    
    json_file = os.path.join(rootdir, "vm_config", args.vm_name + "_" + board_id + ".json")
    customhook_file = os.path.join(rootdir, "custom_hooks", args.vm_name + "_" + board_id + ".sh")

    if not os.path.exists(json_file):
        print("[INFO] Archivo de config no existente. Generando uno nuevo...")
        generate_vm_json(args.vm_name, json_file)

    if not os.path.exists(customhook_file):
        print("[INFO] Archivo de hook no existente. Generando uno nuevo...")
        generate_customhook(args.vm_name, customhook_file)

    data = ""

    with open(json_file) as f:
        data = json.load(f)
        f.close
        
    if (args.cpufreq and data["settings"]["cpufreq_performance"]) \
    or (args.hugepages and data["settings"]["hugepages"]) \
    or (args.gvtg and data["settings"]["intel_gvtg"]) \
    or (args.iommu is not None and int(args.iommu) in data["iommu"]):
        print("1")

    elif (args.vdisk and data["settings"]["vdisk_partition"].lower() != "none"):
        print(data["settings"]["vdisk_partition"])

    elif (args.cpuisolate):
        if data["cpu_isolated"]:
            print(','.join(str(x) for x in data["cpu_isolated"]))     

    elif args.genconfig is not None and \
    (args.genconfig != "keep" or not os.path.exists(customhook_file)):
        generate_vm_json(args.vm_name, json_file)

    elif args.genhook is not None and \
    (args.genhook != "keep" or not os.path.exists(customhook_file)):
        generate_customhook(args.vm_name, customhook_file)

    elif (args.editconfig):
        edit_vm_config(args.vm_name, json_file)
        
    elif (args.edithook):
        edit_qemuhook(args.vm_name, customhook_file)
    else:
        print("0")

if __name__ == "__main__":
    main()
    exit(0)