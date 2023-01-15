---
title: "Type Checking If Expressions"
categories: code language
---
I have this hobby project I've been hacking on for several years. It's a fantasy
console, very much inspired by the delightful [PICO-8][]. Like PICO-8, my
console has its own built-in scripting language. Because I'm me, I of course
took the opportunity to design an entirely new language.

[pico-8]: https://www.lexaloffle.com/pico-8.php

My goal for the project is a fun way to build small-ish 2D games. I want its
scripting language to be expressive enough to be joyful, but small enough that
you can learn the whole language and never need to consult a reference manual
after that. My dream is a goofy little pixellated IDE where you can get lost in
your own flow state and just make shit without having to periodically hit
StackOverflow and then get distracted by the wonders/horrors of the Internet.

I don't know if I'll ever pull this off or the language will ever see the light of day, but it's a fun therapeutic thing for me to noodle on.

## A dynamically typed scripting language

To make a language that fits in your head (or at least my head, whose working
space seems to get smaller every year), I needed to jettison as many feature as
I could. My experience across a range of hobby and [not-so-hobby][dart]
languages is that static types add roughly an order of magnitude of complexity,
so types were one of the first things to go. Like most scripting languages, I
made mine dynamically typed.

[dart]: https://dart.dev/

Here's an example:

```vgs
def onTick()
  var d = 0
  if buttonHeld(2) then d = d - 1 end
  if buttonHeld(3) then d = d + 1 end

  if d != 0 then
    h = h + d
  else if h > 0 then
    h = h - 0.5
  else if h < 0 then
    h = h + 0.5
  end

  if h < -3.0 then h = -3.0 end
  if h > 3.0 then h = 3.0 end
  x = x + h

  if y < 200 then
    v = v + 0.8
  end
  y = y + v
  if y > 200 then
    y = 200
    v = 0
  end

  if buttonPressed(0) then
    if y == 200 then
      playSequence()
      v = -10.0
    end
  end
end
```

Another simplification I made is to eliminate the distinction between statements
and expressions. As in Ruby, Kotlin, and most functional languages, everything
is an expression. The previous chained `if` could be written in a more
explicitly expression-y style like:

```vgs
h = h + if d != 0 then
  d
else if h > 0 then
  -0.5
else if h < 0 then
  0.5
end
```

Unifying statements and expressions means the language doesn't need a separate
`if` statement and conditional expression. Also, I don't know, I just like
expression-oriented languages.

## An imperative language

Even though the language is expression-oriented, it's not explicitly
*functional*. Functional languages are close to my heart, but this is a game
scripting language. A game world is basically a big ball of incrementally
updated mutable state. For the kind of programs and user experience I have in
mind, I think an imperative, procedural style is easy to learn, and fun to
program in. I want users thinking about their game, not, like, monads and
persistent data structures.

So while everything is an expression in my language, it doesn't at all shy away
from side effects and imperative control flow. Variables are assignable. Fields
are settable. There are loops and breaks and early returns. All of those are as
natural and idiomatic as they are in C++, JavaScript, C#, or any of the other
languages that the majority of the world's code is written in.

## Handmade Seattle

Last fall, I attended the wonderful [Handmade Seattle][] conference. I had a
particularly inspiring conversation with [Devine Lu Linvega][devine] about their
tiny [uxn][] VM. They had this idea to build the smallest possible system and
programming language for their own use. Then they rebuilt their own personal
tools -- text editor, music stuff, etc. -- using that.

[handmade seattle]: https://handmade-seattle.com/
[devine]: https://wiki.xxiivv.com/site/home.html
[uxn]: https://wiki.xxiivv.com/site/uxn.html

Now, UXN is *really* minimal. I get a certain satisfaction from programming in
assembly, but it's not the language I would want to use for my own joy. But it
did make me rethink the scripting language for my fantasy console. I picked
dynamic types because that made the language smaller and I figured it would be a
good fit for my (entirely hypothetical at this point) users.

But is it what *I'd* want to use to make little 2D videogames? The game I've
spent the most time hacking on is my also-perennially-incomplete roguelike
[Hauberk][]. I've rewritten it several times, but every incarnation has been in
a statically typed language: C++, C#, Java, and now Dart.

