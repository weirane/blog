---
title: "Rust + WebAssembly: 最近点对问题"
description: A Rust + WebAssembly demo of the closest point problem
toc: true
category: Programming
tags: rust wasm
redirect_from: /r/2
---

先放 [链接][gh-pages]。这个项目一开始是算法课的一个上机作业，[平面上的最近点对问题]。这是一个使用分治法的计算几何学问题，具体的算法就不在这里解释了，这篇博客主要讲讲 Rust 和 WebAssembly。

[平面上的最近点对问题]: https://en.wikipedia.org/wiki/Closest_pair_of_points_problem

## Rust
先说说在这个项目中我学到的关于 Rust 的东西吧。

### 遇到的问题
在命令行中输入数据的时候需要将输入的每一行转化为一个 `Point`，并将这些 `Point` 存入一个 `Vec` 中。由于 [`io::StdinLock`] 实现了 [`BufRead`] 这个 trait，所以可以方便地用 `io::stdin().lock().lines()` 获得一个输入行的迭代器。我的 `Point` 结构体已经实现了 [`FromStr`] trait，现在应该如何将每一行 `map` 成 `Point` 并收集到 `Vec` 中？由于 `Point::from_str` 返回的是一个 `Result` 但我又不想直接 `unwrap` 掉而是想用 `?` 把错误给 propagate 上去，所以事情并没有那么简单。我的第一感觉是
```rust
let points: Vec<_> = io::stdin()
    .lock()
    .lines()
    .map(|line| line.unwrap())
    .take_while(|line| !line.is_empty())
    .map(|line| Point::from_str(&line)?)  // Notice this line
    .collect();
```

但这显然是不对的：

    error[E0277]: the `?` operator can only be used in a closure that returns `Result` or `Option` (or another type that implements `std::ops::Try`)
      --> examples/input.rs:14:21
       |
    14 |         .map(|line| Point::from_str(&line)?)
       |                     ^^^^^^^^^^^^^^^^^^^^^^^ cannot use the `?` operator in a closure that returns `closest_pair::point::Point`

由于 `map` 接受的参数是一个闭包，所以这里的 `?` 只能将 `from_str` 的错误返回给闭包。如果想用 error propagation 的话就要使得 `map` 接受的闭包返回值为一个 `Result<Point, _>`，但是要 `collect` 的是 `Point` 啊！

### 真巧
写的时候正好看到了 reddit 上一个关于 Rust 的一些不那么为人所知的特性的 [thread]。里面正好有人提到可以将一个 `Result<T, E>` 的迭代器 `collect` 成 `Result<Collection<T>, E>`。（惊讶.jpg）

所以最终的结果为
```rust
let points: Vec<_> = io::stdin()
    .lock()
    .lines()
    .map(|line| line.unwrap())
    .take_while(|line| !line.is_empty())
    .map(|line| Ok(Point::from_str(&line)?))
    .collect::<Result<_, ParsePointError>>()?;
```

Rust 的这种可以用一句话完成较为复杂的工作而且将错误处理做好的能力还是非常不错的。

另外我还是想吹一下 Rust 的文档，因为在这个项目中用了一些以前没用过的方法，比如 [`windows`]（~~虽然到最后还是删掉了~~）、[`take`] 等等。Rust 的文档看起来非常舒服，并且很多函数都有使用示例。不像某 cppreference 字号小的不行然后排版奇奇怪怪的（

[thread]: https://www.reddit.com/r/rust/comments/do186h/can_you_share_some_lesser_known_rust_features/
[`io::StdinLock`]: https://doc.rust-lang.org/std/io/struct.StdinLock.html
[`BufRead`]: https://doc.rust-lang.org/std/io/trait.BufRead.html
[`FromStr`]: https://doc.rust-lang.org/std/str/trait.FromStr.html
[`windows`]: https://doc.rust-lang.org/std/primitive.slice.html#method.windows
[`take`]: https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.take

## WebAssembly
官网中对 WebAssembly 的介绍：

> WebAssembly (abbreviated *Wasm*) is a binary instruction format for a stack-based virtual machine. Wasm is designed as a portable target for compilation of high-level languages like C/C++/Rust, enabling deployment on the web for client and server applications.

