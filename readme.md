## Introduction

A set of shell scripts that will build GNU/Linux distribution rootfs image
for rockchip platform.

## Available Distro

* Anolis 8.2 (X11 and Wayland)~~

```
sudo apt-get install binfmt-support qemu-user-static
sudo dpkg -i ubuntu-build-service/packages/*
sudo apt-get install -f
```

## Usage for 64bit Centos

Building a base Anolis system.

```
	ARCH=arm64 ./mk-base-anolis.sh
```

Building the rk-centos rootfs:

```
	ARCH=arm64 ./mk-rootfs-anolis.sh
```

Creating the ext4 image(linaro-rootfs.img):

```
	./mk-image.sh
```

---

