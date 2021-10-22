---
title: "Rethinking User-Defined Operators"
categories: code cpp go java language magpie parsing
---

I just made a radical change with how [Magpie][] handles infix operators --
stuff like `+` and `==`. If that kind of programming language minutiae is up
your alley, read on for how it works now and the reasoning behind it. I don't
think it's perfect, but I think it's pretty solid. At the least, it's flexible
enough to let you have something better than `equals()` in Java.

[magpie]: https://magpie-lang.org/

## A history lesson

There are a couple of different camps that most languages fall into regarding
operator syntax and semantics. Just so we're all together, I'll run through
them:

### No infix at all

The Lisp family simply ditches infix syntax altogether. Functions are always in
prefix form, and operators are just another kind of valid function name. An
expression like `1 + 2 * 3` becomes:

```c
(+ 1 (* 2 3))
```

Since most Lisps aren't object-oriented (ignoring CLOS for the moment), these
functions are basically global and aren't bound to any arguments. Forth works
about the same way, but in postfix fashion:

```c
2 3 * 1 +
```

Again, operators are just regular functions who happen to have names like comic
book profanity. This solution is dead simple and quite flexible. You just have
to give up the ability to write `1 + 2` the way you've been writing it since
grade school.

### Fixed syntax, fixed semantics

This is a common option, and a fan of people who fear their coworkers. Languages
like C, Java, and Go have a fixed set of operators baked into the language along
with fixed predefined semantics. Addition does what the language designers say
it does forever and ever amen.

By baking a set of operators into the language, you can support the "[Please
Excuse My Dead Aunt Sally][pemdas]" operator precedence most users expect and
support things like unary minus without ambiguity.

[pemdas]: https://en.wikipedia.org/wiki/Order_of_operations

It's also great for what some people call "auditability" or "context-free" code.
If you look at an expression with operators, you can figure out what it's doing
without knowing much about the operands. In fact the operators illuminate their
arguments. If you see a minus sign, the arguments must be numbers.

The downside, of course, is that it isn't flexible. Want to add two numbers in
Java? It's `a + b`. Want to add two BigDecimals? Better get used to `a.add(b)`.
The syntax of the language treats library-defined types as second-class
citizens.

### Fixed syntax, extensible semantics

A slightly more flexible approach, and a nice compromise, is what C++ and C# do:
fix the syntax and grammar, but let users overload the semantics for their own
types. You get the convenience of "normal" operator precedence levels and stay
clear of the scary [operator jungle][] apparently waiting just off the beaten
path.

[operator jungle]: http://jim-mcbeath.blogspot.com/2008/12/scala-operator-cheat-sheet.html

At the same time, users get nice syntax for their own types. Your complex number
library can do `a + b`. If you've used a good vector or matrix library in C++,
you've seen how much of a boon that can be for readability.

### Fixed syntax, no fixed operators

And last, but not least, my personal favorite, the Smalltalk approach. Like Lisp
or Forth, Smalltalk has no built-in operators. `+` and `==` are just methods
like any other whose names happen to be hard to pronounce.

Unlike Lisp and Forth, though Smalltalk puts them in *infix* position, so they
look like you expect. It's `a + b`, not `(+ a b)`. The grammatical rule is
pretty simple: if an identifier is only punctuation characters, it's an operator
and *must* occur in infix position. All operators have the same precedence and
associate left-to-right.

Like many things in Smalltalk, this solution is radically simple while still
being expressive and extensible. You lose some of the subtlety of a hard-coded
operator grammar, but you gain the ability to define your own operators or
overload existing ones.

The semantics are equally simple: an operator is just a method call on the
left-hand operand. The right-hand operand is passed to it as the argument. In
other words, `a + b` in Smalltalk would look like `a.+(b)` in Java or C++.

## Magpie: round one

If Magpie had a bumper sticker, it would likely read [WWAKD][kay], so I
initially took the Smalltalk approach. It's workable, keeps the grammar and
parser nice and small, and fits with Magpie's philosophy of letting users
express things the way they want.

