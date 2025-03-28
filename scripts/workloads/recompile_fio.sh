#!/bin/bash

name=$1

cd $BASE_PATH"/app/fio"
make clean
./configure
make
sudo make install
sudo rm $name
sudo cp fio $name
