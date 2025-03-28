#! /bin/bash

# arguments
# SmartLLC or Baseline
run_type="SmartLLC"
# micro or real
bench_type=$1
iter_num=$4
st_bs=$3
dpdk_pkt=$2
option=$5

# Directories
base="/home/hnpark2/ddio"

dbench_path="/home/hnpark2/tool/ddio-bench"
pcm_path="/home/hnpark2/tool/pcm/build/bin"
fio_jobfile="/home/hnpark2/bench/fio/ddio_jobfile/smartllc.fio"
heavy_jobfile="/home/hnpark2/bench/fio/ddio_jobfile/heavy.fio"
light_jobfile="/home/hnpark2/bench/fio/ddio_jobfile/light.fio"
dpdk_path="/home/hnpark2/bench/dpdk-framework/dpdk-rx"
fc_path="/home/hnpark2/bench/fastclick"

tmp_mem="$base/tmp/mem.txt"
tmp_io="$base/tmp/io.txt"
tmp_dpdk="$base/tmp/dpdk.txt"
tmp_pcie="$base/tmp/pcie.txt"
rm $base/tmp/*.txt



# Variables
# Import Workloads information (name, timeline, type, numcore, program command, ... etc)
if [ "$bench_type" == "micro" ]; then
    result_base="$base/results/"$run_type"_"$option"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $base/scripts/configs/workloads.sh
    source $base/scripts/configs/parameters.sh
    export SIZE=$st_bs

elif [ "$bench_type" == "real" ]; then
    result_base="$base/results/"$run_type"_"$option"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $base/scripts/configs/workloads_real.sh
    source $base/scripts/configs/parameters_real.sh
    bs_cf="SmartLLC_$st_bs"
    LCA_LLC_HIT_FL=0.2
    LOC_LLC_MISS_THR=90
    LK_STG_DDIO_MS_THR=40
    LK_STG_TP_THR=35
    LK_STG_LLC_MS_THR=40
    echo "==============================Bench Type Real=============================="
    if [ "$6" == "sens" ]; then
        echo "=============================Running A4 sensitivuty Study ($7, $8) ============================="
        LCA_LLC_HIT_FL=$7
        LOC_LLC_MISS_THR=$8
        LK_STG_DDIO_MS_THR=40
        LK_STG_TP_THR=35
        LK_STG_LLC_MS_THR=40
        # if [ "$7" == "0.3" ]; then
        #     BE_SET=5
        #     AT_SET=2
        # elif [ "$7" == "0.2" ]; then
        #     BE_SET=5
        #     AT_SET=2
        # fi

    elif [ "$6" == "sens2" ]; then
        echo "=============================Running A4 sensitivuty Study 2 ($7, $8, $9) ============================="
        LCA_LLC_HIT_FL=0.2
        LOC_LLC_MISS_THR=90
        LK_STG_DDIO_MS_THR=$7
        LK_STG_TP_THR=$8
        LK_STG_LLC_MS_THR=$9
    elif [ "$6" == "fixed" ]; then
        echo "=============================Running A4 sensitivuty Study Timing ============================="
        BE_SET=$7
        AT_SET=$8
    fi
elif [ "$bench_type" == "real2" ]; then
    result_base="$base/results/"$run_type"_"$option"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $base/scripts/configs/workloads_real2.sh
    source $base/scripts/configs/parameters_real2.sh
    LCA_LLC_HIT_FL=0.2
    LOC_LLC_MISS_THR=90
    LK_STG_DDIO_MS_THR=40
    LK_STG_TP_THR=35
    LK_STG_LLC_MS_THR=40
    echo "==============================Bench Type Real=============================="
    if [ "$6" == "sens" ]; then
        echo "=============================Running A4 sensitivuty Study ($7, $8) ============================="
        LCA_LLC_HIT_FL=$7
        LOC_LLC_MISS_THR=$8
        LK_STG_DDIO_MS_THR=40
        LK_STG_TP_THR=35
        LK_STG_LLC_MS_THR=40

    elif [ "$6" == "sens2" ]; then
        echo "=============================Running A4 sensitivuty Study 2 ($7, $8, $9) ============================="
        LCA_LLC_HIT_FL=0.2
        LOC_LLC_MISS_THR=90
        LK_STG_DDIO_MS_THR=$7
        LK_STG_TP_THR=$8
        LK_STG_LLC_MS_THR=$9
    elif [ "$6" == "fixed" ]; then
        echo "=============================Running A4 sensitivuty Study Timing ============================="
        BE_SET=$7
        AT_SET=$8
    fi
elif [ "$bench_type" == "test" ]; then
    result_base="$base/results/"$run_type"_"$option"_"$bench_type"/pkt"$dpdk_pkt"_bs"$st_bs
    source $base/scripts/configs/workloads_test.sh
    source $base/scripts/configs/parameters_test.sh
    export SIZE=2048k
fi

mkdir -p $result_base


# Get the date
RAW_DATE=$(date '+%Y-%m-%d')
RAW_TIME=$(date '+%H-%M-%S')


# Start iteration 
for ((iter=iter_num; iter<iter_num+1; iter++)); do

    # Init script
    # rm $result_base/result_"$iter".txt
    # sudo $base/scripts/utils/init.sh > /dev/null
    sudo $base/scripts/utils/kill_all.sh > /dev/null
    sudo rm -f /home/hnpark2/ddio/scripts/workloads/dump.rdb

    result_path="$result_base/"$iter
    mkdir -p $result_path
    rm -r $result_path/*
    sudo rm $result_base/result_"$iter".txt
    # Init(new application launched, set initial value) Adj (Reduce until THR), Stable(Reclam when phase change)
    state="Stable"
    LC_Adj="False"
    AT_Adj="False"

    # running command of the applications
    if [ "$bench_type" == "micro" ]; then
        # Microbenchmarks
        # sudo xmem -t -n300000 -r -W -c256 -j${num_core[0]} -w$xmem_ws &
        run_command=(   "" \
                        #"sudo stdbuf -oL $dpdk_path/dpdk-rx -l ${cpu_list[1]} -a $network_device -- -d $dpdk_latency -l 10000 > $result_path/dpdk_output.txt &  $base/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        "sudo -E taskset -c ${cpu_list[2]} /home/hnpark2/bench/fio/fio_lat $fio_jobfile &" \
                        ""\
                        #"sudo xmem_c11 -t -n300000 -r -R -c256 -j${num_core[3]} -w$xmem_large_ws &" \
                        # "sudo xmem_c14 -t -n300000 -r -W -c256 -j${num_core[4]} -w$xmem_large_ws &" \
                        "" \
                        "" \
                        "" \
                        "" )
    elif [ "$bench_type" == "real" ]; then
        # Real Bench
        # app_name=(  "fastclick"     "ffsb"      "Redis-server"     "Redis"      "mcf"      "cactuBSSN"    "gcc"     "omnetpp"       "xalancbmk"     "parest")
        run_command=(   #"sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/compute_config.click > $result_path/dpdk_output.txt &  $base/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        "sudo $base/scripts/workloads/run_ffsb.sh ${cpu_list[1]} $bs_cf &" \
                        "sudo stdbuf -oL $base/scripts/workloads/run_redis_s.sh ${cpu_list[2]} &" \
                        "sudo stdbuf -oL $base/scripts/workloads/run_YCSB.sh ${cpu_list[3]} $result_path $bench_type &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[4]} ${app_name[4]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[5]} ${app_name[5]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[6]} ${app_name[6]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[7]} ${app_name[7]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[8]} ${app_name[8]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[9]} ${app_name[9]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[10]} ${app_name[10]} run &"\
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[11]} ${app_name[11]} run &")
    elif [ "$bench_type" == "real2" ]; then
        # Real Bench
        # app_name=(  "fastclick"     "ffsb"      "Redis-server"     "Redis"      "mcf"      "cactuBSSN"    "gcc"     "omnetpp"       "xalancbmk"     "parest")
        run_command=(   #"sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/compute_config.click > $result_path/dpdk_output.txt &  $base/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        # "sudo -E taskset -c ${cpu_list[1]} /home/hnpark2/bench/fio/fio_lat $heavy_jobfile &" \
                        # "sudo -E taskset -c ${cpu_list[2]} /home/hnpark2/bench/fio/fio_lat $light_jobfile &" \
                        "sudo $base/scripts/workloads/run_heavy_ffsb.sh ${cpu_list[1]} &" \
                        "sudo $base/scripts/workloads/run_light_ffsb.sh ${cpu_list[2]} &" \
                        "sudo stdbuf -oL $base/scripts/workloads/run_redis_s.sh ${cpu_list[3]} &" \
                        "sudo stdbuf -oL $base/scripts/workloads/run_YCSB.sh ${cpu_list[4]} $result_path $bench_type &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[5]} ${app_name[5]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[6]} ${app_name[6]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[7]} ${app_name[7]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[8]} ${app_name[8]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[9]} ${app_name[9]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[10]} ${app_name[10]} run &" \
                        "sudo -u hnpark2 $base/scripts/workloads/run_spec.sh ${cpu_list[11]} ${app_name[11]} run &")
    elif [ "$bench_type" == "test" ]; then
        # Real Bench
        # app_name=(  "fastclick"     "ffsb"      "Redis-server"     "Redis"      "mcf"      "cactuBSSN"    "gcc"     "omnetpp"       "xalancbmk"     "parest")
        run_command=(   #"sudo $fc_path/bin/click --dpdk -l ${cpu_list[0]} -a $network_device -- $fc_path/compute_config.click > $result_path/dpdk_output.txt &  $base/scripts/start_spr3.sh $result_path $dpdk_pkt &" \
                        ""\
                        #"sudo $base/scripts/workloads/run_heavy_ffsb.sh ${cpu_list[1]} &" \
                        "sudo -E taskset -c ${cpu_list[1]} /home/hnpark2/bench/fio/fio_lat /home/hnpark2/bench/fio/ddio_jobfile/smartllc.fio &" \
                        "sudo $base/scripts/workloads/run_light_ffsb.sh ${cpu_list[2]} &" )
        
    fi


    # Start Main log
    echo $RAW_DATE $RAW_TIME > $result_path/main_log.txt
    # Print workload scenario and parameters to the config file
    echo "===============Smart LLC Parameters===============" > $result_path/config.txt
    for param in "${THR_PARAMS[@]}"; do
        printf "%-20s" $param": " >> $result_path/config.txt
        printf "%5s\n" "${!param}" >> $result_path/config.txt
    done
    echo -e "\n===============Workload Parameters===============" >> $result_path/config.txt
    for param in "${WRKLD_PARAMS[@]}"; do
            eval tmp_arr=\( \${${param}[@]} \)
            printf "\n%-12s" $param": " >> $result_path/config.txt
        for ((i = 0; i < $num_application ; i ++)); do
            printf "%1s%13s%1s" "" "${tmp_arr[$i]}" "" >> $result_path/config.txt
        done
    done

    echo -e "\n===============CAT Configuration(Initial)===============" > $result_path/LLC_log.txt
    for param in "${ZONE_PARAMS[@]}"; do
        printf "%-15s" $param": " >> $result_path/LLC_log.txt
        printf "%10s%5s" "${!param}" " ">> $result_path/LLC_log.txt
        if [[ $param == *"LIST"* ]]; then
            printf "\n"  >> $result_path/LLC_log.txt
        fi
    done

    sudo pqos -s | grep -A 8 "COS definitions for Socket 0" >> $result_path/LLC_log.txt
    sudo pqos -s | grep -A 18 "Core information for socket 0:" >> $result_path/LLC_log.txt


    for ((t=0; t<$runtime; t++)); do
        echo "===============[Time $t Log]===============" >> $result_path/main_log.txt
        # re-calculate cpu list of non-IO LCA, IO-LCA, BEA, and Antagonist
        IOLC_CPU_LIST=""
        LC_CPU_LIST=""
        BE_CPU_LIST="17,"
        AT_CPU_LIST=""
        SIO_CPU_LIST=""
        IOLC_APP_LIST=""
        LC_APP_LIST=""
        BE_APP_LIST=""
        AT_APP_LIST=""
        AT_AN_LIST=""
        SIO_APP_LIST=""
        SIO_AN_LIST=""
        new_app="False"
        network_io="False"
        storage_io="False"
        reset_flag="False"
        stop_flag="False"
        for ((i=0; i<$num_application; i++)); do
            if (( start_time[i] > t )); then
                break
            fi
            if [ "${device[$i]}" == "network" ]; then
                network_io="True"
            fi
            if [ "${device[$i]}" == "storage" ]; then
                storage_io="True"
            fi
            # IO LCA
            if [ "${type[$i]}" == "LCA" ] && [ "${isAT[$i]}" == "0" ] && [ "${isIOIA[$i]}" == "1" ]; then
                if [ -z "$IOLC_CPU_LIST" ]; then
                    IOLC_APP_LIST="${app_name[$i]}"
                    IOLC_CPU_LIST="${cpu_list[$i]}"
                else
                    IOLC_APP_LIST="$IOLC_APP_LIST, ${app_name[$i]}"
                    IOLC_CPU_LIST="$IOLC_CPU_LIST,${cpu_list[$i]}"
                fi
            fi
            # Non-IO LCA
            if [ "${type[$i]}" == "LCA" ] && [ "${isAT[$i]}" == "0" ] && [ "${isIOIA[$i]}" == "0" ]; then
                if [ -z "$LC_CPU_LIST" ]; then
                    LC_APP_LIST="${app_name[$i]}"
                    LC_CPU_LIST="${cpu_list[$i]}"
                else
                    LC_APP_LIST="$LC_APP_LIST, ${app_name[$i]}"
                    LC_CPU_LIST="$LC_CPU_LIST,${cpu_list[$i]}"
                fi
            fi
            # BEA
            if [ "${type[$i]}" == "BEA" ] && [ "${isAT[$i]}" == "0" ]; then
                if [ -z "$BE_CPU_LIST" ]; then
                    BE_APP_LIST="${app_name[$i]}"
                    BE_CPU_LIST="${cpu_list[$i]}"
                else
                    BE_APP_LIST="$BE_APP_LIST, ${app_name[$i]}"
                    BE_CPU_LIST="$BE_CPU_LIST,${cpu_list[$i]}"
                fi
            fi
            # ATA
            if [ "${isAT[$i]}" == "1" ]; then
                if [ "${device[$i]}" == "storage" ]; then
                    SIO_AN_LIST=("$i")
                    if [ -z "$SIO_CPU_LIST" ]; then
                        SIO_APP_LIST="${app_name[$i]}"
                        SIO_CPU_LIST="${cpu_list[$i]}"
                    else
                        SIO_APP_LIST="$SIO_APP_LIST, ${app_name[$i]}"
                        SIO_CPU_LIST="$SIO_CPU_LIST,${cpu_list[$i]}"
                    fi
                else 
                    AT_AN_LIST+=("$i")
                    if [ -z "$AT_CPU_LIST" ]; then
                        AT_APP_LIST="${app_name[$i]}"
                        AT_CPU_LIST="${cpu_list[$i]}"
                    else
                        AT_APP_LIST="$AT_APP_LIST, ${app_name[$i]}"
                        AT_CPU_LIST="$AT_CPU_LIST,${cpu_list[$i]}"
                    fi
                fi
                
            fi
        done

        echo -e "\n===============CAT Configuration(t=$t)===============" >> $result_path/LLC_log.txt
        printf "%s%12s%s%9s%s%10s%s\n" "[COS1: IO LCA" "" "COS2: Non-IO LCA" "" "COS3: BEA" "" "COS4: ATA]"  >> $result_path/LLC_log.txt
        # launch new application if any
        for ((i=0; i<$num_application; i++)); do
            # if there is a new application, reset LC/BE zone
            if (( start_time[i] == t )); then
                echo "[Launching APP: " ${app_name[$i]} "]: " ${run_command[$i]} >> $result_path/main_log.txt
                echo "[Zone RESET, Gather Initial Info]" >> $result_path/main_log.txt
                eval ${run_command[$i]} > $result_path/${app_name[$i]}_log.txt 2>&1
                # sleep 5
                new_app="True"
                state="Init"
                LC_Adj="True"
                core_num=$(( ${end_core[$i]} + 1))
                if [ -n "$BE_CPU_LIST" ]; then
                    BE_num=$BE_init
                else
                    BE_num=0
                fi
                if [ -n "$IOLC_CPU_LIST" ] && [ "$option" != "1" ]; then
                    IO_num=2
                else
                    IO_num=0
                fi
                
                # LC_num=$(($LC_init - $BE_num - $IO_num))
                LC_num=$(( LC_init - IO_num ))
                
            fi
        done
        # if there is no new application, apply CAT corresponds to zone configurations

        # Calculate CAT way from zone parameter
        if [ "$option" == "1" ]; then
            BE_CAT=$(printf "0x%x" "$((( 2 ** BE_num - 1)))")
        else
            BE_CAT=$(printf "0x%x" "$(( ( 2 ** BE_num - 1) * 4))")
        fi

        if [ "$6" == "fixed" ]; then
            BE_num=$BE_SET
            BE_CAT=$(printf "0x%x" "$(( ( 2 ** BE_num - 1) * 4))")
        fi

        LC_CAT=$(printf "0x%x" "$(( 2 ** LC_num - 1))")
        # IOLC_CAT="0x600"
        IOLC_CAT=$(printf "0x%x" "$(( 2 ** ( LC_num + IO_num ) - 1 ))")
        if [ "$option" == "3" ]; then
            AT_num=$BE_num
        fi
        if [ "$6" == "fixed" ]; then
            AT_num=$AT_SET
        fi
        # AT_CAT=$(printf "0x%x" "$(( ( 2 ** AT_num - 1) * ( 2 ** ( BE_num - AT_num + 2)) ))")
        AT_CAT=$(printf "0x%x" "$(( ( 2 ** AT_num - 1) * 4 ))")

        # COS1: IO LCA
        if [ -n "$IOLC_CPU_LIST" ]; then
            sudo pqos -e llc:1=$IOLC_CAT > /dev/null
            sudo pqos -a llc:1=$IOLC_CPU_LIST > /dev/null
        fi
        # COS2: NON-IO LCA
        if [ -n "$LC_CPU_LIST" ]; then
            sudo pqos -e llc:2=$LC_CAT > /dev/null
            sudo pqos -a llc:2=$LC_CPU_LIST > /dev/null
        fi
        # COS3: BEA
        if [ -n "$BE_CPU_LIST" ]; then
            sudo pqos -e llc:3=$BE_CAT > /dev/null
            sudo pqos -a llc:3=$BE_CPU_LIST > /dev/null
        fi
        # COS4: Antagonistic APP
        if [ -n "$AT_CPU_LIST" ]; then
            sudo pqos -e llc:4=$AT_CAT > /dev/null
            sudo pqos -a llc:4=$AT_CPU_LIST > /dev/null
        fi
        if [ -n "$SIO_CPU_LIST" ]; then
            sudo pqos -e llc:5=$AT_CAT > /dev/null
            sudo pqos -a llc:5=$SIO_CPU_LIST > /dev/null
        fi
        sudo pqos -e llc:6=0x7ff > /dev/null
        sudo pqos -a llc:6=17 > /dev/null

        # Write to LLC log file
        for param in "${ZONE_PARAMS[@]}"; do
            printf "%-15s" $param": " >> $result_path/LLC_log.txt
            printf "%5s%5s" "${!param}" " " >> $result_path/LLC_log.txt
            if [[ $param == *"LIST"* ]]; then
                printf "\n"  >> $result_path/LLC_log.txt
            fi
        done
        
        sudo pqos -s | grep -A 7 "COS definitions for Socket 0" >> $result_path/LLC_log.txt
        sudo pqos -s | grep -A 18 "Core information for socket 0:" >> $result_path/LLC_log.txt
        # monitoring for 10s
        echo "[Current State: "$state" with LC_Adj: "$LC_Adj" & AT_Adj: "$AT_Adj"]" >> $result_path/main_log.txt
        echo "[Running with LLC State: IO("$IO_num"), LC("$LC_num"), BE("$BE_num"), AT("$AT_num")]" >> $result_path/main_log.txt
        # start monitoring
        # if [[ $new_app == "True" ]]; then
        #     sleep 10
        # fi
        if (( t == 4 )); then
            sleep 10
        fi
        if (( t == 0 )); then
            cd $pcm_path
            sudo stdbuf -oL taskset -c 17 stdbuf -oL pcm 1 -silent | stdbuf -oL grep -A 19 "Core (SKT)" > $result_path/core_raw.txt 2>&1 &
            sudo stdbuf -oL taskset -c 17 stdbuf -oL ./pcm-iio 1.0 -silent | stdbuf -oL grep -A 62 "Socket0" > $result_path/io_thruput.txt 2>&1 &  
            sudo stdbuf -oL taskset -c 17 stdbuf -oL pcm-pcie 1.0 -e -silent | stdbuf -oL grep -A 3 "Skt" > $result_path/pcie_raw.txt 2>&1 &   
            sudo stdbuf -oL taskset -c 17 stdbuf -oL pcm-memory 1.0 -silent | stdbuf -oL grep "NODE 0 Mem " > $tmp_mem 2>&1 &
        fi

        sleep $monitoring_time

        # sudo pkill -x pcm 
        # sudo pkill pcm-iio 
        # sudo pkill pcm-pcie 


        unit_start_time=$(date +%s%N)
        # start parsing
        tail -n $(( 21 * monitoring_time )) $result_path/core_raw.txt > $result_path/tmp.txt
        sed '/Core/,+1d;/^$/d;/--/d;s/|//g;s/ K/000/g;s/ M/000000/g' $result_path/tmp.txt | awk -v n="16" '{if($1<=n && $1>=0){print $0}}' > $result_path/"$t"_core.txt
        # cp $result_path/"$t"_core.txt $result_path/tmp.txt
        # line=$( wc -l < $result_path/"$t"_core.txt )
        # awk -v ln="$line" -v cn="$core_num" '{if(NR <= int(ln/cn)*cn) print $0}' $result_path/tmp.txt > $result_path/"$t"_core.txt
        tail -n $(( 5 * monitoring_time )) $result_path/pcie_raw.txt > $result_path/pcie_tmp.txt
        sed -i '/Skt/d;/--/d;s/ K/000/g;s/ M/000000/g;s/ G/000000000/g' $result_path/pcie_tmp.txt
        # get results from the monitoring ($t_monitoring results)
        # Get global information
        echo "===============Global Monitoring result===============" > $result_path/"$t"_result.txt
        echo "Number of Cores: "$core_num >> $result_path/"$t"_result.txt
        # get IPC of running cores
        # awk '{print $1"   "$4}' $result_path/"$t"_core.txt > $result_path/"$t"_IPC.txt
        # awk 'BEGIN{sum=0; cnt=0;} {sum+=$2; cnt++;} END{print "Average_IPC: "sum/cnt}' $result_path/"$t"_IPC.txt >> $result_path/"$t"_result.txt
        # get L2 hit / miss L3 hit / miss of running cores
        awk '{print $1"  "$10"  "$8"  "$9"  "$7"  "$4}' $result_path/"$t"_core.txt > $result_path/"$t"_cache_stat.txt
        awk 'BEGIN{sl2h=0; sl2m=0; sl3h; sl3m; cnt=0; ipc=0} {
        sl2h+=$2/1000; sl2m+=$3/1000; sl3h+=$4/1000; sl3m+=$5/1000; ipc+=$6; cnt++; 
        } END{print "Average_IPC: "ipc/cnt;
        print "Average_per_core_L2_HIT(K): " sl2h/cnt;  print "Average_per_core_L2_MISS(K): " sl2m/cnt;
        print "Average_per_core_L3_HIT(K): " sl3h/cnt;  print "Average_per_core_L3_MISS(K): " sl3m/cnt;}' $result_path/"$t"_cache_stat.txt >> $result_path/"$t"_result.txt
        
        tail -n $(( 2 * monitoring_time )) $tmp_mem | grep "Read" | awk 'BEGIN{ sum=0; cnt=0;} {sum += $8/1024; cnt++;} END {print "Mem_Read(GB/s): "sum / cnt;}' >> $result_path/"$t"_result.txt
        tail -n $(( 2 * monitoring_time )) $tmp_mem | grep "Write" | awk 'BEGIN{ sum=0; cnt=0;} {sum += $7/1024; cnt++;} END {print "Mem_Write(GB/s): "sum / cnt;}' >> $result_path/"$t"_result.txt

        # get Storage Throughput
        if [ "$bench_type" == "real" ]; then
            # if [ "$storage_io" == "True" ]; then
            cat $result_path/io_thruput.txt | grep -B 10 $storage_device | grep -E "Part0|Part1|Part2|Part3" > $result_path/"$t"_tmp.txt
            tail -n $((4* monitoring_time)) $result_path/"$t"_tmp.txt | awk -F '|' '{print $3 " " $4}'  > $result_path/"$t"_storage_io.txt
            # echo -n "Storage_Throughput(MB/s): " >> $result_path/"$t"_result.txt
            awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage_Throughput_R(GB/s): "4*(sumr)/cnt; print "Storage_Throughput_W(GB/s): "4*(sumw)/cnt; print "Storage_Throughput(GB/s): "4*(sumr+sumw)/cnt;
                }' $result_path/"$t"_storage_io.txt >> $result_path/"$t"_result.txt
            # echo -n "Storage_Throughput_R(GB/s): " >> $result_path/"$t"_result.txt
            # awk 'BEGIN{sum=0; cnt=0;} {if($4=="M"){sum+=$3;cnt++;}else if($4=="G"){sum+=$3*1000;cnt++;}else if($4=="K"){sum+=$3/1000;cnt++;}} 
            # END{print 4*sum/cnt}' $result_path/"$t"_storage_io.txt >> $result_path/"$t"_result.txt
        elif [ "$bench_type" == "real2" ]; then
            cat $result_path/io_thruput.txt | grep -B 10 $storage_device | grep -E "Part0|Part1|Part2" > $result_path/"$t"_tmp.txt
            tail -n $((4* monitoring_time)) $result_path/"$t"_tmp.txt | awk -F '|' '{print $3 " " $4}'  > $result_path/"$t"_storage_io.txt
            # echo -n "Storage_Throughput(MB/s): " >> $result_path/"$t"_result.txt
            awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage_Throughput_R(GB/s): "3*(sumr)/cnt; print "Storage_Throughput_W(GB/s): "3*(sumw)/cnt; print "Storage_Throughput(GB/s): "3*(sumr+sumw)/cnt;
                }' $result_path/"$t"_storage_io.txt >> $result_path/"$t"_result.txt
            cat $result_path/io_thruput.txt | grep -B 10 $storage_device | grep -E "Part3" > $result_path/"$t"_tmp.txt
            tail -n $((4* monitoring_time)) $result_path/"$t"_tmp.txt | awk -F '|' '{print $3 " " $4}'  > $result_path/"$t"_storage_io.txt
            # echo -n "Storage_Throughput(MB/s): " >> $result_path/"$t"_result.txt
            awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage2_Throughput_R(GB/s): "(sumr)/cnt; print "Storage2_Throughput_W(GB/s): "(sumw)/cnt; print "Storage2_Throughput(GB/s): "(sumr+sumw)/cnt;
                }' $result_path/"$t"_storage_io.txt >> $result_path/"$t"_result.txt
        fi

        # fi
        # get Network Throughput
        # if [ "$network_io" == "True" ]; then
        cat $result_path/io_thruput.txt | grep -B 10 $network_device | grep "Part0" > $result_path/"$t"_tmp.txt
        tail -n $((1* monitoring_time)) $result_path/"$t"_tmp.txt | awk -F '|' '{print $3 " " $4}' > $result_path/"$t"_network_io.txt
        # echo -n "Network_Throughput(GB/s): " >> $result_path/"$t"_result.txt
        awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
            if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
            if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
        } END{print "Network_Throughput_R(GB/s): "(sumr)/cnt; print "Network_Throughput_W(GB/s): "(sumw)/cnt; print "Network_Throughput(GB/s): "(sumr+sumw)/cnt;
            }' $result_path/"$t"_network_io.txt >> $result_path/"$t"_result.txt
        
        cat $base/results/tx_result.txt | grep "Average_e2e_latency" | tail -n $((monitoring_time * elapsed_time * 3)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
        END{print "Average_e2e_latency: "sum/cnt;}' >> $result_path/"$t"_result.txt
        cat $base/results/tx_result.txt | grep "99%_e2e_tail_latency" | tail -n $((monitoring_time * elapsed_time * 3)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
        END{print "99%_e2e_tail_latency: "sum/cnt;}' >> $result_path/"$t"_result.txt
        # echo -n "Network_Throughput_R(MB/s): " >> $result_path/"$t"_result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($4=="M"){sum+=$3;cnt++;}else if($4=="G"){sum+=$3*1000;cnt++;}else if($4=="K"){sum+=$3/1000;cnt++;}} 
        # END{print sum/cnt}' $result_path/"$t"_network_io.txt >> $result_path/"$t"_result.txt
        # fi
        # if [ "$storage_io" == "True" ] || [ "$network_io" == "True" ]; then
        # get PCIe miss rate
        cat $result_path/pcie_tmp.txt | awk '{if( (NR%3) != 1){print $6/1000000}}' > $result_path/"$t"_pcie.txt 
        awk 'BEGIN{spm=0; sph=0; cnt=0;} { if(NR%2){spm+=$1; cnt++;}else{sph+=$1;}
        } END{print "PCIe_Hit_Count(M): " sph/cnt; print "PCIe_Miss_Count(M): " spm/cnt;
        print "PCIe_Miss_Rate(%): " (spm/(spm+sph))*100;}' $result_path/"$t"_pcie.txt >> $result_path/"$t"_result.txt
        # fi
        echo "[Done Monitoring, Start Phase Change/Antagonist Detection]" >> $result_path/main_log.txt
        # Get application-specific information
        # get L2/L3 hit/miss of each application [current data]
        # stat_header="  APP  || Cores ||  L2HIT  ||  L2MISS  ||  L3HIT  ||  L3MISS  || IPC(per application stat)"
        # touch $result_path/"$t"_LCA_current_stat.txt
        # touch $result_path/"$t"_ATA_current_stat.txt
        # touch $result_path/"$t"_SIOA_current_stat.txt
        state_tmp=$state
        # BE_init=1
        for (( i = 0 ; i < $num_application ; i ++)); do
            if (( start_time[i] > t )); then
                break
            fi
            # awk -v start="${start_core[$i]}" -v end="${end_core[$i]}" '{if($1>=start && $1<=end) print $0}' $result_path/"$t"_cache_stat.txt > $result_path/"$t"_"${app_name[$i]}"_cache_stat.txt
            echo -n "   "$i"      "${num_core[$i]}"   " >> $result_path/"$t"_current_stat.txt
            awk -v start="${start_core[$i]}" -v end="${end_core[$i]}" 'BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
            if($1>=start && $1<=end){sl2h+=$2/1000; sl2m+=$3/1000; sl3h+=$4/1000; sl3m+=$5/1000; ipc+=$6; cnt++;}
            } END{print sl2h/cnt"     "sl2m/cnt"     "sl3h/cnt"     "sl3m/cnt"     "ipc/cnt;}' $result_path/"$t"_cache_stat.txt >> $result_path/"$t"_current_stat.txt

            # tail -n 1 $result_path/"$t"_current_stat.txt >> $result_path/"$t"_"${app_name[$i]}"_cache_stat.txt 

            # Detect S-IOIA
            if [ "$option" == "0" ] || [ "$option" == "3" ]; then
                if [ "${device[$i]}" == "storage" ] && [ "${isAT[$i]}" == "0" ] && [ "$state" == "Stable" ]; then
                    # Leaky DMA Detection
                    LK_STG_DDIO_MS=$(cat $result_path/"$t"_result.txt | grep "PCIe_Miss_Rate" | awk -v thr="$LK_STG_DDIO_MS_THR" '{if($2 > thr){print "1"}else{print "0"}}')
                    LK_STG_TP=$(cat $result_path/"$t"_result.txt | grep "Throughput_R(GB/s)" | awk -v thr="$LK_STG_TP_THR" 'BEGIN{s1=0;s2=0;}{if(NR<=1){s2+=$2;}else{s1+=$2;}} END{if(100*s2/s1 > thr){print "1"}else{print "0"}}' )
                    LK_STG_LLC_MS=$(awk -v thr="$LK_STG_LLC_MS_THR" -v app="$i" '{if($1==app) {if( ($6/($5+$6))*100 > thr){print "1"}else{print "0"}}}' $result_path/"$t"_current_stat.txt )
                    echo -n "[S-IOIA check(DDIO, THR, LLC): " >> $result_path/main_log.txt
                    echo $LK_STG_DDIO_MS" "$LK_STG_TP" "$LK_STG_LLC_MS"]" >> $result_path/main_log.txt
                    if [ "$LK_STG_DDIO_MS" == "1" ] && [ "$LK_STG_TP" == "1" ] && [ "$LK_STG_LLC_MS" == "1" ]; then
                        echo "[S-IOIA Detected: " ${app_name[$i]} "]" >> $result_path/main_log.txt
                        echo "[Turning off Storage DDIO]" >> $result_path/main_log.txt
                        sudo $dbench_path/storage_disable
                        
                        reset_flag="True"
                        SIO_AN_LIST=("$i")
                        isAT[$i]="1"

                        if [ -n "$BE_CPU_LIST" ]; then
                            LC_Adj="True"
                        fi


                        if [ "$option" == "0" ]; then
                            AT_Adj="True"
                        
                            if [ -z "$SIO_CPU_LIST" ]; then
                                SIO_APP_LIST="${app_name[$i]}"
                                SIO_CPU_LIST="${cpu_list[$i]}"
                            else
                                SIO_APP_LIST="$SIO_APP_LIST, ${app_name[$i]}"
                                SIO_CPU_LIST="$SIO_CPU_LIST,${cpu_list[$i]}"
                            fi
                        fi
                        state_tmp="Init"
                        state=$state_tmp
                    fi
                elif [ "$option" == "0" ] && [ "${isAT[$i]}" == "0" ] && ([ "$state" == "Stable" ] || ( [ "${type[$i]}" == "LCA" ] && [ "${start_time[$i]}" == "$t" ])); then
                    # Detect MIA
                    LOC_L2_MISS=$(awk -v thr="$LOC_L2_MISS_THR" -v app="$i" '{if($1==app){ if( 100*$4/($3+$4) > thr){print "1"}else{print "0"} } }' $result_path/"$t"_current_stat.txt )
                    LOC_LLC_MISS=$(awk -v thr="$LOC_LLC_MISS_THR" -v app="$i" '{if($1==app) {if( 100*$6/($5+$6) > thr){print "1"}else{print "0"}}}' $result_path/"$t"_current_stat.txt )
                    echo -n "[MIA check $i (L2, LLC): " >> $result_path/main_log.txt
                    echo $LOC_L2_MISS" "$LOC_LLC_MISS"]" >> $result_path/main_log.txt
                    if [ "$LOC_L2_MISS" == "1" ] && [ "$LOC_LLC_MISS" == "1" ]; then
                        echo "[MIA Detected: " ${app_name[$i]} "]" >> $result_path/main_log.txt
                        AT_Adj="True"
                        reset_flag="True"
                        if [ -n "$BE_CPU_LIST" ]; then
                            LC_Adj="True"
                        fi
                        
                        
                        isAT[$i]="1"
                        AT_AN_LIST+=("$i")
                        if [ -z "$AT_CPU_LIST" ]; then
                            AT_APP_LIST="${app_name[$i]}"
                            AT_CPU_LIST="${cpu_list[$i]}"
                        else
                            AT_APP_LIST="$AT_APP_LIST, ${app_name[$i]}"
                            AT_CPU_LIST="$AT_CPU_LIST,${cpu_list[$i]}"
                        fi
                        state_tmp="Init"

                    fi
                fi
            fi

            # Group into LCA/BEA/ATA
            if [ "${device[$i]}" == "storage" ]; then
                cat $result_path/"$t"_result.txt | grep "Throughput_R(GB/s)" | awk 'BEGIN{ss=0;}{if(NR==1){ss+=$2;}} END{print ss"  "$2}' >> $result_path/"$t"_SIOIA_current_stat.txt
            fi

            if [ "${type[$i]}" == "LCA" ]; then
                tail -n 1 $result_path/"$t"_current_stat.txt >> $result_path/"$t"_LCA_current_stat.txt
                if [ "${isAT[$i]}" == "1" ]; then
                # BE_init=2
                    tail -n 1 $result_path/"$t"_current_stat.txt >> $result_path/"$t"_ATA_current_stat.txt
                fi
            else
                tail -n 1 $result_path/"$t"_current_stat.txt >> $result_path/"$t"_BEA_current_stat.txt
                if [ "${isAT[$i]}" == "1" ]; then
                # BE_init=2
                    tail -n 1 $result_path/"$t"_current_stat.txt >> $result_path/"$t"_ATA_current_stat.txt
                fi
            fi
            
        done
        state=$state_tmp

        # Based on the information,
        # (1) Classify informations into APP group 
        #  LCA_current_stat (LLC hit rate)
        cat $result_path/"$t"_result.txt | grep "PCIe_Miss_Rate" | awk '{print $2}' > $result_path/"$t"_IOLCA_current_pcie.txt
        cat $result_path/"$t"_result.txt | grep "Mem" | awk 'BEGIN{sum=0;}{sum+=$2;}END{print sum}' > $result_path/"$t"_ATA_current_mem.txt
        if [ -n "$LC_CPU_LIST" ]; then
            awk 'BEGIN{miss=0; hit=0;}{miss+=$6;hit+=$5;}END{print 100*hit/(miss+hit)}' $result_path/"$t"_LCA_current_stat.txt > $result_path/"$t"_LCA_current_LLC_HR.txt
            awk '{print $1"   "100*$5/($5+$6)}' $result_path/"$t"_LCA_current_stat.txt > $result_path/"$t"_LCA_current_LLC_HR_APP.txt
        fi
        if [ -n "$AT_CPU_LIST" ]; then
            awk 'BEGIN{m2=0; h2=0; m3=0; h3=0;}{m2+=$4; h2+=$3; m3+=$6; h3+=$5;}END{print 100*m2/(m2+h2)"  "100*m3/(m3+h3)}' $result_path/"$t"_ATA_current_stat.txt > $result_path/"$t"_ATA_current_L2_LLC_MR.txt
            awk '{print $1"   "100*$4/($3+$4)"   "100*$6/($5+$6)}' $result_path/"$t"_ATA_current_stat.txt > $result_path/"$t"_ATA_current_L2_LLC_MR_APP.txt
        fi
        # no need for SIOIA

        # (2) State Transition (Init, Adj, Stable)
        # save application info as initial value, go to Adj
        # set [initial data]
        stop_flag="False"
        stop_flag1="False"
        stop_flag2="False"
        stop_tmp="False"
        if [ "$state" == "Stable" ]; then   
            # Detect Phase Change of LCA/MIA/SIOIA group, reset and go to Init
            if [ -n "$LC_CPU_LIST" ] || [ -n "$IOLC_CPU_LIST" ]; then
                paste $result_path/LCA_stable_LLC_HR_APP.txt $result_path/"$t"_LCA_current_LLC_HR_APP.txt > $result_path/cmp_tmp.txt
                stop_flag1=$(awk -v thr="$LCA_LLC_HIT_FL" 'BEGIN{fluc=0}{if( (($2*(1+thr) < $4) && ($4-$2 > 10)) || (($2*(1-thr) > $4) && ($2-$4 > 10))){fluc=1;} }END{ if(fluc){print "True"}else{print "False"}}' $result_path/cmp_tmp.txt )
                echo -e "[LLC Hit Rate(%) change(stable cur) per applications: \n"$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                echo "[LCA Phase Change:"$stop_flag1"]" >> $result_path/main_log.txt

                # paste $result_path/IOLCA_stable_pcie.txt $result_path/"$t"_IOLCA_current_pcie.txt > $result_path/cmp_tmp.txt
                # stop_flag2=$(awk -v thr_n="$IOLCA_DDIO_MISS_FL" '{if($1*(1+thr_n) < $2 || $1*(1-thr_n) > $2  ){print "True"}else{print "False"} }' $result_path/cmp_tmp.txt )
                # echo "[PCIe miss rate change(stable cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                # echo "[IOLCA Phase Change:"$stop_flag2"]" >> $result_path/main_log.txt

                if [ "$stop_flag1" == "True" ] || [ "$stop_flag2" == "True" ]; then
                    stop_tmp="True"
                    LC_Adj="True"
                fi
            fi
            if [ -n "$AT_CPU_LIST" ]; then
                paste $result_path/ATA_stable_L2_LLC_MR_APP.txt $result_path/"$t"_ATA_current_L2_LLC_MR_APP.txt > $result_path/cmp_tmp.txt
                for num in "${AT_AN_LIST[@]}"; do
                    stop_num_flag=$(awk -v thr="$BPS_CACHE_MISS_FL" -v n="$num" '{if($1==n){if($2*(1+2*thr) < $5 || $2*(1-2*thr) > $5 || $3*(1+thr) < $6 || $3*(1-thr) > $6 ){print "True"}else{print "False"} }}' $result_path/cmp_tmp.txt )
                    if [ "$stop_num_flag" == "True" ]; then
                        stop_tmp="True"
                        isAT[$num]="0"
                        if [ "$type[$num]" == "LCA" ]; then
                            LC_Adj="True"
                        fi
                    fi
                done
                echo "[MIA L2/LLC Hit Rate(%) change(stable cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                echo "[MIA Phase Change:"$stop_tmp"]" >> $result_path/main_log.txt
            fi
            if [ -n "$SIO_CPU_LIST" ] && [ "$option" == "0" ]; then
                #supports only single S-IOIA
                paste $result_path/SIOIA_stable_stat.txt $result_path/"$t"_SIOIA_current_stat.txt > $result_path/cmp_tmp.txt
                stop_flag=$(awk -v thr_s="$BPS_STG_TP_FL" '{if( $1*(1-thr_s) > $3  ){print "True"}else{print "False"} }' $result_path/cmp_tmp.txt )
                echo "[Storage/Network Throughput change(stable cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                echo "[SIOIA Phase Change:"$stop_flag"]" >> $result_path/main_log.txt
                num=${SIO_AN_LIST[0]}
                if [ "$stop_flag" == "True" ]; then
                    isAT[$num]="0"
                    stop_tmp="True"
                    SIO_AN_LIST=()
                    echo "[S-IOIA back to normal($num): " ${app_name[$num]} "]" >> $result_path/main_log.txt
                    echo "[Turning on Storage DDIO]" >> $result_path/main_log.txt
                    sudo $dbench_path/storage_enable
                    if [ "$type[$num]" == "LCA" ]; then
                        LC_Adj="True"
                    fi  
                fi
            fi
            
            if [ "$stop_tmp" == "True" ]; then
                reset_flag="True"
                state="Init"
                # Check if AT exists, set AT_Adj
                if [ -n "$AT_CPU_LIST" ]; then
                    AT_Adj="True"
                fi
            else 
                state="Stable"
            fi
        fi
        echo "[State after Phase Change/Antagonist Check: "$state" with LC_Adj: "$LC_Adj" & AT_Adj: "$AT_Adj"]" >> $result_path/main_log.txt
        stop_flag="False"
        stop_flag1="False"
        stop_flag2="False"
        stop_flag3="False"

        if [ "$state" == "Init" ]; then
            if [ "$reset_flag" == "True" ]; then
                echo "[Restart Partitioning]" >> $result_path/main_log.txt
                state="Init"
                reset_flag="False"
                if [ "$LC_Adj" == "True" ]; then
                    BE_num=$BE_init
                fi
                if [ "$AT_Adj" == "True" ]; then
                    BE_num=$BE_init
                    AT_num=$BE_num
                    # AT_num=$AT_init
                fi
            elif [ "$LC_Adj" == "True" ]; then
                if [ -n "$BE_CPU_LIST" ] || [ -n "$AT_CPU_LIST" ]; then
                    echo "[Start LC/BE zone Adjustment]" >> $result_path/main_log.txt
                    state="Adj"
                    BE_num=$((BE_init + 1))
                    #store LCA initial (L3 miss)
                    cp $result_path/"$t"_LCA_current_LLC_HR.txt $result_path/LCA_initial_LLC_HR.txt
                    cp $result_path/"$t"_IOLCA_current_pcie.txt $result_path/IOLCA_initial_pcie.txt
                    cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_initial_LLC_HR_APP.txt
                    if [ "$AT_Adj" == "True" ]; then
                        AT_num=$BE_num
                        # AT_num=$AT_init
                    # do not store ATA initial (L2, L3 miss)
                    fi
                    echo "[Increase BE zone to "$BE_num" on next step]" >> $result_path/main_log.txt
                else
                    echo "[Only LCA applications. NO Adjustment]" >> $result_path/main_log.txt
                    BE_num=0
                    state="Stable"
                    LC_Adj="False"
                    echo "[Set LCA Stable Data]" >> $result_path/main_log.txt
                    cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                    cp $result_path/"$t"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                fi
            elif [ "$AT_Adj" == "True" ]; then
                echo "[Start AT zone Adjustment]" >> $result_path/main_log.txt
                # LC done, decrease ATA
                if (( BE_num > AT_min + 1 )); then 
                    state="Adj"
                    AT_num=$((BE_num - 1))
                    # store ATA initial data (previous L2, L3 miss)
                    cp $result_path/"$(( t-1 ))"_ATA_current_mem.txt $result_path/ATA_initial_mem.txt
                    if [ -n "$AT_CPU_LIST" ]; then
                        cp $result_path/"$(( t-1 ))"_ATA_current_L2_LLC_MR.txt $result_path/ATA_initial_L2_LLC_MR.txt
                    fi
                    if [ -n "$SIO_CPU_LIST" ]; then
                        cp $result_path/"$(( t-1 ))"_SIOIA_current_stat.txt $result_path/SIOIA_initial_stat.txt
                    fi
                    echo "[Decrease AT zone to "$AT_num" on next step]" >> $result_path/main_log.txt
                else 
                    state="Stable"
                    AT_Adj="False"
                    AT_num=$AT_min
                    # store ATA initial data (previous L2, L3 miss)
                    if [ -n "$AT_CPU_LIST" ]; then
                        cp $result_path/"$t"_ATA_current_L2_LLC_MR.txt $result_path/ATA_stable_L2_LLC_MR.txt
                    fi
                    if [ -n "$SIO_CPU_LIST" ]; then
                        cp $result_path/"$t"_SIOIA_current_stat.txt $result_path/SIOIA_stable_stat.txt
                    fi
                    echo "[ AT is in the minimum value: "$AT_num"]" >> $result_path/main_log.txt
                fi
            else
                AT_num=0
                cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                cp $result_path/"$t"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                if [ -n "$AT_CPU_LIST" ]; then
                    cp $result_path/"$t"_ATA_current_L2_LLC_MR.txt $result_path/ATA_stable_L2_LLC_MR.txt
                fi
                if [ -n "$SIO_CPU_LIST" ]; then
                    cp $result_path/"$t"_SIOIA_current_stat.txt $result_path/SIOIA_stable_stat.txt
                fi
                state="Stable"
            fi
        elif [ "$state" == "Adj" ]; then
            # If cur < init * THR, decrease LC/AT zone (LC_Adj, AT_Adj)
            # If done, set [stable data], deflag Adj
            # if both done, go to stable
    
            # LC/BE Adjustment
            if [ "$LC_Adj" == "True" ]; then
                echo "[Check LC/BE zone]" >> $result_path/main_log.txt
                # reduce until sustainable miss rate
                if (( BE_num == BE_max )); then
                    # set BE num to maximum way #
                    echo "[Reached Maximum BE Size. Stop Adjustment]" >> $result_path/main_log.txt
                    stop_flag="True"
                    tmp_num=$BE_max
                fi
                paste $result_path/LCA_initial_LLC_HR_APP.txt $result_path/"$t"_LCA_current_LLC_HR_APP.txt > $result_path/cmp_tmp.txt
                stop_flag1=$(awk -v thr="$LCA_LLC_HIT_FL" 'BEGIN{fluc=0}{if($2*(1-thr) > $4 && ($2 - $4 > 5 ) ){fluc=1;} }END{ if(fluc){print "True"}else{print "False"}}' $result_path/cmp_tmp.txt )
                echo -e "[LLC Hit Rate(%) change(init cur) per applications: \n"$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                echo "[LCA Fluctuation("$LCA_LLC_HIT_FL"):"$stop_flag1"]" >> $result_path/main_log.txt

                paste $result_path/IOLCA_initial_pcie.txt $result_path/"$t"_IOLCA_current_pcie.txt > $result_path/cmp_tmp.txt
                stop_flag2=$(awk -v thr_n="$IOLCA_DDIO_MISS_FL" '{if($1*(1+thr_n) < $2){print "True"}else{print "False"} }' $result_path/cmp_tmp.txt )
                echo "[PCIe miss rate change(stable cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                echo "[IOLCA Flucuation:"$stop_flag2"]" >> $result_path/main_log.txt

                # paste $result_path/LCA_initial_LLC_HR.txt $result_path/"$t"_LCA_current_LLC_HR.txt > $result_path/cmp_tmp.txt
                # stop_flag=$(awk -v thr="$LCA_LLC_HIT_FL" '{if($1*(1+thr) < $2 || $1*(1-thr) > $2){print "True"}else{printf "False"} }' $result_path/cmp_tmp.txt )
                # echo "[L3 Hit Rate(%) change(init cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                # echo "[LCA Fluctuation:"$stop_flag"]" >> $result_path/main_log.txt
                # set BE num to previous way #
                if [ "$stop_flag1" == "True" ] || [ "$stop_flag2" == "True" ]; then
                    tmp_num=$(( BE_num-1 ))
                    stop_flag="True"
                fi

                if [ "$stop_flag" == "True" ]; then
                    # set stable data (previous data)
                    if [ "$AT_Adj" == "False" ]; then
                        echo "[Set LCA Stable Data]" >> $result_path/main_log.txt
                        if [ "$tmp_num" == "$BE_max" ]; then 
                            cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            cp $result_path/"$t"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                        else
                            cp $result_path/"$(( t-1 ))"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            cp $result_path/"$(( t-1 ))"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                        fi
                    fi
                    LC_Adj="False"
                    BE_num=$tmp_num
                    echo "[BE("$BE_num") zone Settled]" >> $result_path/main_log.txt
                    if [ "$AT_Adj" == "True" ]; then
                        # start AT zone Adjustment when LC zone Adjustment is done
                        echo "[Start AT zone Adjustment]" >> $result_path/main_log.txt
                        # LC done, decrease ATA
                        if (( BE_num > AT_min + 1 )); then 
                            state="Adj"
                            AT_num=$((BE_num - 1))
                            # store ATA initial data (previous L2, L3 miss)
                            cp $result_path/"$(( t-1 ))"_ATA_current_mem.txt $result_path/ATA_initial_mem.txt
                            if [ -n "$AT_CPU_LIST" ]; then
                                cp $result_path/"$(( t-1 ))"_ATA_current_L2_LLC_MR.txt $result_path/ATA_initial_L2_LLC_MR.txt
                            fi
                            if [ -n "$SIO_CPU_LIST" ]; then
                                cp $result_path/"$(( t-1 ))"_SIOIA_current_stat.txt $result_path/SIOIA_initial_stat.txt
                            fi
                            echo "[Decrease AT zone to "$AT_num" on next step]" >> $result_path/main_log.txt
                        else 
                            state="Stable"
                            AT_Adj="False"
                            AT_num=$AT_min
                            # store ATA initial data (previous L2, L3 miss)
                            if [ -n "$AT_CPU_LIST" ]; then
                                cp $result_path/"$t"_ATA_current_L2_LLC_MR_APP.txt $result_path/ATA_stable_L2_LLC_MR_APP.txt
                                cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            fi
                            if [ -n "$SIO_CPU_LIST" ]; then
                                cp $result_path/"$t"_SIOIA_current_stat.txt $result_path/SIOIA_stable_stat.txt
                                cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            fi
                            echo "[ AT is in the minimum value: "$AT_num"]" >> $result_path/main_log.txt
                        fi
                        
                    else 
                        state="Stable"
                    fi
                elif [ "$stop_flag" == "False" ]; then
                    # increase BE way
                    BE_num=$(( BE_num+1 ))
                    if [ "$AT_Adj" == "True" ]; then
                        AT_num=$BE_num
                        # AT_num=$AT_init
                    fi
                    echo "[Increase BE zone to "$BE_num" on next step]" >> $result_path/main_log.txt
                else 
                    echo "[Error: Invalid STOP_FLAG( "$stop_flag" )]" >> $result_path/main_log.txt
                fi

            # BE/AT Adjustment
            elif [ "$AT_Adj" == "True" ]; then
                echo "[Check BE/AT zone]" >> $result_path/main_log.txt
                # reduce until sustainable miss rate or minimum AT size
                if (( AT_num == AT_min )); then
                    echo "[Reached Minimum AT Size. Stop Adjustment]" >> $result_path/main_log.txt
                    # set AT num to minimum way #
                    stop_flag="True"
                    tmp_num=$AT_min
                fi
                if [ -n "$AT_CPU_LIST" ]; then
                    paste $result_path/ATA_initial_L2_LLC_MR.txt $result_path/"$t"_ATA_current_L2_LLC_MR.txt > $result_path/cmp_tmp.txt
                    stop_flag1=$(awk -v thr="$BPS_CACHE_MISS_FL" '{if($1*(1+thr) < $3 || $2*(1+thr) < $4 ){print "True"}else{print "False"} }' $result_path/cmp_tmp.txt )
                    echo "[L2/LLC Miss Rate(%) change(init cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                    echo "[MIA Fluctuation:"$stop_flag1"]" >> $result_path/main_log.txt
                fi
                if [ -n "$SIO_CPU_LIST" ]; then
                    paste $result_path/SIOIA_initial_stat.txt $result_path/"$t"_SIOIA_current_stat.txt > $result_path/cmp_tmp.txt
                    stop_flag2=$(awk -v thr_s="$BPS_STG_TP_FL" -v thr_n="$BPS_NET_TP_FL" '{if($1*(1-thr_s) > $3 || $2*(1-thr_n) > $4 ){print "True"}else{print "False"} }' $result_path/cmp_tmp.txt )
                    echo "[Storage/Network Throughput change(init cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                    echo "[SIOIA Fluctuation:"$stop_flag2"]" >> $result_path/main_log.txt
                fi

                paste $result_path/ATA_initial_mem.txt $result_path/"$t"_ATA_current_mem.txt > $result_path/cmp_tmp.txt
                stop_flag3=$(awk -v thr="$BPS_MEM_BW_FL" '{if($1*(1+thr) < $3){print "True"}else{print "False"} }' $result_path/cmp_tmp.txt )
                echo "[Mem BW change(init cur): "$(cat $result_path/cmp_tmp.txt)"]" >> $result_path/main_log.txt
                echo "[Mem BW Fluctuation:"$stop_flag3"]" >> $result_path/main_log.txt

                if [ "$stop_flag1" == "True" ] || [ "$stop_flag2" == "True" ] || [ "$stop_flag3" == "True" ];then
                    # set AT num to previous way #
                    stop_flag="True"
                    tmp_num=$(( AT_num+1 ))
                fi
                

                if [ "$stop_flag" == "True" ]; then
                    state="Stable"
                    AT_Adj="False"
                    AT_num=$tmp_num
                    echo "[BE("$BE_num")/AT("$AT_num") zone Settled]" >> $result_path/main_log.txt
                    echo "[Set LCA & ATA Stable Data]" >> $result_path/main_log.txt
                    if [ -n "$AT_CPU_LIST" ]; then
                        if [ "$tmp_num" == "$AT_min" ]; then 
                            cp $result_path/"$t"_ATA_current_L2_LLC_MR_APP.txt $result_path/ATA_stable_L2_LLC_MR_APP.txt
                            cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            cp $result_path/"$t"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                        else
                            cp $result_path/"$(( t-1 ))"_ATA_current_L2_LLC_MR_APP.txt $result_path/ATA_stable_L2_LLC_MR_APP.txt
                            cp $result_path/"$(( t-1 ))"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            cp $result_path/"$(( t-1 ))"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                        fi
                    fi
                    if [ -n "$SIO_CPU_LIST" ]; then
                        if [ "$tmp_num" == "$AT_min" ]; then 
                            cp $result_path/"$t"_SIOIA_current_stat.txt $result_path/SIOIA_stable_stat.txt
                            cp $result_path/"$t"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            cp $result_path/"$t"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                        else
                            cp $result_path/"$(( t-1 ))"_SIOIA_current_stat.txt $result_path/SIOIA_stable_stat.txt
                            cp $result_path/"$(( t-1 ))"_LCA_current_LLC_HR_APP.txt $result_path/LCA_stable_LLC_HR_APP.txt
                            cp $result_path/"$(( t-1 ))"_IOLCA_current_pcie.txt $result_path/IOLCA_stable_pcie.txt
                        fi
                    fi
                elif [ "$stop_flag" == "False" ]; then
                    AT_num=$(( AT_num - 1))
                    echo "[Decrease AT zone to "$AT_num" on next step]" >> $result_path/main_log.txt
                else 
                    echo "[Error: Invalid STOP_FLAG]" >> $result_path/main_log.txt
                fi
            else
                echo "[Error: Invalid State Transition]" >> $result_path/main_log.txt
            fi
        fi
        

        # (2) Update LC zone
        
        # LC_num=$((LC_init - BE_num - IO_num))
        LC_num=$((LC_init - IO_num))
        echo "[Next State: "$state" with LC_Adj: "$LC_Adj" & AT_Adj: "$AT_Adj"]" >> $result_path/main_log.txt
        echo "[Next LLC State: IO("$IO_num"), LC("$LC_num"), BE("$BE_num"), AT("$AT_num")]" >> $result_path/main_log.txt
        
        unit_end_time=$(date +%s%N)
        unit_runtime=$(( (unit_end_time - unit_start_time) / 1000 )) 
        echo $unit_runtime >> $result_path/time.txt
        #cd $result_path
        # rm *tmp* *_cache_stat* *_core* *_pcie* *_network_io* *_storage_io* *_ATA_current_stat*
    done


    cat $result_path/time.txt | awk 'BEGIN{sum=0;cnt=0;}{sum+=$1; cnt++;}END{print "SmartLLC_unit_run_time(ns): " sum/cnt;}' >> $result_path/main_log_"$iter".txt
    sudo mv $result_path/main_log.txt $result_base/main_log_"$iter".txt
    sudo mv $result_path/LLC_log.txt $result_base/LLC_log_"$iter".txt

    files=""
    app_files=""
    lsw_files=""
    bew_files=""
    for ((rt=report_start_time; rt<report_end_time; rt++)); do
        files="${files}${result_path}/${rt}_result.txt "
        app_files="${app_files}${result_path}/${rt}_current_stat.txt "
        lsw_files="${lsw_files}${result_path}/${rt}_LCA_current_stat.txt "
        bew_files="${bew_files}${result_path}/${rt}_BEA_current_stat.txt "
    done
    cat $files > $result_path/concat_result.txt

    cat $lsw_files | awk 'BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
    sl2h+=$2*$3/1000; sl2m+=$2*$4/1000; sl3h+=$2*$5/1000; sl3m+=$2*$6/1000; ipc+=$2*$7; cnt+=$2; } END{print "LSW_L2_Hit_Rate(%): "sl2h/(sl2h+sl2m)*100;
    print "LSW_L3_Hit_Rate(%): "sl3h/(sl3h+sl3m)*100;
    print "LSW_IPC: "ipc/cnt;}' >> $result_base/result_"$iter".txt

    cat $bew_files | awk 'BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
    sl2h+=$2*$3/1000; sl2m+=$2*$4/1000; sl3h+=$2*$5/1000; sl3m+=$2*$6/1000; ipc+=$2*$7; cnt+=$2; } END{print "BEW_L2_Hit_Rate(%): "sl2h/(sl2h+sl2m)*100;
    print "BEW_L3_Hit_Rate(%): "sl3h/(sl3h+sl3m)*100;
    print "BEW_IPC: "ipc/cnt;}' >> $result_base/result_"$iter".txt

    metrics=("L2_HIT" "L2_MISS" "L3_HIT" "L3_MISS" "PCIe_Hit_Count" "PCIe_Miss_Count" "IPC" "Storage_Throughput_R" "Storage_Throughput_W" "Storage2_Throughput_R" "Storage2_Throughput_W" "Network_Throughput_R" "Network_Throughput_W" "Mem_Read" "Mem_Write")
    touch $result_path/results_average.txt
    for metric in "${metrics[@]}"; do 
        cat $result_path/concat_result.txt | grep $metric | \
        awk -v m="$metric" 'BEGIN{sum=0;cnt=0;} {sum+=$2;cnt++;}END{print m": "sum/cnt}' >> $result_path/results_average.txt
    done

    rates=("L2" "L3" "PCIe")
    for rate in "${rates[@]}"; do 
        cat $result_path/results_average.txt | grep $rate | \
        awk -v r="$rate" '{if(NR==1){h=$2;} if(NR==2){m=$2;}}END{print r"_Hit_Rate(%): "(h/(m+h))*100}' >> $result_base/result_"$iter".txt
    done

    if [ "$bench_type" == "real" ]; then
        tail -n 7 $result_path/results_average.txt >> $result_base/result_"$iter".txt
    elif [ "$bench_type" == "real2" ]; then
        tail -n 9 $result_path/results_average.txt >> $result_base/result_"$iter".txt
    fi

    cat $base/results/tx_result.txt | grep "Average_e2e_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_e2e_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $base/results/tx_result.txt | grep "Average_remote_mem_access_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_remote_mem_access_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $base/results/tx_result.txt | grep "Average_remote_compute_access_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_remote_compute_access_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt
    cat $base/results/tx_result.txt | grep "Average_remote_nic-host_latency" | tail -n $((monitoring_time * elapsed_time )) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{print "Average_remote_nic-host_latency: "sum/cnt;}' >> $result_base/result_"$iter".txt

    

    cat $base/results/tx_result.txt | grep "99%_e2e_tail_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{ if(cnt > 0){ print "99%_e2e_tail_latency: "sum/cnt;}}' >> $result_base/result_"$iter".txt
    cat $base/results/tx_result.txt | grep "99%_remote_mem_access_tail_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{ if(cnt > 0){ print "99%_remote_mem_access_tail_latency: "sum/cnt;}}' >> $result_base/result_"$iter".txt
    cat $base/results/tx_result.txt | grep "99%_remote_compute_tail_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{ if(cnt > 0){ print "99%_remote_compute_tail_latency: "sum/cnt;}}' >> $result_base/result_"$iter".txt
    cat $base/results/tx_result.txt | grep "99%_remote_nic-host_latency" | tail -n $((monitoring_time * elapsed_time)) | awk 'BEGIN{sum=0; cnt=0;}{if(NR <10){sum+=$2; cnt++;}}
    END{ if(cnt > 0){ print "99%_remote_nic-host_latency: "sum/cnt;}}' >> $result_base/result_"$iter".txt

    sudo $base/scripts/utils/kill_all.sh > /dev/null 


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
    for (( i=0 ; i < $num_application ; i++)); do
        cat $app_files | awk -v n="$i" -v name="${app_name[$i]}" 'BEGIN{sl2h=0; sl2m=0; sl3h=0; sl3m=0; ipc=0; cnt=0;} {
        if($1==n){sl2h+=$3/1000; sl2m+=$4/1000; sl3h+=$5/1000; sl3m+=$6/1000; ipc+=$7; cnt++;} } END{print name"_L2_Hit_Rate(%): "sl2h/(sl2h+sl2m)*100;
        print name"_L3_Hit_Rate(%): "sl3h/(sl3h+sl3m)*100;
        print name"_IPC: "ipc/cnt;}' >> $result_base/result_"$iter".txt
    done
    # sleep 20

done


