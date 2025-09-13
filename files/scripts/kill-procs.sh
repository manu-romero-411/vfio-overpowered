#!/bin/bash

systemctl stop nvidia-persistenced.service
systemctl --user -M 1000@ stop sunshine.service
lsof -n | grep "$1" | awk '{print $2}' | awk '!seen[$0]++' | xargs -I {} kill -9 {}
fuser -v "$1" | nl -b n | tail -n 1 | xargs -I {} kill -9 {}
sleep 2
