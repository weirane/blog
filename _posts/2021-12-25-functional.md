---
title: 关于基于表达式的编程语言的一些思考
description: Thoughts on Expression-oriented Programming Languages
category: Programming
tags: functional-programming programming-languages
redirect_from: /r/12
toc: false
---

最近学 Go 语言又想起之前看过的一个 talk，presenter 说他几乎不用 `else` 关键字。
因为一般情况下，if 语句的其中一个 branch 会比较短（比如处理特殊情况），这样可以
在这个 branch 结束后直接从函数返回，后续的代码就不需要进行缩进了，如
```go
func fact(n int) int {
    if n <= 1 {
        return 1
    }
    // no extra indent here!
    return fact(n - 1) * n
}
```

可以减少缩进当然是件好事。如果后续代码很长可以采用这种风格。但我觉得并不是所有的
情况都适用于这种写法。相比之下我更喜欢这样的写法
```c
int fact(int n) {
    return n <= 1 ? 1 : fact(n - 1) * n;
}
```
或者使用 `else`
```rust
fn fact(n: i32) -> i32 {
    if n <= 1 {
        1
    } else {
        fact(n - 1) * n
    }
}
```

Go 语言里没有三目运算符，因为语言设计者认为滥用三目运算符可能会降低可读性 [^1]。
三目运算符的可读性确实没有 if 语句高，但是问题的核心其实不在三目运算符。三目运算
符的鼻祖 C 需要它是因为 C 的 if 语句不是一个表达式，所以需要一个新的语法来表示
if 表达式。相比很多语言就不需要三目运算符，因为它们的 if 本身就是一个表达式。同
时 if 语句的可读性也比三目运算符高不少，用 `else if` 再添加几个 branch 也不会降
低可读性。

对我来说基于表达式可以让代码更容易理解。在理解一个基于表达式的程序时，我们可以自
底向上地学习程序，从小的表达式开始理解，再理解上级的表达式。如果表达式没有副作用，
在学习了这个表达式之后就可以把它看作一个黑盒了。一般来说函数式的语言都会支持更多
类型的表达式（如 if 表达式），函数式语言的宗旨之一也是通过组合无副作用的函数而实
现更复杂的功能。

[^1]: go.dev 上的观点应该可以算是语言设计者的吧 https://go.dev/doc/faq#Does_Go_have_a_ternary_form

<!--
https://fsharpforfunandprofit.com/posts/expressions-vs-statements/
-->
