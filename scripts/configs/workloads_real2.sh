#! /bin/bash

#application-specific parameters
# xmem_ws="3840"
# xmem_large_ws="512000"
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


# name of the application (LPW-Heavy)
app_name=(  "fastclick"     "heavy_ffsb"      "light_ffsb"      "Redis-server"      "Redis"         "mcf_r"            "blender_r"      "x264_r"     "parest_r"      "fotonik3d_r"      "lbm_r"  "bwaves_r") # "xz_r"      "roms_r"      "povray_r"     "lbm_r"      "bwaves_r"  )
num_application=${#app_name[@]}
# Isolation way for workloads
isolation_ways=( "0x780"  "0x040"   "0x002"     "0x001"     "0x008"     "0x004"  "0x020"  "0x010")
isol_cpu_list=(  "0-7"    "8"       "9"         "10-11"     "12-13"     "14-15"  "16"     "17")
# launching time of the application (unit: monitoring time)
start_time=("0"             "4"               "4"                "1"                "2"             "3"                 "3"                 "4"             "4"             "4"             "4"                 "4")

# type of the application LCA or BEA (MIA is determined later)
type=(      "LCA"           "BEA"             "LCA"              "BEA"              "BEA"           "LCA"               "LCA"               "BEA"           "BEA"           "BEA"           "BEA"               "BEA")
isAT=(      "0"             "0"               "0"                "0"                "0"             "0"                 "0"                 "0"             "0"             "0"             "0"                 "0")

# Whether it uses the I/O (0 or 1)
isIOIA=(    "1"             "1"               "1"                "0"                "0"             "0"                 "0"                 "0"             "0"             "0"             "0"                 "0")

# I/O device it's using (storage or network)
device=(    "network"       "storage"         "storage_light"          "N/A"              "N/A"           "N/A"               "N/A"               "N/A"           "N/A"           "N/A"           "N/A"               "N/A")

# core affinity of applications
num_core=(  "4"             "3"               "1"                 "1"               "1"             "1"                 "1"                 "1"             "1"             "1"             "1"                 "1")


# Generate core list
cpu_list=("" "" "" "" "" "" "" "" "" )
start_core=("" "" "" "" "" "" "" "" "")
end_core=("" "" "" "" "" "" "" "" "")
current_core=0
last_core=17
for ((i=0; i<$num_application; i++)); do
    if ((current_core + num_core[i] - 1 <= last_core)); then
        if((num_core[i] > 0)); then
            start_core[$i]=$current_core
            end_core[$i]=$((current_core + num_core[i] - 1))
            if((num_core[i]==1)); then
                cpu_list[$i]="${start_core[$i]}"
            else
                cpu_list[$i]="${start_core[$i]}-${end_core[$i]}"
            fi
            current_core=$((current_core + num_core[i]))
        fi
    else
        echo "[WORKLOAD.SH] Cannot allocate cpu cores"
        exit
    fi
done
