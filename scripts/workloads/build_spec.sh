#! /bin/bash

benchs=( "505.mcf_r" "523.xalancbmk_r" "525.x264_r" "548.exchange2_r" "526.blender_r" "510.parest_r" "519.lbm_r" "520.omnetpp_r" "503.bwaves_r" "549.fotonik3d_r")

for bench in "${benchs[@]}"; do
    $BASE_PATH/scripts/workloads/run_spec.sh 0-71 $bench build &
done



