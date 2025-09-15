#!/bin/bash
##TODO: CAMBIAR MODOS DE CPUFREQ SEGÚN EL PROCESADOR

function set_ondemand(){
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        (echo "powersave" | tee ${file}) > /dev/null \
        || (echo_error "Fallo al establecer cpufreq en ${file}." && return 1)
    done
}

function set_performance(){
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        (echo "performance" | tee ${file}) > /dev/null \
        || (echo_error "Fallo al establecer cpufreq en ${file}." && return 1)
    done
}