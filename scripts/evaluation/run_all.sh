#! /bin/bash
# micro / real / real2
bench_type=$1

base="/home/hnpark2/ddio/scripts"
fc_path="/home/hnpark2/bench/fastclick_nolat"
dpdk_path="/home/hnpark2/bench/dpdk-framework/dpdk-rx"
result_path="/home/hnpark2/ddio/results"
sudo rm -r /home/hnpark2/ddio/results/*"_"$bench_type
# /home/hnpark2/ddio/scripts/end_wyatt.sh
# sudo kill -INT $(pgrep dpdk-rx)
# sudo kill -INT $(pgrep click)

# Import Workloads information (name, timeline, type, numcore, program command, ... etc)
if [ "$bench_type" == "micro" ]; then
    source $base/configs/workloads.sh
    source $base/configs/parameters.sh
    sudo xmem -t -n300000 -s -R -c256 -j${num_core[0]} -w$xmem_ws &
    sudo xmem_c11 -t -n300000 -s -W -c256 -j${num_core[3]} -w$xmem_ws &
    sudo xmem_c14 -t -n300000 -r -R -c256 -j${num_core[4]} -w$xmem_large_ws &
    sleep 3

    pkts=("1514"  "1514" "1514" "1514" "1514" "1514" "1514"  "1514" "1514"  "1514"   "64"    "128"   "256"   "512"   "1024"  )
    bss=( "2048k" "4k"   "8k"   "32k"  "64k"  "128k"  "256k" "512k" "1024k" "16k"  "2048k" "2048k" "2048k" "2048k" "2048k" )
    # pkts=("1514")
    # bss=("2048k")
    # pkts=("128" "256" "512")
    # bss=("2048k" "2048k" "2048k")
    sudo $dpdk_path/dpdk-rx -l ${cpu_list[1]} -a $network_device -- -d $dpdk_latency -l 10000 > $result_path/dpdk_output.txt &  
    $base/workloads/start_wyatt.sh $result_path ${pkts[0]} &

    cd $base
    for ((i=0; i<${#pkts[@]}; i++)); do
        if (( i > 9 )); then
            $base/workloads/end_wyatt.sh
            sleep 2
            $base/workloads/start_wyatt.sh $result_path ${pkts[$i]} &
        fi
        for ((iter=0; iter<$num_iteration; iter++)); do 

            sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 0

            sudo taskset -c 17 $base/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter 

            sudo taskset -c 17 $base/Baseline.sh Isolated $bench_type ${pkts[$i]} ${bss[$i]}  $iter

            if (( iter == num_iteration-1 )); then
                sudo $base/utils/parse_result.sh Isolated_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_0_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi

        done
    done

    sudo $base/utils/concat.sh $bench_type
    sudo pkill xmem
    sudo kill -INT $(pgrep dpdk-rx)

elif [ "$bench_type" == "real" ]; then
    source $base/configs/workloads_real.sh
    source $base/configs/parameters_real.sh
    cd $base
    # pkts=("1514"  "1514" "1514" "1514" "1514" "1514" "1514"  "1514" "1514"  "1514"   "64"    "128"   "256"   "512"   "1024"  )
    # bss=( "2048k"    "8k"   "16k"  "32k"  "64k"  "128k"  "256k" "512k" "1024k" "4k"  "2048k" "2048k" "2048k" "2048k" "2048k" )
    # pkts=("1514" "1514")
    # bss=("2048k" "2048k")


    pkts=("1024")
    bss=("2048k")
    sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/smartllc_nolat.click > $result_path/dpdk_output.txt &  
    $base/workloads/start_wyatt.sh $result_path ${pkts[0]} &

    for ((i=0; i<${#pkts[@]}; i++)); do
        if (( i > 9 )); then
            $base/workloads/end_wyatt.sh
            sleep 2
            $base/workloads/start_wyatt.sh $result_path ${pkts[$i]} &
        fi
        for ((iter=0; iter<$num_iteration; iter++)); do

        sudo taskset -c 17  $base/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter
        sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 0
        sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 1
        sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 3
        sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 2
        sudo taskset -c 17 $base/Baseline.sh Isolated $bench_type ${pkts[$i]} ${bss[$i]}  $iter

            if (( iter == num_iteration-1 )); then
                sudo $base/utils/parse_result.sh SmartLLC_0_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh Isolated_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_1_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_2_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_3_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi
        done
        sudo $base/utils/parse_step.sh $bench_type ${bss[$i]} ${pkts[$i]}
    done
    #sudo $base/concat.sh $bench_type
    sudo kill -INT $(pgrep click)

elif [ "$bench_type" == "real2" ]; then
    source $base/configs/workloads_real2.sh
    source $base/configs/parameters_real2.sh
    cd $base

    pkts=("1024")
    bss=("2048k")       # just a dummy number

    sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/smartllc_nolat.click > $result_path/dpdk_output.txt &  
    $base/workloads/start_wyatt.sh $result_path ${pkts[0]} &

    for ((i=0; i<${#pkts[@]}; i++)); do
        for ((iter=0; iter<$num_iteration; iter++)); do
            sudo taskset -c 17  $base/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter
            sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 0
            sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 1
            sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 2
            sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 3
            sudo taskset -c 17 $base/Baseline.sh Isolated $bench_type ${pkts[$i]} ${bss[$i]}  $iter

            if (( iter == num_iteration-1 )); then
                sudo $base/utils/parse_result.sh SmartLLC_0_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh Isolated_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_1_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_2_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_3_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi
        done
        sudo $base/utils/parse_step.sh $bench_type ${bss[$i]} ${pkts[$i]}
    done
    #sudo $base/concat.sh $bench_type
    sudo kill -INT $(pgrep click)

elif [ "$bench_type" == "test" ]; then
    source $base/configs/workloads_test.sh
    source $base/configs/parameters_test.sh
    cd $base

    pkts=("1514")
    bss=("2048k")       # just a dummy number

    sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/smartllc_nolat.click > $result_path/dpdk_output.txt &  
    $base/workloads/start_wyatt.sh $result_path ${pkts[0]} &

    for ((i=0; i<${#pkts[@]}; i++)); do
        for ((iter=0; iter<$num_iteration; iter++)); do
            sudo taskset -c 17  $base/Baseline.sh Shared $bench_type ${pkts[$i]} ${bss[$i]}  $iter
            sudo taskset -c 17 $base/smartLLC.sh $bench_type ${pkts[$i]} ${bss[$i]} $iter 3

            if (( iter == num_iteration-1 )); then
                sudo $base/utils/parse_result.sh Shared_$bench_type/pkt${pkts[$i]}"_bs"${bss[$i]} $num_iteration
                sudo $base/utils/parse_result.sh SmartLLC_3_$bench_type"/pkt"${pkts[$i]}"_bs"${bss[$i]} $num_iteration
            fi
        done
        sudo $base/utils/parse_step.sh $bench_type ${bss[$i]} ${pkts[$i]}
    done
    #sudo $base/concat.sh $bench_type
    sudo kill -INT $(pgrep click)

fi



/home/hnpark2/ddio/scripts/workloads/end_wyatt.sh
