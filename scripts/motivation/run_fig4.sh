#!/bin/bash


tmp_dpdk="$TMP_PATH/dpdk.txt"
tmp_mem="$TMP_PATH/mem.txt"
tmp_llc="$TMP_PATH/llc.txt"
tmp_pcie="$TMP_PATH/pcie.txt"
tmp_io="$TMP_PATH/io.txt"
tmp_miss="$TMP_PATH/miss.txt"

result_base="$BASE_PATH/results/Fig4"
mkdir -p $result_base



rm -r $result_base/*
rm $BASE_PATH/tmp/*.txt
sudo modprobe msr

network_device=$SERVER_NIC_PCIE
lat=100
DPDK_CORE="10-14"
APP_CORE="0-3"
pkt_size="1024"
type="dpdk-rx"

# xmem_on_idx=2
ddio_enable=("0" "0" "0" "0" "1" "1" "1" "1" "1")
xmem_ways=("0x600" "0x0c0" "0x030" "0x003" "0x600" "0x0c0" "0x030" "0x003" "0x003")

# sudo pqos -R

sudo pqos -e llc:1=0x030
sudo pqos -a llc:1=$DPDK_CORE


for ((i=1; i<=$ITER; i++)); do
    result_path="$result_base/$i"
    if [[ ! -d "$result_path" ]]; then
        mkdir $result_path
    fi
    rm $result_path/*.txt
    touch $result_path/result.txt

    # dpdk-tx started
    $BASE_PATH/scripts/workloads/start_client.sh $result_base $pkt_size &
    #start dpdk
    sudo stdbuf -oL $DPDK_PATH/$type -l $DPDK_CORE -a $network_device -- -d $lat -l 1000 -m 0 > $tmp_dpdk &
    sleep 2

    for j in {0..8}; do
        ddio=${ddio_enable[j]}
        mask=${xmem_ways[j]}

        # start X-Mem
        # if (( j == xmem_on_idx )); then
        #     sudo xmem -t -n3000 -c256 -j4 -w5120 &
        #     sleep 5
        # fi

        # terminate dpdk
        if (( j == 8 )); then
            sudo kill -INT $(pgrep dpdk-rx)
            $BASE_PATH/scripts/workloads/end_client.sh
            label="xmem_sol"
        else
            label="ddio"$ddio
            # Turn on/off DDIO
            if (( ddio )); then
                sudo $DBENCH_PATH/network_enable
            else
                sudo $DBENCH_PATH/network_disable
            fi
        fi

        #set LLC ways for streaming application
        sudo pqos -e llc:2=$mask  
        sudo pqos -a llc:2=$APP_CORE
        label=$label"_xmem"$mask
        
        sleep 1
        
        #start monitoring
        # cd $PCM_PATH
        # sudo ./pcm-iio 1.0 -silent | grep -A 62 "Socket0" > $tmp_io & 
        sudo pcm-memory 1 -silent| grep "SKT  0 Mem " > $tmp_mem &
        # sudo pcm-core 1 -silent $e_l2_wb $e_l3_miss | grep -A 20 "Core" > $tmp_llc &
        sudo pcm-pcie -e -silent | grep -A 3 "Skt" > $tmp_pcie &   
        sudo pcm 1 -silent | grep -A 15 "Core (SKT)" > $tmp_miss &

        #gather data for 1 min
        sleep 10
 
        sudo pkill pcm-memory
        # sudo pkill pcm-core
        sudo pkill pcm-pcie
        # sudo pkill pcm-iio
        sudo pkill pcm
        # $base/LLC_WAY/scripts/end_wyatt.sh
        # sudo kill -INT $(pgrep dpdk-rx)
        # sudo kill -INT $(pgrep nt-dpdk-rx)
        
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
        } END{ print "Xmem L3 Miss Count (M): "4*sl3m/cnt; }' $result_path/llc_mr_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sl3h; sl3m; cnt=0;} {
        if($1 >= 0 && $1 <= 1){sl3h+=$2/1000; sl3m+=$3/1000; cnt++;}
        } END{ print "Xmem L3 Miss Rate: " 100*sl3m/(sl3h+sl3m); }' $result_path/llc_mr_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sl3m; cnt=0;} {
        if($1 >= 10 && $1 <= 14){sl3m+=$3/1000000; cnt++;}
        } END{ print "DPDK L3 Miss Count (M): "5*sl3m/cnt; }' $result_path/llc_mr_$label.txt >> $result_path/result.txt
        awk 'BEGIN{sl3h; sl3m; cnt=0;} {
        if($1 >= 10 && $1 <= 14){sl3h+=$2/1000; sl3m+=$3/1000; cnt++;}
        } END{ print "DPDK L3 Miss Rate: " 100*sl3m/(sl3h+sl3m); }' $result_path/llc_mr_$label.txt >> $result_path/result.txt

        echo -n "Average Read BW ($label):" >> $result_path/result.txt
        awk 'BEGIN{ sum=0; cnt=0;} {sum += $8; cnt++;} END {avg = sum / cnt; print avg/1000}' $result_path/read_bw_$label.txt >> $result_path/result.txt
        echo -n "Average Write BW ($label):" >> $result_path/result.txt
        awk 'BEGIN{ sum=0; cnt=0;} {sum += $7; cnt++;} END {avg = sum / cnt; print avg/1000}' $result_path/write_bw_$label.txt >> $result_path/result.txt

        # echo -n "Xmem L2 Writeback (M, $label):" >> $result_path/result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;}else if($2=="K"){sum+=$1/1000;}else{sum+=$1/1000000;} cnt++; } END{avg = sum * 4 / cnt; print avg}' $result_path/core_l2_wb_app_$label.txt >> $result_path/result.txt
        # echo -n "DPDK L2 Writeback (M, $label):" >> $result_path/result.txt
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;}else if($2=="K"){sum+=$1/1000;}else{sum+=$1/1000000;} cnt++; } END{avg = sum * 4/ cnt; print avg}' $result_path/core_l2_wb_io_$label.txt >> $result_path/result.txt

        echo -n "Average PCIe Miss (M, $label):" >> $result_path/result.txt
        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;} else if($2=="K"){sum+=$1/1000;} else {sum+=$1/1000000} cnt++; } END{avg = sum / cnt; print avg}' $result_path/pcie_miss_$label.txt >> $result_path/result.txt
    
        echo -n "Average PCIe Hit (M, $label):" >> $result_path/result.txt 
        awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;} else if($2=="K"){sum+=$1/1000;} else {sum+=$1/1000000} cnt++; } END{avg = sum / cnt; print avg}' $result_path/pcie_hit_$label.txt >> $result_path/result.txt

        cat $tmp_dpdk | tail -n 10 | awk 'BEGIN{sum=0;cnt=0;} {sum+=$6;cnt++;} END{if(cnt){ print "DPDK Throughput:" (sum/cnt)*8*1024/1000; }else{print 0}}' >> $result_path/result.txt
        cat $result_base/tx_result.txt | grep "99%" | tail -n 10 | awk 'BEGIN{sum=0; cnt=0;}{sum+=$2; cnt++;}END{print "99%_tail_latency: "sum/cnt;}' >> $result_path/result.txt
        cat $result_base/tx_result.txt | grep "Average_e2e_latency" | tail -n 10 | awk 'BEGIN{sum=0; cnt=0;}{sum+=$2; cnt++;}END{print "Average_latency: "sum/cnt;}' >> $result_path/result.txt

        # cat $tmp_io | grep -B 10 $network_device | grep "Part0" > $result_path/tmp.txt
        # awk -F '|' '{print $3 " " $4}' $result_path/tmp.txt > $result_path/network_tp.txt
        # echo -n "Network_Throughput(MB/s): " >> $result_path/result.txt 
        # awk 'BEGIN{sum=0; cnt=0;} {if($2=="M"){sum+=$1;cnt++;}else if($2=="G"){sum+=$1*1000;cnt++;}else if($2=="K"){sum+=$1/1000;cnt++;}} END{print sum/cnt}' $result_path/network_tp.txt >> $result_path/result.txt
            

    done
    mv $result_path/result.txt $result_base/result_$i.txt 
    # sudo pkill xmem
    #sudo pkill dpdk-rx
    #sudo pkill nt-dpdk-rx
    # #sudo kill -INT $(pgrep dpdk-rx)
    # #sudo kill -INT $(pgrep nt-dpdk-rx)
    # $base/LLC_WAY/scripts/end_wyatt.sh


done

sudo pqos -R
rm $TMP_PATH/*.txt
$BASE_PATH/scripts/motivation/stop_all.sh
$BASE_PATH/scripts/motivation/parse_result.sh Fig4