#! /bin/bash

# Zone Paramters
ZONE_PARAMS=("IOLC_APP_LIST" "IO_num" "IOLC_CAT" "IOLC_CPU_LIST" \
             "LC_APP_LIST" "LC_num" "LC_CAT" "LC_CPU_LIST" \
             "BE_APP_LIST" "BE_num" "BE_CAT" "BE_CPU_LIST" \
             "AT_APP_LIST" "AT_num" "AT_CAT" "AT_CPU_LIST" \
             "SIO_APP_LIST" "AT_num" "AT_CAT" "SIO_CPU_LIST")

# Default values
LC_init=11
BE_init=2
BE_max=7
IO_init=2
AT_min=2
# AT_init=2

BE_num=0
IO_num=0
LC_num=$(($LC_init-$BE_num-$IO_num))
AT_num=$BE_num



# Threshold parameters
THR_PARAMS=("LCA_LLC_HIT_FL" "IOLCA_DDIO_MISS_FL"\
            "LK_STG_DDIO_MS_THR" "LK_STG_TP_THR" "LK_STG_LLC_MS_THR" \
            "LOC_L2_MISS_THR" "LOC_LLC_MISS_THR" "BPS_CACHE_MISS_FL" "BPS_STG_TP_FL" "BPS_MEM_BW_FL" "BPS_NET_TP_FL")

# LC zone paramter
# T1
LCA_LLC_HIT_FL="0.2"
IOLCA_DDIO_MISS_FL="1" # depreciated
#LCA_NET_TP_FL="0.01"

# Leaky DMA decision
# T2-4
LK_STG_DDIO_MS_THR=40
LK_STG_TP_THR=35
LK_STG_LLC_MS_THR=40

# Pseudo Bypassing
LOC_L2_MISS_THR=80
# T5
LOC_LLC_MISS_THR=90
BPS_CACHE_MISS_FL="0.05"
BPS_STG_TP_FL="0.3"
BPS_MEM_BW_FL="0.1"
BPS_NET_TP_FL="0.01"