[hauberk]: https://github.com/munificent/hauberk

My most pleasurable time spent working on Hauberk is when I'm refactoring and
the type system guides me to what's left to clean up. I just really like working
with types. (It's OK if you don't. As our Burger Sovereign says, have it your
way.)

After talking to Devine, I realized that if I was making this fantasy console
*for me personally*, its language would be typed. So over the past few weeks,
I've been sketching out a statically typed variant of my console's scripting
language. I don't know if it will really come together, but I thought maybe it
would be fun to write about the exploration.

## Type checking `if` expressions

I slapped together a new prototype interpreter for my language. (The main
implementation is a bytecode VM in C++, which is pretty fast but not exactly
easy to hack on.) Then I dutifully started adding a type checking pass to it.
One of the first challenges I hit is how to type check `if` expressions.

As the title up there implies, that's what this post is really about. Because it
turns out that having `if` be an expression while also fully embracing an
imperative style gets a little weird when it comes to type checking.

I'll walk through a bunch of examples and build up to the type checking rules I
have settled on (so far, at least). We'll start simple:

```vgs
var love = if isFriday then "in love" else "not in love" end
```

We need a type for the `if` expression so that we can infer a type for the
variable `love`. In this case, the type is obviously String since both the then
and else branches evaluate to strings.

So the basic rule we'll start with is: **An `if` expression's type is the type
of the branches.**

## Different branch types

But what if they don't have the same type? What about:

```vgs
var love = if isFriday then "in love" else 0 end
```

