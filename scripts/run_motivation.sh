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
    $base/run_fig3.sh nt-dpdk-rx
    python3 $base/gen_fig3.py $BASE_PATH/results/Fig3_nt-dpdk-rx
    sleep 3
}

run_fig4() {
    echo "Running Figure 4..."
    $base/run_fig4.sh
    python3 $base/gen_fig4.py $BASE_PATH/results/Fig4
    sleep 3
}

run_fig5() {
    echo "Running Figure 5..."
    $base/run_fig5.sh
    python3 $base/gen_fig5.py $BASE_PATH/results/Fig5
    sleep 3
}

run_fig68a() {
    echo "Running Figure 6 and 8a..."
    $base/run_fig68a.sh
    python3 $base/gen_fig6.py $BASE_PATH/results/Fig6
    python3 $base/gen_fig8a.py $BASE_PATH/results/Fig8a
    sleep 3
}

run_fig7() {
    echo "Running Figure 7b..."
    $base/run_fig7.sh
    python3 $base/gen_fig7.py $BASE_PATH/results/Fig7
    sleep 3
}

run_fig8b() {
    echo "Running Figure 8b..."
    $base/run_fig8b.sh
    python3 $base/gen_fig8b.py $BASE_PATH/results/Fig8b
    sleep 3
}

# Check if a specific figure was requested
if [ $# -eq 1 ]; then
    figure_number=$1
    
    case $figure_number in
        3)
            start_xmem
            run_fig3
            stop_xmem
            ;;
        4)
            start_xmem
            run_fig4
            stop_xmem
            ;;
        5)
            run_fig5
            ;;
        6|8a)
            run_fig68a
            ;;
        7|7b)
            run_fig7
            ;;
        8b)
            run_fig8b
            ;;
        *)
            echo "Invalid figure number: $figure_number"
            echo "Valid options: 3, 4, 5, 6, 7, 8a, 8b"
            exit 1
            ;;
    esac
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

echo "Done!"