[kay]: https://en.wikipedia.org/wiki/Alan_Kay

I plodded along this way for months. Every time I had to deal with operators,
they were always a bit... annoying, but I labored through it. After immersing
myself in it for a while, I had a pretty good catalog of what I didn't like.
Here it is:

### It's asymmetric

An expression like `a + b` always give `a` control over how the operator is
interpreted. I suppose that's fine for some things, but many, if not most,
operators are conceptually symmetric. It's really weird then that the
implementation isn't. That leads to weird undesirable behavior. For example:

```magpie
var a = "1" + 1 // "11"
var b = 1 + "1" // Error!
```

String's implementation of `+` would coerce the right operand to a string.
Meanwhile, Int's implementation would just bail if the other operand wasn't an
Int too. I could have made Int's implementation of `+` coerce *itself* to a
string if the argument was a string, but that's just weird. First, it's
redundant code. Why should I have that logic in two places? Second, why should
Int know *anything* about strings?

### It's tedious

Magpie's type system is [implemented in Magpie][boot]. This means that operators
on types are just regular Magpie operators. One common operator is `|`. It
creates a [union type][] out of two types. If you have a variable of type
`Int | String` then at runtime it can hold a value that's an Int or a String.

[boot]: /2010/10/29/bootstrapping-a-type-system/
[union type]: http://en.wikipedia.org/wiki/Union_(computer_science)

You should be able to apply this operator on any two types. There are a bunch of
different classes that define types, things like arrays, interfaces, functions,
and tuples (and Class itself, the class of classes). Since `|` is just a method
on those classes, they all need to have it.

Fortunately, classes are open in Magpie, so I can extend all of those classes in
one place and add that method. Like so:

```magpie
extend interface Type
  def |(other Type -> Type)
end

def Class |(other Type -> Type) OrType combine(this, other)
def FunctionType |(other Type -> Type) OrType combine(this, other)
def Interface |(other Type -> Type) OrType combine(this, other)
def OrType |(other Type -> Type) OrType combine(this, other)
def Tuple |(other Type -> Type) OrType combine(this, other)
```

But this is still kind of lame. It's particularly annoying because I have to add
another row here every time a new class of types is defined. I *hate* repeating
myself.

### It passes the buck on its semantics

When I reason about an operator, I tend to assume it has the same semantics
regardless of its operands. If we're talking `==` for equality, I sure as hell
expect it to be symmetric, transitive, and reflexive.

But with the operators-as-methods solution, there's no single point of control
to enshrine those invariants. It's up to each class implementing that operator
to play along with the others. A real-world example of how tricky it is to get
this right is `equals()` in Java. Implementing that correctly is so hard that
Josh Bloch had to dedicate a chapter to it in [Effective Java][].

[effective java]: https://www.oreilly.com/library/view/effective-java/9780134686097/

## Magpie: round two

Those issues were enough to make me want a different solution. I kept coming
back to the idea of just making operators be standalone global functions, but
there's one really nice facet of the Smalltalk solution I didn't want to give
up: dynamic dispatch.

By making operators instance methods, you get class-specific behavior for free.
Getting `+` to do addition for numbers and concatenation for strings is as
simple as having the methods on those two classes do different things.

It finally dawned on me that I can have my cake and eat it too. After all, if an
operator is just a global function with two arguments, there's nothing
preventing the implementation of that function from just immediately calling a
method on one of its arguments. I could make `+` a global function and still get
the exact same behavior as before just by implementing it like:

```magpie
def +(left, right)
   left add(right)
end
```

The `add` replaces our old plus-operator-as-method, and we're back in business.
But what's great is that I don't *have* to do this.

### Central point of control

The key idea is that an operator function becomes a central point of control
that gets first dibs at defining the semantics for that operator. It *may* just
call a method on one of its arguments, but it doesn't have to. There's now a
single place in code where you can define the global invariants for the operator
and that global function can control what responsibility it delegates to its
operands.

For example, it we want to ensure `==` is symmetric, we can just do:

