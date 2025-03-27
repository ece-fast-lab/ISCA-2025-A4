# ISCA-2025-A4 Software Tools

This document provides installation and usage instructions for the tools required by ISCA-2025-A4.

## PCM (Processor Counter Monitor)

PCM provides processor monitoring capabilities for Intel CPUs. We've modified PCM to report more detailed L2 and L3 cache hit/miss metrics.

### Installation

```bash
git clone --recursive https://github.com/skyp0714/pcm
cd pcm
git submodule update --init --recursive
mkdir build
cd build
cmake ..
cmake --build .
sudo cp build/bin/pcm* /usr/local/bin/
```

**Important Note**: PCM must be installed under the tools directory. Some binaries, such as `pcm-iio`, need to be run from their directory.

## CAT (Cache Allocation Technology)

CAT is part of Intel's Resource Director Technology (RDT).

### Installation

1. Visit the [Intel CMT-CAT repository](https://github.com/intel/intel-cmt-cat)
2. Follow the installation guides to install pqos

### System Configuration

Our server machine requires specific GRUB command line parameters:
```
rdt=cmt,mbmtotal,mbmlocal,l3cat,l3cdp,mba
```

## DDIO-bench

DDIO-bench is a tool for enabling or disabling Data Direct I/O on specific PCIe devices.

### Installation

You can build the binaries from the [DDIO-bench repository](https://github.com/aliireza/ddio-bench).

Build the following binaries in `dca_control` directory by setting appropriate parameters:
- `network_enable`
- `network_disable`
- `storage_disable`
- `storage_enable`

### Pre-built Binaries

We provide pre-built binaries configured for:
- One network device using PCIe bus 0x17
- Four storage devices using PCIe bus 0x25
- Three storage devices using PCIe bus 0x25
