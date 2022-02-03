#!/bin/sh
#
# Creates a test .img file with 2 partitions and FAT32/EXT4 filesystems for resizing.
#
# mkfs.fat -f 32
#

# default image name and size
VOLUME=basic.img
SIZE=4G
#
if [ ! -z $1 ]
then
    VOLUME=$1
fi
if [ ! -z $2 ]
then
    SIZE=$2
fi
# if the file already exists, prompt.
if [ -e $VOLUME ]
then
    read -p "Overwrite existing $VOLUME ($SIZE)? Y/N " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y(es) or N(o).";;
    esac
    #
    rm -f $VOLUME
fi
fallocate -l $SIZE $VOLUME
# drive parted ...
sudo parted << EOT
select $VOLUME
mklabel msdos
mkpart primary fat32 1049kB 538MB
mkpart primary ext4 538MB 100%
quit
EOT

# create file systems as per Ubuntu 18+
LOOP=`losetup -f`
# echo "Loop is $LOOP"
sudo losetup -P $LOOP $VOLUME
# UEFI is FAT32 hence
sudo mkfs.fat -F 32 $LOOP"p1"
# mail Linux file system
sudo mkfs.ext4 $LOOP"p2"
# tear down loop
sudo losetup -d $LOOP
# show disk image data
fdisk -l $VOLUME