```magpie
def ==(left, right)
  left equals(right) and right equals(left)
end
```

Want to make sure its reflexive?

```magpie
def ==(left, right)
  // `same?` tests for identity, i.e. reference equality.
  if Reflect same?(left, right) then return true

  left equals(right) and right equals(left)
end
```

Ever get tired of having to make sure to check for `null` before you call
`equals` in Java? A clever `==` in Magpie can handle that for you too:

```magpie
def ==(left, right)
  // `same?` tests for identity, i.e. reference equality.
  if Reflect same?(left, right) then return true

  if left == nothing then return false
  if right == nothing then return false

  left equals(right) and right equals(left)
end
```

(I should point out that Magpie's equivalent to `null`, `nothing`, is a valid
object too, so you could always implement `equals` on it and then ditch the
explicit checks here. Either way works.)

But maybe you don't want to leave equality determination up to the instance
itself at all? One guideline for equality is that two objects should be
equatable only if they're the exact same class. That presents the opportunity to
have the class itself do the comparison (i.e. as a static method on the class):

```magpie
def ==(left, right)
  // Must be same class.
  var leftClass = Reflect getClass(left)
  var rightClass = Reflect getClass(right)
  if Reflect same?(leftClass, rightClass) not then return false

  // Now let the class itself determine equality.
  leftClass equal?(left, right)
end
```

I'm still working out what the exact implementation of this should be, but I
think it's really nice that I can do that figuring in a single place in code.
And, of course, this addresses my other complaints too:

### Symmetry

Since an operator is just a function with two arguments, there's nothing special
about either one. It's symmetric by default. You'll note that all of the
implementations of `==` treat both of their arguments identically. If you
*don't* want an operator to be symmetric, you can do that too, but it's up to
you.

### No more redundancy

Now that operators aren't bound to classes, things like the `|` operator just
need to be defined in one place:

```magpie
def |(left Type, right Type -> Type) OrType combine(left, right)
```

You know how every single time in every class that overloads `==` in C++ or C#,
you have to remember to also overload `!=` too? Not in Magpie:

```magpie
def !=(left, right -> Bool) (left == right) not
```

## Not all sunshine and roses

Alas, nothing is perfect in this world. There's two problems I've stumbled onto
with this approach.

### Name squatting

The first is relatively minor, I think. Because these operators aren't bound to
a class, they're essentially global now, with all of the negative implications
of sticking a name in the global namespace. There can only be one implementation
of any given operator function.

When Magpie has namespaces, that will mitigate it, but many operators will still
likely be in the global namespace. Users probably don't want to have to import
`+`.

My hope is that smart implementations of these functions will defer to their
operands appropriately so that the single point of control doesn't become a
bottleneck. It just becomes a question of good library design. I'll have to see
how it plays out.

Because Magpie is pretty flexible, you can always take the nuclear option --
just replace the old definition of the operator with your own. Everything's
mutable at load time! But let's hope we don't have to go there.

### Return types

This is the real annoyance, and is only a problem because Magpie has static
typing. Because there's only a single function for the operator, it only has a
single return type. In the old system where operators are methods, `+` on String
was defined to return a string, and `+` on Int return a number. It worked just
like you expected.

Now that there's just one `+` function that isn't possible. Honestly, I was
never that crazy about using `+` for string concatenation anyway, so this may
not be a big loss. My short-term solution was to just create a new operator
(tilde: `~`) for string concatenation instead of overloading `+`.

Still, there are other operators where variable return types will probably be
desired. A `++` operator that concatenates two lists should return a list with
the right item type. I'm still working out Magpie's generics story (which is
fiendishly hard for a language whose static type system is as unusual as this
one), but my hunch is that it will help here.

## Writing the code

Despite those problems, I still think this is a big improvement over the
Smalltalk (and Scala) solution. I've got it implemented and working now, and the
code feels cleaner and simpler, which is always a good sign. Still, there may be
pitfalls I'm not noticing so let me know if you see any.
