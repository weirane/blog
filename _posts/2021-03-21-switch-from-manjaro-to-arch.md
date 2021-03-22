---
title: 从 Manjaro 迁移到 Arch Linux
description: Switch from Manjaro to Arch Linux with LUKS and Btrfs
category: Tweaks
tags: archlinux btrfs luks swap xbacklight
redirect_from: /r/9
---

今天我把系统换成了 Arch Linux，用的是 Btrfs 文件系统，套上 LUKS 加密（加密包括
`/boot`）。由于我已经在虚拟机里面实验过整个过程，所以今天的安装过程非常顺利，一
共只用了一两个小时。

## 背景

前几天用 `btrfs-convert` 把我的 Manjaro 的文件系统换成了 Btrfs，然后继续开发我的
Btrfs 快照管理工具 [dosnap][]。奇怪的是，在出错的时候（如 `panic!`）程序不会退出
，而是直接卡住。这还不是最致命的，过了几秒钟我发现我的 polybar 不见了，然后发现
我的家目录里少了一些东西，包括 `~/.config`。还好我之前有做快照，可以直接用
`rsync` 恢复数据。但是在我的一个 Arch Linux 虚拟机中程序如果出错会正确退出。不知
道是为什么，可能是 `btrfs-convert` 的什么 bug。然后就想到用 Arch 虚拟机也有很长
时间了，于是打算直接把物理机也换到 Arch Linux 上来。

[dosnap]: https://github.com/weirane/dosnap/

## 备份

可以使用 Btrfs 的 send/receive 功能进行备份。注意备份的移动硬盘也需要是 Btrfs 文
件系统。先对各个子卷做只读快照，然后对每个快照进行 `btrfs send`：

```sh
sudo btrfs send /mnt/_snapshots/${SNAPSHOT_NAME?} | sudo btrfs receive ${EXTERNAL_DRIVE?}
```

然后再记录一下安装过的软件：
```sh
pacman -Qe >${EXTERNAL_DRIVE?}/pacman-qe
```

## 安装

启动 archiso，然后调整一下终端字体
```sh
setfont ter-v28b
```

### Installation Guide

打开 [installation guide][arch-ig]，一直做到 Partition the disks 之前。

由于磁盘已经分区，所以不需要再分区了。直接上 LUKS 并格式化为 Btrfs。注意需要用
luks1，因为 GRUB 目前还不支持 LUKS2。
```sh
cryptsetup --type luks1 luksFormat /dev/nvme0n1p4
cryptsetup open /dev/nvme0n1p4 archlinux
mkfs.btrfs -L archlinux /dev/mapper/archlinux
```

然后创建子卷并挂载分区
```sh
mount /dev/mapper/archlinux /mnt
btrfs subv create /mnt/@
btrfs subv create /mnt/@home
btrfs subv create /mnt/@opt
btrfs subv create /mnt/@var
umount /mnt

opt='noatime,ssd,space_cache=v2,compress=zstd'
mount -o $opt,subvol=@ /dev/mapper/archlinux /mnt
mkdir /mnt/{efi,var,home,opt}
mount /dev/nvme0n1p1 /mnt/efi
mount -o $opt,subvol=@home /dev/mapper/archlinux /mnt/home
mount -o $opt,subvol=@opt /dev/mapper/archlinux /mnt/opt
mount -o $opt,subvol=@var /dev/mapper/archlinux /mnt/var
```

对 `/var/log/journal` 禁用 CoW：
```sh
mkdir -p /mnt/var/log/journal
chattr +C /mnt/var/log/journal
```

然后从 installation guide 的 [Installation][ig-inst] 一节开始继续一直做到结尾，
记得要在 `pacstrap` 的时候加上 `btrfs-progs`。

[ig-inst]: https://wiki.archlinux.org/index.php/installation_guide#Installation

### 额外的操作

