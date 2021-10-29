---
title: "Bootstrapping a Type System"
categories: code java language magpie
---

[Magpie][] has reached a strange but neat little milestone on the road from
"weird experiment" to "real language": the type system is now bootstrapped. I'm
not aware of any other languages where a statement like that is even
*meaningful* (maybe [Typed Scheme][]?), much less *true*, so I'll try to break
that down.

[magpie]: https://magpie-lang.org/
[typed scheme]: https://cs.brown.edu/courses/cs173/2008/Manual/typed-scheme/index.html

Even if you're not interested in Magpie, my hope is that you can at least get a
better picture of how type systems work in general from this. But, as a warning,
this ventures into an echelon of programming language nerdery that few care to
explore. I'll try not to be too boring, but no promises.

## What is a type?

"Type" like a lot of other simple words ("object" anybody?) ends up with a lot
of fuzzy overlapping definitions in programming: classes, runtime types,
prototypes, type objects, etc. In dynamically typed languages you'll hear
"values have type" while others say those languages have no types.

Magpie makes this distinction *very* blurry, but for our purposes what I care
about is the static definition of a type: it's the stuff that the type checker
works with. For example, say you create a variable:

```magpie
var i = 123
```

The type checker tracks that `i` is an integer. It does so by associating an
object -- a *thing* -- with that name. That object is a type. If you think of
types as objects that the type checker works with, that leads to the natural
question of what operations on types we need to support. For Magpie, there are
two important ones:

### Assignment compatibility

The first operation is a test for assignment compatibility (i.e. the subtype
relation). Put plainly, if we have a variable of type `A`, and we're trying to
assign to it a value of type `B`, is that kosher? This sounds like it's limited
to variables, but that core operation covers almost everything you need to do
with a type. It's equivalent to asking, "Is `B` a subtype of `A`?" and covers
things like, "Can I pass an argument of type `A` to a function declared to
expect type `B`?"

So, with this operation, we can track how types are related to each other, and
make sure we don't pass or assign values of the wrong type.

### Member type

The other operation, which is a little more OOP-specific, is determining if a
type has a member with a given name, and, if so, what its type is. This helps us
ensure we aren't calling unsupported methods or accessing undefined fields on a
class. For example, if we have a chunk of code like:

```magpie
list add("item")
```

