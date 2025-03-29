#! /bin/bash

# arguments
# Shared Isolated
run_type=$1
#run_type="Shared"
# micro or real
bench_type=$2
iter_num=$5
st_bs=$4
dpdk_pkt=$3

# Directories
base="/home/hnpark2/ddio"

fio_jobfile=$BASE_PATH"/app/configs/smartllc.fio"

tmp_mem="$BASE_PATH/tmp/mem.txt"
tmp_io="$BASE_PATH/tmp/io.txt"
tmp_dpdk="$BASE_PATH/tmp/dpdk.txt"
tmp_pcie="$BASE_PATH/tmp/pcie.txt"
rm $BASE_PATH/tmp/*.txt



# Variables
# Import Workloads information (name, timeline, type, numcore, program command, ... etc)
# source $BASE_PATH/scripts/workloads.sh
if [ "$bench_type" == "micro" ]; then
    result_base="$BASE_PATH/results/"$run_type"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $BASE_PATH/scripts/configs/workloads.sh
    source $BASE_PATH/scripts/configs/parameters.sh
    export SIZE=$st_bs
elif [ "$bench_type" == "real" ]; then
    result_base="$BASE_PATH/results/"$run_type"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $BASE_PATH/scripts/configs/workloads_real.sh
    source $BASE_PATH/scripts/configs/parameters_real.sh
    bs_cf="SmartLLC_$st_bs"
elif [ "$bench_type" == "real2" ]; then
    result_base="$BASE_PATH/results/"$run_type"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $BASE_PATH/scripts/configs/workloads_real2.sh
    source $BASE_PATH/scripts/configs/parameters_real2.sh
fi

mkdir -p $result_base


# Get the date
RAW_DATE=$(date '+%Y-%m-%d')
RAW_TIME=$(date '+%H-%M-%S')

# Start iteration 
for ((iter=iter_num; iter<iter_num+1; iter++)); do

    $BASE_PATH/scripts/utils/kill_all.sh > /dev/null
    sudo rm /var/lib/redis/dump.rdb

    result_path="$result_base/$iter"
    mkdir -p $result_path
    rm -r $result_path/*

    # running command of the applications
    # sudo xmem -t -n300000 -r -W -c256 -j${num_core[0]} -w$xmem_ws &
    if [ "$bench_type" == "micro" ]; then
        # Microbenchmarks
        run_command=(   "" \
                        #"sudo $dpdk_path/dpdk-rx -l ${cpu_list[1]} -a $network_device -- -d $dpdk_latency -l 10000 > $result_path/dpdk_output.txt &  $BASE_PATH/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        "sudo -E taskset -c ${cpu_list[2]} fio $fio_jobfile &" \
                        # ""\
                        # "sudo xmem_c11 -t -n300000 -r -R -c256 -j${num_core[3]} -w$xmem_large_ws &" \
                        # "sudo xmem_c14 -t -n300000 -r -R -c256 -j${num_core[4]} -w$xmem_large_ws &" \
                        "" \
                        "" \
                        "" \
                        "" )
    elif [ "$bench_type" == "real" ]; then
        # Real Bench
        # app_name=(  "fastclick"     "ffsb"      "Redis-server"     "Redis"      "mcf"      "cactuBSSN"    "gcc"     "omnetpp"       "xalancbmk"     "parest")
        run_command=(   #"sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/compute_config.click > $result_path/dpdk_output.txt &  $BASE_PATH/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        "sudo -E $BASE_PATH/scripts/workloads/run_ffsb.sh ${cpu_list[1]} $bs_cf &" \
                        "$BASE_PATH/scripts/workloads/run_redis_s.sh ${cpu_list[2]} &" \
                        "$BASE_PATH/scripts/workloads/run_YCSB.sh ${cpu_list[3]} $result_path $bench_type &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[4]} ${app_name[4]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[5]} ${app_name[5]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[6]} ${app_name[6]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[7]} ${app_name[7]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[8]} ${app_name[8]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[9]} ${app_name[9]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[10]} ${app_name[10]} run &"\
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[11]} ${app_name[11]} run &")
    elif [ "$bench_type" == "real2" ]; then
        # Real Bench
        # app_name=(  "fastclick"     "ffsb"      "Redis-server"     "Redis"      "mcf"      "cactuBSSN"    "gcc"     "omnetpp"       "xalancbmk"     "parest")
        run_command=(   #"sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/compute_config.click > $result_path/dpdk_output.txt &  $BASE_PATH/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        # "sudo -E taskset -c ${cpu_list[1]} /home/hnpark2/bench/fio/fio_lat $heavy_jobfile &" \
                        # "sudo -E taskset -c ${cpu_list[2]} /home/hnpark2/bench/fio/fio_lat $light_jobfile &" \
                        "sudo -E $BASE_PATH/scripts/workloads/run_heavy_ffsb.sh ${cpu_list[1]} &" \
                        "sudo -E $BASE_PATH/scripts/workloads/run_light_ffsb.sh ${cpu_list[2]} &" \
                        "sudo -E stdbuf -oL $BASE_PATH/scripts/workloads/run_redis_s.sh ${cpu_list[3]} &" \
                        "sudo -E stdbuf -oL $BASE_PATH/scripts/workloads/run_YCSB.sh ${cpu_list[4]} $result_path $bench_type &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[5]} ${app_name[5]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[6]} ${app_name[6]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[7]} ${app_name[7]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[8]} ${app_name[8]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[9]} ${app_name[9]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[10]} ${app_name[10]} run &" \
                        "$BASE_PATH/scripts/workloads/run_spec.sh ${cpu_list[11]} ${app_name[11]} run &")
    fi
    
    if [ "$run_type" == "Isolated" ]; then
        for ((i=0; i<8; i++)); do
            sudo pqos -e llc:$((i))=${isolation_ways[$i]} > /dev/null
            sudo pqos -a llc:$((i))=${isol_cpu_list[$i]} > /dev/null
        done
        sudo pqos -s | grep -A 12 "COS definitions for Socket 0" >> $result_path/LLC_log.txt
        sudo pqos -s | grep -A 18 "Core information for socket 0:" >> $result_path/LLC_log.txt
    fi

    
    cd $PCM_PATH
    core_num=17

    for ((t=0; t<$runtime; t++)); do
        echo "[Runtime: "$t"]"
        new_app="False"
        for ((i=0; i<$num_application; i++)); do
            if (( start_time[i] == t )); then
                eval ${run_command[$i]} > $result_path/${app_name[$i]}_log.txt 2>&1
                new_app="True"
                # sleep 5
            fi
        done
        # if [[ $new_app == "True" ]]; then
        if (( t == 4 )); then
            sleep 10
        fi
        if (( t == report_start_time )); then
            sudo stdbuf -oL taskset -c 17 stdbuf -oL  pcm  1 -silent | stdbuf -oL grep -A $(($core_num + 1)) "Core (SKT)" > $result_path/core_raw.txt 2>&1 &
            sudo stdbuf -oL taskset -c 17 stdbuf -oL  ./pcm-iio   1 -silent | stdbuf -oL grep -A 62 "Socket0" > $result_path/io_thruput.txt 2>&1 &  
            sudo stdbuf -oL taskset -c 17 stdbuf -oL  pcm-pcie 1 -e -silent  | stdbuf -oL grep -A 3 "Skt" > $result_path/pcie_raw.txt 2>&1 &   
            sudo stdbuf -oL taskset -c 17 stdbuf -oL  pcm-memory  1 -silent | stdbuf -oL grep "SKT  0 Mem " > $tmp_mem 2>&1 &
        fi
        sleep $monitoring_time
    done

    sudo pkill pcm

    # start parsing
    sed '/Core/,+1d;/^$/d;/--/d;s/|//g;s/ K/000/g;s/ M/000000/g' $result_path/core_raw.txt > $result_path/core.txt
    cp $result_path/core.txt $result_path/tmp.txt
    line=$( wc -l < $result_path/core.txt )
    awk -v ln="$line" -v cn="$core_num" '{if(NR <= int(ln/cn)*cn) print $0}' $result_path/tmp.txt > $result_path/core.txt
    sed -i '/Skt/d;/--/d;s/ K/000/g;s/ M/000000/g;s/ G/000000000/g' $result_path/pcie_raw.txt 
    # get L2 hit / miss L3 hit / miss of running cores
    awk '{print $2"  "$10"  "$8"  "$9"  "$7"  "$5}' $result_path/core.txt > $result_path/cache_stat.txt
    awk 'BEGIN{sl2h=0; sl2m=0; sl3h; sl3m; cnt=0;} {
    sl2h+=$2/1000; sl2m+=$3/1000; sl3h+=$4/1000; sl3m+=$5/1000; cnt++; 
    } END{print "Average_per_core_L2_HIT(K): " sl2h/cnt;  print "Average_per_core_L2_MISS(K): " sl2m/cnt;
    print "Average_per_core_L3_HIT(K): " sl3h/cnt;  print "Average_per_core_L3_MISS(K): " sl3m/cnt;}' $result_path/cache_stat.txt >> $result_path/result.txt
    
    # get PCIe miss rate
    awk '{if( (NR%3) != 1){print $6/1000000}}'  $result_path/pcie_raw.txt > $result_path/pcie.txt 
    awk 'BEGIN{spm=0; sph=0; cnt=0;} { if(NR>2){ if(NR%2){spm+=$1; cnt++;}else{sph+=$1;}}
    } END{print "PCIe_Hit_Count(M): " sph/cnt; print "PCIe_Miss_Count(M): " spm/cnt;
    print "PCIe_Miss_Rate(%): " (spm/(spm+sph))*100;}' $result_path/pcie.txt >> $result_path/result.txt

    # get IPC of running cores
    awk '{print $2"   "$5}' $result_path/core.txt > $result_path/IPC.txt
    echo -n "Average_IPC: " >> $result_path/result.txt
    awk 'BEGIN{sum=0; cnt=0;} {sum+=$2; cnt++;} END{print sum/cnt}' $result_path/IPC.txt >> $result_path/result.txt
    
    # get Storage Throughput
    if [ "$bench_type" == "real" ]; then
        cat $result_path/io_thruput.txt | grep -B 10 $storage_device | grep -E "Part0|Part1|Part2|Part3" > $result_path/tmp.txt
        awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/storage_io.txt
        awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage_Throughput_R(GB/s): "4*(sumr)/cnt; print "Storage_Throughput_W(GB/s): "4*(sumw)/cnt;
                }' $result_path/storage_io.txt >> $result_path/result.txt
    elif [ "$bench_type" == "real2" ]; then
        cat $result_path/io_thruput.txt | grep -B 10 $storage_device | grep -E "Part0|Part1|Part2" > $result_path/tmp.txt
        awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/storage_io.txt
        awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage1_Throughput_R(GB/s): "3*(sumr)/cnt; print "Storage1_Throughput_W(GB/s): "3*(sumw)/cnt;
                }' $result_path/storage_io.txt >> $result_path/result.txt

        cat $result_path/io_thruput.txt | grep -B 10 $storage_device | grep -E "Part3" > $result_path/tmp.txt
        awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/storage_io.txt
        awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage2_Throughput_R(GB/s): "(sumr)/cnt; print "Storage2_Throughput_W(GB/s): "(sumw)/cnt;
                }' $result_path/storage_io.txt >> $result_path/result.txt
    fi
    
    # get IO throughput
    cat $result_path/io_thruput.txt | grep -B 10 $network_device | grep "Part0" > $result_path/tmp.txt
    awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/network_io.txt
    awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
        if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
        if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
    } END{print "Network_Throughput_R(GB/s): "(sumr)/cnt; print "Network_Throughput_W(GB/s): "(sumw)/cnt;
    }' $result_path/network_io.txt >> $result_path/result.txt
    # echo -n "Network_Throughput_R(MB/s): " >> $result_path/result.txt
    # awk 'BEGIN{sum=0; cnt=0;} {if($4=="M"){sum+=$3;cnt++;}else if($4=="G"){sum+=$3*1000;cnt++;}else if($4=="K"){sum+=$3/1000;cnt++;}} 
    # END{print sum/cnt}' $result_path/network_io.txt >> $result_path/result.txt
    
    sudo rm -f $result_path/dump.rdb
    sudo rm $result_base/result_"$iter".txt
    
    for ((i=0; i<$num_application; i++)); do
        if [ "${type[$i]}" == "LCA" ]; then
            cat $result_path/cache_stat.txt | awk -v s="${start_core[$i]}" -v e="${end_core[$i]}" '{if($1>=s && $1<=e){print $0}}' >> $result_path/lca_cache_stat.txt
        else
            cat $result_path/cache_stat.txt | awk -v s="${start_core[$i]}" -v e="${end_core[$i]}" '{if($1>=s && $1<=e){print $0}}' >> $result_path/bea_cache_stat.txt
        fi
    done

    cat $result_path/lca_cache_stat.txt | awk 'BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
    sl2h+=$2/1000; sl2m+=$3/1000; sl3h+=$4/1000; sl3m+=$5/1000; ipc+=$6; cnt++;} END{print "LSW_L2_Hit_Rate(%): "sl2h/(sl2h+sl2m)*100;
    print "LSW_L3_Hit_Rate(%): "sl3h/(sl3h+sl3m)*100;
    print "LSW_IPC: "ipc/cnt;}' >> $result_base/result_"$iter".txt

    cat $result_path/bea_cache_stat.txt | awk 'BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
    sl2h+=$2/1000; sl2m+=$3/1000; sl3h+=$4/1000; sl3m+=$5/1000; ipc+=$6; cnt++; } END{print "BEW_L2_Hit_Rate(%): "sl2h/(sl2h+sl2m)*100;
    print "BEW_L3_Hit_Rate(%): "sl3h/(sl3h+sl3m)*100;
    print "BEW_IPC: "ipc/cnt;}' >> $result_base/result_"$iter".txt

    rates=("L2" "L3" "PCIe")
    for rate in "${rates[@]}"; do 
        cat $result_path/result.txt | grep $rate | \
        awk -v r="$rate" '{if(NR==1){h=$2;} if(NR==2){m=$2;}}END{print r"_Hit_Rate(%): "(h/(m+h))*100}' >> $result_base/result_"$iter".txt
    done

    if [ "$bench_type" == "real" ]; then
        tail -n 5 $result_path/result.txt >> $result_base/result_"$iter".txt
    elif [ "$bench_type" == "real2" ]; then
        tail -n 7 $result_path/result.txt >> $result_base/result_"$iter".txt
    fi
    # if [ "$bench_type" == "micro" ]; then
    #     cat $result_path/dpdk_output.txt | grep "Average" | awk '{print "DPDK_Processing Rate: "$6}' >> $result_base/result_"$iter".txt
    # elif [ "$bench_type" == "real" ]; then
    #     cat $result_path/dpdk_output.txt | grep "byte rate is" | awk '{print "DPDK_Processing Rate(MB/s): "$9/1024/1024}' >> $result_base/result_"$iter".txt
    # fi

    cat $tmp_mem | grep "Read" | awk 'BEGIN{ sum=0; cnt=0;} {sum += $8/1024; cnt++;} END {print "Mem_read(GB/s): "sum / cnt;}' >> $result_base/result_"$iter".txt
    cat $tmp_mem | grep "Write" | awk 'BEGIN{ sum=0; cnt=0;} {sum += $7/1024; cnt++;} END {print "Mem_write(GB/s): "sum / cnt;}' >> $result_base/result_"$iter".txt

    cat $BASE_PATH/results/tx_result.txt | grep "Average_e2e_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_e2e_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $BASE_PATH/results/tx_result.txt | grep "Average_remote_mem_access_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_remote_mem_access_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $BASE_PATH/results/tx_result.txt | grep "Average_remote_compute_access_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_remote_compute_access_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $BASE_PATH/results/tx_result.txt | grep "Average_remote_nic-host_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_remote_nic-host_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt


    cat $BASE_PATH/results/tx_result.txt | grep "99%_e2e_tail_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "99%_e2e_tail_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $BASE_PATH/results/tx_result.txt | grep "99%_remote_mem_access_tail_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "99%_remote_mem_access_tail_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $BASE_PATH/results/tx_result.txt | grep "99%_remote_compute_tail_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "99%_remote_compute_tail_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $BASE_PATH/results/tx_result.txt | grep "99%_remote_nic-host_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "99%_remote_nic-host_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt


    $BASE_PATH/scripts/utils/kill_all.sh > /dev/null  

    if [ "$bench_type" == "real" ]; then
        sleep 5
        cat $result_path/ffsb_log.txt | grep "breakdown" >> $result_base/result_"$iter".txt
        # sleep 1
        # cat $result_path/ffsb_log.txt | grep -A 10 "read:" | grep -E 'clat \(usec\)|99.00th=' | awk '/clat \(usec\)/ { split($5, avg_clat, "="); gsub(",", "", avg_clat[2]); print "avg_read:", avg_clat[2]
        #     } /99.00th=/ { split($2, p99_clat, "="); gsub(/\[|\]|,/, "", p99_clat[2]); print "p99_read:", p99_clat[2]}' >> $result_base/result_"$iter".txt
        # cat $result_path/ffsb_log.txt | grep -A 10 "write:" | grep -E 'clat \(usec\)|99.00th=' | awk '/clat \(usec\)/ { split($5, avg_clat, "="); gsub(",", "", avg_clat[2]); print "avg_write:", avg_clat[2]
        #     } /99.00th=/ { split($2, p99_clat, "="); gsub(/\[|\]|,/, "", p99_clat[2]); print "p99_write:", p99_clat[2]}' >> $result_base/result_"$iter".txt
    elif [ "$bench_type" == "real2" ]; then
        sleep 10
        cat $result_path/heavy_ffsb_log.txt | grep "breakdown" >> $result_base/result_"$iter".txt
        cat $result_path/light_ffsb_log.txt | grep "breakdown" >> $result_base/result_"$iter".txt
        # sleep 1
        # cat $result_path/heavy_ffsb_log.txt | grep -A 10 "read:" | grep -E 'clat \(usec\)|99.00th=' | awk '/clat \(usec\)/ { split($5, avg_clat, "="); gsub(",", "", avg_clat[2]); print "Heavy_avg_read:", avg_clat[2]
        #     } /99.00th=/ { split($2, p99_clat, "="); gsub(/\[|\]|,/, "", p99_clat[2]); print "Heavy_p99_read:", p99_clat[2]}' >> $result_base/result_"$iter".txt
        # cat $result_path/heavy_ffsb_log.txt | grep -A 10 "write:" | grep -E 'clat \(usec\)|99.00th=' | awk '/clat \(usec\)/ { split($5, avg_clat, "="); gsub(",", "", avg_clat[2]); print "Heavy_avg_write:", avg_clat[2]
        #     } /99.00th=/ { split($2, p99_clat, "="); gsub(/\[|\]|,/, "", p99_clat[2]); print "Heavy_p99_write:", p99_clat[2]}' >> $result_base/result_"$iter".txt
        # cat $result_path/light_ffsb_log.txt | grep -A 10 "read:" | grep -E 'clat \(usec\)|99.00th=' | awk '/clat \(usec\)/ { split($5, avg_clat, "="); gsub(",", "", avg_clat[2]); print "Light_avg_read:", avg_clat[2]
        #     } /99.00th=/ { split($3, p99_clat, "="); gsub(/\[|\]|,/, "", p99_clat[1]); print "Light_p99_read:", p99_clat[1]}' >> $result_base/result_"$iter".txt
        # cat $result_path/light_ffsb_log.txt | grep -A 10 "write:" | grep -E 'clat \(usec\)|99.00th=' | awk '/clat \(usec\)/ { split($5, avg_clat, "="); gsub(",", "", avg_clat[2]); print "Light_avg_write:", avg_clat[2]
        #     } /99.00th=/ { split($3, p99_clat, "="); gsub(/\[|\]|,/, "", p99_clat[1]); print "Light_p99_write:", p99_clat[1]}' >> $result_base/result_"$iter".txt
    fi
    # per application stat (L2 hit rate. L3 hit rate)
    for ((i=0; i<$num_application; i++)); do
        cat $result_path/cache_stat.txt | awk -v s="${start_core[$i]}" -v e="${end_core[$i]}" -v name="${app_name[$i]}" '
        BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
        if($1>=s && $1<=e){sl2h+=$2/1000; sl2m+=$3/1000; sl3h+=$4/1000; sl3m+=$5/1000; ipc+=$6; cnt++;} } 
        END{print name"_L2_Hit_Rate(%): "sl2h/(sl2h+sl2m)*100; print name"_L3_Hit_Rate(%): "sl3h/(sl3h+sl3m)*100;
        print name"_IPC: "ipc/cnt;}' >> $result_base/result_"$iter".txt
        if [ "${type[$i]}" == "LCA" ]; then
            cat $result_path/cache_stat.txt | awk -v s="${start_core[$i]}" -v e="${end_core[$i]}" '{if($1>=s && $1<=e){print $0}}' >> $result_path/lca_cache_stat.txt
        else
            cat $result_path/cache_stat.txt | awk -v s="${start_core[$i]}" -v e="${end_core[$i]}" '{if($1>=s && $1<=e){print $0}}' >> $result_path/bea_cache_stat.txt
        fi
    done

done

