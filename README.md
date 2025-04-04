# ISCA-2025-A4

[![DOI](https://zenodo.org/badge/955433674.svg)](https://doi.org/10.5281/zenodo.15105163)

## Evaluation Flow

### Setup
1. Download and install all benchmarks as described in the `README.md` under `app` directory

   a. After this step, you should be able to find commands: `fio`, `ffsb`, `xmem`, `xmem_c4`, `xmem_c11`, `xmem_c14`, `click`, `redis-server`, and `dpdk-rx`.
   
   b. Some application folders should be located under the `app` directory. **(`YCSB` and `cpu2017`)**
3. Download and install all tools as described in the `README.md` under `tools` directory

   a. **`pcm`** should be located under the `tools` directory. 
5. Navigate to the `client` directory to set up the client machine

### Pre-experiment Setup
Before starting experiments, after each reboot, and every new terminal:
1. Navigate to `scripts/utils`
2. On server machine, run:
   ```bash
   source ./env.sh
   sudo ./init.sh
   ```
3. On client machine, run:
   ```bash
   setup_basic.sh
   ```

### Viewing Results

Results are generated by Python3 scripts. You can find gerenated png file (`Fig{i}.png`) and raw data text file (`results.txt`) under `results/Fig{i}/`.

Install python dependencies before running the experiments.

```bash
python3 -m pip3 install matplotlib numpy pandas
```

### Running Experiments
Navigate to the `script` directory and select the desired experiment to run.

