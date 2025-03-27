#! /bin/bash

cpu_list=$1
config="/home/hnpark2/bench/ffsb-workloads/configs/heavy_ffsb"

# RAID option
# #lsblk -f
sudo umount /mnt/heavy_ffsb
sudo wipefs -a /dev/md127

# sudo mdadm --stop /dev/md127
# sudo mdadm --zero-superblock /dev/nvme{0,2,3}n1
# sudo mdadm --create /dev/md127 --level=0 --raid-devices=3 /dev/nvme{0,2,3}n1

sudo mkfs.xfs -d agcount=512 -l size=512m /dev/md127
sudo mount /dev/md127 /mnt/heavy_ffsb
sudo taskset -c $cpu_list /home/hnpark2/bench/ffsb-workloads/ffsb/ffsb $config

# noraid option
# sudo umount /mnt/heavy_ffsb0
# sudo wipefs -a /dev/nvme0n1
# sudo mkfs.xfs -d agcount=512 -l size=512m /dev/nvme0n1
# # sudo mkfs.ext4 -E lazy_itable_init=1,lazy_journal_init=1 -F /dev/nvme4n1
# sudo mount /dev/nvme0n1 /mnt/heavy_ffsb0

# sudo taskset -c 4 /home/hnpark2/bench/ffsb-workloads/ffsb/ffsb $config"0"

# sudo umount /mnt/heavy_ffsb1
# sudo wipefs -a /dev/nvme2n1
# sudo mkfs.xfs -d agcount=512 -l size=512m /dev/nvme2n1
# # sudo mkfs.ext4 -E lazy_itable_init=1,lazy_journal_init=1 -F /dev/nvme4n1
# sudo mount /dev/nvme2n1 /mnt/heavy_ffsb1

# sudo taskset -c 5 /home/hnpark2/bench/ffsb-workloads/ffsb/ffsb $config"1"

# sudo umount /mnt/heavy_ffsb2
# sudo wipefs -a /dev/nvme3n1
# sudo mkfs.xfs -d agcount=512 -l size=512m /dev/nvme3n1
# # sudo mkfs.ext4 -E lazy_itable_init=1,lazy_journal_init=1 -F /dev/nvme4n1
# sudo mount /dev/nvme3n1 /mnt/heavy_ffsb2

# sudo taskset -c 6 /home/hnpark2/bench/ffsb-workloads/ffsb/ffsb $config"2"

