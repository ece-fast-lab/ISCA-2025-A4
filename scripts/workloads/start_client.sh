#! /bin/bash

path=$1
size=$2

# Export the variables we want to make available
export PACKET_SIZE=$size

# Instead of sending the script content, we'll execute commands directly
ssh $CLIENT_ACCOUNT@$CLIENT_IP "
export PACKET_SIZE=$PACKET_SIZE
export CLIENT_ACCOUNT=$CLIENT_ACCOUNT
export CLIENT_PASSWORD=$CLIENT_PASSWORD
export CLIENT_NIC_PCIE=$CLIENT_NIC_PCIE
export CLIENT_SNIC_IP=$CLIENT_SNIC_IP
export CLIENT_MAC=$CLIENT_MAC
export SERVER_SNIC_IP=$SERVER_SNIC_IP
export SERVER_MAC=$SERVER_MAC
cd /home/$CLIENT_ACCOUNT/dpdk-framework/dpdk-tx
echo \$CLIENT_PASSWORD | sudo -S ./run_tx.sh \"0-3\" \$PACKET_SIZE \$CLIENT_NIC_PCIE \$SERVER_MAC \$SERVER_SNIC_IP \$CLIENT_MAC \$CLIENT_SNIC_IP  1
" > $path/tx_result.txt
