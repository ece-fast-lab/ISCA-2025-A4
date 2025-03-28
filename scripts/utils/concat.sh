#! /bin/bash

# micro or real
bench=$1
result_base=$BASE_PATH"/results"


pkts=("1514"  "1514" "1514" "1514" "1514" "1514" "1514"  "1514" "1514"  "1514"   "64"    "128"   "256"   "512"   "1024"  )
bss=( "4k" "2048k"   "8k"   "32k"  "64k"  "128k"  "256k" "512k" "1024k" "16k"  "2048k" "2048k" "2048k" "2048k" "2048k" )

types=("SmartLLC_0" "Shared" "Isolated")

for type in "${types[@]}"; do
    cd $result_base"/"$type"_"$bench
    echo $type" parsed!"
    pkts=("64"    "128"   "256"   "512"   "1024"  "1514")
    bss=("2048k" "2048k" "2048k" "2048k" "2048k"  "2048k")
    files=""
    for ((i=0; i<${#pkts[@]}; i++)); do
        files=$files" ./pkt"${pkts[$i]}"_bs"${bss[$i]}"/results.txt"
    done
    cat $files > "./option1.txt"
    pkts=("1514"  "1514" "1514" "1514" "1514" "1514" "1514"  "1514" "1514"  "1514" )
    bss=( "4k"    "8k"   "16k"  "32k"  "64k"  "128k"  "256k" "512k" "1024k" "2048k")
    files=""
    for ((i=0; i<${#pkts[@]}; i++)); do
        files=$files" ./pkt"${pkts[$i]}"_bs"${bss[$i]}"/results.txt"
    done
    cat $files > "./option2.txt"

done

