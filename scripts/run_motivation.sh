#! /bin/bash

base=$BASE_PATH"/scripts/motivation"

# Function to start X-Mem
start_xmem() {
    echo "Starting X-Mem..."
    sudo pqos -R
    sudo pqos -e llc:2=0x003
    sudo pqos -a llc:2=0-3
    sudo xmem -t -n3000 -c256 -j2 -R -w4096 &
    sleep 5
}

# Function to stop X-Mem
stop_xmem() {
    echo "Stopping X-Mem..."
    sudo pkill xmem
    sleep 3
}

# Functions for running each figure
run_fig3() {
    echo "Running Figure 3..."
    $base/run_fig3.sh dpdk-rx
    python3 $base/gen_fig3.py $BASE_PATH/results/Fig3_dpdk-rx
    sleep 3
    $base/run_fig3.sh nt-dpdk-rx
    python3 $base/gen_fig3.py $BASE_PATH/results/Fig3_nt-dpdk-rx
    sleep 3
    cp $BASE_PATH/results/Fig3*/fig*.png $BASE_PATH/results/figs/
}

run_fig4() {
    echo "Running Figure 4..."
    $base/run_fig4.sh
    python3 $base/gen_fig4.py $BASE_PATH/results/Fig4
    sleep 3
    cp $BASE_PATH/results/Fig4/fig*.png $BASE_PATH/results/figs/
}

run_fig5() {
    echo "Running Figure 5..."
    $base/run_fig5.sh
    python3 $base/gen_fig5.py $BASE_PATH/results/Fig5
    sleep 3
    cp $BASE_PATH/results/Fig5/fig*.png $BASE_PATH/results/figs/
}

run_fig68a() {
    echo "Running Figure 6..."
    $base/run_fig68a.sh
    python3 $base/gen_fig6.py $BASE_PATH/results/Fig68a
    python3 $base/gen_fig8a.py $BASE_PATH/results/Fig68a
    sleep 3
    cp $BASE_PATH/results/Fig68a/fig*.png $BASE_PATH/results/figs/
}

run_fig7() {
    echo "Running Figure 7b..."
    $base/run_fig7.sh
    python3 $base/gen_fig7.py $BASE_PATH/results/Fig7
    sleep 3
    cp $BASE_PATH/results/Fig7/fig*.png $BASE_PATH/results/figs/
}

run_fig8b() {
    echo "Running Figure 8b..."
    $base/run_fig8b.sh
    python3 $base/gen_fig8b.py $BASE_PATH/results/Fig8b
    sleep 3
    cp $BASE_PATH/results/Fig8b/fig*.png $BASE_PATH/results/figs/
}

mkdir -p $BASE_PATH/results/figs

# Check if any figure numbers were specified
if [ $# -ge 1 ]; then
    xmem_started=0
    
    # Track which figures have been processed
    declare -A processed_figures
    
    # Process each argument as a figure number
    for figure_number in "$@"; do
        # Skip if this figure has already been processed
        if [ "${processed_figures[$figure_number]}" = "1" ]; then
            echo "Figure $figure_number has already been processed, skipping..."
            continue
        fi
        
        case $figure_number in
            3)
                if [ $xmem_started -eq 0 ]; then
                    start_xmem
                    xmem_started=1
                fi
                run_fig3
                processed_figures[3]=1
                ;;
            4)
                if [ $xmem_started -eq 0 ]; then
                    start_xmem
                    xmem_started=1
                fi
                run_fig4
                processed_figures[4]=1
                ;;
            5)
                run_fig5
                processed_figures[5]=1
                ;;
            6|8a)
                run_fig68a
                processed_figures[6]=1
                processed_figures[8a]=1
                ;;
            7|7b)
                run_fig7
                processed_figures[7]=1
                processed_figures[7b]=1
                ;;
            8b)
                run_fig8b
                processed_figures[8b]=1
                ;;
            *)
                echo "Invalid figure number: $figure_number"
                echo "Valid options: 3, 4, 5, 6, 7, 8a, 8b"
                ;;
        esac
    done
    
    # Stop X-Mem if it was started
    if [ $xmem_started -eq 1 ]; then
        stop_xmem
    fi
else
    # Run all figures
    start_xmem
    run_fig3
    run_fig4
    stop_xmem
    run_fig5
    run_fig68a
    run_fig7
    run_fig8b
fi

$base/stop_all.sh

echo "Done!"
