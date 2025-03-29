# ISCA-2025-A4 Experimental Framework

This README provides instructions for running experiments, locating results, and understanding expected outcomes.

## Running Experiments

### Prerequisites
- Ensure that all benchmarks are installed
- The `BASE_PATH` environment variable must be set to the root directory of the project
- Appropriate permissions for PQOS and DPDK operations (sudo access)

### Running All Experiments
To run all motivation experiments:
```bash
./run_motivation.sh
```

### Running Individual Experiments
To run a specific figure experiment:
```bash
./run_motivation.sh <figure_number>
```

Valid figure numbers: 3, 4, 5, 6, 7, 8a, 8b

Examples:
```bash
# Run only Figure 4 experiment
./run_motivation.sh 4
```

## Results Location

All experimental results are stored in directories under:
```
$BASE_PATH/results/
```

All figures can be found in:
```
$BASE_PATH/results/figs/
```

Or each raw data text file and figure can be found in:
- `$BASE_PATH/results/Fig{i}/` - Raw data for Figure i
Each directory contains:
- `results.txt` - Raw measurement data
- `*.png` - Generated graph images of the figure

## Expected Results

### Fig 3
DPDK-NT shows interference with X-Mem only when X-Mem's LLC ways are allocated overlaps with the leftmost two DCA ways (Fig 3a). However, the LLC hit rate of DPDK-NT is not affected by the allocation of X-Mem. DPDK-T shows interference with X-Mem on three distinct regions. The interference is shown as an increase in the LLC hit rate of both applications and memory bandwidth. However, the extent of interference might vary across the run largely due to inconsistent X-Mem performance.

### Fig 4
The interference between DPDK-T and X-Mem is illustrated as an increase in network tail latency and X-Mem LLC miss rate. When DCA is on, interference is captured when X-Mem's LLC ways are allocated to any of the three regions (aligns with Fig 3b). When DCA is off, interference is not captured in any LLC ways, suggesting that the source of interference is the I/O data allocated to LLC.

### Fig 5
Two important characteristics of storage I/O-intensive applications that uses large block sizes and deep I/O depth stand out in this figure. First, storage I/O throughput is little affected by whether DCA is on or off. Second, the DMA leak (memory bandwidth consumption) is severe even when DCA is on.

### Fig 6
Co-running DPDK-T and FIO significantly increases network latency when DCA is on compared to DPDK-T solo run.