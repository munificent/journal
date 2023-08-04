---
title: "What Color is Your Function?"
categories: code language dart lua go javascript
---

I don't know about you, but nothing gets me going in the morning quite like a
good old fashioned programming language rant. It stirs the blood to see someone
skewer one of those ["blub"][blub] languages the plebians use, muddling through
their day with it between furtive visits to StackOverflow.

[blub]: http://www.paulgraham.com/avg.html

(Meanwhile, you and I, only use the most enlightened of languages. Chisel-sharp
tools designed for the manicured hands of expert craftspersons such as
ourselves.)

Of course, as the *author* of said screed, I run a risk. The language I mock
could be one you like! Without realizing it, I could have let the rabble into my
blog, pitchforks and torches at the ready, and my fool-hardy pamphlet could draw
their ire!

To protect myself from the heat of those flames, and to avoid offending your
possibly delicate sensibilities, instead, I'll rant about a language I just made
up. A strawman whose sole purpose is to be set aflame.

I know, this seems pointless right? Trust me, by the end, we'll see whose face
(or faces!) have been painted on his straw noggin.

## A new language

Learning an entire new (crappy) language just for a blog post is a tall order,
so let's say it's mostly similar to one you and I already know. We'll say it has
syntax sorta like JS. Curly braces and semicolons. `if`, `while`, etc. The
*lingua franca* of the programming grotto.

I'm picking JS *not* because that's what this post is about. It's just that it's
the language you, statistical representation of the average reader, are most
likely to be able grok. Voilà:

```javascript
function thisIsAFunction() {
  return "It's awesome";
}
```

Because our strawman is a *modern* (shitty) language, we also have first-class
functions. So you can make something like this:

```javascript
// Return a list containing all of the elements in collection
// that match predicate.
function filter(collection, predicate) {
  var result = [];
  for (var i = 0; i < collection.length; i++) {
    if (predicate(collection[i])) result.push(collection[i]);
  }
  return result;
}
```

This is one of those *higher-order* functions, and, like the name implies, they
are classy as all get out and super useful. You're probably used to them for
mucking around with collections, but once you internalize the concept, you start
using them damn near everywhere.

Maybe in your testing framework:

```javascript
describe("An apple", function() {
  it("ain't no orange", function() {
    expect("Apple").not.toBe("Orange");
  });
});
```

Or when you need to parse some data:

```javascript
tokens.match(Token.LEFT_BRACKET, function(token) {
  // Parse a list literal...
  tokens.consume(Token.RIGHT_BRACKET);
});
```

So you go to town and write all sorts of awesome reusable libraries and
applications passing around functions, calling functions, returning functions.
Functapalooza.

## What color is your function?

Except wait. Here's where our language gets screwy. It has this one peculiar
feature:

**1. Every function has a color.**

Each function -- anonymous callback or regular named one -- is either red or
blue. Instead of a single `function` keyword, there are two:

```javascript
blue_function doSomethingAzure() {
  // This is a blue function...
}

red_function doSomethingCarnelian() {
  // This is a red function...
}
```

There are *no* colorless functions in the language. Want to make a function?
Gotta pick a color. Them's the rules. And, actually, there are a couple more
rules you have to follow too:

**2. The way you call a function depends on its color.**

Imagine a "blue call" syntax and a "red call" syntax. Something like:

```javascript
doSomethingAzure()blue;
doSomethingCarnelian()red;
```

When calling a function, you need to use the call that corresponds to its color.
If you get it wrong&mdash;call a red function with `blue` after the parentheses
or vice versa&mdash;it does something bad. Dredge up some long-forgotten
nightmare from your childhood like a clown with snakes for arms hiding under
your bed. That jumps out of your monitor and sucks out your vitreous humour.

Annoying rule, right? Oh, and one more:

**3. You can only call a red function from within another red function.**

You *can* call a blue function from within a red one. This is kosher:

```javascript
red_function doSomethingCarnelian() {
  doSomethingAzure()blue;
}
```

But you can't go the other way. If you try to do this:

```javascript
blue_function doSomethingAzure() {
  doSomethingCarnelian()red;
}
```

Well, you're gonna get a visit from old Spidermouth the Night Clown.

