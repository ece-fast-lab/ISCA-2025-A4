#!/bin/bash

name=$1
fio_path="/home/hnpark2/ddio/bench/fio"
cd $fio_path
make clean
./configure
make
sudo make install
sudo rm $name
sudo cp fio $name
