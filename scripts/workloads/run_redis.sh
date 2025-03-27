#!/bin/bash

# example commands:
# mkdir output_experiment3
# sudo ./run_redis.sh b remote 50000 output_experiment3/output_remote  or:
# sudo ./run_redis.sh a local loop output_experiment3/output_local
# python3 process_output.py -i output_experiment3/output_remote/ -o report/experiment3/remote.xlsx

# Command to stop Redis server if nother else would work:
# /etc/init.d/redis-server stop

# script patameters passed from terminal
WORKLOAD=$1
NODE_CONFIG=$2
[ ! $4 ] && OUTPUT_FOLDER="output" || OUTPUT_FOLDER=$4

# Change local parameters here
THREADS=12      # number of threads
LOOP_BASE=5000     # the starting point of the loop
LOOP_STEP=20000  # the step of the loop
LOOP_ITER=6     # the number of iterations of the loop
if [ ! $3 ]; then
    TARGET=100000 # requests per second
elif [ $3 == "loop" ]; then
    QPS_LOOP=1
else
    QPS_LOOP=0
    TARGET=$3
fi


# if no parameter is passed, print help info
if [ ! $1 ]; then
    echo "Usage:"
    echo ""
    echo "Run Experiment:"
    echo "sudo ./run_redis.sh b remote 50000 output_experiment3/output_remote"
    echo ""
    echo "Data Process:"
    echo "python3 process_output.py -i output_experiment3/output_remote/ -o report/experiment3/remote.xlsx"
    echo ""
    exit 0
fi

# stop and restart redis
if [ `redis-cli ping` == "PONG" ]; then
    echo "[Shutting down the Redis...]"
    redis-cli shutdown
    # sudo systemctl stop redis.service
    if [ -z `redis-cli ping` ]; then
        echo "Shutdown success"
    fi
fi

SNC_local=0
CXL_node=8

sudo pkill -f redis-server

if [ "$NODE_CONFIG" == "local" ]; then
    sudo numactl --cpunodebind=$SNC_local --membind=$SNC_local redis-server --daemonize yes 
elif [ "$NODE_CONFIG" == "remote" ]; then
    sudo numactl --cpunodebind=$SNC_local --membind=$CXL_node redis-server --daemonize yes 
elif [ "$NODE_CONFIG" == "interleave" ]; then 
    sudo numactl --cpunodebind=$SNC_local --interleave="${SNC_local},${CXL_node}" redis-server --daemonize yes 
else
    echo "Wrong NUMA config."
    exit 1
fi

mkdir -p $OUTPUT_FOLDER
REDIS_PID=`pgrep redis-server`
echo "redis-server pid = ${REDIS_PID}"

# Set ITERATION to 10 if QPS_LOOP is 1
[ $QPS_LOOP == 1 ] && ITERATION=$LOOP_ITER || ITERATION=1
for ((i=0;i<$ITERATION;i++)); do

    if [ $QPS_LOOP == 1 ]; then
        TARGET=$(($LOOP_BASE+$i*$LOOP_STEP))
        echo "========= QPS - $TARGET ========="
    fi
    # continue # for testing

    # clear redis database
    echo "[Flushing Redis...]"
    while [ "$(redis-cli FLUSHALL)" != "OK" ]; do
        echo "[Waiting for loading finishes]"
        sleep 10
    done

    echo "**************"
    echo "  LOAD PHASE"
    echo "**************"
    echo ""
    taskset --cpu-list 0-3 ./bin/ycsb.sh load redis -s -P workloads/workload$WORKLOAD -p "redis.host=127.0.0.1" -p "redis.port=6379" \
        -threads $THREADS > $OUTPUT_FOLDER/workload${WORKLOAD}_${NODE_CONFIG}_qps${TARGET}_Load.txt

    echo ""
    echo "*************"
    echo "  RUN PHASE"
    echo "*************"
    echo ""

    # actual YSCB client 
    taskset --cpu-list 0-3 ./bin/ycsb.sh run redis -s -P workloads/workload$WORKLOAD \
        -p "redis.host=127.0.0.1" -p "redis.port=6379" \
        -threads $THREADS -target $TARGET > $OUTPUT_FOLDER/workload${WORKLOAD}_${NODE_CONFIG}_qps${TARGET}_Run.txt
    
done