This makes writing higher-order functions like our `filter()` example trickier.
We have to pick a color for *it* and that affects the colors of the functions
we're allowed to pass to it. The obvious solution is to make `filter()` red.
That way, it can take either red or blue functions and call them. But then we
run into the next itchy spot in the hairshirt that is this language:

**4. Red functions are more painful to call.**

For now, I won't precisely define "painful", but just imagine that the
programmer has to jump through some kind of annoying hoops every time they call
a red function. Maybe it's really verbose, or maybe you can't do it inside
certain kinds of statements. Maybe you can only call them on line numbers that
are prime.

What matters is that if you decide to make a function red, everyone using your
API will want to spit in your coffee and/or deposit some even less savory fluids
in it.

The obvious solution then is to *never* use red functions. Just make everything
blue and you're back to the sane world where all functions have the same color,
which is equivalent to them all having no color, which is equivalent to our
language not being entirely stupid.

Alas, the sadistic language designers -- and we all know all programming
language designers are sadists, don't we? -- jabbed one final thorn in our side:

**5. Some core library functions are red.**

There are some functions built in to the platform, functions that we *need* to
use, that we are unable to write ourselves, that only come in red. At this
point, a reasonable person might think the language hates us.

## It's functional programming's fault!

You might be thinking that the problem here is we're trying to use higher-order
functions. If we just stop flouncing around in all of that functional frippery
and write normal blue collar first-order functions like God intended, we'd
spare ourselves all the heartache.

If we only call blue functions, make our function blue. Otherwise, make it red.
As long as we never make functions that accept functions, we don't have to worry
about trying to be "polymorphic over function color" ("polychromatic"?) or any
nonsense like that.

But, alas, higher order functions are just one example. This problem is
pervasive any time we want to break our program down into separate functions
that get reused.

For example, let's say we have a nice little blob of code that, I don't know,
implements Dijkstra's algorithm over a graph representing how much your social
network are crushing on each other. (I spent way too long trying to decide what
such a result would even represent. Transitive undesirability?)

Later, you end up needing to use this same blob of code somewhere else. You do
the natural thing and hoist it out into a separate function. You call it from
the old place and your new code that uses it. But what color should it be?
Obviously, you'll make it blue if you can, but what if it uses one of those
nasty red-only core library functions?

What if the new place you want to call it is blue? You'll have to turn it red.
Then you'll have to turn the function that calls *it* red. Ugh. No matter what,
you'll have to think about color constantly. It will be the sand in your
swimsuit on the beach vacation of development.

## A colorful allegory

Of course, I'm not really talking about color here, am I? It's an allegory, a
literary trick. The Sneetches isn't about stars on bellies, it's about race. By
now, you may have an inkling of what color actually represents. If not, here's
the big reveal:

**Red functions are asynchronous ones.**

If you're programming in JavaScript on Node.js, everytime you define a function
that "returns" a value by invoking a callback, you just made a red function.
Look back at that list of rules and see how my metaphor stacks up:

1.  Synchronous functions return values, async ones do not and instead invoke
    callbacks.

2.  Synchronous functions give their result as a return value, async functions
    give it by invoking a callback you pass to it.

3.  You can't call an async function from a synchronous one because you won't be
    able to determine the result until the async one completes later.

4.  Async functions don't compose in expressions because of the callbacks, have
    different error-handling, and can't be used with `try/catch` or inside a lot
    of other control flow statements.

5.  Node's whole shtick is that the core libs are all asynchronous. (Though they
    did dial that back and start adding `___Sync()` versions of a lot of
    things.)

When people talk about "callback hell" they're talking about how annoying it is
to have red functions in their language. When they create [4,089 libraries for
doing asynchronous programming][async], they're trying to cope at the library
level with a problem that the language foisted onto them.

<div class="update">
<p><em>Update 2021/12/03:</em> 15,118 async libraries as of today.</p>
</div>

[async]: https://www.npmjs.com/search?q=async

## I promise the future is better

People in the Node community have realized that callbacks are a pain for a long
time, and have looked around for solutions. One technique that gets a bunch of
people excited is [*promises*][promises], which you may also know by their
rapper name "futures".

[promises]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise

These are sort of a jacked up wrapper around a callback and an error handler. If
you think of passing a callback and errorback to a function as a *concept*, a
promise is basically a *reification* of that idea. It's a first-class object
that represents an asynchronous operation.

