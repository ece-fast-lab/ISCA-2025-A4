#! /bin/bash


base=$BASE_PATH"/scripts/motivation"

# sudo pqos -R
sudo pqos -e llc:2=0x003
sudo pqos -a llc:2=0-3
sudo xmem -t -n3000 -c256 -j2 -R -w4096 &
sleep 5

# Figure 3a, 3b
$base/run_fig3.sh dpdk-rx
$base/run_fig3.sh nt-dpdk-rx
python3 $base/gen_fig3.py $BASE_PATH/results/Fig3_dpdk-rx
python3 $base/gen_fig3.py $BASE_PATH/results/Fig3_nt-dpdk-rx
sleep 3
# Figure 4
$base/run_fig4.sh
python3 $base/gen_fig4.py $BASE_PATH/results/Fig4
sleep 3

sudo pkill xmem

# Figure 5
$base/run_fig5.sh
python3 $base/gen_fig5.py $BASE_PATH/results/Fig5
sleep 3

# Figure 7b
$base/run_fig7.sh
python3 $base/gen_fig7.py $BASE_PATH/results/Fig7
sleep 3

# Figure 8b
$base/run_fig8b.sh
python3 $base/gen_fig8b.py $BASE_PATH/results/Fig8b
sleep 3


# Run figure 5, 6, and 8a