Here, `love` could end up being initialized to either a `String` or an `Int`.
Now what type do we choose? [Crystal's answer][crystal] is `String | Int`. Union
types are cool but definitely too complex for the language I'm trying to make.

In Kotlin, which is also typed and expression-oriented, the answer is,
apparently, `{Comparable<CapturedType(*)> & java.io.Serializable}`. Which I have
to say does not seem *super* helpful.

[crystal]: https://crystal-lang.org/reference/1.7/syntax_and_semantics/if.html

I assume that the compiler goes looking for a shared supertype of the two branch
types, String and Int. Since String and Int both happen to implement Comparable
(and I guess some serialization interface), you get that as the common
supertype.

In object-oriented languages with subtyping and where the type hierarchy forms a
[lattice][], this common supertype is the least upper bound, and it's a natural
answer to the problem. It shows up in other languages when type-checking
conditional `?:` expressions and a few other places.

[lattice]: https://en.wikipedia.org/wiki/Lattice_(order)

It works, but, as we can see in the Kotlin example here, it doesn't always
produce intuitive or useful results. More to the point, one of the *other*
features I jettisoned from my scripting language is subtyping, so LUB is off
the table.

Without subtyping, every type is disjoint: a value of one type is never a value
of any other type too. That means that if the two branches of an `if` have
different types, then there is no possible type I can infer that contains all of
their values. The only other response is to make it a type error.

That's the next rule: **If the branches have different types, it's a compile
error.**

## Imperative ifs and unused values

That rule does work: It's basically SML's rule for `if` expressions. But I want
my scripting language to feel familiar to users programming in an imperative
style. Consider:

```vgs
var daysNotInLove = 0
if isFriday then
  print("in love")
else
  daysNotInLove = 1
end
```

Here, the two branches have different types. The then branch has type String
because in my language, `print()` returns its argument. (That makes it handy for
stuffing some debug printing in the middle of an expression.) The else branch
has type Int because an assignment expression yields the assigned value.

According to the previous rule, this is a type error because we don't know what
type of value the `if` expression evaluates to.

But it doesn't *matter* since the `if`'s value isn't being used anyway. There's
no need for the compiler to yell at you, and code like this turns out to be very
common in practice.

To address this, the type checker takes some of the surrounding context into
account. When an `if` expression appears in a location where its value won't be
used, then it's no longer an error for the branches to have different types. How
complex is tracking that context? Not too bad, actually. There are a handful of
cases:

*   In a block or function body where you have a sequence of expressions, the
    result is the value of the last expression. The values of all of the
    preceding expressions are discarded. So in an expression sequence, all but
    the last expression are in a "value not used" context.

*   Like other expression-oriented languages, functions in my language
    implicitly return the value that the function body expression evaluates to:

    ```vgs
    def three() Int
      print("About to return three...")
      3
    end

    def onInit()
      print(three()) # Prints "About to return three..." then "3".
    end
    ```

    But if a function has no return type (the same as `void` or unit in other
    languages), it doesn't return a value. In that case, even the last
    expression in the body is a "value not used" context.

*   Loop expressions don't produce values, so their body is always a "value not
    used" context. (I'm toying with the idea of allowing `break` expressions to
    yield a value from the loop, but they don't right now.)

*   Whenever an `if` or `match` expression is in a "value not used" context,
    then we push that context into the branches too. Likewise with the
    right-hand side of `and` and `or` logic operators since those are control
    flow expressions to.

That's it. After I came up with this rule, I did some poking around and it seems
like Kotlin does something similar. It frames it by saying that when you use an
`if` "as an expression" then the two branches must have the same type. That's
roughly the distinction I'm making here too: when an `if` appears in a
statement-like position where its value is discarded, then the branches can
disagree.

## Missing else

This rule allows us to support an even more important flavor of `if` expressions
that are common in imperative code: those without `else` clauses. In SML and
some other functional languages, every `if` expression *must* have an `else`
clause because the presumption is that you will be using the value produced by
the expression and you need a value even when the condition is false.

But in imperative code, it's obviously common to have `if`s whose main purpose
is a side effect and where an `else` clause isn't needed. In fact, when I
analyzed a huge corpus of real-world Dart, I found that only about 20% of `if`
statements had `else` branches.

Now that we understand when an `if` expression is in a context where it's value
isn't used, we can allow omitting `else` branches those. The next rule is: **An
`if` expression can can omit the else branch when in a context where its value
isn't used.**

## Exiting branches

We're almost there. It's starting to feel like we really are type-checking an
imperative language, not ML in BASIC's clothing. I coded this up and
successfully wrote some little example programs. It was starting to feel like a
real typed language!

I could stop here, but there's one last bit of type checking logic for `if`
expressions. I haven't decided if it's worth keeping. Consider:

```vgs
def onInit()
  var love = if isFriday then "in love" else return end
end
```

When `isFriday` is true, then this initializes `love` with the string "in love".
When `isFriday` is false, then the `return` exits from the function entirely so
`love` never gets initialized at all. So even though these branches don't
evaluate to the same type, `love` is always initialized with a String. This code
should be fine.

Or, at least, it should be *sound* according to the type system. Whether this is
*good style* is definitely open for debate. I could probably not allow code like
this. But my default stance is to be as permissive as possible without breaking
soundness, and this is a corner where I can be.

The trick is that expressions like `break`, `return`, and `throw` are special. While they are expressions *grammatically*, they don't actually evaluate to values. If you do:

```vgs
var x = return
```

That `x` never gets initialized. A `return` expression always jumps out of the
surrounding code instead of producing a value. Languages that have expressions
which can do control flow model this by giving these expressions a special type
variously called ["bottom", `⊥` ("up tack"), `Never`, `noreturn`, etc][bottom].
This type means "You're never gonna get a value from me."

[bottom]: https://en.wikipedia.org/wiki/Bottom_type

When checking the two branches of an `if` expression, if one branch has that
special type (the compiler calls it "unreachable" right now), then we just use
the type of the other branch for the `if` expression's type. That allows the
above example to work. In the sample code I've written so far, it rarely comes
into play. It's usually more idiomatic to hoist that control flow out of the
`if` entirely. But we can type check it easily, so the language lets you do it.

## The rules altogether

That's where I'm at right now. It took me a few iterations to get to a point
where all the `if` expressions I expected to be able to write in my example
programs actually type checked correctly but it seems pretty stable now. The
rules are:

*   When an `if` expression is in a context where its value is not used, then
    there is no restriction on what types the branches can have and we're done.

*   Otherwise, there must be an `else` branch and:

*   If both branches have type "unreachable" then the `if` expression's type is
    also "unreachable".

*   If one branch has type "unreachable" then the `if` expression's type is the
    type of the other branch.

*   Otherwise, the two branches must have the same type and the type of the `if`
    is that type.
