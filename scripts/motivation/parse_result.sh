#! /bin/bash

name=$1
result_path=$BASE_PATH"/results/"$name

cd $result_path

for i in {1..5}; do
    awk -F ':' '{print $2}' result_$i.txt > tmp_$i.txt
done

awk -F ':' '{print $1}' result_1.txt > tmp_0.txt

paste tmp* > results.txt

sed -i 's/us//g' results.txt

rm tmp*