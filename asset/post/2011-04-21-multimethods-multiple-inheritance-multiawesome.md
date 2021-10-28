---
title: "Multimethods, Multiple Inheritance, Multiawesome!"
categories: code cpp java js language magpie
---

The luxury of having [a programming language with zero users][magpie] is that I
can make [radical changes][change] to it with impunity. Over the past month,
I've done just that. I've been thinking about both multimethods and multiple
inheritance for a long time, but I couldn't figure out how to make them work.
They both finally clicked together -- I found a way to use each to solve my
problems with the other.

[magpie]: https://magpie-lang.org/
[change]: https://github.com/munificent/magpie/commit/e509e13fd74ba252faf00288196769412cf7811c

With those stumbling blocks behind me, I was free to rebuild the language into a
form I've really wanted it to have since I started. Where Magpie used to be a
more typical [single-dispatch][] single-inheritance object-oriented language,
it's now much closer to [CLOS][].

[single-dispatch]: http://c2.com/cgi/wiki?SingleDispatch
[clos]: http://en.wikipedia.org/wiki/Common_Lisp_Object_System

This is a fundamental change to the language: every time you call a method, you're going through totally different machinery to figure out what code gets executed. What I'm really excited about is that I feel like the language is more powerful now and yet simpler.

Since not a lot of people know anything about multimethods (and I'm still learning!), and most people these days think multiple inheritance is in the same category as punching children and littering, I thought it might be worth running through how and why I added them. If I can, I'll show you some fun stuff that gets a lot easier when you have them.

## What's multiple inheritance?

If you've played with C++, you're at least passingly familiar with multiple inheritance. It's exactly like it sounds: a class can inherit from multiple base classes. All of the methods and properties on the base classes are available on the new derived one.

This is strictly more expressive than single inheritance. Single inheritance
gets you pretty far, but I find it leads to deeper inheritance chains, more
redundancy, and more brittleness. With multiple inheritance, you're free to
split classes into small chunks of well-defined behavior and then recompose them
at will. [This post][mi], I hope, gives you a good idea of what I have in mind
here.

[mi]: /2011/02/21/multiple-inheritance-in-javascript

## What's the problem?

It's not all rosy though, as anyone whose sliced their hand open on the [deadly
diamond of death][diamond] can tell you. Here are a couple of problems that you
can run into:

[diamond]: http://en.wikipedia.org/wiki/Deadly_Diamond_of_Death

### Is state duplicated or not?

Let's say you're making a game. You've got classes for the things in the world
-- monsters, magical items, etc. Lots of things in the world have a position, so
you make a base class for that:

```cpp
class Positioned {
public:
  int x;
  int y;
}
```

Then you derive classes for items and monsters:

```cpp
class Item : public Positioned {
  // Stuff...
}

class Monster : public Positioned {
  // Stuff...
}
```

Groovy. Then you decide to add a [living treasure chest monster][monster] to
attack the unwary:

[monster]: http://wiki.ffxiclopedia.org/wiki/Treasure_Chest_%28Monster%29

```cpp
class ChestMonster : public Monster, public Item {
  // Stuff...
}
```

Pop quiz! Does our ChestMonster have one `x` field or two? I've coded a lot of
C++ and I honestly don't know the answer. Either way it's bad.

If ChestMonster gets two sets of coordinates, one for each path in the class
hierarchy, then how do you know which one you're getting when you access `x` on
an instance of ChestMonster? If it just gets one `x`, what happens if the
constructors for `Item` and `Monster` try to pass different values for it when
they call the constructor for `Positioned` from their constructor? Who wins?

### Which override wins?

Now let's expand our previous example. Let's say there's a virtual method in
Positioned so that a derived class can say whether or not a given position is
valid. Something like:

```cpp
class Positioned {
protected:
  bool canBeAt(int x, int y) = 0;
}
```

This way, derived classes can handle things like ghosts that can walk through
walls or lightweight items that float on water. So Item and Monster both
override `canBeAt()`. When we call that on an instance of ChestMonster, which
one wins?

There probably *is* an answer here, but even if it's unambiguous to the
language, it's confusing for the user.

### Other problems...

