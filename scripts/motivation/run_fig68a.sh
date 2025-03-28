#! /bin/bash

#Fig 5

base="$BASE_PATH/scripts/motivation"
types=("Fig6" "Fig8a")


for type in "${types[@]}"; do
    $base/network_storage_corun.sh $type
done

$base/stop_all.sh

