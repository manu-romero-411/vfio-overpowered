#!/bin/bash
CPU_TOTAL_THREADS=$(grep -c processor /proc/cpuinfo)

function cpu_isolate(){
    systemctl set-property --runtime -- system.slice AllowedCPUs=${1} \
    || (echo_error "Fallo al establecer CPU pinning a nivel sistema." && return 1)

    systemctl set-property --runtime -- user.slice AllowedCPUs=${1} \
    || (echo_error "Fallo al establecer CPU pinning a nivel usuario." && return 1)

    systemctl set-property --runtime -- init.scope AllowedCPUs=${1} \
    || (echo_error "Fallo al establecer CPU pinning a nivel init." && return 1)
}

function cpu_recover(){
    last_cpu=$((CPU_TOTAL_THREADS - 1))
    systemctl set-property --runtime -- system.slice AllowedCPUs=${last_cpu} \
    || (echo_error "Fallo al establecer CPU pinning a nivel sistema." && return 1)

    systemctl set-property --runtime -- user.slice AllowedCPUs=${last_cpu} \
    || (echo_error "Fallo al establecer CPU pinning a nivel usuario." && return 1)

    systemctl set-property --runtime -- init.scope AllowedCPUs=${last_cpu} \
    || (echo_error "Fallo al establecer CPU pinning a nivel init." && return 1)
}