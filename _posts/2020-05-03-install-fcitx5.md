---
title: Fcitx5 安装记
description: Installing fcitx5
category: Tools
tags: fcitx imagemagick
redirect_from: /r/6
---

在 #archlinux-cn 上 fcitx 是个经常被讨论的话题，每次都有人推荐 fcitx5。但是因为
只有在 KDE 中有图形化的配置工具就一直没有尝试。今天有人说配置工具 `kcm-fcitx5`
在非 KDE 中也可以安装了，所以来试试。

## 安装

先卸载 fcitx4：

    pacman -Qsq fcitx | sudo xargs pacman -Rsn

安装 fcitx5：

    sudo pacman -S fcitx5 fcitx5-chinese-addons kcm-fcitx5 fcitx5-qt fcitx5-gtk

Fcitx5 自带的皮肤不是很好看，我还安装了 [material-color 皮肤][material]：

    sudo pacman -S fcitx5-material-color

## 配置

### 输入法

有了图形化的配置工具，配置会轻松很多。首先在「输入法」一栏中添加需要的输入法，我
使用的是双拼，然后在「附加组件」→「拼音」里面修改双拼方案为小鹤双拼。

### 自动启动与环境变量

把自动启动 fcitx 的命令改成 `fcitx5`。

我使用的图形管理是 X11。使用 fcitx4 的时候在 `~/.xprofile` 或者 `~/.xinitrc` 中
设置的环境变量似乎不需要改成 fcitx5，之前 fcitx 使用的配置可以直接使用。

```sh
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
```

## 体验

### 快捷输入

在输入法激活时使用分号键触发快捷输入。在 `/usr/share/fcitx5/data/quickphrase.d`
中有一些自带的快捷输入，包括 emoji 和一些 LaTeX 命令，可以转换部分 LaTeX 命令到
对应的 unicode 字符，这个功能非常实用，可以让 LaTeX 文档更直观。当然也可以在配置
工具中自定义快捷输入。

![emoji quick phrase](/images/6-install-fcitx5/emoji.png)

![LaTeX quick phrase](/images/6-install-fcitx5/quickphrase.png)

### 单行模式

Fcitx5 自带的拼音可以使用单行模式，配合 material color 主题体验很好，有点
Windows 10 自带输入法的感觉。

![material color blue](/images/6-install-fcitx5/blue.png)[^mc-fig]

对于自带的拼音，在配置工具的「附加组件」→「拼音」中打开「可用时在应用程序中显示
预编辑文本」，或者直接修改 `~/.config/fcitx5/conf/pinyin.conf`：

```
# 可用时在应用程序中显示预编辑文本
PreeditInApplicaation=True
```

可惜单行模式对使用 XIM 的程序不能使用 [^no-xim]，而我用的终端模拟器 alacritty 正
好是使用的 XIM 😥[^alacritty-xim]。不过单行模式算不上是刚需，也就无所谓了。

[^mc-fig]: 图片来自 material color 的 [GitHub 仓库][material]，使用 imagemagick
    加了透明（<https://stackoverflow.com/a/33541007/10974106>）
    ```sh
    convert blue.png -fuzz 20% -fill none -draw "color 1,1 floodfill" result.png
    ```
[^no-xim]: <https://github.com/fcitx/fcitx5-chinese-addons/issues/3>
[^alacritty-xim]: <https://github.com/alacritty/alacritty/issues/44>

[material]: https://github.com/hosxy/Fcitx5-Material-Color

## 总结

总的来说，fcitx5 的体验比 4 要好一些。配置选项简洁，配合 material color 皮肤界面
也比较好看。~~也可能只是我没有仔细研究 fcitx4 的配置~~

---
