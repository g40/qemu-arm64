#!/bin/sh
#
# tested on Ubuntu 20.04.3 LTS
#
#

# modify to suit local conditions
# modify to suit local conditions
if [ $# -eq 1 ]
then
    ADAPTER=$1
else
    ADAPTER=ens33
fi
echo "Bridging $ADAPTER"

#------------------------------------------------------------------------
sudo ip link add name br0 type bridge
sudo ip addr flush dev $ADAPTER
sudo ip link set $ADAPTER master br0
# _should_ (!) remove need to run qemu under sudo
# sudo ip tuntap add dev tap0 mode tap user `whoami` group netdev
# it's the group that is important. make sure to have addded udev rule.
sudo ip tuntap add dev tap0 mode tap group netdev
sudo ip link set tap0 master br0
sudo ip link set up dev $ADAPTER
sudo ip link set up dev tap0
sudo ip link set up dev br0
sudo dhclient -v br0
ls -alsh /sys/devices/virtual/net/

# done ...
sudo -k

