#!/bin/bash

export CLIENT_IP=192.17.102.193
export CLIENT_ACCOUNT=1 # client user account
export CLIENT_PASSWORD=1 # client user password
export SERVER_IP=192.17.101.49
export HOST_ACCOUNT=1 # server user account
export HOST_PASSWORD=1 # server user password

export CLIENT_SNIC_IP=192.168.200.20
export CLIENT_MAC=08:c0:eb:bf:ef:52
export SERVER_SNIC_IP=192.168.200.22
export SERVER_MAC=b8:ce:f6:d2:12:ea

export CLIENT_NIC_PCIE="0000:03:00.0" #
export SERVER_NIC_PCIE="0000:17:00.0" #
export SERVER_SSD_PCIE="0000:25:00.0" #

export BASE_PATH=/home/$HOST_ACCOUNT/ISCA-2025-A4
export TMP_PATH=$BASE_PATH/tmp
export SCRIPT_PATH=$BASE_PATH/scripts
export DPDK_PATH=$BASE_PATH/app/dpdk_microbench
export PCM_PATH=$BASE_PATH/tools/pcm/build/bin
export DBENCH_PATH=$BASE_PATH/tools/dca_control

export ITER=5