There are other annoyances too. Multiple inheritance means you need syntax for
calling all of your base class constructors, which is more complex than Java's
simple `super(...)`.

When we get to multimethods, we'll see that linearization is trickier in
multiple inheritance. The [C3 linearization algorithm][c3] developed for
[Dylan][] is the canonical solution, I think, but it's not what I'd call simple.

[c3]: https://en.wikipedia.org/wiki/C3_linearization
[dylan]: http://www.opendylan.org/

These problems are scary enough that language designers ran away. Java, C# and
JavaScript only allow single inheritance. Other languages deal with this by
providing limited forms of multiple inheritance. Ruby has mixins. Scala has
traits.

## A solution?

After reading a bunch, I convinced myself that almost all of the problems with
multiple inheritance come from *multiple paths to the same base class.*
Duplicate state, ambiguous overrides, and even C3's complexity have a lot to do
with inheriting the same class twice. Why not just disallow that?

My idea for Magpie was that you could inherit from multiple classes, but it's an
error to inherit from the same class twice either directly or indirectly. In
other words, the family tree leading to a given class must always be a *tree*
and never a graph. No deadly diamond. Problem solved!

### The root of the problem

Well, not quite. You see most object-oriented languages have a root class -- the
[top type][] for you type system folks -- usually called something like
"Object". This is the class that all classes without an explicit superclass
implicitly inherit from. That means *every* class hierarchy is a graph: they
always connect back to Object at the top.

[top type]: http://en.wikipedia.org/wiki/Top_type

We could just ditch that concept (C++ does), but a root class is really useful.
There are some operations that are valid on pretty much everything. Think
`toString()`, `getHashCode()`, and `equals()`. Without a root class, there's no
place to hang methods like that.

I got stuck on this issue for months. In the meantime, I started learning more
about multimethods.

## Multi-what?

Multimethods, like [pattern matching][], are a language puzzle to me. They are *so awesome* and yet so *few* languages support them. People are finally starting to catch on to pattern matching, but the set of languages that support multimethods can still fit in your hand: Common Lisp, through [CLOS][], [Dylan][] (mostly dead but maybe being resurrected now?), and the still nascent [Slate][] language.

[pattern matching]: http://en.wikipedia.org/wiki/Pattern_matching
[clos]: http://www.dreamsongs.com/CLOS.html
[slate]: https://github.com/briantrice/slate-language

