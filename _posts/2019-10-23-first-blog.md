---
title: 第一篇博客
description: The first blog, an explantion of how this blog is set up
tags: jekyll
redirect_from: /r/0
---

这个博客使用 [jekyll] 构建加上 [minimal mistakes][minimistake] 主题的 `dirt` [皮肤][skin]。源代码在 [GitHub][gh-source] 上，用 Travis CI 自动部署到 GitHub Pages：[![Build Status](https://travis-ci.org/weirane/blog.svg?branch=master)](https://travis-ci.org/weirane/blog)。

Jekyll 和 minimal mistakes 配置起来应该不算太难，官方的文档讲得很详细，~~但是很懒的我并不想仔细看完~~。需要注意的是使用这种配置方式并不属于文档中描述的「hosted on GitHub Pages」，因为构建网站是在 Travis CI 中完成的，GitHub 得到的已经是构建完成的 HTML, CSS 和 JavaScript。配置的时候还参考了 iBug 的一篇 [blog]，我也从他的 [repo] 中借鉴了一些配置，在此表示感谢～

为什么使用这样的构建方式？

- 暂时还没有想购买域名，所以打算使用 GitHub Pages；
- 直接在 GitHub Pages 上建博客（即上面说的「hosted on GitHub Pages」）的限制较大，如不能使用一些插件等。正好看到了 iBug 的 [blog]，所以打算使用 Travis CI 构建 `_site`，然后将 `_site` 放到 [`weirane.github.io`][gh-dest] 这个 repo 上。

最后希望可以将博客坚持下去，不要中途弃坑（

[jekyll]: https://jekyllrb.com/
[minimistake]: https://mmistakes.github.io/minimal-mistakes/
[skin]: https://mmistakes.github.io/minimal-mistakes/docs/configuration/#skin
[gh-source]: https://github.com/weirane/blog
[blog]: https://ibugone.com/blog/2018/04/build-github-pages-with-travis-ci/
[repo]: https://github.com/iBug/iBug-source
[gh-dest]: https://github.com/weirane/weirane.github.io
