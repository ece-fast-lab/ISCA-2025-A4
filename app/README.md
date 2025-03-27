# ISCA-2025-A4 Benchmark Suite

This repository contains a collection of benchmarks for ISCA-2025-A4.

## Directory Structure

### configs/
This directory contains benchmark configuration files for each application. These files define the parameters and settings used when running the benchmarks.

## Installation

The following instructions will guide you through installing all benchmarks and dependencies.

### FIO (Flexible I/O Tester)

We modified FIO to make CPU cores to touch (read) the I/O data read from SSDs.

```bash
git clone https://github.com/skyp0714/fio.git
cd fio
./configure
make
sudo make install
cd ../
```

### FFSB (Flexible File System Benchmark)

We extended FFSB to support latency report.

```bash
git clone https://github.com/skyp0714/ffsb.git
cd ffsb
./configure
make
sudo make install
cd ../
```

### X-Mem (eXtensible Memory Characterization Tool)
Use Python 2.7 and Scons 2.3.0 for building X-Mem

```bash
git clone https://github.com/microsoft/X-Mem
cd X-Mem
./build-linux.sh x64_avx 16
sudo cp bin/xmem-linux-x64_avx /usr/local/bin/xmem
cd ../
```

### Fastclick

```bash
git clone https://github.com/GarboLou/fastclick.git
cd fastclick
git checkout origin/isca-25-a4
./configure --enable-multithread --disable-linuxmodule --enable-intel-cpu --enable-user-multithread --verbose CFLAGS="-g -O3" CXXFLAGS="-g -std=gnu++11 -O3" --disable-dynamic-linking --enable-poll --enable-bound-port-transfer --enable-dpdk --enable-batch --with-netmap=no --enable-zerocopy --disable-dpdk-pool --disable-dpdk-packet --enable-user-timestamp
make
sudo make install
cd ../
```

### Redis
Follow this redis installation guide on Lonux: https://redis.io/docs/latest/operate/oss_and_stack/install/install-redis/install-redis-on-linux/

### YCSB
```bash
git clone https://github.com/brianfrankcooper/YCSB
```