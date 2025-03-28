#!/bin/bash

# Figure 8b

tmp_dpdk="$TMP_PATH/dpdk.txt"
tmp_mem="$TMP_PATH/mem.txt"
tmp_llc="$TMP_PATH/llc.txt"
tmp_pcie="$TMP_PATH/pcie.txt"
tmp_io="$TMP_PATH/io.txt"
tmp_miss="$TMP_PATH/miss.txt"

fio_jobfile="$BASE_PATH/app/configs/dpdk_fio.fio"

result_base="$BASE_PATH/results/Fig8b"
mkdir -p $result_base

rm -r $result_base/*
rm $BASE_PATH/tmp/*.txt
sudo modprobe msr

storage_device=$SERVER_SSD_PCIE
APP_CORE="0-3"
FIO_CORE="10-13"
bs="2048k"

fio_ways=("0x1e0" "0x1c0" "0x180" "0x100" "0")

sudo pqos -R

sudo pqos -e llc:1=0x01e0
sudo pqos -a llc:1=$APP_CORE

sudo $DBENCH_PATH/storage_disable
sudo xmem -t -n3000 -c256 -j2 -R -r -w4096 &


for ((i=1; i<=$ITER; i++)); do
    result_path="$result_base/$i"
    if [[ ! -d "$result_path" ]]; then
        mkdir $result_path
    fi
    rm $result_path/*.txt
    touch $result_path/result.txt

    export SIZE=$bs
    echo "Running FIO with block size: $SIZE..."
    sudo -E taskset -c $FIO_CORE fio $fio_jobfile &
    sleep 5

    for j in {0..4}; do
        mask=${fio_ways[j]}
        if [[ "$mask" == "0" ]]; then
            sudo pkill fio
        fi
        #set LLC ways for streaming application
        sudo pqos -e llc:2=$mask  
        sudo pqos -a llc:2=$FIO_CORE
        label="fio"$mask
        
        sleep 1
        
        #start monitoring
        cd $PCM_PATH
        sudo stdbuf -oL pcm-memory 1 -silent  | stdbuf -oL grep "SKT  0 Mem " > $tmp_mem &
        sudo stdbuf -oL ./pcm-iio 1.0 -silent | stdbuf -oL grep -A 62 "Socket0" > $tmp_io &  
        sudo stdbuf -oL pcm-pcie -e -silent   | stdbuf -oL grep -A 3 "Skt" > $tmp_pcie &   
        sudo stdbuf -oL pcm 1 -silent         | stdbuf -oL grep -A 15 "Core (SKT)" > $tmp_miss &

        #gather data for 1 min
        sleep 10

        sudo pkill pcm
        
        sleep 1

        cat $tmp_mem | grep "Read" > $result_path/read_bw_$label.txt
        cat $tmp_mem | grep "Write" > $result_path/write_bw_$label.txt


        # awk -F '  +' '{if($2 <=3 && $2 >= 0) print $7}' $tmp_llc > $result_path/core_l2_wb_app_$label.txt
        # awk -F '  +' '{if( (10<=$2 && $2<=13) ) print $7}' $tmp_llc > $result_path/core_l2_wb_io_$label.txt 
        # awk -F '  +' '{if($2 <= 3 && $2>=0 ) print $8}' $tmp_llc > $result_path/core_l3_miss_app_$label.txt
        # awk -F '  +' '{if( (10<=$2 && $2<=14)  ) print $8}' $tmp_llc > $result_path/core_l3_miss_io_$label.txt   
        sed -i '/Core/,+1d;/^$/d;/--/d;s/|//g;s/ K/000/g;s/ M/000000/g' $tmp_miss 
        awk '{print $2"  "$9"  "$7}' $tmp_miss > $result_path/llc_mr_$label.txt 


        awk -F '  +' '{if( $8 ~ /\(Miss\)/ || $9 ~ /\(Miss\)/ ) print $6}' $tmp_pcie > $result_path/pcie_miss_$label.txt
        awk -F '  +' '{if( $9 ~ /\(Hit\)/ ) print $6}' $tmp_pcie > $result_path/pcie_hit_$label.txt

        echo "==========Monitoring Result ($label)==========" >> $result_path/result.txt  
        awk 'BEGIN{sl3m; cnt=0;} {
        if($1 >= 0 && $1 <= 1){sl3m+=$3/1000000; cnt++;}
        } END{ print "Xmem_L3_Miss_Count(M): "4*sl3m/cnt; }' $result_path/llc_mr_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sl3h; sl3m; cnt=0;} {
        if($1 >= 0 && $1 <= 1){sl3h+=$2/1000; sl3m+=$3/1000; cnt++;}
        } END{ print "Xmem_L3_Miss_Rate: " 100*sl3m/(sl3h+sl3m); }' $result_path/llc_mr_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sl3m; cnt=0;} {
        if($1 >= 10 && $1 <= 13){sl3m+=$3/1000000; cnt++;}
        } END{ print "FIO_L3_Miss_Count(M): "5*sl3m/cnt; }' $result_path/llc_mr_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sl3h; sl3m; cnt=0;} {
        if($1 >= 10 && $1 <= 13){sl3h+=$2/1000; sl3m+=$3/1000; cnt++;}
        } END{ print "FIO_L3_Miss_Rate: " 100*sl3m/(sl3h+sl3m); }' $result_path/llc_mr_$label.txt >> $result_path/result.txt

        awk 'BEGIN{ sum=0; cnt=0;} {sum += $8; cnt++;} END {avg = sum / cnt; print "Average_Read_BW(GB/s): "avg/1000}' $result_path/read_bw_$label.txt >> $result_path/result.txt
        awk 'BEGIN{ sum=0; cnt=0;} {sum += $7; cnt++;} END {avg = sum / cnt; print "Average_Write_BW(GB/s): "avg/1000}' $result_path/write_bw_$label.txt >> $result_path/result.txt

        cat $tmp_io | grep -B 10 $storage_device | grep -E "Part0|Part1|Part2|Part3" > $result_path/tmp.txt
        awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/storage_io.txt
        awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
            if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
            if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
            } END{print "Storage1_Throughput_R(GB/s): "4*(sumr)/cnt; print "Storage1_Throughput_W(GB/s): "4*(sumw)/cnt;
            }' $result_path/storage_io.txt >> $result_path/result.txt
        # echo -n "Xmem L2 Writeback (M, $label):" >> $result_path/result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;}else if($2=="K"){sum+=$1/1000;}else{sum+=$1/1000000;} cnt++; } END{avg = sum * 4 / cnt; print avg}' $result_path/core_l2_wb_app_$label.txt >> $result_path/result.txt
        # echo -n "DPDK L2 Writeback (M, $label):" >> $result_path/result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;}else if($2=="K"){sum+=$1/1000;}else{sum+=$1/1000000;} cnt++; } END{avg = sum * 4/ cnt; print avg}' $result_path/core_l2_wb_io_$label.txt >> $result_path/result.txt

        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1*1000;} else if($2=="K"){sum+=$1;} else {sum+=$1/1000} cnt++; } END{avg = sum / cnt; print "Average_PCIe_M(M): "avg/1000}' $result_path/pcie_miss_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1*1000;} else if($2=="K"){sum+=$1;} else {sum+=$1/1000} cnt++; } END{avg = sum / cnt; print "Average_PCIe_H(M): "avg/1000}' $result_path/pcie_hit_$label.txt >> $result_path/result.txt
        
    done
    mv $result_path/result.txt $result_base/result_$i.txt 


done

sudo pqos -R
rm $TMP_PATH/*.txt
$BASE_PATH/scripts/workloads/stop_all.sh
sudo $DBENCH_PATH/network_enable
sudo pkill xmem

$BASE_PATH/scripts/motivation/parse_result.sh Fig8b
