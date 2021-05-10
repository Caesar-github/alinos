#!/bin/bash -e

TARGET_ROOTFS_DIR="binary"
MOUNTPOINT=./rootfs
ROOTFSIMAGE=anolis-rootfs.img
BASEPACKAGES=packages/arm64/base

if [ "$ARCH" == "armhf" ]; then
        ARCH='armhf'
elif [ "$ARCH" == "arm64" ]; then
        ARCH='arm64'
else
    echo -e "\033[36m please input is: armhf or arm64...... \033[0m"
fi

finish() {
	sudo umount $TARGET_ROOTFS_DIR/dev
	exit -1
}
trap finish ERR

sudo mount $ROOTFSIMAGE ${TARGET_ROOTFS_DIR}

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

yum update

### install network tools
yum install -y sudo passwd openssh telnet net-tools openssh-server

### install display server
#yum groupinstall "X Window System" -y
#yum groupinstall "GNOME Desktop" -y
yum groupinstall "Server with GUI" -y

EOF

# overlay folder
sudo cp -rf overlay/usr/lib/systemd/system/* ${TARGET_ROOTFS_DIR}/usr/lib/systemd/system/

sudo umount $TARGET_ROOTFS_DIR/dev
