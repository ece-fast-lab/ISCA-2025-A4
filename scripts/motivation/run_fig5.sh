#! /bin/bash

#Fig 5

base="$BASE_PATH/scripts/motivation"
result_path="$BASE_PATH/results/Fig5"
types=("en" "dis")

rm $result_path/*

for type in "${types[@]}"; do
    $base/storage_solo.sh $type
    $base/parse_result.sh Fig5/$type
done

cd $result_path
cat en/results.txt dis/results.txt > results.txt

$base/stop_all.sh

