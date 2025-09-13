#!/bin/bash

function set_ondemand(){
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "powersave" > $file; done
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

function set_performance(){
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "performance" > $file; done
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}