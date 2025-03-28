#! /bin/bash

core=$1

sudo taskset -c $core redis-server $BASE_PATH/app/configs/redis.conf --daemonize yes
#set save "" --appendonly no 