安装到这里还需一些额外的操作。更改 `/etc/mkinitcpio.conf` 的 `BINARIES`，然后在
`HOOKS` 中的 `filesystems` 之前加入 `encrypt`：
```bash
BINARIES=(/usr/bin/btrfs)
HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)
```
然后重新生成 initramfs
```sh
mkinitcpio -P
```

更改 `/etc/default/grub` 中的内核命令行，这里我还顺便打开了 cgroup v2。
`PARTUUID` 可以使用 `blkid` 命令查看。
```sh
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet systemd.unified_cgroup_hierarchy=1"
GRUB_CMDLINE_LINUX="cryptdevice=PARTUUID=xxx:archlinux"
```

[arch-ig]: https://wiki.archlinux.org/index.php/installation_guide

### 同步家目录

新建用户，并从备份中用 rsync 把家目录同步回来：
```sh
# run as wang
rsync -a ${EXTERNAL_DRIVE?}/home-snap/wang/* ~
rsync -a ${EXTERNAL_DRIVE?}/home-snap/wang/.* ~
```

### 安装软件包

安装我自己常用的软件
```sh
cd ~/.dotfiles/weirane-dotfiles-deps
makepkg -si
```

用下面的命令查看有哪些之前安装过而不在本机上的包，然后选择要安装的包并安装。
```sh
comm -23 <(cut -d' ' -f1 ${EXTERNAL_DRIVE?}/pacman-qe | sort) \
         <(pacman -Qq | sort) | less
```

## 配置

下面进行一些增加安全性或者便携性的配置。

### 加密 swap

为防止关机后 swap 中残留明文的内存数据，需要将 swap 加密。我不需要 hibernation，
所以参考 [ArchWiki][archwiki-swap]，将以下内容加入 `/etc/crypttab`：
```
swap  PARTUUID=xxx  /dev/urandom  swap,cipher=aes-xts-plain64,size=512
```

将原来 `/etc/fstab` 中 swap 的一行改为
```
/dev/mapper/swap        none            swap            defaults        0 0
```

[archwiki-swap]: https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption#Without_suspend-to-disk_support

### Key in initramfs

可以在 initramfs 中放一个 LUKS key，这样在开机的时候就不需要输两次 LUKS 密码了。
我一般将 key 放在 `/etc` 中。注意要调整 key file 和装有 key file 的 initramfs 的
权限。

```sh
sudo dd bs=512 count=4 if=/dev/urandom of=/path/to/key
sudo cryptsetup luksAddKey /dev/nvme0n1p4 /path/to/key
chmod 000 /path/to/key
chmod -R g-rwx,o-rwx /boot
```

把 key 加入 `/etc/mkinitcpio.conf` 中的 `FILES`：
```bash
FILES=(/path/to/key)
```

改 `/etc/default/grub` 中的内核命令行，加入 `cryptkey=rootfs:/path/to/key`：
```sh
GRUB_CMDLINE_LINUX="cryptdevice=PARTUUID=xxx:archlinux cryptkey=rootfs:/path/to/key"
```

## 解决问题

### xbacklight

进入图形界面后发现 polybar 中的亮度模块没有显示，`xbacklight` 命令没有输出。参考
[ArchWiki][aw-backlight] 之后发现应该安装 `xf86-video-intel` 并将下面的配置写入
`/etc/X11/xorg.conf.d/20-xbacklight.conf`：
```
Section "Device"
    Identifier  "Intel Graphics"
    Driver      "intel"
    Option      "Backlight"  "intel_backlight"
EndSection
```

[aw-backlight]: https://wiki.archlinux.org/index.php/Backlight#xbacklight

## 总结

整个过程挺顺利的，现在应该只剩一些之前在 `/etc` 中的配置没来得及同步了。由于家目
录是直接 `rsync` 过来的，所以所有的数据都还在，家目录中的程序的配置也没有丢失，
firefox 等程序也不需要重新登录或者进行其它的配置。

## 参考

- <https://blog.lilydjwg.me/2019/3/31/move-system-to-ssd.214336.html>
- <https://gist.github.com/ansulev/7cdf38a3d387599adf9addd248b09db8>
