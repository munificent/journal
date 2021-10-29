---
title: "Wrapping My Head Around Optional Typing"
categories: code language dart
---

<div class="update">
<p><em>Update 2018/02/22:</em> With the release of <a href="https://medium.com/dartlang/announcing-dart-2-80ba01f43b6">Dart 2.0</a>, Dart <a href="https://dart.dev/dart-2">removed optional types</a> in favor of a full static type system with inference.</p>
</div>

One of the really cool parts about being involved with [Dart][] is that I get a
lot of first-hand experience with an optionally-typed language. I've been
[fascinated][] [by][] [optional typing][] for a while, but there are few
opportunities to actually try it out on non-trivial code. With Dart, I get to
use an optionally typed language whose lineage goes right back to [one of the
original wellsprings][strongtalk].

[dart]: http://dart.dev
[fascinated]: /2010/08/31/type-checking-a-dynamic-language/
[by]: /2010/09/01/a-type-checking-conundrum/
[optional typing]: /2010/10/29/bootstrapping-a-type-system/
[strongtalk]: http://www.strongtalk.org/

What I found was that it was surprisingly hard to wrap my head around. I
initially considered it just sort of halfway between dynamic and static typing,
like a 50/50 blend. It turns out, I think, that is more different than that. If
there is a line between dynamic languages and static ones, optionally typed ones
aren't on that line. They float off in their own axis [like imaginary
numbers][i]. In fact, I think they go off in *multiple* axes.

[i]: http://en.wikipedia.org/wiki/Complex_plane

Before I go into how I *think* about them, I should probably lay down the basic
semantics. Here's the super science breakdown on how optional types work in
Dart. If you want a more, uh, professional treatment, you can also check out
[Gilad's less rambling version][unsound].

[unsound]: https://web.archive.org/web/20120113015751/http://www.dartlang.org/articles/optional-types/

## Type annotations are optional

At it's heart, Dart is a dynamically typed language, so you can code without any
annotations:

```dart
sum(a, b) {
  var result = a + b;
  return result;
}
```

Here, you've said that `a`, `b`, and `result` can be any type at all and that's
OK. But you can also choose to provide a type annotation in all of the usual
places -- variable declarations, function parameters, or fields, and return
types. So this is valid too:

```dart
num sum(num a, num b) {
  var result = a + b;
  return result;
}
```

Now we've stated our intent that `a` and `b` hold numbers. We've also said that
`sum()` should return a number. Note that we didn't annotate `result`. It can
still be anything. Dart lets you mix and match untyped and typed code, so here
the result of a `a + b` is assigned to an untyped variable. Likewise, we get the
untyped `result` and use it as the return value for a function with a typed
return.

This mixing and matching is important because it means you can gradually fold
types into your code. You can leave them all off while you're prototyping and
then start filling them in as you've nailed down the design.

### Tools can use them

OK, so you've sprinkled some types through your code. Why bother? What do they
do? The most basic "feature" that, surprisingly, does add value, is that they
help document your code. Other people reading it can see what types you expect
variables to be.

The next step up on the scale of usefulness is that, since they're in the code,
tools like IDEs, compilers, and linters are free to do whatever analysis they
want using them. Dart does two favors for anyone writing an editor for it:

1.  **Types have a built-in declarative syntax.** Unlike JavaScript, Python and
    other dynamic languages, Dart doesn't use an *imperative* syntax for
    defining types. The grammar for classes and interfaces is essentially
    static. That means an editor can figure out all of the methods a type
    supports just by parsing a source file. There's no runtime modifcation or
    monkey-patching that it needs to worry about.

2.  **Variables can have a known type.** If you choose to annotate them (or the
    editor can infer them), then it knows the type of a variable. If it knows
    the type, then thanks to the previous point, it knows what you can do with
    it. Ta-da: auto-complete and refactoring are now possible for a dynamic
    language. It can also do static type checking like you get in most
    statically-typed languages.

### They can be checked at runtime

But tooling is gilding the lily. When you're talking about types, you expect,
you know, a *type checker*. You have that too (at least in the VM -- what types
mean when compiled to JS is another interesting story). When you run in checked
mode, every type annotation gets checked at runtime. It's as if every line of
code like this:

```dart
int i = someFunction();
```

Turns into (more or less, simplifying things a bit) this:

```dart
var _temp = someFunction();
if (_temp is! int) throw 'Type error! Run for your life!';
var i = _temp;
```

You can think of every type annotation as an *expectation*: this thing *should*
be a number here. In checked mode, the VM will constantly validate your
expectations and stop if something doesn't hold.

It's important to note that these checks are done *dynamically*, at runtime.
There isn't a separate static type checking pass. For example, if you have code
like this:

```dart
if (2 == 3) {
  // Should never get here.
  int i = 'not int';
}
```

You won't see a type error here because execution never actually gets inside the
`if` block. You may be rightly wondering why in the hell you'd want to wait
until runtime to find a type error instead of doing it statically. Dart's take
is that you can do both.

Note that we said earlier that tools *can* do static type checking if they want.
What Dart does is *also* give you the option to perform those checks at runtime.
This is actually how most static languages work too. Very few languages are
fully statically sound. Most enforce at least some soundness through runtime
checks. Consider this Java code:

```java
String[] array = new String[5];
Object[] untyped = array;
untyped[2] = 123; // Not a string.
```

Here we're creating an array of strings. Then we assign it to a variable whose
type is an array of objects (i.e. anything). Then we try to stuff something that
isn't a string (but *is* an object) in it.

<div class="update">
<p><em>Update 2011/10/23:</em> I was wrongly using an int array here. Changed it to <code>string[]</code>. I didn't realize only arrays of reference types are covariant in Java.
</p>
</div>

The static type checker won't catch this because [arrays are covariant in
Java][covariant arrays]. That means that to ensure the last line doesn't crash
your VM, it will do a *runtime* check every time you set an element in an array
to make sure it's the right type.

