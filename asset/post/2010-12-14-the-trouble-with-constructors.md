---
title: "The Trouble with Constructors"
categories: code language magpie
---

Every fledgling programming language exists somewhere on the continuum between
"scratchings in a notebook" and "making Java nervous". Right now, Magpie is
farther to the right than total vaporware, but it's not yet at the point where I
actually want people to use it (though you're certainly [welcome to
try][magpie]). The big reason for that is that there's some core pieces I'm
still figuring out. Without those in place, any attempts to use the language
will either fail or just be invalidated when I change something.

[magpie]: https://magpie-lang.org/

The biggest piece of that is the object system -- how classes work. The two
challenging parts of *that* are inheritance and constructors. I think I've got a
few ideas that are finally starting to stick there, so I thought I'd start
documenting them to make sure I've got it clear in my head, and hopefully get
some feedback.

In this post, I'll just worry about constructors. The way Magpie handles
constructing instances of classes is a bit... uh... odd. I'll explain
[Memento][]-style, starting with the end and working backwards to see how I got
there. By the end (or is it the beginning?) it should hopefully make sense.

[memento]: http://www.imdb.com/title/tt0209144/

## Making an object

To see where we end up, here's a simple class in Magpie:

```magpie
class Point
  var x Int
  var y Int
end
```

Pretty basic. It has two fields. Because those fields don't have initializers
(i.e. they aren't like `var z = 123`), they need to get those values passed in.
Given that class up there, you can do that and make an instance like this:

```magpie
var point = Point new(x: 1 y: 2)
```

That doesn't look very special. It looks like `new` is just a static method on
the class, and you pass in named arguments? That's half right. `new` *is* just a
static ("shared" in Magpie-ese) method. Magpie doesn't have named arguments.
What it has are *records*. The above is identical to:

```magpie
var coords = x: 1 y: 2
var point = Point new(coords)
```

Records in Magpie are as they are in ML: [structurally typed][] anonymous
structs. A series of `keyword: value` pairs forms a single expression that
evaluates to a record value. Sort of like object literals in Javascript,
although they're statically typed in Magpie.

[structurally typed]: http://en.wikipedia.org/wiki/Structural_type_system

So, this is pretty straightforward. When you define a class, it automatically
gets a shared method called `new` that expects a record with fields that match
all of the required fields of the class?

Well, sort of. Actually, the `new` method doesn't do much at all. It's defined
as simply:

```magpie
def new(arg) construct(arg)
```

OK, so what's `construct`?

## Raw constructors

Raw constructors are the real way that instances of a named class are created
in Magpie. Each class automatically gets a shared `construct` method. That
method (like `new`) takes a record with fields for all of the fields of the
class. It then builds an instance of the class and copies those field values
over.

So raw constructors are the real way that instances of a class are allocated in
Magpie. So what is `new` for then?

## A time to initialize

Calling `construct` is the primitive way to create an instance, but many (most?)
classes need to perform some initialization when an instance is created. Or
maybe they'll calculate the values of some of the fields instead of just taking
them in as arguments. `new` exists to give you a place to do that.

For example, let's say we actually wanted to create points using polar
coordinates, even though it stores them as Cartesian. In that case, we could
define `new` like:

```magpie
class Point
  shared def new(theta Int, radius Int -> Point)
    var x = cos(theta) * radius
    var y = sin(theta) * radius
    construct(x: x y: y)
  end

  var x Int
  var y Int
end
```

As you can see `new` is basically a factory method. It does some calculation,
and then the very last thing it does is call `construct`, the *real* way to
create an object, and returns the result. (Like Ruby, a function implicitly
returns the result of its last expression.)

The reason Magpie always gives you *both* `construct` and `new` is for
[forward-compatibility][]. `new` is the way users typically create instances, so
Magpie gives you a default one that forwards to `construct`. If you later
realize you need to do more initialization than just a straight call to
`construct`, you can replace `new` without having to change every place you're
creating an object.

[forward-compatibility]: /2010/09/18/futureproofing-uniform-access-and-masquerades/

## OK, but why?

That seems pretty strange. Why on Earth would I design things this way instead
of just using normal constructors like most other languages?

Let's imagine that Magpie *did* have normal constructors (which it did until a
few days ago, actually). Let's translate our Point class to use that:

```magpie
class Point
  // 'this' here defines a constructor method
  this(x Int, y Int)
    this x = x
    this y = y
  end

  var x Int
  var y Int
end
```

Pretty straightforward, and it works fine. Now, let's break it:

```magpie
class Point
  this(x Int, y Int)
    this x = x
  end

  var x Int
  var y Int
end
```

Here, we failed to initialize the `y` field. What is its value? We can fix that
the way Java does with `final` fields by statically checking for [definite
assignment][]. Part of the type checking process will be to walk through the
constructor function and make sure every declared field in the class gets
assigned to. This isn't rocket science, and I went ahead and [implemented
that][impl] in Magpie too.

