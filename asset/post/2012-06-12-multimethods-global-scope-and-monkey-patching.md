---
title: "Multimethods, Global Scope, and Monkey-Patching"
categories: code language magpie
---

> What I mean is that if you really want to understand something, the best way
> is to try and explain it to someone else. That forces you to sort it out in
> your mind. And the more slow and dim-witted your pupil, the more you have to
> break things down into more and more simple ideas. And that's really the
> essence of programming. By the time you've sorted out a complicated idea into
> little steps that even a stupid machine can deal with, you've learned
> something about it yourself.

<p class="cite">Douglas Adams</p>

I'm interested in all kinds of languages, so I'd read about [multimethods][] and
generic functions in [Common Lisp][], [Clojure][] and [Dylan][]. Even
lesser-known languages like [Cecil][] and [Nice][]. But it wasn't until I
*implemented* them in [my own language][magpie] that I ran into a seemingly
innocuous question: how are multimethods scoped?

[multimethods]: http://c2.com/cgi/wiki?MultiMethods
[common lisp]: https://en.wikipedia.org/wiki/Common_Lisp_Object_System
[clojure]: http://clojure.org/multimethods
[dylan]: https://opendylan.org/books/dpg/multi.html
[cecil]: http://www.cs.washington.edu/research/projects/cecil/www/cecil.html
[nice]: http://nice.sourceforge.net/
[magpie]: http://magpie-lang.org/

This question consumed a great number of showers and morning commutes. I
implemented a bunch of different versions and watched them break. What I finally
stumbled on is really simple, but... *wrong-feeling*. This post is an
explanation of how multimethods are scoped in Magpie, but also sort of a
*rationalization* since the answer turns out to be "globally".

But I'm getting ahead of myself. First, let me rewind and set up some
preliminaries. OK, maybe a *lot* of preliminaries. This is a corner of language
design that I think few people wander into and previous explorers don't seem
have left a map so maybe there will be some value in this.

## What is scope?

When you hear "scope" you probably think something like this:

```c
{
  int a = 1;
  {
    int a = 2;
    printf("%d", a);
  }
  printf("%d", a);
}
```

The curly braces in C++ define *block scopes*. When you declare a local
variable, it goes in the nearest enclosing scope. When the compiler sees a use
of a variable (here `a`), it looks in the surrounding scopes to figure out what
it's bound to.

Scopes can nest, like you see here. When a variable is defined in multiple
scopes, the innermost one *shadows* the others and wins. So this program will
print `2` followed by `1`.

Some languages like JavaScript (before [ES6][]) and C (before [C99][]) don't
have block scope like this. Instead they just have *function scope*. Each
function body can have its own local variables, but there are no nested scopes
inside that (unless you actually nest a function in JS). You still have
variables outside of functions, so you still have to think about nesting,
though.

[es6]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let
[c99]: http://stackoverflow.com/questions/1880745/c99-can-i-declare-variables-in-the-beginning-of-a-block-in-a-for

Both of these kinds of scope have something in common: they use *[lexical
scoping][]*. It's called that because you can tell what a variable name is bound
to just be looking at the *text* (hence "lexical") of the program. This is in
contrast to *[dynamic scoping][]* where you can only tell what a name is bound
to at *runtime*. Lexical scoping was one of the big innovations of [ALGOL][],
and almost every language works like it these days.

[lexical scoping]: http://c2.com/cgi/wiki?LexicalScoping
[dynamic scoping]: http://en.wikipedia.org/wiki/Static_scoping#Dynamic_scoping
[algol]: http://en.wikipedia.org/wiki/ALGOL

This is all well and good for scoping *variables*, but for the sake of this
post, I'll widen the term to talk about any kind of identifier that appears in a
program. Variables aren't the only place names appear in many languages.
Consider this bit of JavaScript:

```javascript
function(who) {
  alert(who.favoriteColor);
}
```

Here we have two names in the program (ignoring `alert`), `who` and
`favoriteColor`. We need to figure out what they represent in order to run the
code. `who` is easy, it's just a lexically scoped variable and we can see that
it's bound to whatever you pass to the function.

What's about `favoriteColor`? Since it comes after a `.`, that means it's a
*property accessor*. Each object in JS carries a little bag of named properties
around with it. When we do `.favoriteColor` here, it looks for a property named
`favoriteColor` in that bag at runtime and returns its value. We'll call this
*object scope*.

Being a [prototype-based language][proto], JS is pretty simple here. It has only
lexical scope and object scope. Class-based object-oriented languages often have
a couple more scopes. Methods are looked up on the *class* of the receiver, and
there is usually a separate scope for "static" methods.

[proto]: http://en.wikipedia.org/wiki/Prototype-based_programming

## What scopes does Magpie have?