If you've never heard of multimethods, the basic idea is pretty simple though a
bit confusing if you come from a single-dispatch (C++, Java, C#, etc.)
background. Those latter languages do runtime dispatch only on the receiver,
using the term "overriding":

```cpp
class Base {
public:
  virtual void method() { printf("Base!"); }
}

class Derived : public Base {
public:
  virtual void method() { printf("Derived!"); }
}

// Later...
Base* obj = new Derived();
obj->method(); // Prints "Derived!"
```

The last line is the key bit. Even though `obj` is a pointer of type `Base`, at
*runtime* it looks up the actual class of the object being pointed to and finds
the right method for it.

This is in contrast with over*loading* which is statically dispatched in those
languages. Let's see:

```cpp
void method(Base* obj) { printf("Base!"); }
void method(Derived* obj) { printf("Derived!"); }

// Later...
Base* obj = new Derived();
method(obj);
```

Does this also print `"Derived!"`? Alas, no. With function arguments, the
overloaded function is chosen at *compile* time. Since the compiler only knows
that `obj` is of type `Base*`, it binds the call to the version of
`overloaded()` that expects that. At runtime, the actual class of the object
that `obj` points to is ignored.

### The receiver argument

When we see a chunk of code like `collection.add("item")`, we tend to think of
`collection` and `"item"` as being fundamentally different from each other. But
really, they're just two arguments being passed to `add()`. It's just that one
happens to appear to the left of the method name. It could just as easily be
`add(collection, "item")` (which is exactly how it would be in C or Lisp more or
less).

From that perspective, single dispatch seems weird. You've got this special
behavior that only applies to the first argument passed to every method
(`this`), and the other arguments are second-class citizens.

Multiple dispatch fixes that. In a language with multiple dispatch, the
*runtime* types of *all* arguments are used to select the actual method that
gets called when given a set of overloads. If C++ supported multiple dispatch,
and you wrote this:

```cpp
void method(Base* a, Base* b) { printf("base base"); }
void method(Base* a, Derived* b) { printf("base derived"); }
void method(Derived* a, Base* b) { printf("derived base"); }
void method(Derived* a, Derived* b) { printf("derived derived"); }

// Later...
Base* a = new Derived();
Base* b = new Derived();
method(a, b);
```

When you ran it, it would print `"derived derived"` even though the *static*
types of `a` and `b` are just `Base*`.

### What's the problem?

I'll give a stronger sales pitch for multiple dispatch later, but I hope you can
see already that multiple dispatch is more general and more expressive than
single dispatch. But it isn't easy.

The problem is what's called *linearization*. Given a set of overloaded methods
(like our four examples above) and a set of actual arguments, which method wins
and actually gets called?

In our example here, it's pretty obvious. Derived classes take precedence over
base ones, so the derived-most overload wins. There are some pathological cases
that are nasty, though:

```cpp
void method(Base* a, Derived* b) { printf("base derived"); }
void method(Derived* a, Base* b) { printf("derived base"); }

// Later...
Base* a = new Derived();
Base* b = new Derived();
method(a, b);
```

Which one should win? There isn't a clear right answer here. I guess every time
you call that method, the runtime would have to email the original author of the
code and be all "Dude, what did you want this to do?"

But ignoring pathological cases, linearization is still tricky, which a perusal
of the C3 algorithm should convince you of. Take a look at some of the
[explanatory examples that Python uses][mro] and report back to me.

[mro]: http://www.python.org/download/releases/2.3/mro/

## You scratch my back, I'll scratch yours

If you look at that Python page, you'll notice that most of the pathological
examples have something in common: *multiple paths to the same base class.* The
original problem with multiple inheritance is back!

But this is great news, because it means that our trick of not allowing
inheriting the same class twice will also dramatically simplify linearization of
multimethods.

Can multimethods in turn help us out with our root class problem? Indeed, they
can! When you define a method in a language that supports multimethods, you
provide a pattern that describes the arguments that method accepts. For example
(finally switching to Magpie syntax), a method like this:

```magpie
def overloaded(a is Base, b is Derived)
  print("base derived")
end
```

Will match a first argument of type `Base` (or a subclass of it) and a second of
type `Derived` (again, or a subclass). They say that this method is
*specialized* to those types.

But it isn't necessary to specialize an argument at all. A type pattern is just
one kind of pattern. You can also define a method like this:

```magpie
def overloaded(a, b)
  print("who knows?!")
end
```

Here, `a` and `b` aren't specialized to a class at all, which means this method
matches *any* pair of arguments. A method that is applicable to an object of any
class? Sounds an awful lot like what we'd want something like `toString()` or
`getHashCode()` to work on.

Problem solved. We don't need a root class. We just use unspecialized methods
instead.

## The core of a language

This is the new core of Magpie. Classes can inherit from multiple base classes,
as long as there is no overlap, and all methods are defined outside of the class
as multimethods. This is very close to how CLOS works. But there's a little
sugar I've added.

With multimethods, all arguments including the "receiver" are just regular
arguments, so there's no special `this`. That implies just using a normal
non-object-oriented function call syntax. For example, this in C++:

```cpp
planner.getAddressBook().getPhoneNumbers().add("867-5309");
```

Would look something like this in CLOS:

```lisp
(add (get-phone-numbers (get-address-book planner)) "867-5309")
```

Maybe it's just me, but I find that hard to read. My experience is that most
operations tend to have one argument that *is* kind of special. Putting that
argument to the left of the operation makes it easier to read the code from left
to right. It also gives a hint as to which arguments are likely to be most
strongly affected by the call. So the above in Magpie would be:

```magpie
planner addressBook phoneNumbers add("867-5309")
```

Semantically, it's pure multiple dispatch. *Syntactically*, you can specify that
an argument appears to the left of the method, to the right, or both. A getter,
like `addressBook` in `planner addressBook` is just a method with one argument
that appears to the left. A method call like `add` in `phoneNumbers
add("867-5309")` has arguments on both sides. And a straight function call like
`print("hi")` just has an argument to the right.

I'm still poking at the syntax, but so far I really like it. You get flexibility
over how your code reads but the uniform semantics of multiple dispatch.

## The sales pitch

If you've made it this far, I'll try to reward you. Through all of this, I
haven't really shown what's cool about multimethods. Why go through all this
trouble? Here's why...

### Overloading in a dynamic language

Since most dynamic languages don't have any concept of annotating a method's
expected types, that generally rules out the ability to overload at all. That's
a shame since lots of methods are nicely defined in terms of optional arguments,
or arguments of different types.

For a real world example, consider the magic `$()` function in [jQuery][]. It's [documented like this][doc]:

[jquery]: http://jquery.com/
[doc]: http://api.jquery.com/jQuery/

```text
$(selector, [context])
selector      - A string containing a selector expression.
context       - A DOM Element, Document, or jQuery to use as
                context.

$(element)
element       - A DOM element to wrap in a jQuery object.

$(elementArray)
elementArray  - An array containing a set of DOM elements to
                wrap in a jQuery object.

$(jQuery object)
jQuery object - An existing jQuery object to clone.

$()
```

Those look an awful lot like overloads, which Javascript doesn't support. How do
they do this? By making [one monolithic function][fn] with a slew of
`instanceof` checks interspersed throughout it. Eek!

[fn]: https://github.com/jquery/jquery/blob/15da298f72bf94a95563abc12b8e6fec8c604099/src/core.js#L72-L179

In Magpie you can just do:

```magpie
def $(selector is String) ...
def $(selector is String, context) ...
def $(element is Element) ...
def $(elementArray is List) ...
def $(object is JQuery) ...
def $() ...
```

The language itself then takes care of picking the appropriate method for you
and doing all of the `instanceof` checks and variable binding itself. The nice
thing about that is that it happens atomically. You don't have to worry about
bugs where you *think* `selector` is a string, but you forgot the `instanceof`
check. If it picks the first method up there, you know for certain `selector`
will be a string.

### Binary operators

Magpie doesn't have built-in operators, so you're free to define your own and
overload existing ones. (But, for the love of God, please don't go [all Scala on
it][ops].) Multimethods are a big help here.