The type checker needs to get the type of the `list` variable and ask it what
the type of its `add` member is. If the answer to that is nothing (i.e. it
doesn't have that member) or not a function that accepts a string, then that
method call is an error.

## An interface for types

If you have an OOP mindset, you can look at those two operations as defining an
interface. If you were implementing a type checker in Java, you could define a
type to be any class that implements:

```java
interface Type {
  boolean canAssignFrom(Type other);
  Type getMemberType(String name);
}
```

The concrete classes that represented kinds of types (say "Class",
"Interface", "Array", etc.) would then implement that interface and you're
good to go. The Magpie interpreter does exactly that.

## First-class types

It's just that *where* it does that is kind of unusual. In Magpie, all types are
first-class, like Ruby or Python. For example:

```magpie
var monkey = Monkey new("Bobo")
```

In this code, `Monkey` is just a global variable whose value is an object
representing the `Monkey` class. So classes are first-class objects.

But there are *types* that are not *classes*. For example, "array of ints" is a
type, but it's not a class. Magpie also has [ad-hoc unions][union], so "int or
string" is a type, but it's not a class.

[union]: /2010/08/23/void-null-maybe-and-nothing/

It would be perfectly valid for *classes* to be first-class, without having all
types be first-class, except for one important thing: generics. Magpie has
generics because I'm firmly of the opinion that a type system without generics
is about as useful as a language with functions but no parameters. Do you really
want a language whose type system is as expressive as `GOSUB` in BASIC?

Given generics, you should be able to instantiate them with any *type*, not just
any *class*. That way, you can create things like "collection of array of ints".
It's also important for type arguments in generics to be [reified][] (unlike
[Java's half-baked generics][erasure]). If you have a "list of ints" it should
*know* that it's a list of ints and be able to act on that fact.

[reified]: http://stackoverflow.com/questions/557340/c-generic-list-t-how-to-get-the-type-of-t/557355#557355
[erasure]: https://en.wikipedia.org/wiki/Generics_in_Java#Problems_with_type_erasure

Those last two points -- that any type can be a type argument in a generic, and
that type arguments should be reified -- means that all types really do need to
be first-class objects in Magpie.

## Piercing the veil

So, going down this path, we find ourselves in a weird place. Over in the Java
type checking code, we have some `Type` interface and a bunch of Java classes
that implement it. The type system is fully fleshed out in Java. Meanwhile, on
the other side of the veil we have these first-class objects in Magpie that also
fully implement the type system.

That's redundant, kind of ugly, and hard to manage. To get rid of that
redundancy, we'll kill one side. Which one? We know we need types to be first
class in Magpie, so that really only leaves one option: yank the type system out
of Java.

## What a type checker does

A type checker is actually a pretty simple piece of software. It basically walks
through a chunk of code tracking the types of the operations and checking them
for validity. For example, consider:

    print((1 + 2) string)

The parser converts that into an [AST][], a little tree like:

[ast]: http://en.wikipedia.org/wiki/Abstract_syntax_tree

```text
(print)
   |
(string)
   |
  (+)
  / \
(1) (2)
```

The type checker walks that tree from the bottom to top. Something like this:

1.  Get the type of `1` (`Int`).

2.  Get the type of `2` (`Int`).

3.  Look up the type of `+` on the receiver's type (`Int`, from *1*).

4.  See if the parameter type for `+` (`Int`, from the declaration of `+`)
    matches the argument type (`Int`, from *2*). (It does.)

5.  Get the return type of that method (`Int`).

6.  Look up the type of `string` on the receiver's type (`Int`, from *5*).

7.  Get the return type of that method (`String`).

8.  Look up the type of `print`.

9.  See if the parameter type for `print` (`String`, from its declaration)
    matches the argument type (`String`, from *7*). (It does.)

And we're done. Steps 3 6, and 8 are where we do `getMemberType()`. Steps 4 and
9 are where we use `canAssignFrom()`. Nothing too crazy. In Magpie, this is
basically [one file][].

[one file]: https://github.com/munificent/magpie/blob/b37c7265c689fb150c6463c9538284610dba1a01/src/com/stuffwithstuff/magpie/interpreter/ExprChecker.java

## Re-piercing the veil

Here's where it gets weird. We need to get this working with first-class types.
That means that `getMemberType` and `canAssignFrom` will be methods written in
Magpie.

To do this, the type checker will do something unusual. In the middle of
*statically* checking a chunk of code, it will periodically switch to
*dynamically* evaluating some Magpie code. Whenever it needs to compare two
types or look up a method, it hands off to the interpreter which calls the
appropriate method and and passes the result back to the type checker.

This is slightly less crazy than it seems because the code being dynamically
evaluated (methods on the type objects) is generally not the code being type-
checked (any random piece of Magpie code like `1 + 2`). Keeping track of which
context the interpreter is in is a little bit confusing, but it works.

## Bootstrapping

Magpie has worked this way successfully for several months. This is possible
because at its core, Magpie is dynamic -- it can execute a chunk of Magpie code
without having done any compilation or type checking on it. So I could write the
classes that defined the type system in Magpie without using any type
annotations and they'd run happily along like any dynamic language.

It worked that way, with the type system itself being dynamically typed until I
had enough type system features in place to actually be able to express all of
the types I needed.

In the last week or so, I finally reached that point. The most important part
was interfaces. I needed the ability to define an interface for `Type` that the
different type classes (`ArrayType`, `Class`, `Tuple`, etc.) could implement.
Interface types are defined entirely within Magpie -- there isn't a single line
of Java code related to them.

Once I had that working, I could use that to define a `Type` interface (an
instance of the Magpie class `Interface`). Then I could turn around and use that
type to annotate the types of the different methods that the type system
requires. Where before, methods like `canAssignFrom(other)` were dynamically
typed, now I could do `canAssignFrom(other Type)`.

The end result was, by far, the most mind-crushingly meta thing I've ever had to
wade through. Behold:

```magpie
interface Type
  canAssignFrom(other Type -> Bool)
  getMemberType(name String -> Type | Nothing)
  // Some other stuff...
end
```

That chunk of Magpie code defines an interface `Type` that the type classes in
Magpie must implement. You'll note that it's recursive -- most of its methods
take arguments of type `Type`.

Every class that defines a type in Magpie implements that. Interfaces are a
type, so [`Interface`][interface] implements `Type`, of course:

[interface]: https://github.com/munificent/magpie/blob/b37c7265c689fb150c6463c9538284610dba1a01/base/Interface.mag

```magpie
class Interface
  canAssignFrom(other Type -> Bool)
    // Check that other type has every member of this one.
    for member = members do
      var type = member memberType()
      let otherMem = other getMemberType(member name) then
        // Must be assignable.
        if type canAssignFrom(otherMem) not then return false
        end
      else return false // Must have members.
    end

    // If we got here, every method was found and matched.
    true
  end

  getMemberType(name String -> Type | Nothing)
    let member = members first(
          fn (m Member -> Bool) m name == name) then
      member memberType()
    end
  end

  // Other stuff...
end
```

So we have a Magpie class, `Interface` that implements an interface, `Type`,
that is in turn an instance of that same `Interface` class.

Now that all of the methods in the classes defining the type system have type
annotations, this means the type checker will check them too. So when a Magpie
program is type checked, it also type checks the type system itself.

## One less language

With all types being actual live Magpie objects, that raises an odd question:
What is a type annotation? In most languages, there are actually two languages
mixed together: the language of expressions and the language of types. So, in
Java, there are value expressions like `1 + 2` but also type expressions like
`List<Int>`, and these are two totally separate languages.

But in Magpie, even type expressions need to yield Magpie objects, so there is
no meaningful distinction between expressions and type annotations. Type
annotations are just regular Magpie expressions, evaluated dynamically during
type checking. If you have a function like:

```magpie
parseNumber(value String -> Int | Nothing)
    // ...
end
```

That `String` is just a regular Magpie expression, as is `Int | Nothing`. In
the case of the latter, `|` is just an operator on the `Class` class.

This means that not only is Magpie's type system extensible, even its type
*annotations* are. If you wanted to, you could define new operators or functions
and use them in type annotations:

```magpie
what(arg doSomething(Very * Strange))
```

I honestly don't know if that's a useful feature, but I do like the idea of not
having the type system welded into the language. If you like prototypes, or
algebraic data types, wouldn't it be nice if you could add them to the language
yourself? Or maybe that's just crazy talk.

## Why?

You may be asking why the hell I went so far down the rabbit hole here. I didn't
intend to, honest. I really don't want Magpie to be some weird esoteric
language. All I wanted was:

1.  The ability to imperatively modify classes like you can in Python and Ruby.

2.  Static type checking (after that imperative modification has happened).

This just seemed like the most straightforward way to pull that off, but if you
got any better ideas, I'm all ears.
