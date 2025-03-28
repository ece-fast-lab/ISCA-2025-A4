#! /bin/bash

cpu_list=$1
bs_cf=$2

config=$BASE_PATH"/app/configs/$bs_cf"

#lsblk -f
sudo umount /mnt/ffsb_test
sudo wipefs -a /dev/md127
sudo mkfs.xfs /dev/md127
# sudo mkfs.ext4 -E lazy_itable_init=1,lazy_journal_init=1 -F /dev/md127
sudo mount /dev/md127 /mnt/ffsb_test
sudo taskset -c $cpu_list ffsb $config


