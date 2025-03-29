#! /bin/bash

#application-specific parameters
xmem_ws="4096"
xmem_large_ws="10240"
dpdk_latency="100"
network_device=$SERVER_NIC_PCIE
storage_device=$SERVER_SSD_PCIE

# Execution Time
num_iteration=$ITER
runtime=30
report_start_time=25
report_end_time=$runtime
monitoring_time=2
elapsed_time=$(( report_end_time - report_start_time ))

# Script for workload scenario (up to 8 applications)
# workloads should be in chronological order

WRKLD_PARAMS=("app_name" "isolation_ways" "start_time" \
            "type" "isAT" "isIOIA" "device" \
            "num_core" "cpu_list" "start_core" "end_core")

# name of the application
# 
app_name=(  "xmem_ssr"  "dpdk-rx"   "FIO"     "xmem_ssw"   "xmem_lrr")
num_application=${#app_name[@]}
# Isolation way for workloads
isolation_ways=(  "0x600" "0x180"     "0x070"    "0x003"     "0x00c"   )

# launching time of the application (unit: monitoring time)
start_time=("0"     "0"         "1"       "0"         "0"         "" "" "" "")

# type of the application LCA or BEA (MIA is determined by later)
type=(      "LCA"   "LCA"       "BEA"     "BEA"       "BEA"       "" "" "" "")
isAT=(      "0"     "0"         "0"       "0"         "0"         "" "" "" "")

# Whether it uses the I/O (0 or 1)
isIOIA=(    "0"     "1"         "1"       "0"         "0"         "" "" "" "")

# I/O device it's using (storage or network)
device=(    "N/A"   "network"   "storage"     "N/A"       "N/A"   "" "" "" "")

# core affinity of applications
num_core=(  "3"     "4"         "4"       "3"         "3"         "" "" "" "")

# Generate core list
cpu_list=("" "" "" "" "" "" "" "" "" )
start_core=("" "" "" "" "" "" "" "" "")
end_core=("" "" "" "" "" "" "" "" "")
current_core=0
last_core=17
for ((i=0; i<$num_application; i++)); do
    if ((current_core + num_core[i] - 1 <= last_core)); then
        start_core[$i]=$current_core
        end_core[$i]=$((current_core + num_core[i] - 1))
        if((num_core[i]==1)); then
            cpu_list[$i]="${start_core[$i]}"
        else
            cpu_list[$i]="${start_core[$i]}-${end_core[$i]}"
        fi
        current_core=$((current_core + num_core[i]))
    else
        echo "[WORKLOAD.SH] Cannot allocate cpu cores"
        exit
    fi
done

