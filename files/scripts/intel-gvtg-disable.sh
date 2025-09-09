#!/bin/bash

VFIO_GVTG_ID="af5972fb-5530-41a7-0000-fd836204445b"

echo 1 > "/sys/devices/pci0000:00/0000:00:02.0/$VFIO_GVTG_ID/remove"

