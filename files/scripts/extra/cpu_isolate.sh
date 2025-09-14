#!/bin/bash
TOTAL_THREADS=$(grep -c processor /proc/cpuinfo)

function cpu_isolate(){
    systemctl set-property --runtime -- system.slice AllowedCPUs=${1}
    systemctl set-property --runtime -- user.slice AllowedCPUs=${1}
    systemctl set-property --runtime -- init.scope AllowedCPUs=${1}
}

function cpu_recover(){
    last_cpu=$((TOTAL_THREADS - 1))
    systemctl set-property --runtime -- system.slice AllowedCPUs=0-${last_cpu}
    systemctl set-property --runtime -- user.slice AllowedCPUs=0-${last_cpu}
    systemctl set-property --runtime -- init.scope AllowedCPUs=0-${last_cpu}
}