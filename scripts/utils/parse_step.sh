#! /bin/bash



bench_type=$1
bs=$2
pckt=$3

result_base=$BASE_PATH"/results"

types=( "Shared" "Isolated" "SmartLLC_1" "SmartLLC_2" "SmartLLC_3" "SmartLLC_0" )

rm $result_base/step_"$bench_type"_result_"$bs".txt

for type in "${types[@]}"; do

    echo $type >> $result_base/step_"$bench_type"_result_"$bs".txt
    cat $result_base/$type"_"$bench_type/pkt${pckt}_bs$bs/results.txt >> $result_base/step_"$bench_type"_result_"$bs".txt

done

sed -i 's/\t//g' $result_base/step_"$bench_type"_result_"$bs".txt

