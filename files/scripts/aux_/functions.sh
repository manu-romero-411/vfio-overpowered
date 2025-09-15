#!/bin/bash

function kill_proc(){
        ps -aux | grep "$1" | awk '{print $2}' | xargs -I {} kill -9 {}
        #lsof -n | grep "$1" | awk '{print $2}' | awk '!seen[$0]++' | xargs -I {} kill -9 {}
        sleep 2
}

function kill_proc_fuser(){
        fuser -v "$1" | nl -b n | tail -n 1 | xargs -I {} kill -9 {}
}

function kill_proc_gpu(){
        (lsof -n /dev/dri/* | awk '{print $2}' | awk '!seen[$0]++' | xargs -I {} kill -9 {}) 2>/dev/null 
	sleep 2
        ps -aux | grep Xorg | grep -v grep | awk '{print $2}' | xargs -I {} kill -9 {}
}