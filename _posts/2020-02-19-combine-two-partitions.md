---
title: 合并挂载在 `/` 和 `/home` 的分区
description: Combine the partitions mounted on / and /home
category: Tweaks
tags: partition rsync
redirect_from: /r/4
---

最近需要装一个很大的虚拟机，在导入 VirtualBox 的时候出现了「`NS_ERROR_INVALID_ARG (0x80070057)`」这个错误，上网查发现是因为硬盘空间不足。我的硬盘有 67G 的空闲空间，但是因为把 `/home` 单独分了一个分区，两个分区每个都有 30G 左右的剩余空间，无法充分利用。我的 `/` 和 `/home` 对应的分区是相连的，合并较为方便，便打算将这两个分区合并起来。以下是 `df`[^1] 的结果：

```terminal
$ df
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p6   81G   47G   30G  61% /
/dev/nvme0n1p8   53G   13G   37G  26% /home
/dev/nvme0n1p1  256M   30M  227M  12% /boot/efi
```

[^1]: 这里的 `df` 是一个小函数，见我的 [dotfiles 仓库](https://github.com/weirane/dotfiles/blob/2cab6e6/zsh/functions.zsh#L22)

## 背景
两年前第一次尝试 Linux 的时候我将 Linux 安装在了一个移动硬盘上。这种情况文件系统损坏的可能性比较大，所以将 `/` 和 `/home` 分开是有好处的，因为如果 `/` 所在的分区出现了故障 `/home` 中的个人文件不会受影响。

所以后来在内置硬盘上安装 Linux 的时候也将 `/home` 单独分了一个分区，但是对于内置硬盘分区出现故障还是不太容易发生的。分成两个分区之后就得比较小心，否则一个分区空间不够时另一个分区也帮不上忙；或者出现上述的情况，整个硬盘的空闲空间足够，但是分开后不够。（256G 硬盘的悲伤）

## 过程
### 备份
对于改分区这种危险操作，事前进行备份总是没有错的。使用 `rsync` 备份家目录到一个移动硬盘，可以把一些 cache 之类的目录排除，`rsync` 具体的用法参考 [`man rsync`][rsync1]。

```bash
sudo rsync -aAXvu --delete \
    "$HOME" "/mnt/point/of/external/drive/home" \
    --exclude=...
```

此命令也可以用于定期备份。

[rsync1]: https://man.archlinux.org/man/extra/rsync/rsync.1 "rsync(1)"

### 迁移
由于需要操作 `/home`，在登录一般用户的时候会无法将其 `umount`，所以得用 root 账号登录。为此我把我的登录管理器 `lightdm` disable 掉
```bash
sudo systemctl disable lightdm
```
重新启动后便进入了 tty1，输入 root 的用户名和密码，然后将挂载在 `/home` 的分区挂载到另一个目录上，再使用 `rsync` 同步：
```bash
umount /home
mkdir /mnt/home
mount /dev/nvme0n1p8 /mnt/home
rsync -aAXuv /mnt/home/wang /home
```

### 合并分区
`rsync` 同步完成之后就需要修改分区了。此时可以直接使用 `fdisk` 或者其它的命令行工具修改，但是我还是想稳一点，用 Gparted 来修改，顺便测试一下登录一般用户会不会出现问题。使用 `Ctrl`+`Alt`+`F2` 切到 tty2，登录一般用户并运行 `startx` 启动图形界面（我用的是 i3，不同的配置及不同的桌面环境的启动方式可能会有不同），此时可以看看家目录中的文件是否正常，然后利用 Gparted 删除 `/home` 对应的分区，再扩展 `/` 的分区。

改完分区后可以确认一下 `/etc/fstab` 有没有问题，如果 `/home` 在上面的话应该将这一行删掉，否则可能出现挂载失败而进入 rescue mode 的情况。

### 完成
分区修改好之后登出，回到 tty1 将登录管理器重新 enable 便可重启。

## 结果
成功 🎉

```terminal
$ df
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p6  133G   60G   68G  47% /
/dev/nvme0n1p1  256M   30M  227M  12% /boot/efi
```

---
