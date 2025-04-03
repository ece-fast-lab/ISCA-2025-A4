# ISCA-2025-A4 Benchmark Suite

This repository contains a collection of benchmarks for ISCA-2025-A4.

## Directory Structure

### configs/
This directory contains benchmark configuration files for each application. These files define the parameters and settings used when running the benchmarks.

Set the network PCIE port in `smartllc_lat.click` and `smartllc_nolat.click` properly. (match with the `$SERVER_NIC_PCIE` defined in `../scripts/utils/env.sh`)

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

X-Mem internally designates the core affinity.
We pre-compiled X-Mem with different core afiinities under `X-Mem_bin`. postfix c{i} indicates that the core affinity starts with ith core, where default is 0.
Install them before you run the experiments

```bash
cd X-Mem_bin
sudo mv * /usr/local/bin/
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
Follow this redis installation guide on Lonux: https://redis.io/docs/latest/operate/oss_and_stack/install/install-redis/install-redis-from-source/

### YCSB
```bash
git clone https://github.com/brianfrankcooper/YCSB
cd YCSB
mvn -pl site.ycsb:redis-binding -am clean package
```
YCSB should be located under this directory (`app/YCSB`)

### SPEC 2017
Install SPEC CPU 2017 bench under this directory (`app/cpu2017`).

Follow this official guide: https://www.spec.org/cpu2017/Docs/quick-start.html
