---
title: 从零开始的 λ 演算
description: 'A summary of the PyCon talk "Lambda Calculus from the Ground Up"'
category: Programming
tags: functional-programming lambda-calculus python
redirect_from: /r/10
---

这是我在看完 PyCon 2019 演讲「Lambda Calculus from the Ground Up」之后做的一个文
字版，原视频在 <https://youtu.be/pkCLMl0e_0k>{:target="_blank"}。另见官网中的
[介绍][descpy]，这里提供一个翻译。

> 最近关于编程风格的指南层出不穷。但是如果我们把风格限制为只允许出现单参数的函数
> 会发生什么呢？没有模组，没有类，没有控制流，没有数据结构，甚至连整数、正则表达
> 式等内建类型都没有，只有函数。用这种风格能写出程序吗？令人惊讶的是，答案是肯定
> 的。在这个教程中，你将学到如何从零开始在 Python 中推导 λ 演算。
>
> 你不会在这个教程中学到有实际用处的东西。没有打包，没有工具，没有库，没有部署，
> 也没有神奇的 Python 编程技术。你也不会学到会被你用在实际项目上的东西。但是你将
> 获得很多乐趣，将感到惊叹，并学习一些基础的计算机科学，这是你进一步探索函数式编
> 程、类型理论、编程语言等话题的起点。

[descpy]: https://pycon-archive.python.org/2019/schedule/presentation/79/

## 规则

如上介绍所说，我们只允许函数调用，或者参数替换这一种操作。以下列举一些不被允许的
操作：

```python
def f(x):
    return x + 1  # 不允许使用数字和运算符 +

def f(x, y):
    ...  # 只允许单个参数
```

以下是一些合法的操作，但是他们好像没什么意义：

```python
def f(x):
    return x

def f(x):
    return x(x)

def f(x):
    def g(y):
        return x(y)
    return g
```

所以在这样的一个如此抽象的系统中，我们可以做些什么？

## 布尔值（[18:27][]）

首先来构造布尔值和布尔运算。可以借用选择器的概念来构造布尔值。`TRUE` 选择两个值
中的第一个，而 `FALSE` 选择第二个。注意这里的 `TRUE` 和 `FALSE` 并不是一个具体的
值，而是一种行为。

```python
def TRUE(x):
    return lambda y: x

def FALSE(x):
    return lambda y: y
```

```python-repl
>>> TRUE('5v')('gnd')
'5v'
>>> FALSE('5v')('gnd')
'gnd'
```

接下来是布尔运算 `NOT`, `AND` 和 `OR`。注意到 `NOT` 的参数应该是 `TRUE` 或者
`FALSE`，它们都是需要两个输入的函数（[柯里化][curried]的）。然后根据 `TRUE` 和
`FALSE` 在两个值中的选择情况便可构造出 `NOT`。

```python
def NOT(x):
    return x(FALSE)(TRUE)
```

对于 `AND`，在它的第一个参数为 `TRUE` 的时候，值就等于第二个参数；在第一个参数为
`FALSE` 的时候，值为 `FALSE`（也就是它的第一个参数）。`OR` 可以根据类似的思想写
出：

```python
def AND(x):
    return lambda y: x(y)(x)

def OR(x):
    return lambda y: x(x)(y)
```

<details markdown="1">
<summary>布尔运算演示</summary>
```python-repl
>>> NOT(TRUE)
<function FALSE(x)>
>>> NOT(FALSE)
<function TRUE(x)>
```

```python-repl
>>> AND(TRUE)(TRUE)
<function TRUE(x)>
>>> AND(TRUE)(FALSE)
<function FALSE(x)>
>>> AND(FALSE)(TRUE)
<function FALSE(x)>
>>> AND(FALSE)(FALSE)
<function FALSE(x)>
```

```python-repl
>>> OR(TRUE)(TRUE)
<function TRUE(x)>
>>> OR(TRUE)(FALSE)
<function TRUE(x)>
>>> OR(FALSE)(TRUE)
<function TRUE(x)>
>>> OR(FALSE)(FALSE)
<function FALSE(x)>
```
</details>

[curried]: https://en.wikipedia.org/wiki/Currying

## 数字（[34:45][]）

