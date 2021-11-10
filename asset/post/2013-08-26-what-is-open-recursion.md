---
title: What is "Open Recursion"?
categories: code language dart
---

Someone on StackOverflow stumbled onto the strange term "open recursion" and
[asked what it meant][so]. Since most of the other answers to this online are
pretty opaque, I started writing an answer. But then I accidentally wrote a blog
post.

[so]: http://stackoverflow.com/questions/17803621/why-is-it-called-open-or-closed-recursion

I honestly couldn't remember what it meant either, so I cracked open my copy of
[Types and Programming Languages][tapl] where, I believe, Pierce first
introduces the term. After skimming a bit, I think I've got it. For those who
don't have the book or don't want to wade through PL nerd terminology, I'll try
to translate it to something a little friendlier.

[tapl]: http://www.cis.upenn.edu/~bcpierce/tapl/

First, a bit of context. Pierce is explaining the semantics and types of
object-oriented languages starting from a non-OOP core based on the lambda
calculus and records. He starts the book with the simplest possible
proto-language and then keeps adding extensions to it to build up to the kind of
languages we see today. He coined "open recursion" to refer to the kind of
extensions you need in order to build an object-oriented language from a simpler
language that just has functions (i.e. "lambdas", "closures", or "anonymous
delegates") and records (more or less "object literals" in JS or "maps" in other
languages).

Since not too many people know the lambda calculus, for this scene I will use a
subset of [Dart][] as its stand-in. We'll allow function declarations and maps,
but no actual classes or methods.

[dart]: https://dart.dev

Now the question is, if you were to only have maps of functions, what would you
be missing compared to "real" objects? Pierce's answer is "open recursion".
We'll break that down into the two words, last one first:

## "Recursion"

Say you want to make an "object" that represents a counter. It exposes three
operations:  `increment()`, `get()`, and `set()`. You could make such an object
in our Dart subset like this:

```dart
makeCounter() {
  // Declare the instance state for the "object".
  var count = 0;

  // Declare functions for the "methods". They are closures,
  // so they can access `count`.
  increment() {
    count++;
  }

  get() {
    return count;
  }

  set(value) {
    count = value;
  }

  // Make an "object" as a map of functions.
  return {
    'get': get,
    'set': set,
    'increment': increment
  };
}
```

Great. This works fine. But let's say we wanted to implement `increment()` in
terms of `get()` and `set()`. One common feature of methods is that they can
call each other. Let's try:

```dart
makeCounter() {
  // Declare the instance state for the "object".
  var count = 0;

  // Declare functions for the "methods". They are closures,
  // so they can access count.
  increment() {
    set(get() + 1));
  }

  get() {
    return count;
  }

  set(value) {
    count = value;
  }

  // Make an "object" as a map of functions.
  return {
    'get': get,
    'set': set,
    'increment': increment
  };
}
```

Oops! This doesn't work. The problem is that `increment()` is calling `get()`
and `set()` here, but those functions haven't been declared yet. [Unlike
JavaScript][hoisting], Dart doesn't silently hoist function declarations up. So
at the point that we're defining `increment()`, `get()` and `set()` aren't
declared.

[hoisting]: http://www.adequatelygood.com/JavaScript-Scoping-and-Hoisting.html

We could move `increment()` after `get()` and `set()` to fix this issue. But
then *those* two methods wouldn't be able to see `increment()`. No matter what,
there's no way to have all of those functions in scope inside each of the other
ones.

The problem is that the definitions of the functions come *one after the other*.
What you really need is to define them all in one lump where they can all see
each other simultaneously.

In functional languages, the name for that "lump" is a "mutually recursive
definition". It lets you declare a bunch of variable names and refer to those
names within the definitions of each of those variables. In Scheme and ML, this
is the difference between [`let` and `letrec`][let] (the `rec` in the name
stands for "recursive"). In C, you use [forward declarations][fwd] to do this.

[let]: http://docs.racket-lang.org/reference/let.html
[fwd]: http://en.wikipedia.org/wiki/Forward_declaration

So by "recursion" here, what he means is **method definitions are mutually
recursive so that they can see each other's *names*.** It *doesn't* mean that
they actually have to call each other at runtime and *be* recursive. Just that
their names are in scope so that they *could* do that.

## "Open"

