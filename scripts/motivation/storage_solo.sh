#!/bin/bash

#local NUMA node:0, remote NUMA node:1~3
node=0
type=$1
fio_jobfile="$BASE_PATH/app/configs/bs_sens.fio"
tmp_mem="$BASE_PATH/tmp/mem.txt"
tmp_llc="$BASE_PATH/tmp/llc.txt"
tmp_io="$BASE_PATH/tmp/io.txt"
result_base="$BASE_PATH/results/Fig5/$type"

CPU_CORES="10-13"
storage_device=$SERVER_SSD_PCIE

bss=("4k" "8k" "16k" "32k" "64k" "128k" "256k" "512k" "1024k" "2048k")

mkdir -p $result_base
rm -r $result_base/*

sudo modprobe msr

# restricting LLC ways of the FIO application
sudo pqos -R
sudo pqos -a llc:1=$CPU_CORES
sudo pqos -e llc:1=0x0300

if [[ "$type" = "en" ]]; then
    sudo $DBENCH_PATH/storage_enable
    #echo "DDIO enabled" >> $result_path/result.txt 
else
    sudo $DBENCH_PATH/storage_disable
    #echo "DDIO disabled" >> $result_path/result.txt
fi

for ((i=1; i<=$ITER; i++)); do
    result_path="$result_base/$i"
    mkdir -p $result_path
    rm $result_path/*.txt
    touch $result_path/result.txt
    for bs in "${bss[@]}"; do

        export SIZE=$bs
        echo "Running FIO with block size: $SIZE..."
        sudo -E taskset -c $CPU_CORES fio $fio_jobfile &

        cd $PCM_PATH
        # sudo ./pcm 1 | grep "Total UPI incoming data traffic:" > $tmp/upi.txt &
        sudo pcm-memory 1 -silent| grep "SKT  0 Mem " > $tmp_mem &
        #sudo ./pcm-core 1 -e cpu/event=0xd1,umask=0x1,name=mem_load_uops_retired_l3_hit/ -e cpu/event=0xd1,umask=0x2,name=mem_load_uops_retired_l3_hit/ -e cpu/event=0xd1,umask=0x4,name=mem_load_uops_retired_l3_hit/ > $tmp_llc &
        sudo ./pcm-iio 1.0 -silent | grep -A 62 "Socket0" > $tmp_io & 

        sleep 10
        
        sudo pkill pcm-memory
        sudo pkill pcm-iio
        # sudo pkill pcm
        sudo pkill fio

        cat $tmp_mem | grep "Read" > $result_path/read_bw_$bs.txt
        cat $tmp_mem | grep "Write" > $result_path/write_bw_$bs.txt
        #awk '{if($1 >= 50 && $1 <= 53) print }' $tmp_llc > $result_path/core_llc_$bs.txt 
        cat $tmp_io | grep -B 10 $storage_device > $BASE_PATH/tmp/io_storage.txt
        cat $BASE_PATH/tmp/io_storage.txt | grep -E "Part0|Part1|Part2|Part3" > $BASE_PATH/tmp/io_storage2.txt

        echo -n "Average Read BW ($bs):" >> $result_path/result.txt
        awk 'BEGIN{ sum=0; cnt=0;} {sum += $8; cnt++;} END {avg = sum / cnt; print avg}' $result_path/read_bw_$bs.txt >> $result_path/result.txt
        echo -n "Average Write BW ($bs):" >> $result_path/result.txt
        awk 'BEGIN{ sum=0; cnt=0;} {sum += $7; cnt++;} END {avg = sum / cnt; print avg}' $result_path/write_bw_$bs.txt >> $result_path/result.txt
        #echo -n "Average LLC read ($bs):" >> $result_path/result.txt
        #awk 'BEGIN{sum=0; cnt=0;} {if($10=="M"){sum+=$9;} else if($10=="K"){sum+=$9/1000;} if($12=="M"){sum+=$11;} else if($12=="K"){sum+=$11/1000;} if($14=="M"){sum+=$13;} else if($14=="K"){sum+=$13/1000;} cnt++; } END{avg = sum * 4 / cnt; print avg}' $result_path/core_llc_$bs.txt >> $result_path/result.txt
        echo -n "Average IO read ($bs):" >> $result_path/result.txt
        awk -F '|' '{print $3}' $BASE_PATH/tmp/io_storage2.txt > $result_path/io_$bs.txt
        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;} if($2=="G"){sum+=$1*1000;} cnt++; } END{avg = sum*4 / cnt; print avg}' $result_path/io_$bs.txt >> $result_path/result.txt
        
        # echo -n "Average UPI read ($bs):" >> $result_path/result.txt
        # awk 'BEGIN{ sum=0; cnt=0;} {if($7=="M"){sum += $6;} else if($7=="K"){sum+=$6/1000;}  else if($7=="G"){sum+=$6*1000;} cnt++;} END {avg = sum / cnt; print avg}' $tmp/upi.txt >> $result_path/result.txt

    done
    mv $result_path/result.txt $result_base/result_$i.txt

done

$BASE_PATH/scripts/workloads/stop_all.sh
sudo $DBENCH_PATH/storage_enable
