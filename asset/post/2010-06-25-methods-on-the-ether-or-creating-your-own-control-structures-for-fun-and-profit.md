---
title: "Methods on the Ether: Or Creating Your Own Control Structures for Fun and Profit"
categories: code finch language
---

One of my favorite things about [Lisp][] and [Smalltalk][] is that they don't
have special syntax for control structures. Sometimes the most elegant way to
express a solution to a problem requires a [unique flow control construct][dsl].
Beyond that, there's something appealingly minimal about a language that doesn't
have a fixed set of hardcoded magic keywords.

[lisp]: http://en.wikipedia.org/wiki/Lisp_%28programming_language%29
[smalltalk]: http://en.wikipedia.org/wiki/Smalltalk
[dsl]: http://en.wikipedia.org/wiki/Domain-specific_language

Unfortunately, languages like Lisp and Smalltalk that have this feature
typically marry it to a syntax that looks strange to the large number of the
world's programmers who were weaned on C and other curly brace languages. To
explore a couple of a ideas, I started tinkering on a little interpreted
language called [Finch][]. Here, I'll try to explain how I addressed the
build-your-own-control-flow problem while (I hope) keeping the syntax relatively
readable to most people.

[finch]: https://finch.stuffwithstuff.com/

## A Smalltalk primer

Finch is inspired directly by Smalltalk (by way of [Self][]), so it'll help to
review how Smalltalk handles control flow before we get to Finch. If you know
Smalltalk, feel free to skip this.

[self]: http://en.wikipedia.org/wiki/Self_%28programming_language%29

Let's consider a fairly boring chunk of code in a curly brace language:

```c
if (numWeasels > numCakes) {
  print("Not enough cakes!");
} else {
  for (int i = 0; i < numWeasels; i++) {
    print("A weasel eats a cake!");
  }
}
```

We've got three keywords there: `if`, `else`, and `for`. Here's how that code
would look in Smalltalk:

```smalltalk
numWeasels > numCakes ifTrue: [
  'Not enough cakes!' print
] ifFalse: [
  i := 0.
  [ i < numWeasels ] whileTrue: [
    'A weasel eats a cake!' print.
    i := i + 1
  ]
]
```

Whoa, what? First, we'll gloss over the basic stuff we don't care about here:
`.` is used to separate statements, `:=` is for assignment, and the function
(method) comes after the argument instead of before.

The control flow part of that code is this:

```smalltalk
... ifTrue: [
  ...
] ifFalse: [
  [ ... ] whileTrue: [ ... ]
]
```

You may think that all we've done is simple replacement: curlies become square
brackets, `if` becomes `ifTrue:`, etc. Not so fast. `ifTrue:`, `IfFalse:`, and
`whileTrue:` aren't reserved words in Smalltalk. They aren't special at all, in
fact -- you could implement them in Smalltalk itself if you wanted to. In fact,
let's do that.

An if/then construct is basically a "procedure" that takes three arguments: a
Boolean condition to check, a block of code to execute if the condition is true
and (optionally) a block to execute if the condition is false. If you were to
declare a "function" for if/then in C, it would look like this:

```c
void ifThen(bool condition, Code ifTrue, Code ifFalse);
```

The problem, of course, is that Code isn't a type in C: there's no easy way to
pass around a reference to a chunk of code outside of function pointers.
Smalltalk doesn't have that problem -- it has *blocks*. That's what the square
brackets are doing in the original example. They create a block -- a chunk of
unevaluated code encapsulated as an object. If you do this:

```smalltalk
[ 'hi' print ]
```

It doesn't print "hi". Instead, it creates an object representing that chunk of
code. If you then *call* the block by sending it a `value` message:

```smalltalk
[ 'hi' print ] value
```

*Then* it prints the string. Of course, you don't have to call a block
immediately, or at all. You can store it in a variable, pass it to another
function, call it repeatedly, etc.

The other piece of syntax to understand is Smalltalk's notion of a "keyword". In
most languages, keywords are reserved words built into the language. In
Smalltalk, keywords are just another kind of user-defined function like regular
method calls or operators. Keywords are identified by ending the name with a
colon (`:`). They're used in Smalltalk to send messages to objects with multiple
arguments. Where in C you would do `AddKeyValue(dictionary, "key", "value")`, in
Smalltalk you'd say `dictionary addKey: "key" value: "value"`. In that example,
the name of the method is `addKey:value:`.

Now we can understand how the original Smalltalk code works. `numWeasels >
numCakes` is an expression that returns a Boolean value. `ifTrue:ifFalse:` is a
message then sent to that Boolean. It takes two arguments, a "then" block and an
"else" else block. If the Boolean value is true, it evaluates the "then" block,
otherwise it evaluates the "else" block. No special syntax required.

Keywords and blocks are a fantastically powerful system. Blocks may also take
arguments and can access variables declared outside of their scopes (i.e. they
are [closures][]), which means you've got a very simple syntax that lets you
create all sorts of control structures and functional idioms like `map` and
`filter`. It just looks funny.

[closures]: http://en.wikipedia.org/wiki/Closure_%28computer_science%29

## Back to Finch

I wanted Finch to have that power but look less funny. (According to my
definition of "funny", of course. Smalltalkers think their language looks
perfectly normal.) Here's how our example looks in Finch:

```finch
if: numWeasels > numCakes then: {
  write: "Not enough cakes!"
} else: {
  from: 1 to: numWeasels do: {
    write: "A weasel eats a cake!"
  }
}
```

The first minor change is using curlies to define blocks instead of square
brackets. The more interesting change is that `if:then:else:` doesn't seem to
have a receiver -- an object that the method is acting on.

You'll remember in Smalltalk that the condition `numWeasels > numCakes` comes
*before* the `ifTrue:ifFalse` message. That's because `ifTrue:ifFalse` is a
method on Boolean objects.

That's a smart solution for Smalltalk, but it seemed strange to me to see the
condition first. I think most programmers want to see the keyword to
understand what that condition is for before seeing the expression itself.
Hence `if:` comes before `numWeasels > numCakes`.

So how do I square that with the fact that Finch is OOP and every method must
be a message sent to some receiver?

## Enter the Ether

The answer is... through a little parser trick. If the parser encounters a
keyword message before it's encountered a receiver to send that message to (i.e.
it parses `foo: bar` instead of `obj foo: bar` as expected), then it
automatically inserts `Ether` before it. Ether is a special global object that
represents the implicit receiver of keyword messages if the receiver is omitted.
(In some ways, this is similar to how you can omit `this` in most OOP
languages.)

When you call `if:then:else:` in Finch, you're sending that message to Ether,
which is what handles the message. The result, I think, is a syntax as powerful
as Smalltalk, but one that reads more naturally.

At the same time, we haven't given up any of the flexibility of a dynamic OOP
language. Ether is just a normal global object, which means you can add your own
methods to it as you see fit. This lets you create top-level control structures
in Finch that look just like "real" ones.

For example, the `from:to:do:` block we saw earlier is actually written in
Finch. It uses `while:do:` which is the only looping construct explicitly built
into the interpreter. Its definition is:

```finch
Ether :: from: start to: end do: block {
  i <- start
  while: { i <= end } do: {
    block call: i
    i <-- i + 1
  }
}
```
