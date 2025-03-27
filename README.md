# ISCA-2025-A4

## Evaluation Flow

### Setup
1. Download all benchmarks as described in the `README.md` under `app` directory
2. Download all tools as described in the `README.md` under `tools` directory
3. Navigate to the `client` directory to set up the client machine

### Pre-experiment Setup
Before starting experiments and after each reboot:
1. Navigate to `scripts/utils`
2. Run environment setup:
   ```bash
   source env.sh
   sudo init.sh
   ```
3. On client machine, run:
   ```bash
   setup_basic.sh
   ```

### Running Experiments
Navigate to the `script` directory and select the desired experiment to run.
