#!/bin/sh
# Ctrl+A, X to exit QEMU
#
# ./qemu-arm64 <.img filename> <disk size i.e. 6G>
#
# i.e 18.04
DISTRO=bionic
# amount of guest OS RAM
RAM=2G
# size of guest OS disk
SIZE=6G
# QEMU MAC
MAC=52:55:00:d1:55:02
# bridged adapter name
# modify to suit local conditions
ADAPTER=ens33

# check for distro override
if [ ! -z $1 ]
then
    DISTRO=$1
fi
# check for size overide
if [ ! -z $2 ]
then
    SIZE=$2
fi
# preamble - make sure qemu stuff is on board
if [ ! -e /usr/bin/qemu-system-aarch64 ]
then
    sudo apt-get install qemu-system-arm
    sudo apt-get install qemu-efi-aarch64
    sudo apt-get install qemu-utils
    #  obsolete with ip
    # sudo apt install bridge-utils ifupdown uml-utilities net-tools
    sudo -k
fi

# grab a Ubuntu net install image
if [ ! -e mini.iso ]
then
    wget http://ports.ubuntu.com/ubuntu-ports/dists/$DISTRO-updates/main/installer-arm64/current/images/netboot/mini.iso
fi

# check for the image file into which we will install Ubuntu.
if [ ! -e $DISTRO.img ]
then
    #
    read -p "Continue installing $DISTRO.img? Y/N " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y(es) or N(o).";;
    esac
    # set up the UEFI boot helper
    dd if=/dev/zero of=flash-1.img bs=1M count=64
    dd if=/dev/zero of=flash-0.img bs=1M count=64
    dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=flash-0.img conv=notrunc
    # create the filesystem .img
    qemu-img create $DISTRO.img $SIZE
    
    # install from .iso file. 
    qemu-system-aarch64 -nographic -no-reboot -machine virt,gic-version=max -m $RAM -cpu max -smp 4 \
    # -D ./$DISTRO.log \
    -netdev tap,id=tap0,ifname=tap0,script=no,downscript=no \
    -device e1000,netdev=tap0,mac=$MAC \
    -drive file=$DISTRO.img,format=raw,if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
    -drive file=mini.iso,format=raw,if=none,id=drive1,cache=writeback -device virtio-blk,drive=drive1,bootindex=1 \
    -drive file=flash-0.img,format=raw,if=pflash \
    -drive file=flash-1.img,format=raw,if=pflash 
else
    # just run it ...
    qemu-system-aarch64 -nographic -no-reboot -machine virt,gic-version=max -m $RAM -cpu max -smp 4 \
    # -D ./$DISTRO.log \
    -netdev tap,id=mynet0,ifname=tap0,script=no,downscript=no \
    -device e1000,netdev=mynet0,mac=$MAC \
    -drive file=$DISTRO.img,format=raw,if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
    -drive file=flash-0.img,format=raw,if=pflash \
    -drive file=flash-1.img,format=raw,if=pflash 
    #-------------------------------------------------
    RETCODE=$?
    # echo "QEMU exit code $RETCODE\n"
    #-------------------------------------------------
    if [ $RETCODE -eq 0 ]; then
        read -p "Backup $DISTRO.img? Y/N " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer Y(es) or N(o).";;
        esac
        cp $DISTRO.img $DISTRO.img.bak
    fi
fi
