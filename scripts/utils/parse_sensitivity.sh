#! /bin/bash



bench_type=$1
bs=$2
pckt=$3
parameters=$4


types=( "SmartLLC_0" )

if [ "$parameters" == "1" ]; then

    result_base=$BASE_PATH"/results/sensitivity/T1T5"
    t1s=("0.3" "0.3" "0.3" "0.2" "0.2" "0.2")
    t5s=("95"  "90"  "70"  "95"  "90"  "70")

    rm $result_base/results.txt

    echo "Shared" >> $result_base/results.txt
    cat $result_base/Shared_$bench_type/pkt${pckt}_bs$bs/results.txt >> $result_base/results.txt

    for type in "${types[@]}"; do

        for ((i=0; i<${#t1s[@]}; i++)); do

        T1=${t1s[$i]}
        T5=${t5s[$i]}

        echo $type"_"$T1"_"$T5 >> $result_base/results.txt
        cat $result_base/$T1"_"$T5/$type"_"$bench_type/pkt${pckt}_bs$bs/results.txt >> $result_base/results.txt

        done

    done
    sed -i 's/\t//g' $result_base/results.txt
elif [ "$parameters" == "2" ]; then

    result_base=$BASE_PATH"/results/sensitivity/T2T3T4"
    # t2s=("60" "50" "40" "40" "40" "40" "40" "30" "40" "40")
    # t3s=("35" "35" "55" "45" "35" "35" "35" "35" "30" "35")
    # t4s=("40" "40" "40" "40" "80" "60" "40" "40" "40" "20")
    t2s=("60" "50" "40" "40" "40" "40" "40")
    t3s=("35" "35" "65" "50" "35" "35" "35")
    t4s=("40" "40" "40" "40" "80" "60" "40")

    rm $result_base/results.txt

    echo "Shared" >> $result_base/results.txt
    cat $result_base/Shared_$bench_type/pkt${pckt}_bs$bs/results.txt >> $result_base/results.txt

    for type in "${types[@]}"; do

        for ((i=0; i<${#t2s[@]}; i++)); do

        T2=${t2s[$i]}
        T3=${t3s[$i]}
        T4=${t4s[$i]}

        echo $type"_"$T2"_"$T3"_"$T4 >> $result_base/results.txt
        cat $result_base/$T2"_"$T3"_"$T4/$type"_"$bench_type/pkt${pckt}_bs$bs/results.txt >> $result_base/results.txt
        done
    done

    sed -i 's/\t//g' $result_base/results.txt
fi