因为我们能够做的只有函数调用，所以可以尝试用调用函数的次数表示数字，比如
`TWO(f)(x)` 的含义是以 `x` 为初始值，调用 `f` 两次：
```python
ONE = lambda f: lambda x: f(x)
TWO = lambda f: lambda x: f(f(x))
THREE = lambda f: lambda x: f(f(f(x)))
FOUR = lambda f: lambda x: f(f(f(f(x))))
```

零表示为调用函数零次，即不调用函数：
```python
ZERO = lambda f: lambda x: x
```

为了能够方便地展示我们的系统中的数字，在此写一个函数用来将系统中的数字转为
Python 中的一个 `int`。这个函数并不在 λ 演算系统中，只是为了方便地查看系统中的数
字。
```python
def toint(n):
    return n(lambda x: x + 1)(0)
```

```python
>>> toint(THREE)
3
```

### 加法和乘法（[50:02][]）

使用 [Peano 公理][peano-axioms] 的思想，先实现一个数字的后继。
```python
SUCC = lambda n: lambda f: lambda x: f(n(f)(x))
```

在这个实现中，`SUCC` 的返回值是一个数（因为拥有 `lambda f: lambda x: xxx` 这样的
「接口」），而这个返回的数是以 `x` 为初始值调用了 `n` 次函数 `f`（用 `n(f)(x)`
表示）后又多调用了 `f` 一次的结果，所以表示 *n*&nbsp;+&nbsp;1。

```python-repl
>>> toint(SUCC(THREE))
4
```

有了 `SUCC` 就可以实现加法了。*x*&nbsp;+&nbsp;*y* 就是在 *x* 的基础上调用 *y* 次
`SUCC`。而数字的行为正好是调用某个函数多少次。
```python
ADD = lambda x: lambda y: y(SUCC)(x)
```

乘法就是将「调用函数 `f` *x* 次」（即 `x(f)` 这个行为）重复 *y* 次：
```python
MUL = lambda x: lambda y: lambda f: y(x(f))
```

从上面的定义可以看出乘法就是用[函数的复合][composition]，即 `MUL x y = y ∘ x`。

加法和乘法的演示：
```python-repl
>>> toint(ADD(FOUR)(THREE))
7
>>> toint(MUL(FOUR)(THREE))
12
```

[peano-axioms]: https://en.wikipedia.org/wiki/Peano_axioms
[composition]: https://en.wikipedia.org/wiki/Function_composition

### 二元组（[2:03:49][]）

为了实现减法，我们需要先实现二元组。

`CONS(a)(b)` 将会返回一个「选择器」，这个选择器根据给它的参数选择 `a` 和 `b` 中
的一个。这里的函数名借用了 Lisp 中的名字。
```python
CONS = lambda a: lambda b: (lambda s: s(a)(b))
CAR = lambda p: p(TRUE)
CDR = lambda p: p(FALSE)
```

```python-repl
>>> p = CONS(2)(3)
>>> CAR(p)
2
>>> CDR(p)
3
```

这里的 `CONS` 接受两个参数并构造了一个二元组，`CAR` 和 `CDR` 分别取二元组中的第
一个和第二个值。

### 减法（[2:12:15][]）

下面借助二元组来实现一个数的前驱。我们可以从 (0, 0) 开始增加，(1, 0), (2, 1) ……
二元组的第二个数是第一个数的前驱，而第一个数就是增加的次数。

```python
T = lambda p: CONS(SUCC(CAR(p)))(CAR(p))
```

```python-repl
>>> a = FOUR(T)(CONS(ZERO)(ZERO))
>>> toint(CAR(a))
4
>>> toint(CDR(a))
3
```

上面的 `a` 是从 (0, 0) 开始执行了函数 `T` 4 次后的结果，它本身是一个二元组，第二
个值就是 4 的前驱 3。于是实现前驱的方式为从 `CONS(ZERO)(ZERO)` 开始执行函数
`T` `n` 次，再取二元组的第二个值：
```python
PRED = lambda n: CDR(n(T)(CONS(ZERO)(ZERO)))
```

```python-repl
>>> a = FOUR(THREE)
>>> toint(a)
81
>>> b = PRED(a)
>>> toint(b)
80
```

然后仿造加法构造减法：
```python
SUB = lambda x: lambda y: y(PRED)(x)
```

```python-repl
>>> a = SUB(FOUR)(TWO)
>>> toint(a)
2
```

### 判断一个数是否为零（[2:24:12][]）

