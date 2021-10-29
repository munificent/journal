---
title: "Future-Proofing, Uniform Access, and Masquerades"
categories: c-sharp code java language magpie
---

Take a look at this Java code:

```java
public class Person {
  public String name;
  public int age;
}
```

Does it make you cringe a little bit? If so, I'm guessing it's because those
fields aren't wrapped in nice getters and setters.

But why do that? What if we want them to be mutable and don't have any
validation or logic to perform when they change? Isn't simpler better? The
answer, of course, is that just because we don't need that *now*, that doesn't
mean we won't need them *later*.

I think of this kind of speculative defensive coding as *future-proofing*, and
it drives me crazy that I have to do it. Eventually, this post will get around
to being about [Magpie][], but I hope that there is food for thought here even
if you never take an interest in that little language.

[magpie]: https://magpie-lang.org/

Before we really get going, let me show you a couple of other common
future-proofing practices I see.

### Hiding constructors behind factories

Java loves this one:

```java
class PersonFactory {
  public Person create() {
    return new Person();
  }
}

void doSomething(PersonFactory factory) {
  Person person = factory.create();
  // ...
}
```

Assuming you can dodge the infinite regress of `FactoryFactoryFactories`, this
helps abstract out the places where you call a constructor directly. Wrapping
that behind a factory lets you swap out the concrete class being constructed.

### Hiding classes behind interfaces

The pattern looks like this (here in C#, where its most applicable):

```csharp
interface IPerson
{
  string Name { get; set; }
  int    Age  { get; set; }
}

class Person : IPerson
{
  public string Name { get; set; }
  public int    Age  { get; set; }
}

void DoSomethingWithPerson(IPerson person)
{
  // ...
}
```

All of your concrete classes get squirrelled away and you only ever visibly deal
with the interface types. I've seen entire codebases designed around this.

This lets us swap out our use of `Person` with some other concrete class that
implements the same interface. This can be really helpful for replacing concrete
classes with [mocks][] for unit testing, which can otherwise be tricky in C# and
C++ where methods default to non-virtual.

[mocks]: http://en.wikipedia.org/wiki/Mock_object

## Why do we do this?

If all of this seems like a pain in the ass with little benefit,
congratulations, you've just earned your "Feel Superior to Enterprise OOP
Programmers" merit badge. Your complimentary Ruby T-shirt should be arriving in
the mail shortly. It *is* a pain. Actually, it's worse than a pain, it's
*boring*. Boring work is a cardinal sin in programming -- it indicates something
that the computer *should* be doing but isn't.

So why do we end up writing this kind of code all the time? There are plenty of
other speculative things we could do now that we manage to shrug off by claiming
[YAGNI][]. What's special about the examples I listed?

[yagni]: http://c2.com/xp/YouArentGonnaNeedIt.html

Let's say we *don't* futureproof. Say we use public fields everywhere. Then
later we realize we do need to validate the field. What will we have to do to
make that change?

## Depth not volume

What's easier: changing a hundred lines of code in one file, or changing one
line of code in a hundred files? The former you can do before lunch. The latter
means you might need to call a meeting, coordinate with teams, slap some
[deprecated annotations][] on things, plan a release, aww hell just give up.

[deprecated annotations]: http://download.oracle.com/javase/1.5.0/docs/guide/javadoc/deprecation/deprecation.html

Making non-local changes *hurts*. It hurts badly enough that a lot of our core
ideas about good software engineering, things like coupling and cohesion, exist
in part to localize stuff to minimize that hurt.

We futureproof not to minimize the *amount* of change we'll need to do in the
future but to minimize the *width* of change we'll have to do. Ask yourself
this: How often do you apply defensive practices inside the bodies of methods
compared to in the public signature of a type?

## The uniform access principle

Now we get to the heart of the problem. What's special about these examples that
causes them to lead to *wide* changes? The key issue is that making any of the
changes described touches *every callsite*. If you change a field to a getter in
Java, you have to add parentheses every place that field is used. If you hide a
constructor behind a factory, you'll be grepping for every `new` in your
codebase. In C#, if you decide to replace every mention of a class with an
interface, you'll at the very least have to change the name.

The problem here is that these examples violate what Bertrand Meyer calls the
[uniform access principle][]. In Java, accessing a field is fundamentally
syntactically different from calling a getter. If you go from one to the other,
each callsite has to change. According to Meyer, that's because access to fields
and calculated values isn't *uniform*.

[uniform access principle]: http://en.wikipedia.org/wiki/Uniform_access_principle

### Properties

Most other languages in wide use today have addressed that problem. Python,
Ruby, C#, and Javascript support *properties*: things that *look* like fields
but behave like functions. This means you can transparently switch between the
two without affecting every callsite. You no longer need to futureproof them.
Java, as always, is like Chunk in The Goonies, struggling to keep up with the
rest of the gang.

(Caveat: fields and properties are *source* compatible in C#, but not *binary*
compatible, which is why you'll see many C# programmers always wrapping fields
in properties.)

### Constructors and factories

One of the things that got me thinking about this idea was [this recent
post][post]. The author painted himself into a corner by not futureproofing: he
was calling a constructor directly but now needed it to construct a different
class. Worse, the callsite was outside of code he had control over.

[post]: http://blog.hackensplat.com/2010/09/construct-something-else-c.html

Meyer's idea of uniform access to fields is really a small piece of a larger
idea: Can users define their own abstractions that are syntactically identical
to built-in behavior? Can we swap out default language-provided behavior with
our own logic without having to change the calling convention?

Unfortunately, this is a case where the answer is "no." In all of the dominant
static OOP languages, calling `new` always returns an instance of a fixed class.
There's no way to replace it with our own logic. We're stuck with factories.

<div class="update">

<p><em>Update 2021/10/16:</em> <a href="https://dart.dev">Dart</a>, which was
created a couple of years after I wrote this post allows you to define
<a href="https://dart.dev/guides/language/language-tour#factory-constructors">
&ldquo;factory&rdquo; constructors</a> that don&lsquo;t implicitly create a new
instance of the containing class.</p>

</div>

### Interfaces and classes

The other example is a messier problem. What does it mean to later replace
references to a class with references to an interface? In C#, at the least
you'll be adding `I` to the name everywhere, but there are likely other changes
involved too. Calls to static methods on the class will need to be refactored,
and any place where you're calling a constructor will need to be changed
somehow. This is a sticky problem to get tangled up in after the fact.

Again, C# and simliar languages don't give you much help here. Of course,
dynamic languages like Ruby and Python *do* have you covered. If there's no type
annotations to begin with, duck typing lets you swap things out all you want. Go
to town!

## How Magpie approaches this (or how it *will* once it's implemented)

I look at the dynamic solution as throwing out the baby with the bathwater. I
really like type checking. It sucks to have to discard it completely just to
avoid having to do some boring future-proofing. Can we keep the type checking
and still solve the above two problems? I think so.

### Constructors and factories

Constructors are the easy one. Magpie has no special syntax for constructors.
`new` is just a method you call on a class object:

```magpie
var bob = Person new("Bob")
```

If you later decide you need that to construct a different type, you can
always swap out the method:

```magpie
Person defineMethod("rawNew", Person getMethod("new"))
def Person new(name)
  // Don't want to create a person...
  Dude new(name)
end
```

To be honest, though, that's kinda gross. Try not to do that. A better solution
really is to use a factory here -- some object that you can swap out that will
create people. Fortunately, Magpie makes this a bit easier too. A class *is* a
factory:

```magpie
var makeSomeone(name, factory)
  factory new(name)
end

makeSomeone("Bob", Person) // Makes a person.
makeSomeone("Bob", Hero)   // Makes a hero.
```

Since classes are first, uh, class, you can just pass them around and use them
like factories as-is. Because they're also instances of a class (their
metaclass), they can even implement interfaces:

