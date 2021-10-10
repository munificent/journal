---
title: "New Syntax for Binding Methods in Finch"
categories: code
---

I just checked in a small change to [Finch][] that I think makes the language read
better. There is now [syntactic sugar][] for binding a method to an object.

[finch]: http://finch.stuffwithstuff.com/
[syntactic sugar]: http://en.wikipedia.org/wiki/Syntactic_sugar

When Finch starts up, it runs a "[core][]" Finch script that builds a bunch of the standard objects and environment. It used to have a lot of code that looked like this:

[core]: https://github.com/munificent/finch/blob/master/lib/core.fin

```finch
True addMethod: "not" body: { False }

' Define a for-style loop.
Ether addMethod: "from:to:step:do:" { |start end step block|

  i <- start

  while: { i <= end } do: {
    block call: i
    i <-- i + step
  }
}

' Concatenate two arrays.
Array prototype addMethod: "++" body: { |right|
  result <- []

  self each: {|e| result add: e }
  right each: {|e| result add: e }

  result
}
```

The change is a new "bind" expression using `::`. This gets rid of the
explicit calls to `addMethod:body:` and replaces them with this:

```finch
True :: not { False }

' Define a for-style loop.
Ether :: from: start to: end step: step do: block {
  i <- start

  while: { i <= end } do: {
    block call: i
    i <-- i + step
  }
}

' Concatenate two arrays.
Array prototype :: ++ right {
  result <- []

  self each: {|e| result add: e }
  right each: {|e| result add: e }

  result
}
```

It's a little shorter and cleaner, but what I really like is that it lets the
parser validate your method signature a bit. Where `addMethod:body:` takes any
string as a method name, this ensures that your method name is something the
parser won't choke on.

It also ensures you have a single argument for an operator (`self` is the
other, of course), or an argument for each keyword for a keyword message.

I should take this opportunity to point out that I'm also starting to get some
[documentation](http://finch.stuffwithstuff.com/) online too. This and the rest of Finch's expression syntax is now [fully documented](http://finch.stuffwithstuff.com/expressions.html). Almost like a real programming language!
