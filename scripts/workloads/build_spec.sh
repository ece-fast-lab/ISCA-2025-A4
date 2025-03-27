#! /bin/bash


# benchs=("omnetpp_r")
# build don't work for
# benchs=( "cactuBSSN_r"        "wrf_r"   "cam4_r"  "bwaves_r")
benchs=( "wrf_r" )
#benchs=( "500.perlbench_r" "505.mcf_r" "523.xalancbmk_r" "525.x264_r" "531.deepsjeng_r" "541.leela_r" "548.exchange2_r" "557.xz_r" "508.namd_r" "511.povray_r" "521.wrf_r" "526.blender_r" "527.cam4_r" "538.imagick_r" "544.nab_r" "554.roms_r")

#benchs=( "521.wrf_r" "527.cam4_r"  )

for bench in "${benchs[@]}"; do
    ./run_spec.sh 0-71 $bench build &
done