由于 `ZERO` 的行为是直接返回第二个输入，所以下面的第二个括号中为 `TRUE`。而其它
的数都会调用第一个输入，所以直接让这个输入返回 `FALSE`。
```python
ISZERO = lambda n: n(lambda _: FALSE)(TRUE)
```

```python-repl
>>> ISZERO(ZERO)
<function TRUE(x)>
>>> ISZERO(ONE)
<function FALSE(x)>
```

## 递归（[2:30:13][]）

我们已经有了 `AND`, `SUCC`, `ADD`, `CONS`, `CAR` 和 `ISZERO` 等等函数，现在我们
要来挑战写出阶乘函数。阶乘在普通 Python 中的一种写法是
```python
fact = lambda n: 1 if n == 0 else n * fact(n-1)
```

它只用了判断是否为零，乘法和减法三种操作。把它转化为 λ 演算中的形式，得到
```python
FACT = lambda n: ISZERO(n) \
                 (ONE) \
                 (MUL(n)(FACT(PRED(n))))
```

但是这个实现有问题：
```python-repl
>>> FACT(THREE)
RecursionError: maximum recursion depth exceeded
```

### 惰性求值（[2:34:40][]）

原因是 Python 函数不是惰性求值（lazy）的，递归发生在 `ISZERO` 判断之前。为了规避
这个限制，我们实现以下的 lazy 版本
```python
L_TRUE = lambda x: lambda y: x()
L_FALSE = lambda x: lambda y: y()
L_ISZERO = lambda n: n(lambda _: L_FALSE)(L_TRUE)

FACT = lambda n: L_ISZERO(n) \
                 (lambda: ONE) \
                 (lambda: MUL(n)(FACT(PRED(n))))
```

```python-repl
>>> a = FACT(THREE)
>>> toint(a)
6
```

### 避免引用自己（[2:47:30][]）

目前还有一个问题，在 λ 演算中没有全局变量，没有把值「存储」在一个变量中的概念。
而我们在 `FACT` 的定义中使用了 `FACT` 这个名字。

<div class="notice--info" markdown="1">
<i class="fas fa-question-circle"></i>
**我们也用了 `ISZERO` 和 `ONE` 等等名字啊？**

事实上这些名字不需要存储的概念。可以把所有出现了 `ONE` 的地方换成它的定义（相当
于 `:%s/\<ONE\>/(lambda f:lambda x:f(x))/g`）而程序还是会正确运行。而不能换
`FACT` 的原因是它的定义本身就使用了 `FACT` 这个名字。
</div>

如何在实现 `FACT` 的时候不引用它自己的名字？为了方便先用 `fact` 函数来试验，我们
不希望在下面的实现中出现 `fact`：
```python
fact = lambda n: 1 if n == 0 else n * fact(n-1)
#                                     ^^^^ bad
```

一种方式是把 `fact` 作为参数传进去，但是这样还是用了 `fact` 这个名字，而且这个写
法在 `fact` 还没定义的时候就使用了它。
```python
fact = (lambda f: lambda n: 1 if n == 0 else n * f(n-1)) \
       (fact)
#       ^^^^ ?
```

解决方案是直接复制粘贴，而不是把自己的名字传进参数：
```python
fact = (lambda f: lambda n: 1 if n == 0 else n * f(n-1)) \
       (lambda f: lambda n: 1 if n == 0 else n * f(n-1))
```

我们还需要修正一下 `f` 的调用方法（因为需要先传入 `f` 再传入 `n`）。下面是最终的
结果：
```python
fact = (lambda f: lambda n: 1 if n == 0 else n * f(f)(n-1)) \
       (lambda f: lambda n: 1 if n == 0 else n * f(f)(n-1))
#                                                ^^^^
```

```python-repl
>>> fact(4)
24
```

可以把 `fact` 直接换成它的定义：
```python-repl
>>> (lambda f: lambda n: 1 if n == 0 else n * f(f)(n-1)) \
... (lambda f: lambda n: 1 if n == 0 else n * f(f)(n-1))(4)
24
```

### 不动点（[3:00:38][]）

以上的实现有一点不好，它把一个很长的括号重复了两次。我们也可以借助不动点实现
`fact`。

回到之前尝试实现 `fact` 的时候，
```python
fact = (lambda f: lambda n: 1 if n == 0 else n * f(n-1))(fact)
```

