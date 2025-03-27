#! /bin/bash

echo "ps101899" | sudo -S kill -INT $(pgrep dpdk-tx)