[definite assignment]: http://java.sun.com/docs/books/jls/first*edition/html/16.doc.html
[impl]: https://github.com/munificent/magpie/blob/e79021536467a03ca6973822ea7963b317c5dacf/src/com/stuffwithstuff/magpie/interpreter/DefiniteFieldAssignment.java

So we're good, right? Well, what about this:

```magpie
class Point
  this(x Int, y Int)
    doSomethingWithAPoint(this)
    this x = x
    this y = y
  end

  var x Int
  var y Int
end
```

In the constructor, we're passing `this` to another function. That function,
reasonably enough, expects the Point it receives to be fully initialized, but at
this point it isn't. So that's bad.

We can fix that by making the static analysis even more comprehensive. While we
check for definite assignment, we'll also track and make sure that `this` isn't
used until all fields are definitely assigned.

Of course, you need to be able to use `this` to actually assign the fields. So
we'll need to special-case that. At this point, it starts to look like we're
building some ad-hoc [typestate][] system where the static "type" of `this`
mutates as we walk through the body of the constructor and gets tagged with all
of the fields that have been assigned to it. Like:

[typestate]: https://en.wikipedia.org/wiki/Typestate_analysis

```magpie
this(x Int, y Int)
  // Here 'this' is "Point with no fields assigned".
  this x = x
  // Now it's "Point with x".
  this y = y
  // Now it's "Point with x and y" and we're good.
end
```

This is doable, but it's a bit of a chore to implement. Much worse is that it's
a real chore for any (purely hypothetical at this point) Magpie user to have to
know. In order to understand the weird type errors you can get in a constructor,
you have to fully understand all of this flow analysis I just described.

I'm trying to keep Magpie as simple as I can, and this is definitely not it.

## Why don't other languages have this problem?

Here is where we get to the real motivation that leads to all of this. Java and
C# don't have this issue with their constructors. It's perfectly valid to do
this in Java:

```java
class Point {
  public Point(int x, int y) {
    doSomethingWithPoint(x, y);
    this.x = x;
    this.y = y;
  }

  private final int x;
  private final int y;
}
```

It's bad form, but it's safe. The reason why is because Java has *default
initialization*. Before you ever assign to a field in Java, it still has a
well-defined value. Numbers are 0, Booleans are false, and reference types are
`null`.

Whoops! That last one is a [doozy][]. I *hate* having to check for `null` at
runtime. One of the major motivations for designing Magpie was to have it
[statically eliminate][null] the need for those. If I say a variable is of type
Monkey, I want it to always be a *monkey*, not "possibly a monkey, but also
possibly this other magical missing monkey value".

[doozy]: http://lambda-the-ultimate.org/node/3186
[null]: /2010/08/23/void-null-maybe-and-nothing/

The problem then is that it isn't always possible to create a value of some
arbitrary type *ex nihilo*. We can't just default initialize a field of Monkey
by creating a new monkey from scratch. Maybe it needs arguments to be
constructed.

So default initialization has to go. Every field in an instance of a class will
need to be explicitly initialized before anyone can use that instance. In other
words, until its fully set-up, `this` is verboten.

(C++ has its own solution for this, of course: constructor initialization lists.
They solve this problem neatly, but at the expense of adding a non-trivial
amount of complexity to the language.)

The most straightforward solution I could come up with was this: *create the
instance as a single atomic operation*. To do this, we need to pass in *all* of
the fields the instance needs, and it will return us a fully-initialized
ready-to-use object. That's `construct`.

What's nice about this approach is that it's dead simple. There's almost no
special support in Magpie for constructors. No syntax for defining them. No
special definite assignment for tracking that fields are initialized. Just a
single built-in `construct` method auto-generated by the interpreter for each
class, and you're good to go.

It's not all rosy, though. Doing things this way can be kind of gross if your
class has a lot of fields to initialize. You end up having to build a big record
as the last expression in your `new` method.

The other challenge is that circular immutable data structures aren't really
feasible. (Magpie doesn't have immutable fields yet, but it will.) Haskell has
it even worse than Magpie since *everything* is immutable and it's actually
[surprisingly tricky][knot] to solve it.

[knot]: http://www.haskell.org/haskellwiki/Tying_the_Knot

What may be the biggest drawback, though, is that it's unusual. Unfamiliarity is
its own steep cost, especially in a fledgling language.

## Rewind

So, going from cause to effect, it's:

1.  To get rid of null references, I had to get rid of default initialization.

2.  To get rid of default initialization, I had to get rid of access to `this`
    before an object has been fully-constructed.

3.  To do that, I turned construction into a single `construct` method that
    takes all of the required state and returns a new instance all in one step.

4.  Then, to get user-defined initialization back, I wrapped that in a `new`
    method that you can swap out to do what you want.

The reasoning seemed pretty sound to me, but I'm always eager to hear what
others think about it.