```magpie
interface NamedFactory
  new(name String)
end
```

Now any class that has a constructor that takes a string will implicitly
implement that interface. You get type-safe factories without having to actually
create separate special factory classes.

### Classes and mocks

The other example problem is a little trickier. You have a concrete class that
you're using everywhere and you realize later that you actually need to swap it
out. One solution is to subclass the concrete class but that always feels dirty
to me in Java. If I'm creating a mock class, I don't actually want to reuse any
of the code from the base class, so why am I inheriting it?

Instead, Magpie has (will have) a relatively simple feature called
*masquerades*. Say we have a concrete class like:

```magpie
class Person
  this (name)
    this name = name
  end

  greet() print("Hi, I'm " + name)
end
```

We're using it like this:

```magpie
var greetEachOther(a Person, b Person)
  a greet
  b greet
end
```

In most static languages, since `greetEachOther` is typed to expect instances of
the concrete `Person`, the only other option you have is passing in a subclass.
Magpie gives you another alternative. Here's the class we want to use in place
of a person:

```magpie
class Robot
  name = "Robot"

  greet() print("Greetings, fleshy human.")
end
```

This class has no relation to `Person` in the class hierarchy. But it *does*
happen to have all of the methods that `Person` has. If there was some
hypothetical `IPerson` interface that `Person` implemented, `Robot` would
implement it too. Masquerades let us approximate that. You can ask an object of
one type to masquerade as another. As long as they have compatible methods, it
will succeed, *even though both types are concrete and unrelated*:

```magpie
var main(->)
  var robot = Robot new
  // robot's type is Robot
  var imposter = robot masqueradeAs[Person]
  // imposter's type is Person but is still a reference to robot
  // and this is now type-safe:
  greetEachOther(Person new("Bob"), imposter)
end
```

As far as I know, this is a novel feature in programming languages, but I think
it's a useful one. I would definitely appreciate any feedback on it either way,
though.

## Wrap it up

One of the ideas I've been following with the design of Magpie without realizing
it is to try to maximize this uniform access principle. As much as possible, you
should be able to write the code *today* for the problems you have *today*. You
shouldn't need to waste time futureproofing. It's the language's job to be
flexible enough to handle that. Making sure that the built-in language
constructs are syntactically compatible with user-defined abstractions is one
important piece for doing that.

As a nice side-effect, it makes the language more consistent and gives more
power to users. There's less "well the built-in stuff can do that, but you
can't." That, to me, is a sign of a good language.
