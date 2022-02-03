
    QEMU: Run a networked Ubuntu ARM64 guest on a Ubuntu x64 host

    
#### TL;DR

First time use:

```
# add current user to netdev group
sudo usermod -a -G netdev `whoami`
# add udev rule for access to bridged adapter
sudo cp 10-qemu.rules /etc/udev/rules.d
# set up networking for QEMU
sudo ./bradd.sh
# installs Ubuntu bionic to guest
./qemu-arm64.sh
```

After first time use:
```
# runs existing Ubuntu bionic in guest
./qemu-arm64.sh
```


#### Getting started

Add udev rules and user to netdev group so we can run tap mode QEMU w/o sudo rights. This is a one-time operation.

```
# add user to netdev group
sudo usermod -a -G netdev <username>
# add udev rule for access to bridged adapter
sudo cp 10-qemu.rules /etc/udev/rules.d
#
```

#### Network tap.

The QEMU set up requires a bridged network adapter is accessible and working for full Internet access.

Use `bradd.sh` to set up bridge and tap devices and `brdel.sh` to tear down. These scripts do require (once-off) sudo access. 

Check on the host:

```
$ ls -alsh /sys/devices/virtual/net/
total 0
0 drwxr-xr-x  7 root root 0 Jan 29 23:41 .
0 drwxr-xr-x 20 root root 0 Jan 29 23:41 ..
0 drwxr-xr-x  7 root root 0 Jan 30 00:03 br0
0 drwxr-xr-x  5 root root 0 Jan 29 23:41 lo
0 drwxr-xr-x  6 root root 0 Jan 30 00:03 tap0
```

#### Initial Ubuntu Arm64 setup

Simply run `./qemu-arm64.sh` in a shell. This will download the seed installation .ISO and kick off the process. 


#### Upgrading

This is done inside the QEMU guest. So after 18.04 installation is complete continue by
ensuring the image contains the most up to date components, then do a release upgrade.

This will enable stepping up through 18.04 -> 20.04 -> 21.10.

```
sudo apt update
sudo apt upgrade
do-release-upgrade -f DistUpgradeViewNonInteractive
```

Once 20.04 is running you will need to modify release-upgrades as per

`sudo nano /etc/update-manager/release-upgrades`

changing `Prompt=lts` to `Prompt=normal`

If interrupted `sudo dpkg --configure -a`

#### Timeouts

When running QEMU on slower processors (ancient gen 3 Intel i5 for example), systemd timeouts start to appear during boot. This seems to apply to 1) /boot/efi disk and 2) default login TTY.

Fix for 1) is to add the `x-systemd.device-timeout=300s` option as shown below

```
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/vda2 during installation
UUID=e745426a-d9e3-4439-8bdb-bcdf6268526d /               ext4    errors=remount-ro 0       1
# /boot/efi was on /dev/vda1 during installation
UUID=8932-A045  /boot/efi       vfat    umask=0077,x-systemd.device-timeout=300s      0       1
/swapfile                                 none            swap    sw              0       0
```

#### Need for SSH access

This is a hack fix for 2) above. 

```
[ TIME ] Timed out waiting for device /dev/ttyAMA0.
[DEPEND] Dependency failed for Serial Getty on ttyAMA0.
...
```
means no direct terminal access to QEMU guest. 

So access via SSH and run `sudo systemctl start serial-getty@ttyAMA0.service` to get console login.

TBC:

`systemctl show getty@tty1.service | grep ^Timeout`

`systemctl status serial-getty@ttyAMA0.service`


#### Resizing an .IMG file

Use the included `rs.sh` script. 

Usage:

`./rs.sh basic.img 8G`

which will 

