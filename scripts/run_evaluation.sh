#! /bin/bash


base=$BASE_PATH"/scripts/evaluation"

$BASE_PATH/scripts/utils/kill_all.sh
$BASE_PATH/scripts/workloads/end_client.sh
mkdir -p $BASE_PATH/results/figs
mkdir -p $BASE_PATH/tmp

# HPW heavy scenario
if [ "$1" == "" ] || [ "$1" == "real" ]; then
    sudo $BASE_PATH/scripts/utils/switch.sh real
    $base/run_all.sh real

    mkdir -p $BASE_PATH/results/HPW_heavy
    sudo rm -r $BASE_PATH/results/HPW_heavy/*
    mv $BASE_PATH/results/*real* $BASE_PATH/results/HPW_heavy/

    python3 $base/gen_fig13a.py $BASE_PATH/results/HPW_heavy
    cp $BASE_PATH/results/HPW_heavy/fig*.png $BASE_PATH/results/figs/
    python3 $base/gen_fig14.py $BASE_PATH/results/HPW_heavy
    cp $BASE_PATH/results/HPW_heavy/fig*.png $BASE_PATH/results/figs/
fi

# LPW heavy scenario
if [ "$1" == "" ] || [ "$1" == "real2" ]; then
    sudo $BASE_PATH/scripts/utils/switch.sh real2
    $base/run_all.sh real2

    mkdir -p $BASE_PATH/results/LPW_heavy
    sudo rm -r $BASE_PATH/results/LPW_heavy/*
    mv $BASE_PATH/results/*real* $BASE_PATH/results/LPW_heavy/

    python3 $base/gen_fig13b.py $BASE_PATH/results/LPW_heavy
    cp $BASE_PATH/results/LPW_heavy/fig*.png $BASE_PATH/results/figs/
    
    # revert to original configuration
    sudo $BASE_PATH/scripts/utils/switch.sh real
fi
