#!/bin/bash

function kill_proc(){
        lsof -n | grep "$1" | awk '{print $2}' | awk '!seen[$0]++' | xargs -I {} kill -9 {}
        sleep 2
}

function kill_proc_fuser(){
        fuser -v "$1" | nl -b n | tail -n 1 | xargs -I {} kill -9 {}
}