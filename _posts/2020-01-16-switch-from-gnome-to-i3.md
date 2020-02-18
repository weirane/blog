---
title: 从 GNOME 迁移到 i3
description: Switching from GNOME to i3
category: I3
tags: i3 dotfiles
redirect_from: /r/3
---

本文记录一下在我的 Manjaro 上从 GNOME 迁移到 [i3-gaps] 的经历，也可以为在其它 Arch 系发行版上安装 i3-gaps 提供一些参考。i3 是一种平铺窗口管理器（tiling window manager）。我在本机安装 i3 之前先在虚拟机上尝试了一下 [Manjaro 的 i3 edition][manjaro-i3] 以熟悉一下 i3 的 key bindings，以下在配置时有所参考它的默认配置。

[i3-gaps]: https://github.com/Airblader/i3
[manjaro-i3]: https://manjaro.org/download/#i3

---

2020-01-23 更新：增加了 [多显示器](#多显示器) 一节。

## 安装
`i3-wm` 和 `i3-gaps` 这两个包都提供 i3 window manager，而且它们互相冲突。由于我在虚拟机中体验的是 `i3-gaps` 所以这里就用了 `i3-gaps` 这个版本。

使用 `pacman` 安装 `i3-gaps`。安装之后在目录 `/usr/share/xsessions` 中会出现 `i3.desktop`，直接重启即可在 gdm 菜单中看到 `i3`，选择它再输入密码登录即可进入 i3。 Gdm 是在安装 GNOME 的时候安装的，也可以选择其它的登录管理器。

再安装一些基本的程序，如 `dmenu` 或者 `dmenu-manjaro`（推荐），终端和顶栏。我使用的终端是 [termite]，顶栏是 [polybar]。

[termite]: https://github.com/thestinger/termite
[polybar]: https://github.com/polybar/polybar

---

由于没有图形化的菜单，所以 i3 中的配置基本上都是手写配置文件。我的 i3 配置文件 `~/.config/i3/config` 是在 Manjaro i3 edition 的默认配置基础上修改的。

## 软件配置
### fcitx
需要将 fcitx 加入自动启动的程序中，因为 GNOME 会自动启动 fcitx 而 i3 不会。需要注意的是如果使用 vim 的 `fcitx.vim` 插件的话不能以 root 的身份启动 fcitx（如将 `fcitx` 命令放在 `~/.xprofile` 中），不然打开 vim 时出现 `fcitx.vim` 插件报错：

    socket file of fcitx not found, fcitx.vim not loaded.

原因是 `/tmp/fcitx-socket-:1` 这个 socket 的所有者是 root，`fcitx.vim` 对它没有写权限。启动命令最好放在 i3 的配置文件中，即在 `~/.config/i3/config` 中加入：

    exec --no-startup-id fcitx

### 设置墙纸
可以使用 `feh` 来设置墙纸，使用命令

    feh --bg-fill <image file>

在 i3 启动时自动执行该命令即可。

### notify-send
使用 `notify-send` 发现并没有显示通知。此时需要安装一个 [notification daemon]，我选的是 `dunst`。将它加入 i3 自动启动的程序中或者利用 `systemd` 自动启动即可。

[notification daemon]: https://wiki.archlinux.org/index.php/Desktop_notifications#Notification_servers

### Termite 透明背景
使用 termite 的透明背景功能需要安装 `xcompmgr` 并让它自动启动。

### 设置 xdg-open 使用的程序
使用以下命令设置

    xdg-mime default <program>.desktop <MIME type>

或者直接修改 `~/.local/share/applications/defaults.list`（没有就创建该文件），示例如下：
```ini
[Default Applications]
application/pdf=org.pwmt.zathura.desktop
image/png=sxiv.desktop
```

### 截图
使用 `scrot`。写一个脚本以支持不同的情况并使用 `zenity` 选择保存位置，如下面 [这个 gist][scrot-gist]：

<script src="https://gist.github.com/weirane/d8209c45e8c8e69dc33cd460e5dec7c0.js"></script>

并在 `~/.config/i3/config` 中添加：

    bindsym Print exec --no-startup-id /path/to/screenshot.sh --whole
    bindsym $mod+Shift+Print exec --no-startup-id /path/to/screenshot.sh --window
    bindsym Shift+Print --release exec --no-startup-id /path/to/screenshot.sh --select

这样的效果是使用 `PrtSc` 截取全屏，`Shift`+`PrtSc` 截取一个区域，`Super`+`Shift`+`PrtSc` 截取当前的窗口。

[scrot-gist]: https://gist.github.com/weirane/d8209c45e8c8e69dc33cd460e5dec7c0

### 挂载
在 i3 中没有了 GNOME 中插入 U 盘自动挂载的功能，不过可以利用 dmenu 写一个挂载 drive 的脚本，如下面的 [gist][mount-gist]：

<script src="https://gist.github.com/weirane/d3eea2b74d31b4da5ae9b5f7b41c33ab.js"></script>

再给这个脚本绑定一个快捷键即可。

[mount-gist]: https://gist.github.com/weirane/d3eea2b74d31b4da5ae9b5f7b41c33ab

### 图片和 PDF 阅读器
由于从 GNOME 3.32 开始一些 GNOME 应用的标题栏变得很厚，evince 和 gthumb 在 i3 这种平铺窗口管理器下有一个很高的标题栏，所以打算换一个阅读器。选择的图片阅读器是 [sxiv]，PDF 阅读器是 [zathura]。对应的配置文件在我的 [dotfiles] 仓库里。

[sxiv]: https://github.com/muennich/sxiv
[zathura]: https://pwmt.org/projects/zathura/
[dotfiles]: https://github.com/weirane/dotfiles/blob/master/dotconfig/

## 硬件相关
### 连接 WiFi、蓝牙
安装 `network-manager-applet` 和 `blueman`，再设置自动启动 `nm-applet` 和 `blueman-applet` 即可，重新登录（或者手动启动这两个程序）即可在系统托盘看到对应的菜单。

开机时自动打开蓝牙：编辑文件 `/etc/bluetooth/main.conf`，将 `[Policy]` 一节中的 `AutoEnable` 设置为 true：

```ini
[Policy]
AutoEnable=true
```

### Disable beeps
根据 [Arch Wiki][disble-beep]，使用命令
```sh
sudo rmmod pcspkr
```

或者把此设置永久化：
```sh
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf
```

[disble-beep]: https://wiki.archlinux.org/index.php/PC_speaker#Disable_PC_Speaker

### Remap CapsLock
我一般会将 CapsLock 键映射成 Ctrl 键，可以利用 `~/.Xmodmap` 文件进行设置：

    clear lock
    clear control
    add control = Caps_Lock Control_L Control_R
    keycode 66 = Control_L Control_L Control_L Control_L

然后在 `~/.xinitrc` 中加入 `xmodmap ~/.Xmodmap`。这样设置之后就无法通过键盘中的某一个键实现 CapsLock 了，如果需要的话可以使用 `xdotool key Caps_Lock` 命令来触发。

<div class="notice--info" markdown="1">
<i class="fas fa-exclamation-circle"></i> **注意！**

用这种方法对执行 `xmodmap` 命令后连接的键盘没有效果。经过一番调研[^1]<sup>,</sup>[^2]，一个解决方案是使用 `inotifywait` 监控 `/dev/input` 中的新设备并在有新设备时执行 `xmodmap` 命令，写一个 [脚本][auto-xmodmap] 并设置自动启动即可。
</div>

[auto-xmodmap]: https://github.com/weirane/dotfiles/blob/master/dotconfig/i3/scripts/xmodmap-on-new-input.sh
[^1]: 这个 bug report 的最后一个 comment：<https://bugs.launchpad.net/ubuntu/+source/xorg-server/+bug/287215>
[^2]: <https://bugs.freedesktop.org/show_bug.cgi?id=25262#c3>

### 触摸板相关
目标：
- 轻拍触摸板相当于按键
- 触摸板自然滚动（natrual scrolling）

参考 [这里][touchpad]，将以下内容写入文件 `/etc/X11/xorg.conf.d/90-touchpad.conf`：

    Section "InputClass"
            Identifier "touchpad"
            MatchIsTouchpad "on"
            Driver "libinput"
            Option "Tapping" "on"
            Option "TappingButtonMap" "lrm"
            Option "NaturalScrolling" "on"
            Option "ScrollMethod" "twofinger"
    EndSection

重启或注销再登录即可看到效果。

[touchpad]: https://cravencode.com/post/essentials/enable-tap-to-click-in-i3wm/

### 多显示器
配置多个显示器可以使用 [`xrandr`] 工具。图形化的配置工具可以使用 `arandr` 这个包。

[`xrandr`]: https://wiki.archlinux.org/index.php/Xrandr

### 锁屏
想要达到以下的效果：
- 定时锁定
- 合上屏幕自动锁定
- 锁屏后短时间黑屏

利用 `xset`，`xss-lock` 配合锁屏工具 `i3lock`。`xset` 用于设置屏幕黑暗时间，`xss-lock` 可以监控 [DPMS] 信号并自动执行锁屏程序。在 i3 配置文件中加入

    exec --no-startup-id xss-lock -n /path/to/dim-screen.sh -- /path/to/lock.sh -i

[dim-screen.sh][dim-screen] 修改自 xss-lock 的仓库，[lock.sh][locksh] 如链接。

[dim-screen]: https://github.com/weirane/dotfiles/blob/master/dotconfig/i3/scripts/dim-screen.sh
[locksh]: https://github.com/weirane/dotfiles/blob/master/dotconfig/i3/scripts/lock.sh

[DPMS]: https://wiki.archlinux.org/index.php/Display_Power_Management_Signaling

### 音量/亮度调节键
参考 StackOverflow 上的一个 [答案][light-volume]，安装 `xorg-xbacklight` 并将以下五行加入 `~/.config/i3/config`：

    bindsym XF86AudioMute exec "amixer sset 'Master' toggle"
    bindsym XF86AudioLowerVolume exec "amixer sset 'Master' 5%-"
    bindsym XF86AudioRaiseVolume exec "amixer sset 'Master' 5%+"
    bindsym XF86MonBrightnessUp exec "xbacklight -inc 5"
    bindsym XF86MonBrightnessDown exec "xbacklight -dec 5"

[light-volume]: https://unix.stackexchange.com/a/439487

---
