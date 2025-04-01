#! /bin/bash
# micro / real / real2
bench_type=$1

result_path=$BASE_PATH"/results"
sudo rm -r $result_path/*"_"$bench_type

# Import Workloads information (name, timeline, type, numcore, program command, ... etc)
if [ "$bench_type" == "micro" ]; then
    source $SCRIPT_PATH/configs/workloads.sh
    source $SCRIPT_PATH/configs/parameters.sh
    sudo xmem -t -n300000 -s -R -c256 -j${num_core[0]} -w$xmem_ws &
    sudo xmem_c11 -t -n300000 -s -W -c256 -j${num_core[3]} -w$xmem_ws &
    sudo xmem_c14 -t -n300000 -r -R -c256 -j${num_core[4]} -w$xmem_large_ws &
    sleep 3

    pkts=("1514"  "1514" "1514" "1514" "1514" "1514" "1514"  "1514" "1514"  "1514"   "64"    "128"   "256"   "512"   "1024"  )
    bss=( "2048k" "4k"   "8k"   "32k"  "64k"  "128k"  "256k" "512k" "1024k" "16k"  "2048k" "2048k" "2048k" "2048k" "2048k" )
    
    sudo $DPDK_PATH/dpdk-rx -l ${cpu_list[1]} -a $SERVER_NIC_PCIE -- -d $dpdk_latency -l 10000 > $result_path/dpdk_output.txt &  
    $SCRIPT_PATH/workloads/start_client.sh $result_path ${pkts[0]} &

    for ((i=0; i<${#pkts[@]}; i++)); do
        if (( i > 9 )); then
            $SCRIPT_PATH/workloads/end_client.sh
            sleep 2
            $SCRIPT_PATH/workloads/start_client.sh $result_path ${pkts[$i]} &
        fi
        for ((iter=0; iter<$num_iteration; iter++)); do 

            taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 0

            taskset -c 17 $SCRIPT_PATH/evaluation/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter 

            taskset -c 17 $SCRIPT_PATH/evaluation/Baseline.sh Isolated $bench_type ${pkts[$i]} ${bss[$i]}  $iter

            if (( iter == num_iteration-1 )); then
                $SCRIPT_PATH/utils/parse_result.sh Isolated_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_0_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi

        done
    done

    $SCRIPT_PATH/utils/concat.sh $bench_type
    sudo pkill xmem
    sudo kill -INT $(pgrep dpdk-rx)

elif [ "$bench_type" == "real" ]; then
    source $SCRIPT_PATH/configs/workloads_real.sh
    source $SCRIPT_PATH/configs/parameters_real.sh
    cd $SCRIPT_PATH
    # pkts=("1514"  "1514" "1514" "1514" "1514" "1514" "1514"  "1514" "1514"  "1514"   "64"    "128"   "256"   "512"   "1024"  )
    # bss=( "2048k"    "8k"   "16k"  "32k"  "64k"  "128k"  "256k" "512k" "1024k" "4k"  "2048k" "2048k" "2048k" "2048k" "2048k" )
    # pkts=("1514" "1514")
    # bss=("2048k" "2048k")


    pkts=("1024")
    bss=("2048k")
    sudo click --dpdk -l ${cpu_list[0]} -a $SERVER_NIC_PCIE -- $BASE_PATH/app/configs/smartllc_nolat.click > $result_path/dpdk_output.txt &  
    $SCRIPT_PATH/workloads/start_client.sh $result_path ${pkts[0]} &

    for ((i=0; i<${#pkts[@]}; i++)); do
        if (( i > 9 )); then
            $SCRIPT_PATH/workloads/end_client.sh
            sleep 2
            $SCRIPT_PATH/workloads/start_client.sh $result_path ${pkts[$i]} &
        fi
        for ((iter=0; iter<$num_iteration; iter++)); do

        taskset -c 17  $SCRIPT_PATH/evaluation/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter
        taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 0
        taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 1
        taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 3
        taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 2
        taskset -c 17 $SCRIPT_PATH/evaluation/Baseline.sh Isolated $bench_type ${pkts[$i]} ${bss[$i]}  $iter

            if (( iter == num_iteration-1 )); then
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_0_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh Isolated_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_1_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_2_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_3_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi
        done
        $SCRIPT_PATH/utils/parse_step.sh $bench_type ${bss[$i]} ${pkts[$i]}
    done
    sudo kill -INT $(pgrep click)

elif [ "$bench_type" == "real2" ]; then
    source $SCRIPT_PATH/configs/workloads_real2.sh
    source $SCRIPT_PATH/configs/parameters_real2.sh
    cd $SCRIPT_PATH

    pkts=("1024")
    bss=("2048k")       # just a dummy number

    sudo click --dpdk -l ${cpu_list[0]} -a $network_device -- $BASE_PATH/app/configs/smartllc_real2.click > $result_path/dpdk_output.txt &  
    $SCRIPT_PATH/workloads/start_client.sh $result_path ${pkts[0]} &

    for ((i=0; i<${#pkts[@]}; i++)); do
        for ((iter=0; iter<$num_iteration; iter++)); do
            taskset -c 17  $SCRIPT_PATH/evaluation/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter
            taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 0
            taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 1
            taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 2
            taskset -c 17 $SCRIPT_PATH/evaluation/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 3
            taskset -c 17 $SCRIPT_PATH/evaluation/Baseline.sh Isolated $bench_type ${pkts[$i]} ${bss[$i]}  $iter

            if (( iter == num_iteration-1 )); then
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_0_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh Isolated_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_1_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_2_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                $SCRIPT_PATH/utils/parse_result.sh SmartLLC_3_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi
        done
        $SCRIPT_PATH/utils/parse_step.sh $bench_type ${bss[$i]} ${pkts[$i]}
    done
    sudo kill -INT $(pgrep click)

fi

$SCRIPT_PATH/workloads/end_client.sh