[covariant arrays]: http://c2.com/cgi/wiki?JavaArraysBreakTypeSafety

There's another common case where you skirt around the static checker and rely
on dynamic type tests: casts.

```java
void callback(Object data) {
  // It's my callback, so I know the data is an int.
  int value = (Integer) data;
}
```

There are times when you know more than the type system does and you just
forcibly assert your knowledge. Doing so shouldn't let you just take down the VM
(unlike in C++ where an improper type cast *can* set your house on fire), so
every cast does a runtime check too.

Since Dart lets you mix untyped and typed code, it just embraces this model of
validating at runtime more fully. Doing so has a couple of other advantages:

1.  **You don't have to rely on your type system for security.** Java tries to
    rely on the type system and bytecode verification to ensure that code can't
    maliciously break the security guarantees of the VM. From what I've heard,
    doing so turned out to be unbelievably complicated.

    Dart, on the other hand, can rely on a much simpler runtime model
    (isolates) to ensure security boundaries.

2.  **The type system can be less pessimistic.** Static type systems, by their
    fundamental nature, are pessimistic. Since they don't know what *actual*
    code paths will execute at runtime and which *actual* types a variable will
    have, they err on the side of caution. They report errors for any code that
    *may* run, or any variables that *may* have the wrong type.

    This is good for ensuring real errors don't get missed, but it's a drag when
    it reports false positives. Consider:

        bool contains(List<Object> collection, Object needle) {
          for (final item in collection) {
            if (item == needle) return true;
          }
          return false;
        }

        var numbers = <int>[1, 2, 3, 4];
        print(numbers.contains(2));

    There's a type error here according to most static type systems. We're
    passing a `List<int>` to a function that takes a `List<Object>`, which
    relies on [covariance][], but that isn't statically safe. This `contains`
    function *could* call `collection.add("not an int")` and that would be an
    error.

    However, it *doesn't actually do that*. It's using the collection in a way
    that's perfectly safe with covariance. By loosening the type system, and
    relying on dynamic checks to catch *actual* errors at runtime, we can
    reduce the number of false positives that the type system chokes on.

[covariance]: http://en.wikipedia.org/wiki/Covariance_and_contravariance_%28computer_science%29

### They can be ignored at runtime

