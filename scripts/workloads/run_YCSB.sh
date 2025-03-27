#! /bin/bash
list=$1
OUTPUT_FOLDER=$2

THREADS=4
TARGET=100000
WORKLOAD=$3
YCSB_path="/home/hnpark2/bench/YCSB-Redis/YCSB"

# clear redis database
echo "[Flushing Redis...]"
sleep 3
redis-cli config set save "" 
redis-cli CONFIG SET appendonly no
while [ "$(redis-cli FLUSHALL)" != "OK" ]; do
    echo "[Waiting for loading finishes]"
    sleep 1
done

echo "**************"
echo "  LOAD PHASE"
echo "**************"
echo ""
taskset --cpu-list $list $YCSB_path/bin/ycsb.sh load redis -s -P $YCSB_path/workloads/workload$WORKLOAD -p "redis.host=127.0.0.1" -p "redis.port=6379" \
    -threads $THREADS > $OUTPUT_FOLDER/YCSB_load.txt

echo ""
echo "*************"
echo "  RUN PHASE"
echo "*************"
echo ""

# actual YSCB client 
taskset --cpu-list $list $YCSB_path/bin/ycsb.sh run redis -s -P $YCSB_path/workloads/workload$WORKLOAD \
    -p "redis.host=127.0.0.1" -p "redis.port=6379" \
    -threads $THREADS -target $TARGET > $OUTPUT_FOLDER/YCSB_Run.txt


