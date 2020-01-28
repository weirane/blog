---
title: AutoCompleters I Use in Vim
description: My experiences with YouCompleteMe and TabNine
category: Tools
tags: vim
redirect_from: /r/1
---

At the start, I should point out that this blog will not be a tutorial of how to install, configure or use an autocompleter in vim --- there are a plenty of them on the web. But if you are interested in my configurations under linux, you are welcome to visit my [dotfiles] repository.

[dotfiles]: https://github.com/weirane/dotfiles

## YouCompleteMe
The main completion tool I have been using is [YouCompleteMe], a wonderful plugin for Vim. It supports a wide range of languages (from C/C++, Python, Rust to CSS and much more) with semantic completion abilities. This plugin alone should satisfy the completion needs of almost all the languages I write.

The downside of it may be the tedious installation process if semantic completion is needed (perhaps only for new comers). The [full installation guide] in the official README is rather long. Luckily, on my Manjaro machine, following the [quick way] to install is enough for semantic completion. On distributions other than or not based on Arch Linux, the version of clang in the package manager may not satisfy ycm's need, thus the full installation guide have to be followed.

[YouCompleteMe]: https://github.com/ycm-core/YouCompleteMe
[full installation guide]: https://github.com/ycm-core/YouCompleteMe#full-installation-guide
[quick way]: https://github.com/ycm-core/YouCompleteMe#linux-64-bit

## TabNine
I came across [TabNine] a few weeks ago, and the first sight at the website raised my interest:

> TabNine uses deep learning to help you write code faster.

The completion tools I've been using have always been focusing on completing words, but TabNine goes beyond that. Besides word and semantic completion, with the power of Deep TabNine --- the deep learning model --- TabNine is able to predict what you want to type next. And some of the predictions are truly astonishing.

<figure class="half">
    <img src="/images/1-autocomp/yes-no.png" alt="yes-no" />
    <img src="/images/1-autocomp/good-bad.png" alt="good-bad" />
    <figcaption>Prediction in if-else clauses</figcaption>
</figure>

<figure class="half">
    <img src="/images/1-autocomp/rep.png" alt="yes-no" />
    <img src="/images/1-autocomp/rep2.png" alt="good-bad" />
    <figcaption>It just makes live easier</figcaption>
</figure>

This list goes on. And according to this [FAQ], TabNine is written in the [Rust] programming language, which makes me, a rustacean, very excited.

[TabNine]: https://tabnine.com
[FAQ]: https://tabnine.com/faq#language
[Rust]: https://rust-lang.org

### Drawbacks
With some truly amazing features, TabNine also has several drawbacks.

- It is not open source, and Deep TabNine may not be free of charge in the future.
- The machine learning model occupies 692 MB of disk space, which is not a small number. Avoiding the download of the model locally while wanting to use the deep leaning completion feature requires you to use TabNine Cloud, which sends the code to the cloud and may raise privacy concerns.
- It consumes a considerable amount of memory. Completing for a single markdown document (less than 50 lines) takes 1.5 GB of memory (even much more than chrome!), which is a big portion on my 8G-memory laptop.

So having weighed the pros and cons, I have decided that YouCompleteMe will still be my primary completion tool and TabNine will only be used in limited situations involving a lot of repetitions.
