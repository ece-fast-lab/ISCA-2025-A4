#! /bin/bash

# Execute the commands directly over SSH
ssh $CLIENT_ACCOUNT@$CLIENT_IP "
export CLIENT_PASSWORD=$CLIENT_PASSWORD
echo \$CLIENT_PASSWORD | sudo -S kill -INT \$(pgrep dpdk-tx)
"
