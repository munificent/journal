---
title: "One and Only One"
categories: code language magpie
---

My little language [Magpie][] has a feature that may at first seem really
limiting: *all functions take exactly one argument and return one value, no
more, no less.* I'll try to explain why I made that choice, and some of the
surprising benefits of it.

[magpie]: https://magpie-lang.org/

It feels weird explaining a programming language that literally no one on Earth
is using, but my hope is that in the future people *will* be using Magpie, and
this might come in handy. At the very least, it'll help me remember where I'm
at.

First off, a quick primer in Magpie syntax. Here's a function to square a
number:

```magpie1
Square (n Int -> Int) n * n
```

The name comes first, followed by the type signature in parentheses. To the left
of the `->` is the argument, to the right is the return type. The body of the
function is the single expression `n * n`. Like Ruby and most functional
languages, returning is implicit: a function returns the result of evaluating
its body.

You can call it like this:

```magpie1
Square 3 // Returns 9.
```

Unlike C and other languages, function arguments aren't put inside
parentheses.

## So what if I want to pass in multiple args?

That's easy. Here's a function to multiply three numbers:

```magpie1
Mult (a Int, b Int, c Int -> Int) a * b * c
```

You can call it like:

```magpie1
Mult (2, 3, 4) // Returns 24.
```

## Hey! I thought you said functions always take one argument!

They do, they do. However, Magpie also supports [tuples][]. A tuple lets you
make a single value by combining others together. In Magpie, tuples are created
using the comma operator:

[tuples]: http://en.wikipedia.org/wiki/Tuple

```magpie1
(1, 2)             // A tuple of two Int fields.
(2, true, "three") // A tuple of three fields of different type.
```

(They are also placed inside parentheses, but you can more or less ignore that.
It's more for precedence reasons than anything else. The comma is where the
magic is.)

So, when you see a call like `Mult (2, 3, 4)` what you're really seeing is
calling `Mult` with a single argument, the tuple `(2, 3, 4)`.

## Are you just playing semantics?

No, this isn't just a semantic trick. `Mult` really does take a single value.
I'll prove it:

```magpie1
// Create a local variable and assign a tuple to it.
def arg <- (2, 3, 4)

// Pass the single argument to the function.
Mult arg
```

This is perfectly legit in Magpie and doesn't require function overloading or
anything. In fact, this is kind of useful. When you start playing with function
references (i.e. callbacks), it's really convenient to be able to pass around
arguments to functions without needing to distinguish between how many arguments
it takes: it always takes one.

## Neat trick. What about functions with no arguments?

That actually uses tuples too, sort of. You can make a tuple out of any number
of values, including one and zero. A single value *is* a one-value tuple (a
monuple?). But you can also have a tuple with *no* values, strange as that
sounds. There's exactly one of them. (How could there be different ones?) It's
called "Unit", and looks like `()`. So if you had a function like this:

```magpie1
SayHi (->) Print "hi!"
```

You could call it like this:

```magpie1
SayHi () // Prints "hi".
```

That's a bit tedious, though, so in most cases you can omit the `()` and Magpie
will infer it:

```magpie1
SayHi // Prints "hi".
```

## What about returns? I don't see `Print` returning anything.

Sure, it is. Just like Unit can be omitted as an argument, it's also omitted as
a return. `Print` returns `()` every time it's called. Since a function returns
the result of evaluating its body, that means `SayHi` also returns `()`.

## What's the point?

Unit gives us the ability to make everything in Magpie an expression. Since you
can return Unit like a value, Magpie doesn't need to make a distinction between
*expressions* (which return things) and *statements* (which don't). This means
that things like flow control can be regular expressions in Magpie. For example:

```magpie1
Square (if 1 < 2 then 3 else 4)
```

This calls the `Square` function and passes in 3. We can do this because
`if/then/else` is a regular expression and can be used anywhere.

So having "nothing" be a returnable value lets us make the language a lot more
flexible.

## You still forgot one case...

And, of course, this also means you can return *multiple* values, just like
you can in Python or Lua:

```magpie1
Swap (a Int, b Int -> (Int, Int)) (b, a)

Swap (1, 2) // returns (2, 1)
```

So, in the end, it isn't much of a limitation at all.
