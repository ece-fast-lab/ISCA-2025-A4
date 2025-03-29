#! /bin/bash

#Stop reamaining processes
# sudo pkill xmem
# /home/hnpark2/ddio/scripts/end_wyatt.sh
# sudo kill -INT $(pgrep dpdk-rx)
# sudo kill -INT $(pgrep click)
sudo pkill fio
sudo pkill pcm
#Restore DDIO/CAT configuration
sudo $BASE_PATH/tools/dca_control/storage_enable
sudo $BASE_PATH/tools/dca_control/network_enable
sudo pqos -R
sudo wrmsr 0xc8b 0x0600

sudo rm -r $BASE_PATH/app/cpu2017/tmp/*
sudo rm -r $BASE_PATH/app/cpu2017/benchspec/CPU/*/run
# perlbench_r mcf_r xalancbmk_r x264_r deepsjeng_r leela_r exchange2_r xz_r namd_r povray_r blender_r imagick_r nab_r roms_r
sudo rm -r $BASE_PATH/app/cpu2017/result/*
# 531.deepsjeng_r
# 541.leela_r

sudo pkill ffsb
sudo pkill base
sleep 2
sudo pkill peak

sudo pkill omnetpp
sudo pkill parest
sudo pkill perlbench
sudo pkill x264_r
sudo pkill xz_r
sudo pkill deepsjeng
sudo pkill fotonik
sudo pkill bwave
sudo pkill mcf
sudo pkill leela
sudo pkill cact
sudo pkill namd
sudo pkill xalan
sudo pkill exchange2_r
sudo pkill roms_r
sudo pkill namd_r
sudo pkill povray_r
sudo pkill blender_r
sudo pkill nab
# sudo pkill cam4
sudo pkill gcc
sudo pkill lbm
sleep 3
sudo pkill omnetpp
sudo pkill parest
sudo pkill x264_r
sudo pkill xz_r
sudo pkill perlbench
sudo pkill fotonik
sudo pkill bwave
sudo pkill mcf
sudo pkill cact
sudo pkill leela
sudo pkill gcc
# sudo pkill cam4
sudo pkill namd
sudo pkill xalan
sudo pkill lbm
sudo pkill deepsjeng
sudo pkill exchange2_r
sudo pkill roms_r
sudo pkill namd_r
sudo pkill povray_r
sudo pkill blender_r
sudo pkill nab




# erase page cache
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Redis
if [ `redis-cli ping` == "PONG" ]; then
    echo "[Shutting down the Redis...]"
    redis-cli shutdown
    # sudo systemctl stop redis.service
    if [ -z `redis-cli ping` ]; then
        echo "Shutdown success"
    fi
fi
sudo pkill redis-server
