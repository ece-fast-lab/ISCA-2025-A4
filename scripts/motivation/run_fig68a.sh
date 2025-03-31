#!/bin/bash


tmp_dpdk="$TMP_PATH/dpdk.txt"
tmp_mem="$TMP_PATH/mem.txt"
tmp_pcie="$TMP_PATH/pcie.txt"
tmp_miss="$TMP_PATH/miss.txt"
tmp_io="$TMP_PATH/io.txt"

fio_jobfile="$BASE_PATH/app/configs/dpdk_fio.fio"

result_base="$BASE_PATH/results/Fig68a"
mkdir -p $result_base



rm -r $result_base/*
rm $BASE_PATH/tmp/*.txt
sudo modprobe msr

network_device=$SERVER_NIC_PCIE
storage_device=$SERVER_SSD_PCIE
lat=150
DPDK_CORE="0-4"
FIO_CORE="10-13"
pkt_size="1024"
dpdk_bin="dpdk-rx"

block_sizes=("0" "4k" "8k" "16k" "32k" "64k" "128k" "256k" "512k" "1024k" "2048k")

sudo pqos -e llc:1=0x60
sudo pqos -a llc:1=$DPDK_CORE

sudo pqos -e llc:2=0x180
sudo pqos -a llc:2=$FIO_CORE

for ((i=1; i<=$ITER; i++)); do
    result_path="$result_base/$i"
    if [[ ! -d "$result_path" ]]; then
        mkdir $result_path
    fi
    rm $result_path/*.txt
    touch $result_path/result.txt

    # dpdk-tx started
    $BASE_PATH/scripts/workloads/start_client.sh $result_base $pkt_size &

    #start dpdk-rx
    sudo stdbuf -oL $DPDK_PATH/$dpdk_bin -l $DPDK_CORE -a $network_device -- -d $lat -l 10000 -m 0 > $tmp_dpdk &

    for j in "${!block_sizes[@]}"; do
        
        # run FIO
        bs=${block_sizes[$j]}
        if [[ "$bs" != "0" ]]; then
            export SIZE=$bs
            echo "Running FIO with block size: $SIZE..."
            sudo -E taskset -c $FIO_CORE fio $fio_jobfile &
            # DPDK+FIO
            name="dpdk"$pkt_size"+fio"$bs
        else
            # DPDK solo
            name="dpdk_solo"$pkt_size
        fi

        # iterate twice disabling/enabling ddio
        for k in {0..2}; do
            # Turn on/off DDIO
            label=$name"_ddio"$k
            if (( k == 1 )); then
                sudo $DBENCH_PATH/storage_enable
                sudo $DBENCH_PATH/network_enable
            elif (( k == 0 )); then
                sudo $DBENCH_PATH/storage_disable
                sudo $DBENCH_PATH/network_disable
            elif (( k == 2 )); then
                sudo $DBENCH_PATH/storage_disable
                sudo $DBENCH_PATH/network_enable
            fi
            sleep 2
            # start monitoring
            cd $PCM_PATH
            sudo stdbuf -oL pcm-memory 1 -silent  | stdbuf -oL grep "SKT  0 Mem " > $tmp_mem &
            sudo stdbuf -oL ./pcm-iio 1.0 -silent | stdbuf -oL grep -A 62 "Socket0" > $tmp_io &  
            sudo stdbuf -oL pcm-pcie -e -silent   | stdbuf -oL grep -A 3 "Skt" > $tmp_pcie &   
            sudo stdbuf -oL pcm 1 -silent         | stdbuf -oL grep -A 15 "Core (SKT)" > $tmp_miss &

            sleep 10

            sudo pkill pcm

            awk -F '  +' '{if( $8 ~ /\(Miss\)/ || $9 ~ /\(Miss\)/ ) print $6}' $tmp_pcie > $result_path/pcie_miss_$label.txt
            awk -F '  +' '{if( $9 ~ /\(Hit\)/ ) print $6}' $tmp_pcie > $result_path/pcie_hit_$label.txt
            cat $tmp_mem | grep "Read" > $result_path/read_bw_$label.txt
            cat $tmp_mem | grep "Write" > $result_path/write_bw_$label.txt
            

            echo "==========Monitoring Result ("$label")==========" >> $result_path/result.txt   
            awk 'BEGIN{ sum=0; cnt=0;} {sum += $8; cnt++;} END {avg = sum / cnt; print "Average_read_BW: "avg}' $result_path/read_bw_$label.txt >> $result_path/result.txt
            awk 'BEGIN{ sum=0; cnt=0;} {sum += $7; cnt++;} END {avg = sum / cnt; print "Average_write_BW: "avg}' $result_path/write_bw_$label.txt >> $result_path/result.txt
            
            awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1*1000;} else if($2=="K"){sum+=$1;} else {sum+=$1/1000} cnt++; } END{avg = sum / cnt; print "Average_PCIe_M(K): "avg}' $result_path/pcie_miss_$label.txt >> $result_path/result.txt
            awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1*1000;} else if($2=="K"){sum+=$1;} else {sum+=$1/1000} cnt++; } END{avg = sum / cnt; print "Average_PCIe_H(K): "avg}' $result_path/pcie_hit_$label.txt >> $result_path/result.txt
            
            cat $result_base/tx_result.txt | grep "99%_e2e_tail_latency" | tail -n 10 | awk 'BEGIN{sum=0; cnt=0;}{sum+=$2; cnt++;}END{print "99%_tail_latency: "sum/cnt;}' >> $result_path/result.txt
            cat $result_base/tx_result.txt | grep "Average_e2e_latency"  | tail -n 10 | awk 'BEGIN{sum=0; cnt=0;}{sum+=$2; cnt++;}END{print "Average_latency: "sum/cnt;}' >> $result_path/result.txt

            cat $tmp_io | grep -B 10 $network_device | grep "Part0" > $result_path/tmp.txt
            awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/network_io.txt
            awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
            } END{print "Network_Throughput_R(GB/s): "(sumr)/cnt; print "Network_Throughput_W(GB/s): "(sumw)/cnt;
            }' $result_path/network_io.txt >> $result_path/result.txt
            cat $tmp_io | grep -B 10 $storage_device | grep -E "Part0|Part1|Part2|Part3" > $result_path/tmp.txt
            awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/storage_io.txt
            awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
                if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
                if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
                } END{print "Storage1_Throughput_R(GB/s): "4*(sumr)/cnt; print "Storage1_Throughput_W(GB/s): "4*(sumw)/cnt;
                }' $result_path/storage_io.txt >> $result_path/result.txt

        done
        sudo pkill fio
    done
    mv $result_path/result.txt $result_base/result_$i.txt
    $BASE_PATH/scripts/workloads/end_client.sh
    sudo pkill dpdk-rx
    sleep 3

done

$BASE_PATH/scripts/motivation/parse_result.sh Fig68a
sudo $DBENCH_PATH/storage_enable
sudo $DBENCH_PATH/network_enable
sudo pqos -R
sudo wrmsr 0xc8b 0x0600
