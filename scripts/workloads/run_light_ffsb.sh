#! /bin/bash

cpu_list=$1
config=$BASE_PATH"/app/configs/light_ffsb"

#lsblk -f
sudo umount /mnt/light_ffsb
sudo wipefs -a /dev/nvme3n1
sudo mkfs.xfs -d agcount=512 -l size=512m /dev/nvme3n1
# sudo mkfs.ext4 -E lazy_itable_init=1,lazy_journal_init=1 -F /dev/nvme4n1
sudo mount /dev/nvme3n1 /mnt/light_ffsb
sudo taskset -c $cpu_list ffsb $config