```
$/rs.sh basic.img 8G
Resizing basic.img to 8G
Image resized.
/dev/loop14: msdos partitions 1 2
CHANGED: partition=2 start=1050624 old: size=11532288 end=12582912 new: size=15726559 end=16777183
e2fsck 1.45.5 (07-Jan-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/loop14p2: 11/360448 files (0.0% non-contiguous), 44646/1441536 blocks
resize2fs 1.45.5 (07-Jan-2020)
Resizing the filesystem on /dev/loop14p2 to 1965819 (4k) blocks.
The filesystem on /dev/loop14p2 is now 1965819 (4k) blocks long.

Disk basic.img: 8 GiB, 8589934592 bytes, 16777216 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x4248edf7

Device     Boot   Start      End  Sectors  Size Id Type
basic.img1         2048  1050623  1048576  512M  c W95 FAT32 (LBA)
basic.img2      1050624 16777182 15726559  7.5G 83 Linux
```

The `mi.sh` (make image) in the repo will create a 2 partition .IMG file to a specified size for testing etc. using the resize script.

#### Collaboration:

Comments, questions, and pull requests welcomed.


#### GIT:

`git config credential.helper store`

#### Burps observed

Ubuntu 21.10

```
BdsDxe: loading Boot0005 "ubuntu" from HD(1,GPT,D2B66078-EE65-4E9F-B4D9-5077FB8C1902,0x800,0x100000)/\EFI\ubuntu\grubaa64.efi
BdsDxe: starting Boot0005 "ubuntu" from HD(1,GPT,D2B66078-EE65-4E9F-B4D9-5077FB8C1902,0x800,0x100000)/\EFI\ubuntu\grubaa64.efi
error: no suitable video mode found.
EFI stub: ERROR: FIRMWARE BUG: kernel image not aligned on 64k boundary
EFI stub: ERROR: FIRMWARE BUG: Image BSS overlaps adjacent EFI memory region
```

```
Configuration file '/etc/update-manager/release-upgrades'
 ==> Modified (by you or by a script) since installation.
 ==> Package distributor has shipped an updated version.
   What would you like to do about it ?  Your options are:
    Y or I  : install the package maintainer's version
    N or O  : keep your currently-installed version
      D     : show the differences between the versions
      Z     : start a shell to examine the situation
 The default action is to keep your current version.
*** release-upgrades (Y/I/N/O/D/Z) [default=N] ? n
Setting up update-manager-core (1:21.10.5) ...
Setting up language-pack-gnome-en (1:21.10+20211008) ...
Setting up language-pack-en-base (1:21.10+20211008) ...
Generating locales (this might take a while)...
Generation complete.
Setting up language-pack-gnome-en-base (1:21.10+20211008) ...
Processing triggers for install-info (6.7.0.dfsg.2-6) ...
Processing triggers for libc-bin (2.34-0ubuntu3) ...
Processing triggers for dictionaries-common (1.28.4) ...
Processing triggers for ca-certificates (20210119ubuntu1) ...
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
Processing triggers for initramfs-tools (0.140ubuntu6) ...
update-initramfs: Generating /boot/initrd.img-5.4.0-96-generic
dpkg: error: dpkg database lock was locked by another process with pid 15240
Note: removing the lock file is always wrong, and can end up damaging the
locked area and the entire system. See <https://wiki.debian.org/Teams/Dpkg/FAQ>.
```

```
Setting up python3 (3.9.4-1build1) ...
running python rtupdate hooks for python3.9...
running python post-rtupdate hooks for python3.9...
Setting up python3-six (1.16.0-2) ...
Setting up python3-certifi (2020.6.20-1) ...
Setting up python3-gi (3.40.1-1build1) ...
Setting up python3-idna (2.10-1) ...
Setting up python3-urllib3 (1.26.5-1~exp1) ...
Setting up python3-netifaces (0.10.9-0.2) ...
Setting up gnupg (2.2.20-1ubuntu4) ...
Setting up bind9-dnsutils (1:9.16.15-1ubuntu1.1) ...
Setting up lsb-release (11.1.0ubuntu3) ...
Setting up python3-distro-info (1.0) ...
Setting up python3-pkg-resources (52.0.0-4) ...
Setting up python3-dbus (1.2.16-5) ...
Setting up grub-efi-arm64 (2.04-1ubuntu47) ...
Unknown device "/dev/disk/by-id/*": No such file or directory
Installing grub to /boot/efi.
Installing for arm64-efi platform.
Installation finished. No error reported.
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
```
