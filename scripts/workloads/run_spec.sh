#! /bin/bash

cpu_list=$1
bench=$2
action=$3

cd $BASE_PATH/app/cpu2017
source shrc

taskset -c $cpu_list runcpu -c default.cfg --noreportable --action=$action --size=ref $bench
