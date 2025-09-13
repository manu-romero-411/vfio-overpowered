#!/usr/bin/env python3
import argparse
import vfio_prepare as prep
import vfio_release as rel
import functions.global_vars as globals
import argparse

def main():
    parser = argparse.ArgumentParser("vfio_overpowered")
    # Creamos un grupo mutuamente exclusivo y obligatorio
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "-p", "--prepare",
        action="store_true",
        help="Preparar recursos de hardware pre-VM"
    )
    group.add_argument(
        "-r", "--release",
        action="store_true",
        help="Liberar recursos de hardware post-VM"
    )

    parser.add_argument(
        "vm_name",
        type=str,
        help="Nombre de la máquina virtual en libvirt"
    )

    args = parser.parse_args()

    if args.prepare:
        prep.vfio_prepare(args.vm_name)
    else:
        rel.vfio_release(args.vm_name)

if __name__ == "__main__":
    main()
