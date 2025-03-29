# ISCA-2025-A4 Experimental Framework

This README provides instructions for running experiments, locating results, and understanding expected outcomes.

## Running Experiments

### Prerequisites
- Ensure that all benchmarks and tools are installed
- Ensure all enviroment variables are defined properly
- Appropriate permissions for PQOS and DPDK operations (sudo access)

### Running All Experiments
To run all motivation experiments:
```bash
./run_motivation.sh
```
To run evaluation experiments:
```bash
./run_evaluation.sh
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

Since experiments are conducted on real hardware, results may vary due to several influencing factors. Specifically, X-Mem tends to exhibit inconsistent performance, which could result in trends not precisely matching those presented and necessitate repeated runs. **Intermidtently, X-Mem LLC miss rate results very low. Please rerun in this case.**

Key takeaways from the figures are as follows. We also provide example figures under `ex_figs/`

### Fig 3a
X-Mem shows interference with DPDK-NT only when X-Mem's LLC ways are allocated overlaps with the leftmost two DCA ways. However, the LLC hit rate of DPDK-NT is only affected when X-Mem is allocated to 0x030, contending with DPDK-NT code.

### Fig 3b
DPDK-T shows interference with X-Mem on three distinct regions. However, the extent of interference might vary across the run largely due to inconsistent X-Mem performance.

### Fig 4
When DCA is on, interference is captured when X-Mem's LLC ways are allocated to any of the three regions (aligns with Fig 3b). When DCA is off, interference in inclusive ways(0x003) is not captured.

### Fig 5
First, storage I/O throughput is little affected by whether DCA is on or off. Second, the DMA leak (memory bandwidth consumption) is severe even when DCA is on.

### Fig 6
Co-running DPDK-T and FIO significantly increases network latency when DCA is on compared to DPDK-T solo run.

### Fig 7
Overlapping DPDK-T allocated LLC ways to inclusive ways are benefitial to DPDK-T. Memory bandwidth consumption and network latency reduces comparing (0x00c, 0x03c, 0x0fc) to (0x00f, 0x03f, 0x0ff), respectively.

### Fig 8a
When co-running DPDK-T and FIO, disabling storage I/O DCA reduces DCA contention, improving network latency while not affecting the storage I/O throughput noticably.

### Fig 8b
Reducing the FIO ways reduces DMA bloat. X-Mem LLC miss rate decrease while Storage I/O throughput remains.

### HPW-heavy / LPW-heavy
HPW performance increases by ~50%, without compromising that of LPWs. Systemwide performance is also improved.