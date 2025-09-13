#!/usr/bin/env python3
import json
import os
import argparse
import re
import subprocess

def parse_bash_exports(path):
    exports = {}
    pattern = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)=(.*)$')

    with open(path, 'r', encoding='utf-8') as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith('#'):
                continue

            m = pattern.match(line)
            if not m:
                continue

            key, val = m.groups()
            # Limpiar comillas externas
            if (val.startswith('"') and val.endswith('"')) or \
               (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]

            # Sustitución de comandos simple: $(...)
            if val.startswith('$(') and val.endswith(')'):
                cmd = val[2:-1]
                # Ojo: evaluar sólo comandos no peligrosos
                val = subprocess.getoutput(cmd)

            exports[key] = val

    return exports
"""
def vfio_prepare(vm_name):
    data = ""

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
"""

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
    group.add_argument(
        "--cpufreq",
        action="store_true",
        help="Ajustar frecuencia de CPU"
    )
    group.add_argument(
        "--hugepages",
        action="store_true",
        help="Configurar hugepages"
    )
    group.add_argument(
        "--gvtg",
        action="store_true",
        help="Activar GVT-g"
    )
    group.add_argument(
        "--vdisk",
        action="store_true",
        help="Asignar disco virtual (UUID)"
    )
    group.add_argument(
        "--iommu",
        metavar="GROUP_ID",
        help="Configurar IOMMU (grupo)"
    )

    args = parser.parse_args()

    rootdir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "..", "..")
    global_vars = parse_bash_exports(os.path.join(rootdir, "vfio.env"))
    board_id = subprocess.getoutput("cat /sys/devices/virtual/dmi/id/board_name")
   
    data = ""
    with open(os.path.join(rootdir, "vm-config", args.vm_name + "_" + board_id + ".json")) as f:
        data = json.load(f)
        f.close
        
    # Lógica según la opción elegida
    if (args.cpufreq and data["settings"]["cpufreq_performance"]) \
    or (args.hugepages and data["settings"]["hugepages"]) \
    or (args.gvtg and data["settings"]["intel_gvtg"]) \
    or (args.iommu is not None and int(args.iommu) in data["iommu"]):
        print("1")
    elif (args.vdisk and data["settings"]["vdisk_partition"].lower() != "none"):
        print(data["settings"]["vdisk_partition"])
    else:
        print("0")

if __name__ == "__main__":
    main()