I just jammed a bunch of fancy PL language in that paragraph so it probably
sounds like a sweet deal, but it's basically snake oil. Promises *do* make async
code a little easier to write. They compose a bit better, so rule #4 isn't
*quite* so onerous.

But, honestly, it's like the difference between being punched in the gut versus
being punched in the privates. Technically less painful, yes, but I don't think
anyone should really get thrilled about the value proposition.

You still can't use them with exception handling or other control flow
statements. You still can't call a function that returns a future from
synchronous code. (Well, you *can*, but if you do, the person who later
maintains your code will invent a time machine, travel back in time to the
moment that you did this and stab you in the face with a #2 pencil.)

You've still divided your entire world into asynchronous and synchronous halves
and all of the misery that entails. So, even if your language features promises
or futures, its face looks an awful lot like the one on my strawman.

(Yes, that means even [Dart][], the language I work on. That's why I'm so
excited some of the team are [experimenting with other concurrency
models][fletch].)

[dart]: http://dartlang.org
[fletch]: https://github.com/dart-lang/fletch

## I'm awaiting a solution

C# programmers are probably feeling pretty smug right now (a condition they've
increasingly fallen prey to as Hejlsberg and company have piled sweet feature
after sweet feature into the language). In C#, you can use [the `await`
keyword](https://msdn.microsoft.com/en-us/library/hh191443.aspx) to invoke an
asynchronous function.

This lets you make asynchronous calls just as easily as you can synchronous
ones, with the tiny addition of a cute little keyword. You can nest `await`
calls in expressions, use them in exception handling code, stuff them inside
control flow. Go nuts. Make it rain `await` calls like a they're dollars in the
advance you got for your new rap album.

Async-await *is* nice, which is why we're adding it to Dart. It makes it a lot
easier to *write* asynchronous code. You know a "but" is coming. It is.
*But...* you still have divided the world in two. Those async functions are
easier to write, but *they're still async functions*.

You've still got two colors. Async-await solves annoying rule #4: they make red
functions not much worse to call than blue ones. But all of the other rules are
still there:

1. Synchronous functions return values, async ones return `Task<T>` (or
   `Future<T>` in Dart) wrappers around the value.

2. Sync functions are just called, async ones need an `await`.

3. If you call an async function you've got this wrapper object when you
   actually want the `T`. You can't unwrap it unless you make *your* function
   async and await it. (But see below.)

4. Aside from a liberal garnish of `await`, we did at least fix this.

5. C#'s core library is actually older than async so I guess they never had
   this problem.

It *is* better. I will take async-await over bare callbacks or futures any day
of the week. But we're lying to ourselves if we think all of our troubles are
gone. As soon as you start trying to write higher-order functions, or reuse
code, you're right back to realizing color is still there, bleeding all over
your codebase.

## What language *isn't* colored?

So JS, Dart, C#, and Python have this problem. CoffeeScript and most other
languages that compile to JS do too (which is why Dart inherited it). I *think*
even ClojureScript has this issue even though they've tried really hard to push
against it with their [core.async][core async] stuff.

[core async]: https://github.com/clojure/core.async

Wanna know one that doesn't? *Java.* I know right? How often do you get to say,
"Yeah, Java is the one that really does this right."? But there you go. In
their defense, they are actively trying to correct this oversight by moving to
futures and async IO. It's like a race to the bottom.

C# also actually *can* avoid this problem too. They opted *in* to having color.
Before they added async-await and all of the `Task<T>` stuff, you just used
regular sync API calls. Three more languages that don't have this problem: Go,
Lua, and Ruby.

Any guess what they have in common?

*Threads.* Or, more precisely: *multiple independent callstacks that [can be
switched between][iter]*. It isn't strictly necessary for them to be operating
system threads. Goroutines in Go, coroutines in Lua, and fibers in Ruby are
perfectly adequate.

[iter]: /2013/01/13/iteration-inside-and-out/

(That's why C# has that little caveat. You can avoid the pain of async in C# by
using threads.)

## Remembrance of operations past

The fundamental problem is "How do you pick up where you left off when an
operation completes"? You've built up some big callstack and then you call some
IO operation. For performance, that operation uses the operating system's
underlying asynchronous API. You *cannot* wait for it to complete because it
won't. You have to return all the way back to your language's event loop and
give the OS some time to spin before it will be done.

Once operation completes, you need to resume what you were doing. The usual way
a language "remembers where it is" is the *callstack*. That tracks all of the
functions that are currently being invoked and where the instruction pointer is
in each one.

But to do async IO, you have to unwind and discard the entire C callstack. Kind
of a Catch-22. You can do super fast IO, you just can't do anything with the
result! Every language that has async IO in its core -- or in the case of JS,
the browser's event loop -- copes with this in some way.

Node with its ever-marching-to-the-right callbacks stuffs all of those
callframes in closures. When you do:

```javascript
function makeSundae(callback) {
  scoopIceCream(function (iceCream) {
    warmUpCaramel(function (caramel) {
      callback(pourOnIceCream(iceCream, caramel));
    });
  });
}
```

Each of those function expressions *closes* over all of its surrounding
context. That moves parameters like `iceCream` and `caramel` off the callstack
and onto the heap. When the outer function returns and the callstack is
trashed, it's cool. That data is still floating around the heap.

The problem is you have to *manually* reify every damn one of these steps.
There's actually a name for this transformation: [*continuation-passing
style*][cps]. It was invented by language hackers in the 70s as an intermediate
representation to use in the internals of their compilers. It's a really bizarro
way to represent code that happens to make some compiler optimizations easier to
do.

