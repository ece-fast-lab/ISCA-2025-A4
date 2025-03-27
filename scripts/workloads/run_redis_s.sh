#! /bin/bash

core=$1

sudo taskset -c $core redis-server /home/hnpark2/ddio/scripts/workloads/redis.conf --daemonize yes
#set save "" --appendonly no 
