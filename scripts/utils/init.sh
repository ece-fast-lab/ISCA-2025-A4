#!/bin/bash

# Set hugepage for DPDK
sudo bash -c 'echo 8192 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages'
sudo sysctl -p /etc/sysctl.conf
cat /proc/meminfo | grep -i huge

#Set CPU frequencies
sudo cpupower frequency-set -g performance

#Stop gdm3
sudo systemctl stop gdm3.service

#Stop rshim
systemctl stop rshim

#Stop default Redis server
sudo systemctl stop redis
sudo sysctl vm.overcommit_memory=0

# Set environmental variables
source /home/hnpark2/ISCA-2025-A4/scripts/utils/env.sh