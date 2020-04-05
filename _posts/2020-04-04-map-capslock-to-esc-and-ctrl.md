---
title: 将 Caps Lock 映射为 Escape 和 Ctrl
description: Map Caps Lock to Escape and Ctrl
category: Tweaks
tags: keyboard
redirect_from: /r/5
---

Caps Lock 可能是键盘上最没有用的一个键了，但是它又占据了 home row 的位置。一些人
会把它映射成 Escape 或者 Ctrl。但是作为一个 Vim 用户，Escape 和 Ctrl 都是很常用
的键。如何让 Caps Lock 在单击的时候是 Escape，和其它键配合的时候是 Ctrl？

## 之前的配置

### Xmodmap

[以前][pre-capslock] 有写过使用 xmodmap 将 Caps Lock 变为 Ctrl 的方法，但是这个
方法不能让单击 Caps Lock 时产生 Escape 的效果。

[pre-capslock]: /2020/01/switch-from-gnome-to-i3.html#remap-capslock

### hwdb

Xmodmap 的问题之一是它只对 X 有效，到了 tty 中就不起作用了。有一个更加底层的方法
是使用 hwdb。参考 [Arch Wiki][map-scan]，对笔记本内置的键盘可以将以下的内容写入
`/etc/udev/hwdb.d/xxx.hwdb` 中

    evdev:atkbd:dmi:*
     KEYBOARD_KEY_3a=leftctrl  # Caps Lock down as Left Ctrl

运行以下命令生效

    sudo systemd-hwdb update
    sudo udevadm trigger

如果 hwdb 可以对连续的几个 scancode 进行设置的话也许可以达成映射 Caps Lock 为
Escape 和 Ctrl 的目标，但是好像并不行，reddit 上有一个 [帖子][reddit-scancode]
也一直没有人给出解决方法。

[map-scan]: https://wiki.archlinux.org/index.php/Map_scancodes_to_keycodes "Map scancodes to keycodes"
[reddit-scancode]: https://www.reddit.com/r/archlinux/comments/9s7569/map_caps_lock_to_escape_and_control_using_udev/

## 可行的方法

使用 [Interception Tool][int-tool] 配合插件 [caps2esc]。安装这两个 AUR 包或者去
主页上查看安装方法。

    yay -S interception-tools interception-caps2esc

将以下内容写入 `/etc/udevmon.yaml`：

```yaml
- JOB: "intercept -g $DEVNODE | caps2esc | uinput -d $DEVNODE"
  DEVICE:
    EVENTS:
      EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
```

运行并自动启动 `udevmon`：`sudo systemctl enable --now udevmon`

如此配置之后 Caps Lock 在单击的时候会变成 Escape，做为组合键的时候是 Ctrl。同时
原来的 Escape 键变成了 Caps Lock。

但是我不想让 Escape 映射成 Caps Lock，研究了 `caps2esc` 的源码后发现只要将替换
ESC 的 `code` 那两行删除即可，如下。

```diff
diff --git a/caps2esc.c b/caps2esc.c
index e9e29b6..d3641f2 100644
--- a/caps2esc.c
+++ b/caps2esc.c
@@ -77,8 +77,6 @@ int main(void) {
             continue;
         }
 
-        if (input.code == KEY_ESC)
-            input.code = KEY_CAPSLOCK;
         write_event(&input);
     }
 }
```

安装新编译出来的 `caps2esc` 再 `sudo systemctl restart udevmon` 即可。

这里注意一定不要把下面的 `write_event(&input);` 删掉了，否则会让所有的键都没反应
，重启也没有用，因为 `udevmon` 会自动启动。最后得想办法删掉
`/etc/systemd/system/multi-user.target.wants/udevmon.service` 以取消自动启动
`udevmon`，比如用 Live USB 或者 SSH 到主机。（不要问我是怎么知道的）

此时如果需要触发 Caps Lock 键（比如 Caps Lock 不知为什么被打开了），只能先将
`udevmon` 停止再按 Caps Lock。为了方便我给 `caps2esc` 加了一个 signal handler，
当收到 `SIGUSR1` 的时候触发 Caps Lock，这样需要的时候可以直接 `sudo killall
-USR1 caps2esc`。[源代码][nocaps-src] 放在了 GitHub 上，还有一个对应的AUR 包
`intercept-caps2esc-nocaps-git`。

[int-tool]: https://gitlab.com/interception/linux/tools
[caps2esc]: https://gitlab.com/interception/linux/plugins/caps2esc
[nocaps-src]: https://github.com/weirane/caps2esc