OK, so we have block scope, object scope, method scope, static scope. There's
lexical scoping and dynamic scoping. Which of these does Magpie have? Just one:
*lexical block scope.*

Magpie is a [class-based][] [object-oriented][] language, and its syntax is
designed to look (more or less) like one. It doesn't use a dot to separate the
"receiver" from the method or property, but it otherwise looks like it *would*
have object, method, and static scope:

```magpie
list add(item)
```

[class-based]: http://magpie-lang.org/classes.html
[object-oriented]: http://magpie-lang.org/objects.html

When it's compiling that expression, the variables `list` and `item` are looked
up in lexical scope like you expect. But the method `add` is too. In Magpie,
methods are not bound to classes. Instead, they are defined separately. If you
know C's model of "structs + functions", you have roughly the right idea. If you
know CLOS or Dylan, you have *exactly* the right idea.

When you see `list add(item)`, it looks like you're calling `add` "on" some
`list` object, but what it really means is "call this `add` method, passing in
`list` and `item` as arguments". It's the same as `add(list, item)` in other
languages. Magpie just has a syntax that lets you stick the method name in the
middle.

In addition, "property accessors" in Magpie [are methods too][uniform]. So when
you see `person favoriteColor`, that's essentially `favoriteColor(person)`. To
compile that, we just look up `favoriteColor` in lexical scope like you would a
variable.

So how far up do these scopes go? In Magpie, each source file is a [module][]
and each module has its own top-level scope. There is no single global shared
scope. Instead, each module is its own little island that only sees the names
that it defines or explicitly imports.

[uniform]: http://en.wikipedia.org/wiki/Uniform_access_principle
[module]: http://magpie-lang.org/modules.html

## What about polymorphism?

"Polymorphism" in the object-oriented sense means that the same method can do
different things at runtime given different kinds of objects. "Single-dispatch"
OOP languages, which are probably what you're familiar with, achieve this by
treating the receiving object (i.e. `this`) as a scope. By looking up the method
on the receiver at runtime, you get behavior that varies based on that object.
Magpie on the other hand, just looks up the method in lexical scope.

If methods aren't looked up on the object (or on its class), how do we get
polymorphism in Magpie? How can I make an `add()` method that does the right
thing given a list, a set, or a map?

The answer is that all methods in Magpie are [multimethods][multi]. The [docs][]
have the full story, but here's the TL;DR: You can define multiple methods with
the same name but different argument [patterns][], like so:

```magpie
def (list is List) add(item)
    // add stuff to list...
end

def (set is Set) add(item)
    // add stuff to set...
end

def (map is Map) add(item)
    // add stuff to map...
end
```

In C, this would just be an error because the names collide. In Magpie, it's
A-OK. What this does is a create a *single* `add()` *multi*method that contains
those three methods. When you call `add()`, the interpreter looks at the types
of the arguments at runtime and picks the right method to call. Instead of using
*scoping* for polymorphism, it essentially uses [pattern matching][].

[multi]: /2011/04/21/multimethods-multiple-inheritance-multiawesome/
[docs]: http://magpie-lang.org/multimethods.html
[patterns]: http://magpie-lang.org/patterns.html
[pattern matching]: http://www.haskell.org/tutorial/patterns.html

## Time for a snack break

That probably all sounds a bit hand-wavey. Let's walk through a concrete example
and see how all of the moving parts mesh together. First, let's make a module
that defines a class and some methods for it.

```magpie
// sandwich.mag
defclass Sandwich
  val meat
  val condiment
end

def (sandwich is Sandwich) isVegetarian
  sandwich meat == "tofu"
end

def (sandwich is Sandwich) toString
  "A tasty " + meat + " and " + condiment + " sandwich"
end
```

So we have a class `Sandwich`. The class definition also automatically give us
getter methods for `meat` and `condiment` that return the appropriate fields
given a `Sandwich` instance on the left. We also define another method
`isVegetarian`. It takes a sandwich and returns `true` if the sandwich doesn't
have any meat in it. Finally, we add a `toString` method so you can print
sandwiches.

Now let's make another module that uses this one:

```magpie
// main.mag
import sandwich

val sandwich = Sandwich new(meat: "ham", condiment: "mayo")
print("veggie? " + sandwich isVegetarian)
print(sandwich)
```

Seems pretty simple, right? It turns out that not binding methods to classes
leads to a couple of subtle but deep problems. (At least they were subtle to
*me*. I didn't realize them until I'd implemented the intepreter and ran
straight into them.)

These problems all turn out to be related exactly to the original question of
this post, how methods are scoped, and solving them is what led to Magpie's
current (and perhaps surprising) answer.

## The first problem: "overriding" methods

So what happens when we run this example? Let's say for now that methods are
scoped just like variables, which is how Magpie *used* to work. We'll walk
through it a line at a time.

