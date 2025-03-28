#! /bin/bash

sudo $BASE_PATH/tools/dca_control/storage_enable
sudo $BASE_PATH/tools/dca_control/network_enable
#sudo pkill xmem
sudo pqos -R
sudo wrmsr 0xc8b 0x0600

sudo pkill dpdk-rx
sudo pkill m_fio
sudo pkill -f fio_lat
sudo pkill WATER-NSQUARED
sudo pkill click
$BASE_PATH/scripts/workloads/end_client.sh