No one ever for a second thought that a programmer would *write actual code
like that*. And then Node came along and all of the sudden here we are
pretending to be compiler backends. Where did we go wrong?

[cps]: http://en.wikipedia.org/wiki/Continuation-passing_style

Note that promises and futures don't actually buy you anything, either. If
you've used them, you know you're still hand-creating giant piles of function
literals. You're just passing them to `.then()` instead of to the asynchronous
function itself.

## Awaiting a generated solution

Async-await *does* help. If you peel back your compiler's skull and see what
it's doing when it hits an `await` call you'd see it actually doing the
CPS-transform. That's *why* you need to use `await` in C#: it's a clue to the
compiler to say, "break the function in half here". Everything after the `await`
gets hoisted into a new function that the compiler synthesizes on your behalf.

This is why async-await didn't need any *runtime* support in the .NET
framework. The compiler compiles it away to a series of chained closures that
it can already handle. (Interestingly, closures themselves also don't need
runtime support. *They* get compiled to anonymous classes. In C#, closures
really *are* a [poor man's objects][poor].)

[poor]: http://c2.com/cgi/wiki?ClosuresAndObjectsAreEquivalent

You might be wondering when I'm going to bring up generators. Does your
language have a `yield` keyword? Then it can do something very similar.

(In fact, I *believe* generators and async-await are isomorphic. I've got a bit
of code floating around in some dark corner of my hard disc that implements a
generator-style game loop using only async-await.)

Where was I? Oh, right. So with callbacks, promises, async-await, and
generators, you ultimately end up taking your asynchronous function and
smearing it out into a bunch of closures that live over in the heap.

Your function passes the outermost one into the runtime. When the event loop or
IO operation is done, it invokes that function and you pick up where you left
off. But that means everything above you *also* has to return. You still have
to unwind the *whole* stack.

This is where the "red functions can only be called by red functions" rule
comes from. You have to closurify the entire callstack all the way back to
`main()` or the event handler.

## Reified callstacks

But if you have threads (green- or OS-level), you don't need to do that. You
can just suspend the entire thread and hop straight back to the OS or event
loop *without having to return from all of those functions*.

Go is the language that does this most beautifully in my opinion. As soon as
you do any IO operation, it just parks that goroutine and resumes any other
ones that aren't blocked on IO.

If you look at the IO operations in the standard library, they seem
synchronous. In other words, they just do work and then return a result when
they are done. But it's not that they're synchronous in the sense that it would
mean in JavaScript. Other Go code can run while one of these operations is
pending. It's that Go has *eliminated the distinction between synchronous and
asynchronous code*.

Concurrency in Go is a facet of how *you* choose to model your program, and not
a color seared into each function in the standard library. This means all of
the pain of the five rules I mentioned above is completely and totally
eliminated.

So, the next time you start telling me about some new hot language and how
awesome its concurrency story is because it has asynchronous APIs, now you'll
know why I start grinding my teeth. Because it means you're right back to red
functions and blue ones.
