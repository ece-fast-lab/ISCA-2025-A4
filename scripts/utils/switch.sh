#! /bin/bash

# real / real2
target=$1
# lat / nolat
lat=$2


if [ "$target" == "real" ]; then
    #unmount,erase RAID of real2
    sudo umount /mnt/heavy_ffsb
    sudo umount /mnt/light_ffsb
    sudo wipefs -a /dev/md127
    sudo wipefs -a /dev/nvme3n1
    sudo mdadm --stop /dev/md127
    sudo mdadm --zero-superblock /dev/nvme{0,1,2}n1

    # set raid to real
    sudo mdadm --create /dev/md127 --level=0 --raid-devices=4 /dev/nvme{0,1,2,3}n1

    sudo rm $BASE_PATH/tools/dca_control/*able
    sudo cp $BASE_PATH/tools/dca_control/net17st25/* $BASE_PATH/tools/dca_control/

    cat /proc/mdstat 

elif [ "$target" == "real2" ]; then
    #unmount,erase RAID of real
    sudo umount /mnt/ffsb_test
    sudo wipefs -a /dev/md127
    sudo mdadm --stop /dev/md127
    sudo mdadm --zero-superblock /dev/nvme{0,1,2,3}n1

    # set raid to real2
    sudo mdadm --create /dev/md127 --level=0 --raid-devices=3 /dev/nvme{0,1,2}n1

    sudo rm $BASE_PATH/tools/dca_control/*able
    sudo cp $BASE_PATH/tools/dca_control/st3v1/* $BASE_PATH/tools/dca_control/

    cat /proc/mdstat 
fi

if [ "$lat" == "lat" ]; then
    sed -i "s/dpdk-framework/dpdk-lat/g" $BASE_PATH/scripts/workloads/start_client.sh
    sed -i "s/smartllc_nolat/smartllc_lat/g" $BASE_PATH/scripts/run_all.sh
    sed -i "s/fastclick_nolat/fastclick_lat/g" $BASE_PATH/scripts/run_all.sh
    # sudo rm -r /home/hnpark2/bench/fastclick
    # sudo cp -r /home/hnpark2/bench/fastclick_lat /home/hnpark2/bench/fastclick
elif [ "$lat" == "nolat" ]; then
    sed -i "s/dpdk-lat/dpdk-framework/g" $BASE_PATH/scripts/workloads/start_client.sh
    sed -i "s/smartllc_lat/smartllc_nolat/g" $BASE_PATH/scripts/run_all.sh
    sed -i "s/fastclick_lat/fastclick_nolat/g" $BASE_PATH/scripts/run_all.sh
    
    # sudo rm -r /home/hnpark2/bench/fastclick
    # sudo cp -r /home/hnpark2/bench/fastclick_nolat /home/hnpark2/bench/fastclick
fi

