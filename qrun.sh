#!/bin/sh
#
# quickly run a .img file using QEMU.
#
# ./qrun.sh bionic.img
#

# amount of guest OS RAM
RAM=2G
# QEMU MAC
MAC=52:55:00:d1:55:02
# default image name
VOLUME=test.img
# check for .IMG override
if [ ! -z $1 ]
then
    VOLUME=$1
fi
# just run it ...
qemu-system-aarch64 -nographic -no-reboot -machine virt,gic-version=max -m $RAM -cpu max -smp 4 \
-netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no \
-device e1000,netdev=mynet0,mac=$MAC \
-drive file=$VOLUME,format=raw,if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
-drive file=flash-0.img,format=raw,if=pflash \
-drive file=flash-1.img,format=raw,if=pflash 