This is where things get weird. (Actually, if you're a type system person,
they're already weird because covariant generics are wrong wrong wrong.) I've
been talking about checked mode, but there's another mode: production mode. In
that mode, the type annotations *completely ignored*. In other words, Dart lets
you run this:

```dart
int i = 'not int';
bool b = 'not a bool either';
num wtf = i + b;
print(wtf); // "not intnot a bool either".
```

This probably seems a little odd.

<img alt="Your type errors will blot out the sun! Then we will code in the shade." src="/image/2011/10/daaart.jpeg" class="framed"/>

Maybe more than a little odd. In production mode, Dart behaves exactly as if it were a dynamically-typed language. Imagine if you decided to write your JavaScript like this (not that anyone would be [crazy enough to do that][closure]):

[closure]: https://github.com/google/closure-compiler/wiki/Annotating-JavaScript-for-the-Closure-Compiler

```javascript
var /* int */ i = 'not int';
var /* bool */ b = 'not a bool either';
var /* num */ wtf = i + b;
print(wtf); // "not intnot a bool either".
```

Unsurprisingly, those comments won't do anything at runtime. That's how Dart runs in production mode.

## How should you think of this?

OK, so what do we have? We have a nice little syntax for jamming type
annotations into your program. If you use them, then tools can take advantage of
that to help you work with your code. Also, in checked mode, the VM will
validate them for you. But in production, they are ignored.

That... doesn't really sound much like a "type system" compared to other
languages. In fact, if you try to think of it as a type system, it's pretty
disappointing. It's more like some type... stuff. Instead of thinking of it in
terms of type systems, I tried to find something else I was familiar with from
other languages that I could map it to. It finally clicked when someone at work
referred to them as *type assertions*.

**Now I get it.**

If you've done C or C++ programming, you've probably used [`assert()`][assert]
or some flavor of it. If not, it looks like this:

[assert]: http://en.wikipedia.org/wiki/Assertion_%28computing%29

```c
float divide(float num, float denom) {
  assert(denom != 0);
  return num / denom;
}
```

That `assert()` call evaluates its argument. If the result is false, then
`assert()` aborts the program and starts ringing the alarm bells. Actually,
that's not entirely true. *If you run the program in debug mode* and the
assertion fails, then it halts.

Most projects have at least two build configurations. "Debug" is what developers
use day in and day out. It has extra diagnostic stuff like symbol table
information for debugging, and also includes all of the assertions. But there is
also usually a "release" mode. This is the build you ship to customers and run
in production. In that mode, the assertions are compiled out. They are erased
completely. Sound familiar?

Now why on Earth would you want to disable your asserts in release mode? Isn't
that like wearing your life jacket to boating class and then taking it off when
you go out on the water?

It turns out that removing your asserts at runtime actually has a few advantages:

1.  **It's faster.** All of those assert conditions have to be executed and
    checked at runtime. That can add a lot of runtime overhead. When I used to
    be a game developer, debug builds of games typically ran much slower than
    release. (Playing a videogame running at four frames a second is a strange
    skill to cultivate.)

2.  **The app should try its hardest to continue.** Once your program is in the
    customer's hands, you *really* don't want it to crash. It's possible that
    some of those assertions are bogus and the app will still actually work if
    you run past a failed one. Sure, in rehearsal you stop on the first wrong
    note, but once the audience sits down and the curtains go up, *the show must
    go on.*

3.  **The user can't handle a failed assertion anyway.** If you *were* to let
    the asserts remain in release mode, what do you do when one fails? In
    debug mode, a failed assertion will do all sorts of helpful stuff like
    show a stack trace with line numbers, maybe do a heap dump. All that is
    really helpful... if you're a programmer on the project.

    If you're just Joan User, that's utterly useless (and may be a security
    hazard!) The best the app could hope to do is show a sad face error message
    and restart. There's nothing an end user can productively do with the
    knowledge that a bug in the code itself has manifested.

So what Dart does is apply that reasoning to the type assertions themselves. You
really can think of type annotations in Dart as being syntactic sugar for this:

```dart
var _temp = someFunction();
assert(_temp is int);
var i = _temp;
```

As a developer, you run in checked mode and Dart gives you much of the benefit
of a typed language. All those asserts help you enforce API requirements just
like they do in C++ or other languages. In fact, you could adopt this style in
JavaScript if you really wanted to.

By baking a certain flavor of assert (asserting on type) into the *syntax* of
the language itself, Dart makes it easy for tools to parse those type
annotations too and provide more contextual information about your code.

## Is it a type system?

The term "type system" carries a lot of implied assumptions and meaning with it.
If you take what you know about type systems and look at Dart through that lens,
you will be disappointed, infuriated, and/or confused.

This doesn't mean Dart's approach to types is a *bad feature*, just that it's
not what you think it is. Meatloaf is a pretty terrible dessert, but it's a fine
entrée. If you don't think about type systems and just ask yourself "is the set
of features that Dart provides helpful in writing code?", I think the answer is
"yes". It's just not helpful in exactly the same way that type systems in other
languages help.

I don't really think of Dart as having a *type system.* I think of it as having
*type requirements*. I can use types to define what the APIs of my library
expect (preconditions) and promise to deliver (postconditions). At runtime,
those assertions will be validated so I can figure out which side is failing to
live up to its obligation.

I find that's a pretty handy tool to have, and it's really nice to get that
without having to give up the simplicity and flexibility of a dynamically typed
language.