[ops]: http://jim-mcbeath.blogspot.com/2008/12/scala-operator-cheat-sheet.html

A simple example is `!=`. In C# and C++, when you overload `==` you have to
remember to also overload `!=` since that's also a method on the class you're
overloading it for. In Magpie, a single definition of `!=` serves to cover all
cases:

```magpie
def (left) != (right)
    not(left == right)
end
```

Now when you overload `==`, you get `!=` for free.

Another example is `+`. Magpie uses it for both numeric addition and string
contenation. Many languages have to build that directly into the language to get
the overloading to work right. In Magpie, it's just:

```magpie
def (left is Int) + (right is Int) ...

def (left) + (right)
    concatenate(left string, right string)
end
```

If both arguments are ints, the first method wins and you get addition.
Otherwise, it calls the `string` method on the two arguments and concatenates.

### Value patterns

We've covered methods that specialize on types and ones that allow an argument
of any type. There's another flavor of pattern too: *value patterns*. Those let
you define methods that only match on specific argument values. Consider the
venerable Fibonacci function. With value patterns, you can implement it like
this:

```magpie
def fib(0) 0
def fib(1) 1
def fib(n is Int) fib(n - 2) + fib(n - 1)
```

Note that the order these are defined doesn't matter. The linearization
algorithm takes care of picking the first two methods for those values of `n`: a
value pattern always wins over a type pattern.

Value patterns turn out to be a perfect fit for a surprising problem: static
methods. Most object-oriented languages let you define methods that don't work
on an *instance* of a class, but instead on the class itself. In C++/C#/Java
these are called "static", for example:

```java
Integer.parseInt("123");
```

Static object-oriented languages handle this by having built-in special support
for static methods. In Smalltalk, classes are [first class][]. That means a
class is just another object you can pass around. It handles "static" methods by
making them regular *instance* methods on the class *of the class object
itself* -- its [metaclass][].

[first class]: http://en.wikipedia.org/wiki/First-class_object
[metaclass]: http://www.ifi.uzh.ch/richter/Classes/oose2/05_Metaclasses/02_smalltalk/02_metaclasses_smalltalk.html