如果把中间的部分抽出来
```python
R = lambda f: lambda n: 1 if n == 0 else n * f(n-1)
```

那么 `fact = R(fact)`，即 `fact` 是 `R` 的一个不动点。如果有一个可以计算不动点的
函数，就可以得到 `fact` 了。

假设这个函数存在，设它为 `Y`。那么有 `Y(R) = R(Y(R))`。变形：
```python
Y(R) = (lambda x: R(x))(Y(R))
```
仿照上一节中的做法，把括号中的表达式复制一遍，再修正一下 `x` 的调用方法：
```python
Y(R) = (lambda x: R(x))(lambda x: R(x))
```

```python
Y(R) = (lambda x: R(x(x)))(lambda x: R(x(x)))
```

那么我们就得到了 `Y`
```python
Y = lambda f: (lambda x: f(x(x)))(lambda x: f(x(x)))
```

### Y 组合子（[3:13:20][]）

这里的 `Y` 就是著名的 [Y 组合子][ycomb]（Y combinator）。但是
```python-repl
>>> R = lambda f: lambda n: 1 if n == 0 else n * f(n-1)
>>> fact = Y(R)
RecursionError: maximum recursion depth exceeded
```

要解决这个问题，可以把 `x(x)` 换成 `lambda z: x(x)(z)`，它可以延后 `x` 的求值。
```python
Y = lambda f: (lambda x: f(lambda z: x(x)(z)))(lambda x: f(lambda z: x(x)(z)))
```

```python-repl
>>> R = lambda f: lambda n: 1 if n == 0 else n * f(n-1)
>>> fact = Y(R)
>>> fact(4)
24
```

把 `Y` 用在其它函数上：
```python-repl
>>> fib = Y(lambda f: lambda n: 1 if n <= 2 else f(n-1) + f(n-2))
>>> fib(10)
55
```

实现 `FACT`：
```python-repl
>>> FACT = Y(
...     lambda f: lambda n: L_ISZERO(n) \
...                         (lambda: ONE) \
...                         (lambda: MUL(n)(f(PRED(n))))
... )
>>> a = FACT(FOUR)
>>> toint(a)
24
```

本文中的代码已整理到 [Gist][gist-code] 上。

[ycomb]: https://en.wikipedia.org/wiki/Fixed-point_combinator#Fixed-point_combinators_in_lambda_calculus

## 补充

[惰性求值](#惰性求值23440) 一节中也可以使用另一种方法。参考 [Y 组合子](#y-组合子31320)
一节，用 `lambda x: f(x)` 代替 `f`，这样不需要新定义 lazy 版本的函数。因为万物皆
是函数，所以不需要担心 `f(x)` 因为 `f` 不是函数而出错。

```python
FACT = lambda n: ISZERO(n) \
                 (lambda x: ONE(x)) \
                 (lambda x: MUL(n)(FACT(PRED(n)))(x))
```
```python
FACT = Y(
    lambda f: lambda n: ISZERO(n) \
                        (lambda x: ONE(x)) \
                        (lambda x: MUL(n)(f(PRED(n)))(x))
)
```

## 总结

- 这里推导的 λ 演算没有什么实际用途，没有谁会用这里的 λ 演算写一个现实中使用的程
    序；
- 但是 λ 演算的思想在函数式语言中随处可见，非函数式语言也都在慢慢吸收函数式语言
    中的一些的思想和概念；
- λ 演算就像机器语言一样。现在绝大多数人都在写高级语言，但是高级语言在某种程度上
    是机器语言的抽象，了解一些机器语言或者汇编的知识有助于写出更好，效率更高的代
    码。类似地，了解 λ 演算对理解和运用函数式语言和其它语言中的函数式元素是很有
    益的。

[gist-code]: https://gist.github.com/weirane/62a976baab7f4e56a4b5de596d41177e

[18:27]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=18m27s
[34:45]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=34m45s
[50:02]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=50m02s
[2:03:49]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=2h03m49s
[2:12:15]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=2h12m15s
[2:24:12]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=2h24m12s
[2:30:13]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=2h30m13s
[2:34:40]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=2h34m40s
[2:47:30]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=2h47m30s
[3:00:38]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=3h00m38s
[3:13:20]: https://www.youtube.com/watch?v=pkCLMl0e_0k&t=3h13m20s
