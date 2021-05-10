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

if [ ! -d $TARGET_ROOTFS_DIR ] ; then
    sudo mkdir -p $TARGET_ROOTFS_DIR
fi

if [ ! -d ${MOUNTPOINT} ]; then
    sudo mkdir -p $MOUNTPOINT
fi

if [ ! -d ${BASEPACKAGES} ]; then
    sudo mkdir -p $BASEPACKAGES
fi

if [ -e $ROOTFSIMAGE ]; then
        sudo rm -rf $ROOTFSIMAGE
fi

if [ ! -e AnolisOS-8.2-RC2-aarch64-dvd.iso ]; then
	echo "\033[36m wget AnolisOS-8.2-RC2-aarch64-dvd.iso \033[0m"
	wget -c http://mirrors.openanolis.org/anolis/8.2/isos/RC2/aarch64/AnolisOS-8.2-RC2-aarch64-dvd.iso
fi

if [ -e AnolisOS-8.2-RC2-aarch64-dvd.iso ]; then
	echo "\033[36m nmount AnolisOS-8.2-RC2-aarch64-dvd.iso \033[0m"
	sudo mount -o loop AnolisOS-8.2-RC2-aarch64-dvd.iso ${MOUNTPOINT}/
	sudo cp $MOUNTPOINT/images/install.img install.img
	sudo cp $MOUNTPOINT/BaseOS/Packages/anolis-release-8.2-7.an8.aarch64.rpm ${BASEPACKAGES}/
	sudo cp $MOUNTPOINT/BaseOS/Packages/anolis-repos-8.2-7.an8.aarch64.rpm ${BASEPACKAGES}/
	sudo cp $MOUNTPOINT/BaseOS/Packages/yum-4.2.17-6.0.1.an8.noarch.rpm ${BASEPACKAGES}/
	sudo cp $MOUNTPOINT/BaseOS/Packages/yum-utils-4.0.12-3.el8.noarch.rpm ${BASEPACKAGES}/

	sync
	sudo umount ${MOUNTPOINT}/

	sudo mount install.img ${MOUNTPOINT}/
	sudo cp $MOUNTPOINT/LiveOS/rootfs.img rootfs.img
	sync
	sudo umount $MOUNTPOINT || true
	sudo rm install.img
fi

# Create directories
dd if=/dev/zero of=${ROOTFSIMAGE} bs=1M count=0 seek=8000
sudo mount rootfs.img $TARGET_ROOTFS_DIR

finish() {
    sudo umount ${MOUNTPOINT} || true
    echo -e "error exit"
    exit -1
}

echo Format rootfs to ext4
mkfs.ext4 ${ROOTFSIMAGE}

echo Mount rootfs to ${MOUNTPOINT}
sudo mount ${ROOTFSIMAGE} ${MOUNTPOINT}

trap finish ERR

echo Copy rootfs to ${MOUNTPOINT}
sudo cp -rfp ${TARGET_ROOTFS_DIR}/*  ${MOUNTPOINT}

# packages folder
sudo mkdir -p $MOUNTPOINT/packages
sudo cp -rf packages/$ARCH/* $MOUNTPOINT/packages

# overlay folder
sudo cp -rf overlay/* ${MOUNTPOINT}/
sudo cp -rf overlay-firmware/* ${MOUNTPOINT}/

# bt/wifi firmware
if [ "$ARCH" == "armhf" ]; then
    sudo cp -f overlay-firmware/usr/bin/brcm_patchram_plus1_32 $MOUNTPOINT/usr/bin/brcm_patchram_plus1
    sudo cp -f overlay-firmware/usr/bin/rk_wifi_init_32 $MOUNTPOINT/usr/bin/rk_wifi_init
elif [ "$ARCH" == "arm64" ]; then
    sudo cp -f overlay-firmware/usr/bin/brcm_patchram_plus1_64 $MOUNTPOINT/usr/bin/brcm_patchram_plus1
    sudo cp -f overlay-firmware/usr/bin/rk_wifi_init_64 $MOUNTPOINT/usr/bin/rk_wifi_init
fi
sudo mkdir -p $MOUNTPOINT/system/lib/modules/
sudo find overlay-firmware/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} $MOUNTPOINT/system/lib/modules/

# rm default target
if [ -e ${MOUNTPOINT/etc/systemd/system/default.target} ]; then
sudo rm ${MOUNTPOINT}/etc/systemd/system/default.target
fi


if [ ! -e ${MOUNTPOINT/etc/systemd/system/default.target} ]; then
cd ${MOUNTPOINT}
ln -s usr/lib/systemd/system/multi-user.target etc/systemd/system/default.target
cd -
fi

echo Umount rootfs
sudo umount ${TARGET_ROOTFS_DIR}
sudo umount ${MOUNTPOINT}

sudo rm rootfs.img

echo Rootfs Image: ${ROOTFSIMAGE}

sudo mount $ROOTFSIMAGE ${TARGET_ROOTFS_DIR}

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
        sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
        sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi

sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR
chmod +x /etc/rc.local

### make yum working
rpm2cpio /packages/base/anolis-release-8.2-7.an8.aarch64.rpm|cpio -idumv
rpm2cpio /packages/base/anolis-repos-8.2-7.an8.aarch64.rpm|cpio -idumv
rpm2cpio /packages/base/yum-4.2.17-6.0.1.an8.noarch.rpm|cpio -idumv
rpm2cpio /packages/base/yum-utils-4.0.12-3.el8.noarch.rpm|cpio -idumv

sed -i 's/\$releasever/8/g' /etc/yum.repos.d/AnolisOS-*
sync


EOF
sudo umount $TARGET_ROOTFS_DIR/dev
sudo umount ${TARGET_ROOTFS_DIR}
