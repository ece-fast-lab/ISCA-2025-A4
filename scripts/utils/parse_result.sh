#! /bin/bash

result_path=$BASE_PATH"/results"
name=$1
if [ -n "$2" ]; then
    iter=$2
else
    iter=5 
fi

cd $result_path/$name
sudo rm results.txt
for ((i=0; i<$iter; i++)); do
    awk -F ':' '{print $2}' result_$i.txt > tmp_$i.txt
done

awk -F ':' '{print $1":  "}' result_0.txt > index_tmp.txt

paste index_tmp.txt tmp* > results.txt

sed -i 's/us//g' results.txt

rm *tmp*
