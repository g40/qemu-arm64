#!/bin/sh
#
# tested on Ubuntu 20.04.3 LTS
#
# requires 
#
#

# modify to suit local conditions
if [ $# -eq 1 ]
then
    ADAPTER=$1
else
    ADAPTER=ens33
fi
echo "Removing bridge from $ADAPTER"

sudo ip link set tap0 nomaster
sudo ip tuntap del tap0 mode tap
sudo ip link set $ADAPTER nomaster
sudo ip link set down dev br0
sudo ip link del br0
sudo ip link set up dev $ADAPTER
sudo dhclient -v $ADAPTER

# done
sudo -k