That means for every class, (say `Int`) there's a corresponding metaclass
(`IntMetaclass`). When you call a method on an int, like `123.sqrt()`, the
runtime finds that method on the `Int` class. When you call a method on `Int`
itself, like `Int.parse("123")`, it finds that on the *meta*class.

Classes are first class in Magpie too, so it worked that way for a while. That
meant making a pair of classes for each class and [a fairly confusing metaclass
hierarchy][hierarchy]. With multimethods, that all [just goes away][away].
Instead, a "static" method is just a method that matches on a class *by value*:

[hierarchy]: http://en.wikipedia.org/wiki/File:Smalltalk_80_metaclasses.svg
[away]: https://github.com/munificent/magpie/commit/424b2724af47fffc426c1e432c8fae051ce3a0d1#L6L18

```magpie
def (== Int) parse(text String) ...
```

The `(== Int)` pattern here means we match on `Int` by value as opposed to `(is
Int)` which means to match on it by type. With that, I can ditch metaclasses
completely. Things like constructors simply become multimethods that specialize
to class values for their left-hand argument.

### Safely extensible classes

Finally, we get to the last bit, the real reason I wanted to add multimethods in
the first place. Before I started working on Magpie, I spent most of my time in
C#. One of my favorite features is [extension methods][]. They give you the
ability to effectively add new methods to a class without the horrors of
monkey-patching.

[extension methods]: /2008/02/09/c-extension-methods-not-just-for-breakfast/

My motivation is pretty mundane -- I think method call syntax is the usually the
most readable, and I care deeply about readability. I prefer this:

```java
list.reverse();
```

Over this:

```java
Collections.reverse(list);
```

But I want to avoid the chaos of monkey-patching. Multimethods are a neat
solution to this. With multimethods, the methods aren't directly tied to classes
at all. You're perfectly free to define a `reverse` method like this:

```magpie
def (list is List) reverse() ...
```

And then you can call `reverse()` as it if were a native method on Lists.
Because you aren't cracking open the class itself, this is nice and modular.
Code that imports the module where you define that will get your `reverse()`
method, and modules that don't won't. If they define their own `reverse()`
method, there's no collision. You can even access both within the same module by
renaming when you import:

```magpie
import bobs.list.methods with
    reverse as bobs.reverse
end
import your.list.methods with
    reverse as your.reverse
end

var list = [1, 2, 3]
list bobs.reverse()
list your.reverse()
```

(Here, the `.` is just part of the method name. It looks funny at first, but
hopefully not *too* funny.)

## What now?

I'm still ironing out the kinks with all of this, but so far it looks pretty
promising. It's nice to be able to define methods on whatever types you want,
and I find multiple inheritance to be a refreshingly effective way to reuse code
after years of dealing with single inheritance.

I've still got lots of work and weird edge cases to deal with, though. The
syntax for patterns and defining methods is OK but not ideal. There's a couple
of ugly corner cases between how multimethods and modules interact.

The two biggest pieces are that in the process of doing this, I yanked a bunch
of other code out. It was really hard to get this to work without breaking the
other existing features so I just scrapped them. As of today, Magpie no longer
has [extensible syntax][] or [static checking][], previously its two most
interesting features. Oops!

[extensible syntax]: /2011/02/13/extending-syntax-from-within-a-language
[static checking]: /2010/10/29/bootstrapping-a-type-system/

Getting the syntax extension stuff working again won't be too much trouble.
Getting the type system going again will be a bit of work. When I tore it out, I
realized how much code was related just to that and how much complexity a static
type system really adds to the language. When I add it back in, I'll try to keep
all of that in Magpie (it used to be half Magpie, half directly in the
interpreter).

A surprising thing I noticed is that multimethods actually cover some of the
utility of static types. With them, I'm still usually annotating the types that
methods expect, which is nice for documentation, and I still get the guarantee
that a method won't get an unexpected argument.

I still want to get a real type system (or multiple, which is a big motivation
for defining it at the library level!) going too, but it's refreshing not having
to deal with it for a while. One thing I've learned in the past year is that
designing a type system is about ten times harder than designing a language.
