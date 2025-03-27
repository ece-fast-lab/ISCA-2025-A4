#! /bin/bash

cpu_list=$1
bench=$2
action=$3
#echo "ps101899" | su hnpark2
cd /home/hnpark2/bench/cpu2017
source shrc
#taskset -c $cpu_list runcpu -c default.cfg --noreportable --size=ref $bench
taskset -c $cpu_list runcpu -c default.cfg --noreportable --action=$action --size=ref $bench
