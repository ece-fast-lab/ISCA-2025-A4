# Client Setup Instructions

This document provides instructions for setting up the client machine for testing.

## Prerequisites

- Make sure environment variables are set up correctly by running:
  ```bash
  source ../scripts/utils/env.sh
  ```
- Copy SSD ID to bypass password from nowon (for both root and user):
  ```bash
  ssh-copy-id $CLIENT_ACCOUNT@$CLIENT_IP
  sudo ssh-copy-id $CLIENT_ACCOUNT@$CLIENT_IP
  ```

## Setup Steps

1. Copy the DPDK application package to the client machine:
   ```bash
   scp ./dpdk-tx.tar $CLIENT_ACCOUNT@$CLIENT_IP:~/
   ```

2. SSH into the client machine:
   ```bash
   ssh $CLIENT_ACCOUNT@$CLIENT_IP
   ```

3. Extract the DPDK package:
   ```bash
   tar -xf dpdk-tx.tar
   ```

4. Compile the DPDK applications:
   ```bash
   cd dpdk-framework/dpdk-tx/
   make
   cd ../../dpdk-lat/dpdk-tx/
   make
   ```

5. Run the basic setup script:
   ```bash
   cd ../../
   sudo ./setup_basic.sh
   ```
   This script configures the system for DPDK, including setting up huge pages and binding network interfaces.

## Verification

After setup, verify that the applications compiled correctly and the network interfaces are properly bound to DPDK-compatible drivers.