```magpie
import sandwich
```

This takes all of the top-level variables and methods in `sandwich.mag` and
binds them to the same names in `main.mag`. After that, `Sandwich`, `meat`,
`condiment`, `isVegetarian`, and `toString` are all available for use.

```magpie
val sandwich = Sandwich new(meat: "ham", condiment: "mayo")
```

This creates a new `Sandwich` instance and stores it in a variable `sandwich`.

```magpie
print("veggie? " + sandwich isVegetarian)
```

This calls `isVegetarian`. We've imported that method, so there's no problem
here. Now consider the last line:

```magpie
print(sandwich)
```

`print()` is a built-in method that takes an object, converts it to a string by
calling `toString` on it, and then displays it. "Built-in" just means it's
defined in another `core` module and is automatically imported, so we do indeed
have access to it from `main.mag`. So we call it and pass in the sandwich. What
happens next?

What *doesn't* happen is that it doesn't call the `toString` that we actually
defined for `Sandwich`. That method is scoped to `sandwich.mag`. We imported
that module into `main.mag` so we could call it *there*. But we aren't calling
`toString` in `main.mag`. It's being called from `print`, which is in `core`.
The `core` module has no idea there's this other `toString` method specialized
for sandwiches because the `toString` multimethod `core` knows about is
unrelated to the one `sandwich.mag` and `main.mag` have.

Ouch. Our intent in `sandwich.mag` is that defining `toString` would work like
[overriding][] in other OOP languages. Any place that is calling `toString`
should see that new specialization even if it hasn't directly imported the
module that contains it.

[overriding]: http://en.wikipedia.org/wiki/Method_overriding

## The first solution: shared multimethod objects

My [fix][] for this was to change what it means to import a multimethod. In our
little example, the import graph is like:

```asciiart
core
 ^^
 │└───┐
 │ sandwich
 │┌───┘
main
```

`main.mag` imports `sandwich.mag` and they both also (implicitly) import `core`.
Core itself contains a `toString` method with specializations for the atomic
types like numbers and strings.

The first fix was that when you import a method, you import the *exact same
multimethod object*. So `sandwich.mag` imports the `toString` multimethod from
`core`. When we then define a new `(sandwich is Sandwich) toString`
specialization, that goes into the *exact same multimethod that `core` is
using*. There is basically a single `toString` object in memory that all of
those modules have a reference to.

This works because `core` is the first module that created it, and our other two
modules are both importing it. So every place that's using `toString` has a path
of imports that ultimately traces back to the root in `core`.

[fix]: https://groups.google.com/g/magpie-lang/c/BilLNpvklYQ

## The second problem: colliding imports

Problem solved, right? Well, not so fast. After I did this, I ran into the next
issue. Here's another example. We've got these two modules:

```magpie
// pal.mag
defclass Pal
  val name
end

// pet.mag
defclass Pet
  val name
end
```

They both define classes that have `name` fields. That means they both
implicitly create `name` methods. Then we use them:

```magpie
// main.mag
import Pal
import Pet

def greet(who)
  print("Hi, " + who name + "!")
end

greet(Pal new(name: "Fred"))
greet(Pet new(name: "Rex"))
```

The intent here is clear: `greet()` should be able to print anything that has a
`name` getter. What happens when we run this with our current semantics? It
turns out we don't get very far.

The `import Pal` line works fine. It brings `Pal` and `name` into `main.mag`.
Then the second import comes along. It defines `Pet` fine, but there's already a
`name` multimethod defined now. We have a name collision.

We didn't have a name collision in the first example. Even though `toString` got
imported into `main.mag` both from `core` and `sandwich.mag`, they were the
exact same object, so we could just safely ignore it. Here, though, that isn't
the case. The import graph is like:

```asciiart
pal  pet
 ^    ^
 └─┐┌─┘
  main
```

There is no root module where a single `name` multimethod is being created.
Instead, `pal.mag` and `pet.mag` both create their own unrelated `name`
multimethods. When `main.mag` tries to import them both, they aren't the same
object, so they collide.

## The second (failed) solution: just deal with it

My first stab at "fixing" this was to just declare those semantics are How It
Should Be. If you have colliding method names, you just rename on import, like:

```magpie
// main.mag
import Pal with
    name as pal.name
end
import Pet with
    name as pet.name
end
```

That works, but it's really ugly. I found in practice that method collisions
were surprisingly common, almost always coming from fields with simple names
like `name`. Having to qualify those at every use site sucks:

greet(who)
  print("Hi, " + who pal.name + "!")
end

Worse, it breaks [duck typing][]. Using this scheme, there's no way to create a
single `greet()` method that works on both pets and pals since there isn't a
single `name` method it can call on both.

[duck typing]: http://en.wikipedia.org/wiki/Duck_typing

