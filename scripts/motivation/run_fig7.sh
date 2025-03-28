#!/bin/bash


tmp_dpdk="$TMP_PATH/dpdk.txt"
tmp_mem="$TMP_PATH/mem.txt"
tmp_llc="$TMP_PATH/llc.txt"
tmp_io="$TMP_PATH/io.txt"
tmp_pcie="$TMP_PATH/pcie.txt"
tmp_miss="$TMP_PATH/miss.txt"

result_base="$BASE_PATH/results/Fig7"
mkdir -p $result_base

rm -r $result_base/*
rm $BASE_PATH/tmp/*.txt
sudo modprobe msr

network_device=$SERVER_NIC_PCIE
DPDK_CORE="10-14"
pkt_size="1024"
lat=100

e_l2_wb="-e cpu/event=0xf0,umask=0x40,name=l2_wb/"
e_l3_miss="-e cpu/event=0xd1,umask=0x20,name=l3_miss/"

sudo pqos -R
   
sudo pqos -a llc:1=$DPDK_CORE
# llc_masks=( "0x0600" "0x0180" "0x0780" "0x01e0"  "0x07e0" "0x01f8" "0x07f8")
llc_masks=( "0x003" "0x00c" "0x00f" "0x03c"  "0x03f" "0x0fc" "0x0ff")
# sudo pqos -s


# sudo $DPDK_PATH/dpdk-rx -l $DPDK_CORE -a $network_device -- -d $lat -l 10000 -m 0 > $tmp_dpdk &
# $base/LLC_WAY/scripts/start_wyatt.sh $result_base $pkt_size &

echo "Start Iteration"
for ((i=1; i<=$ITER; i++)); do
    result_path="$result_base/$i"
    mkdir -p $result_path
    rm $result_path/*.txt
    touch $result_path/result.txt

    for mask_i in "${!llc_masks[@]}"; do

        #set LLC ways for group1
        sudo pqos -e llc:1=${llc_masks[$mask_i]}  
        mask=${llc_masks[$mask_i]}

        #start dpdk
        sudo $DPDK_PATH/dpdk-rx -l $DPDK_CORE -a $network_device -- -d $lat -l 1000 -m 0 > $tmp_dpdk &
        $BASE_PATH/scripts/workloads/start_client.sh $result_path $pkt_size &
        
        sleep 3
        
        #start monitoring
        cd $PCM_PATH
        sudo stdbuf -oL pcm-memory 1 -silent  | stdbuf -oL grep "SKT  0 Mem " > $tmp_mem &
        sudo stdbuf -oL ./pcm-iio 1.0 -silent | stdbuf -oL grep -A 62 "Socket0" > $tmp_io &  
        sudo stdbuf -oL pcm-pcie -e -silent   | stdbuf -oL grep -A 3 "Skt" > $tmp_pcie &   
        sudo stdbuf -oL pcm 1 -silent         | stdbuf -oL grep -A 15 "Core (SKT)" > $tmp_miss &

        #gather data for 1 min
        echo "===========Monitoring Start==========="
        sleep 10
        echo "===========Monitoring End==========="
 
        sudo pkill pcm 
        sudo pkill dpdk-rx
        $BASE_PATH/scripts/workloads/end_client.sh
        sudo pkill xmem

        sleep 1
        

        cat $tmp_mem | grep "Read" > $result_path/read_bw_$mask.txt
        cat $tmp_mem | grep "Write" > $result_path/write_bw_$mask.txt
        
        sed -i '/Core/,+1d;/^$/d;/--/d;s/|//g;s/ K/000/g;s/ M/000000/g' $tmp_miss 
        awk '{print $2"  "$9"  "$7}' $tmp_miss > $result_path/llc_mr_$mask.txt  
        
        # awk -F '  +' '{if($2 <=3 && $2 >= 0) print $7}' $tmp_llc > $result_path/core_l2_wb_app_$mask.txt
        # awk -F '  +' '{if( (10<=$2 && $2<=13) ) print $7}' $tmp_llc > $result_path/core_l2_wb_io_$mask.txt 

        awk -F '  +' '{if( $8 ~ /\(Miss\)/ || $9 ~ /\(Miss\)/ ) print $6}' $tmp_pcie > $result_path/pcie_miss_$mask.txt
        awk -F '  +' '{if( $9 ~ /\(Hit\)/ ) print $6}' $tmp_pcie > $result_path/pcie_hit_$mask.txt

        echo "==========Monitoring Result ($mask)==========" >> $result_path/result.txt   
        awk 'BEGIN{sl3m; cnt=0;} { if($1 >= 10 && $1 <= 13){sl3m+=$3/1000000; cnt++;}
        } END{ print "DPDK_L3_Miss_Count_(M): "5*sl3m/cnt; }' $result_path/llc_mr_$mask.txt >> $result_path/result.txt
        awk 'BEGIN{sl3h; sl3m; cnt=0;} { if($1 >= 10 && $1 <= 13){sl3h+=$2/1000; sl3m+=$3/1000; cnt++;}
        } END{ print "DPDK_L3_Miss_Rate: " 100*sl3m/(sl3h+sl3m); }' $result_path/llc_mr_$mask.txt >> $result_path/result.txt
        

        awk 'BEGIN{ sum=0; cnt=0;} {sum += $8; cnt++;} END {avg = sum / cnt; print "Average_read_BW: "avg}' $result_path/read_bw_$mask.txt >> $result_path/result.txt
        awk 'BEGIN{ sum=0; cnt=0;} {sum += $7; cnt++;} END {avg = sum / cnt; print "Average_write_BW: "avg}' $result_path/write_bw_$mask.txt >> $result_path/result.txt
    
        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1*1000;} else if($2=="K"){sum+=$1;} else {sum+=$1/1000} cnt++; } END{avg = sum / cnt; print "Average_PCIe_M(M): "avg/1000}' $result_path/pcie_miss_$mask.txt >> $result_path/result.txt
        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1*1000;} else if($2=="K"){sum+=$1;} else {sum+=$1/1000} cnt++; } END{avg = sum / cnt; print "Average_PCIe_H(M): "avg/1000}' $result_path/pcie_hit_$mask.txt >> $result_path/result.txt
        
        # echo -n "app L2 Writeback (M, $mask):" >> $result_path/result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;}else if($2=="K"){sum+=$1/1000;}else{sum+=$1/1000000;} cnt++; } END{avg = sum * 4 / cnt; print avg}' $result_path/core_l2_wb_app_$mask.txt >> $result_path/result.txt
        # echo -n "IO L2 Writeback (M, $mask):" >> $result_path/result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;}else if($2=="K"){sum+=$1/1000;}else{sum+=$1/1000000;} cnt++; } END{avg = sum * 4/ cnt; print avg}' $result_path/core_l2_wb_io_$mask.txt >> $result_path/result.txt

        cat $result_path/tx_result.txt | grep "99%_e2e_tail_latency" | tail -n 5 | awk 'BEGIN{sum=0; cnt=0;}{sum+=$2; cnt++;}END{print "99%_tail_latency: "sum/cnt;}' >> $result_path/result.txt
        cat $result_path/tx_result.txt | grep "Average_e2e_latency"  | tail -n 5 | awk 'BEGIN{sum=0; cnt=0;}{sum+=$2; cnt++;}END{print "Average_latency: "sum/cnt;}' >> $result_path/result.txt

        cat $tmp_io | grep -B 10 $network_device | grep "Part0" > $result_path/tmp.txt
        awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/network_io.txt
        awk 'BEGIN{sumr=0; cnt=0; sumw=0;} {
            if($2=="M"){sumr+=$1/1024;}else if($2=="G"){sumr+=$1;}else if($2=="K"){sumr+=$1/1024/1024;} cnt++;
            if($4=="M"){sumw+=$3/1024;}else if($4=="G"){sumw+=$3;}else if($4=="K"){sumw+=$3/1024/1024;}
        } END{print "Network_Throughput_R(GB/s): "(sumr)/cnt; print "Network_Throughput_W(GB/s): "(sumw)/cnt;
        }' $result_path/network_io.txt >> $result_path/result.txt
        
        sleep 3

    done
    mv $result_path/result.txt $result_base/result_$i.txt 
    

    sleep 1

done

$BASE_PATH/scripts/motivation/stop_all.sh
$BASE_PATH/scripts/motivation/parse_result.sh Fig7
sudo pqos -R
rm $TMP_PATH/*.txt