WebAssembly 应该说是一个比较新的技术了，但是使用 Rust 开发 WebAssembly 已经有了一些很好用的工具，比如 [wasm-pack] 等，Rust 官方有一个 [tutorial] 很清晰地展示了如何使用 Rust 来写 WebAssembly。

[wasm-pack]: https://rustwasm.github.io/wasm-pack/

### 如何传数据
在这个项目中一大问题是 Rust 和 JavaScript 应该如何相互传数据。原来我打算的是只在 Rust 中定义一个函数接收一个 point 的数组然后返回结果。但是目前 WebAssembly 并不支持我想用的参数和返回值类型：

1. 一个点由两个坐标构成，但是与 JavaScript 交互的函数参数类型不能是 `Vec<(f64, f64)>`；
2. 我的结果是五个浮点数（距离和两个点的坐标），而 WebAssembly 目前还不能返回一个 tuple：

        the trait `wasm_bindgen::convert::traits::IntoWasmAbi` is not implemented for `(f64, f64, f64, f64, f64)`

解决办法之一是调用函数时传两个数组，分别为横坐标和纵坐标，然后定义一个 `struct` 来放五个返回值：
```rust
#[wasm_bindgen]
pub struct ReturnType {
     pub dist: f64,
     pub p0_x: f64,
     pub p0_y: f64,
     pub p1_x: f64,
     pub p1_y: f64,
}

#[wasm_bindgen]
pub fn calculate(xs: &[f64], ys: &[f64]) -> ReturnType { ... }
```
这种设计的交互的方式就是在 JavaScript 里维护横纵坐标的数组，要计算的时候将这两个数组传给 Rust，Rust 经过计算将一个 `ReturnType` 返回给 JavaScript。但是感觉这样的交互模式很奇怪，要把点的两个坐标分开。

### 解决方案
直接使用一个 struct `WasmApp` 来存储点的数组和计算的返回值，然后把添加点和计算等操作都做成 `WasmApp` 的方法：
```rust
#[wasm_bindgen]
#[derive(Debug, Default)]
pub struct WasmApp {
    points: Vec<Point>,
    pub dist: f64,
    pub p0_x: f64,
    pub p0_y: f64,
    pub p1_x: f64,
    pub p1_y: f64,
}

#[wasm_bindgen]
impl WasmApp {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self { ... }
    #[wasm_bindgen(js_name = addPoint)]
    pub fn add_point(&mut self, x: f64, y: f64) { ... }
    pub fn calculate(&mut self) -> Result<(), JsValue> { ... }
    pub fn clear(&mut self) { ... }
}
```
其中的 `js_name` 的作用为指定 JavaScript 调用时函数的名字。由于 Rust 和 JavaScript 对函数的 naming convensions 不一样，这个选项可以让代码在 Rust 和 JavaScript 两边都遵守主流的命名模式。

`Result<(), JsValue>` 是一个合法的返回值，参见 [wasm-bindgen guide] 中的说明。当 `Result` 的值为 `Ok(_)` 的时候正常返回，若为 `Err(_)`，则此函数在 JavaScript 中抛出一个异常，可以使用 `try`-`catch` 来处理。

这样在 JavaScript 中只需调用 `WasmApp` 的方法，不再需要分开存储点的坐标了。不过因为目前无法返回一个 tuple，所以返回值还是只能通过 `WasmApp` 的属性获得。

[wasm-bindgen guide]: https://rustwasm.github.io/docs/wasm-bindgen/reference/types/result.html

## 部署
这个项目使用 [webpack] 部署 WebAssembly 应用，webpack 也是官网的 [tutorial] 使用的工具。用命令 `npm build` 即可得到 `dist` 目录，将其复制到目标服务器上即可。还要注意的是目标服务器需要将 `*.wasm` 的 MIME 类型设置为 `application/wasm`。我使用了一个与此博客类似的 Travis CI 配置来自动地在我向此项目的 [仓库][repo] push 的时候编译并部署到 [GitHub Pages][gh-pages] 上。

最终结果：:tada:

![demo](/images/2-rust-wasm-cp/demo.png)

之后我还打算给这个 canvas 加一个 grid 让距离值看起来更直观，目前就这样吧。

[webpack]: https://webpack.js.org/
[tutorial]: https://rustwasm.github.io/docs/book/
[repo]: https://github.com/weirane/closest-pair-wasm
[gh-pages]: https://weirane.github.io/closest-pair-wasm/