## The third (failed) solution: do something really complex

At first, I tried to fix this by doing some hairy method merging when you
imported. If you had a method name collision on import, it would create a new
local multimethod object that contained all of the specializations of both of
the ones you're importing. That fixes the above problem. `main.mag` will end up
with one `name` method that can accept both pals and pets.

But it unfixes the *first* problem. If you import a multimethod (like `toString`
in the first example) and then add a new specialization, you need to push that
specialization back *up* to the modules that you imported.

So to get that working, I made it track all of the modules where you had
imported a multimethod from. When you defined a new specialization, that would
get pushed back up to those modules too.

This did sort of work, but it was complex, felt brittle, and was hard to reason
about.

## The fourth solution: go global

I spent a lot of time thinking about it and finally asked if there was a
radically simpler answer that would work. One came to mind: **make methods
*globally* scoped.**

Any time you define a method, in *any* module, it would just go into a single
global pool of multimethods that all modules share. Overriding works, because
you're *always* overriding: there is only a single multimethod with a given name
across the entire program. Duck typing works for the exact same reason.

But global scope is [bad][], right? I felt like I was committing some cardinal
sin by even contemplating this. After much gnashing of teeth, I concocted a
rationalization for why this might not be so bad. Here goes...

[bad]: http://c2.com/cgi/wiki?GlobalVariablesAreBad

Consider your favorite conventional OOP language. We'll do Ruby because it looks
nice here:

```ruby
class Cow
  def speak()
    puts "moo"
  end
end

class Dog
  def speak()
    puts "woof"
  end
end
```

We have two classes that both define `speak` methods. We don't think of `speak`
as being "global" here because you get to the `speak` methods *through* an
instance of `Cow` or `Dog`. Once you do, the method will correctly be associated
with the right type and do the right thing. You can't call `Dog`'s `speak` on an
instance of `Cow` or some other unrelated type. Likewise, if you don't have a
dog or a cow, you can't get to `speak` at all.

Now consider the Magpie equivalent, and assume that multimethods are globally scoped:

```magpie
defclass Cow
end

def (is Cow) speak
  print("moo")
end

defclass Dog
end

def (is Dog) speak
  print("woof")
end
```

How does it compare? Like the Ruby solution, you can't call `Cow`'s `speak`
method using a `Dog` or some other type. If you don't have a dog or a cow, you
can't get to `speak` at all.

What this means is that the *multi*method is globally scoped. But actual
specializations, the stuff you care about, functionally aren't. Since they are
specialized to types, if you don't have an object of that type, you can't get to
the method. The multimethod is sitting there in global scope where anyone can
get to it, but unless you have the key (an object of the right class), you can't
crack it open and get at the methods.

In other words, globally scoped multimethods in Magpie are isomorphic to methods
in a single dispatch language. Actually, that's only half true. Single-dispatch
languages only support a *subset* of what multimethods let you do. Magpie can
also express a bunch of stuff that single-dispatch languages can't.

## Better than monkey-patching

Multimethods match on *all* of their arguments, not just the "receiver" on the
left-hand side. Let's go back to our Ruby example. Say we need to serialize Dogs
and Cows to a stream. Since classes in Ruby are open for extension, we can do:

```ruby
class Dog
  def serialize(stream)
    stream write("dog")
  end
end

class Cow
  def serialize(stream)
    stream write("cow")
  end
end
```

Swell. But then someone else on our team gets tasked with making dogs and cows
support serializing to XML. If they aren't aware of *our* monkey-patch and add:

```ruby
class Dog
  def serialize(xmlWriter)
    xmlWriter write("<dog></dog>")
  end
end

class Cow
  def serialize(xmlWriter)
    xmlWriter write("<cow></cow>")
  end
end
```

Those `serialize` methods will obliterate the ones for writing to a stream. Or
maybe the other way around. It depends on whose code gets to run last. Nasty.

Meanwhile, in Magpie:

```magpie
def (dog is Dog) write(stream is Stream)
  stream write("dog")
end

def (cow is Cow) write(stream is Stream)
  stream write("cow")
end

def (dog is Dog) write(writer is XmlWriter)
  writer write("<dog></dog>")
end

def (cow is Cow) write(writer is XmlWriter)
  writer write("<cow></cow>")
end
```

Here, there is no collision at all. When you call `write`, the interpreter looks
at both the left-hand argument (a `Cow` or a `Dog`) *and* the right-hand side (a
`Stream` or an `XmlWriter`) and picks the one perfect method for those types.

This means you can effectively "monkey-patch" with much finer-grained control
and less chance of collision. The entire argument signature forms a key that's
used to select the right method. If you don't want people to accidentally hit
your specific method, just ensure that it requires an argument of a type that's
hard to get a hold of.
