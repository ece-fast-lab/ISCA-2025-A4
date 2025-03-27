#! /bin/bash

path=$1
size=$2

cat /home/hnpark2/ddio/scripts/workloads/start_code_$size.sh | ssh hnpark2@192.17.100.21 > $path/tx_result.txt