We can fake mutually recursive definitions in our mini-Dart by using function
expressions and reassigning variables like this:

```dart
makeCounter() {
  // Declare the instance state for the "object".
  var count = 0;

  // Declare the variables up front.
  var increment, get, set.

  // Now that the names are all in scope,
  // create the function bodies.
  increment = () {
    set(get() + 1));
  };

  get = () {
    return count;
  };

  set = (value) {
    count = value;
  };

  // Make an "object" as a map of functions.
  return {
    'get': get,
    'set': set,
    'increment': increment
  };
}
```

Note the `=` between the method names and `()` now. That means we're assigning
anonymous functions to the already-declared variables. This gives us recursive
structures. Do we have objects yet? What's missing?

Another key feature of object-oriented languages is inheritance (or "delegation"
in prototype-based languages). That means creating a new object whose behavior
is a modification of an existing object's behavior. Think overriding methods in
derived classes.

Let's try to do that. We'll try to make a counter that logs itself. To avoid
re-implementation, we'll piggyback the existing counter code:

```dart
makeLoggingCounter() {
  var counter = makeCounter();

  return {
    'get': () {
      print('get!');
      return counter['get']();
    },
    'set': (value) {
      print('set!');
      counter['set'](value);
    },
    'increment': () {
      print('increment!');
      counter['increment']();
    }
  };
}
```

How did we do? When we call `get()` and `set()` on our logging counter, it does
correctly print "get!" and "set!" and then updates the counter appropriately.
The problem comes when we call `increment()`. That *does* print "increment!".
But, remember, `increment()` is implemented in terms of `get()` and `set()`.

Since we intended to *override* those methods in our logging object, calling
`increment()` *should* print "get!" and "set!" too. It doesn't. That's because
the non-logging object's implementation of `increment()` is *statically* bound
to the *base* definitions of those methods. We haven't *overridden* them in our
derived logging counter, we've just *shadowed* them.

In C++ parlance, `get()` and `set()` are [non-virtual][]. Our mini-Dart language
isn't expressive enough to handle virtual methods. The problem is that inside
`makeCounter()`, we don't see the instance of the logging counter at all. To fix
this, we have to pass that object in explicitly:

[non-virtual]: http://en.wikipedia.org/wiki/Virtual_function

```dart
makeCounter(receiver) {
  // Declare the instance state for the "object".
  var count = 0;

  // Declare the variables up front.
  var increment, get, set;

  // Now that the names are all in scope,
  // create the function bodies.
  increment = () {
    receiver['set'](receiver['get']() + 1));
  };

  get = () {
    return count;
  };

  set = (value) {
    count = value;
  };

  // Add the methods to the receiver.
  receiver['get'] = get;
  receiver['set'] = set;
  receiver['increment'] = increment;
}
```

Note how now `increment()`'s definition looks up `get()` and `set()` on that
passed in `receiver()` object. To create the logging counter, now we do:

```dart
makeLoggingCounter() {
  // Create a blank object.
  counter = {};

  // Turn it into a counter.
  makeCounter(counter);

  // Keep track of the original methods.
  var superGet = counter['get'];
  var superSet = counter['set'];
  var superIncrement = counter['increment'];

  // Override the methods.
  counter['get'] = () {
    print('get!');
    return superGet();
  };

  counter['set'] = (value) {
    print('set!');
    superSet(value);
  };

  counter['increment'] = () {
    print('increment!');
    superIncrement();
  };

  return counter;
}
```

Ta-da!

To make this work, we had to pass the `receiver` into `makeCounter()` so that
its methods could see the "derived" object. This lets it see and call overridden
methods. Those methods are now effectively "virtual".

Before we did this, the methods in `makeCounter()` *closed* over each other. In
other words, they were all closures and called each other by closing over each
other's variables. By passing in the receiver explicitly, we've cracked open
that closure and let the derived object get in so the base methods can see it.
Hence: "open".

## Recap

So, if you compare a real object-oriented language to a simpler language with
just structures and functions, the differences are:

1.  All of the methods can see and call each other. The order they are defined
    doesn't matter since their definitions are "simultaneous" or *mutually
    recursive*.

2.  The base methods have access to the derived receiver object (i.e. `this` or
    `self` in other languages) so they don't close over just each other. They
    are *open* to overridden methods.

Thus: *open recursion*.
