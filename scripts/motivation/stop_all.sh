#! /bin/bash

#sudo pkill xmem
sudo pkill fio
sudo pkill fio
sudo pkill dpdk
sudo pkill pcm
sudo kill -INT $(pgrep dpdk-rx)
sudo kill -INT $(pgrep nt-dpdk-rx)
$BASE_PATH/scripts/workloads/end_client.sh
sudo $DBENCH_PATH/network_enable
sudo $DBENCH_PATH/storage_enable