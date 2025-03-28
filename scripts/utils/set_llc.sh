#! /bin/bash

# reset previous CAT settings
sudo pqos -R

# set pqos for Streaming application
#sudo pqos -a llc:1=0-3
#sudo pqos -e llc:1=0x003

# set pqos for cache-sensitive multi-threaded program
sudo pqos -a llc:2=0-7
sudo pqos -e llc:2=0x001c

#set pqos for DPDK program
sudo pqos -a llc:3=8-17
sudo pqos -e llc:3=0x07c0

