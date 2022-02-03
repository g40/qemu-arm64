#!/bin/sh
#
# ./rs.sh 2>&1 | tee rs.log
#
# safely resize partition 2 in an .IMG file/ext4 filesystem
#
# requires:
#
# sudo apt install e2fsprogs qemu-utils cloud-guest-utils

# default image name and size
VOLUME=bionic.img
SIZE=8G
#
if [ ! -z $1 ]
then
    VOLUME=$1
fi
if [ ! -z $2 ]
then
    SIZE=$2
fi
#
if [ ! -f $VOLUME ]
then
    echo "$VOLUME does not exist"
    exit
fi
#
echo "Resizing $VOLUME to $SIZE"
# resize using qemu tools
qemu-img resize -f raw $VOLUME $SIZE
# get first free index
LOOP=`losetup -f`
# echo "Loop is $LOOP\n"
# set up a loop device using index and backing volume
sudo losetup -P $LOOP $VOLUME
# this handles GPT warning left by qemu-img
sudo partprobe -s $LOOP
# disk partition number
sudo growpart $LOOP 2
# check ext4 filesystem
sudo e2fsck -f $LOOP"p2"
# resize to fit available space
sudo resize2fs $LOOP"p2"
# tear down loop device
sudo losetup -d $LOOP
# check full image once more
fdisk -l $VOLUME
