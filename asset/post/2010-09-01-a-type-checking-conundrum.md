---
title: "A Type Checking Conundrum!"
categories: code language magpie
---

Ever since I decided to mesh the worlds of static and dynamic typing together in
Magpie, I've been wondering when the gears would really grind together and halt.
Today is the day. The issue I'm running into is one of hidden state, both in
closures and in objects. Consider this post a plea for assistance or ideas.

## A quick intro

Just to frame things since you are very likely not at all familiar with
Magpie, here's the salient features of the language:

*   It's a dynamically-typed OOP language like Python or Ruby.

*   You can optionally add type annotations to method parameters or returns.

*   After the top-level of a script is run, but before `main()` is called, it
    statically type checks the script to look for errors based on the
    annotations you've provided.

Here's a simple example:

```magpie
var say(what String ->)
  print(what)
end

say("hey")
```

This program runs fine and does what you expect. Now consider this one:

```magpie
var say(what String ->)
  print(what)
end

say(123)
```

This one actually runs without errors too (and prints "123″ since `print`
converts its argument to a string anyway). That's because the call to `say(123)`
is at the top level, which is run before type checking. If we change it to this:

```magpie
var say(what String ->)
    print(what)
end

var main(->)
    say(123)
end
```

Now we correctly get a error that `say` expects a `String` and is being passed
an `Int`. The interpreter then stops without ever calling `main()`.

## Conundrum!

All that so far is fine and dandy. Now lets consider something a little...
softer:

```magpie
var returnString(-> String)
  var a = 123
  a = "string"
  return a
end
```

This type checks fine too. At the point that we're returning `a`, the type
checker knows its a `String` as expected. But this highlights an important
feature: variables can change their type. That makes sense given that Magpie is
at its core a dynamic language. It also plays nicely with some other features
like [or types][].

[or types]: /2010/08/23/void-null-maybe-and-nothing/

Unfortunately, it's also the heart of the problem. Consider this example:

```magpie
var a = 123

var returnInt(-> Int)
  return a
end

a = "string"
returnInt()
```

The type checker runs through that top-down. First it evaluates `var a = 123`
and records that `a` is defined with the type of `123`: `Int`. Then it verifies
that `returnInt()` returns its declared type (`Int`) in the body of the
function. It's just returning `a`. It's already noted that `a`'s type is `Int`,
so everything looks fine.

Later, it updates the type of `a` to `String` but at that point, the damage is
done. When this program is run, `returnInt()` returns a `String` even though the
type checker didn't notice the error.

In this example, the problem manifests through a closure (accessing a variable
declared outside of a function's scope), but objects can have the exact same
problem. A method's return type may be based on a field, but that field's type
could change at any time.

## Options

So, how should Magpie handle this? Options I can think of are:

1.  **Do some really smart analysis to look at *every* place a field or
    closed-over variable is assigned to and set its type to the union of all of
    those.** That seems like the Right Thing to Do, but I'm pretty sure it's
    undecidable/intractable/impossible given recursion and other circular
    references.

2.  **Do nothing. Change a variable's type at your own risk.** From the static
    type system point of view, that seems... dirty. But Magpie never promises
    perfect type checking, just more than you get from a completely dynamic
    language. It doesn't give type guarantees, just type gentleman's agreements.

    Also, like a dynamic language, Magpie won't completely die if you pass a
    variable of the wrong type to a method, it'll just end up with some "method
    not found" error. In other words, the "wrong" behavior here is no worse than
    every other dynamic language on Earth.

3.  **Don't allow variables to change type.** This is the static language
    solution. If a variable can't change type after initialization, this problem
    vanishes completely. But it feels like a weird thing for a dynamic language
    to do.

## Now what?

Not that anyone but me really cares about Magpie, but if you do care enough to
have a suggestion, I'm all ears. I tried scanning through the literature on
gradual and optional typing, but I didn't see anything that caught my eye. (I
believe [Siek's][gradual] solution is to disallow references to change type.)

[gradual]: http://ecee.colorado.edu/~siek/gradualtyping.html

For now, I'll just default to "do nothing", but if there's a cleaner solution
that can help users catch real type errors before their programs run, that would
be super awesome.
