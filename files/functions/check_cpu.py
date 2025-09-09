import re
import os
import subprocess
import json
import argparse
import platform

def check_cpu():
    cpu_name = None
    with open("/proc/cpuinfo") as f:
        for line in f:
            if line.startswith("model name"):
                cpu_name = line.split(":", 1)[1].strip()
                break

    if not cpu_name or not "Intel" in cpu_name:
        return False

    # 1. Captura core (3,5,7,9), modelo numérico (4–5 dígitos) y sufijo de letras
    pattern = re.compile(
        r"Intel\(R\)\s+Core\(TM\)\s+"
        r"i(?P<core>[3579])-"                    # core i3,i5,i7,i9
        r"(?P<number>\d{4,5})"                   # e.g. 7600 o 10500
        r"(?P<suffix>[A-Z]*)$"                   # sufijo (K,U,G0,...), puede estar vacío
    )
    m = pattern.search(cpu_name)
    if not m:
        return False

    core = int(m.group("core"))
    number = m.group("number")
    suffix = m.group("suffix")

    # 2. Descarta cualquier sufijo que contenga 'F'
    if "F" in suffix:
        return False

    # 3. Calcula generación: si son 5 dígitos toma los dos primeros, si 4 dígitos el primero
    gen = int(number[:2]) if len(number) == 5 else int(number[0])

    # 4. Valida rango de gen 5–10
    return 5 <= gen <= 10