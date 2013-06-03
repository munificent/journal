---
layout: post
title: "Playing with Generics in TypeScript 0.9.0"
categories: code language typescript dart
---

This was just going to be a comment on [this reddit thread](http://www.reddit.com/r/programming/comments/1cyij4/typescript_09_early_previews_with_support_for/), but then it seemed to take on a life of its own, so I figured I may as well <s>milk it for all it's worth</s> make a nice post out of it.

Yesterday, the TypeScript guys [announced a preview of the new 0.9.0 version](http://blogs.msdn.com/b/typescript/archive/2013/04/22/announcing-0-9-early-previews.aspx) of the language featuring generics. I, like a lot of people, was really curious to see what approach they'd take with them. Retrofitting a type system onto a dynamic language is *hard* and generics are one of the places where that new suit of armor can really chafe the squishy flesh underneath.

This is a topic strangely near to my heart for another reason too. I'm on the [Dart team](http://www.dartlang.org/) and when Dart was announced, we were widely criticized for its type system. Generics are covariant in Dart, which is a mortal sin to many.

Now when any new type system comes out, my first thought is, "I wonder if it's got covariant generics?" (My second thought is, "God, I need a hobby that doesn't involve programming languages.")

Some more caveats before I get going:

* I literally spent five minutes poking at this, so I may have things wrong.
* Compiling programs with a compiler that isn't 1.0 yet and claiming that says something about the language specification is asking for trouble.
* I, despite my current occupation, am surprisingly bad at reading language specs.
* I am currently drinking a [fairly strong beer](http://www.ratebeer.com/beer/elysian-bete-blanche-belgian-tripel-2011-and-later/138973/).

OK, party time! After playing around with it a bit, as far as I can tell, *TypeScript's subtype relations are more permissive than I expected*. This isn't necessarily bad, just surprising. As a preamble, let's define a supertype and subtype:

{% highlight dart %}
class Base {}
class Derived extends Base {}
{% endhighlight %}

Now consider:

{% highlight dart %}
class Box<T> {
  constructor(public value: T) {}
};
{% endhighlight %}

This is the simplest possible generic type.

{% highlight dart %}
var a : Box<Base> = new Box<Base>(null);
var b : Box<Derived> = new Box<Derived>(null);
{% endhighlight %}

These are both fine, as you would expect.

{% highlight dart %}
new Box<number>("not num")
{% endhighlight %}

This gives:

    /generics.ts(5,0): error TS2081: Supplied parameters do not match any signature of call target.
    /generics.ts(5,0): error TS2085: Could not select overload for 'new' expression.

Looks about right. Now let's try covariance:

{% highlight dart %}
var c : Box<Base> = new Box<Derived>(null);
{% endhighlight %}

No errors. Contravariance?

{% highlight dart %}
var d : Box<Derived> = new Box<Base>(null);
{% endhighlight %}

Still no errors. This, I think, makes its type system looser than arrays in Java, and more permissive than Dart. Generics are *bi*variant in TypeScript.

{% highlight dart %}
var e : Box<number> = new Box<string>(null);
{% endhighlight %}

As a sanity check, this *does* give an error.

    /generics.ts(73,4): error TS2012: Cannot convert 'Box<string>' to 'Box<number>':
    Types of property 'value' of types 'Box<string>' and 'Box<number>' are incompatible.

So it doesn't just *ignore* the type parameters, it really is bivariant: it will allow either a subtype or supertype relation for the type parameters, but not no relation at all.

Part of this may be because TypeScript's type system is structural (neat!). For example:

{% highlight dart %}
class A {
  foo(arg : Base) {}
}

class B {
  foo(arg : Derived) {}
}
{% endhighlight %}

Here we have two unrelated types that happen to have the same shape (method names and signatures). Perhaps surprisingly, there's no error here:

{% highlight dart %}
var f : A = new B();
var g : B = new A();
{% endhighlight %}

This is perhaps extra surprising because `A` and `B` don't have the *exact* same signatures: their parameter types for `arg` are different. So the type system is both structural and allows either supertype or subtypes on parameters.

If the type system is structural, maybe the `Box<T>` examples only worked then because it had no methods (aside from the `value` property) that used the type parameter. What if we make sure `T` shows up in parameter and return positions?

{% highlight dart %}
class Box<T> {
  constructor(public value: T) {}
  takeParam(arg: T) {}
  returnType(): T { return null; }
};
{% endhighlight %}

Nope, this makes no difference. Still same behavior as before.

I believe the relevant bits of the spec are:

> **3.6.2.1 Type Arguments**
>
> A type reference to a generic type G designates a type wherein all
> occurrences of G’s type parameters have been replaced with the actual type
> arguments supplied in the type reference.

I think this basically says that generics are structurally typed and the type relation is determined based on the *expanded* type where type arguments have been applied. In other words, generic types don't have type relations, just generic type *applications*. For example:

{% highlight dart %}
class Generic<T> {
  method(arg: T) {}
}

class NotGeneric {
  method(arg: number) {}
}

var h : NotGeneric = new Generic<number>();
{% endhighlight %}

This is fine in TypeScript unlike most nominally-typed languages. Pretty neat!

> **3.8.2 Subtypes and Supertypes**
>
> S is a subtype of a type T, and T is a supertype of S, if one of the
> following is true:
>
>   - S’ and T are object types and, for each member M in T, one of the
>     following is true:
>
>       - M is a non-specialized call or construct signature and S’ contains a
>         call or construct signature N where, when substituting ‘Object’ for
>         all type parameters declared by M and N (if any),
>
>           - for parameter positions that are present in both signatures,
>             **each parameter type in N is a subtype or supertype of the corresponding parameter type in M**,
>
>           - the result type of M is Void, or the result type of N is a
>             subtype of that of M
>
>           - ...
>
>       - ...
>
>   - ...

My emphasis added. I believe this basically says that to compare two types, you walk their members and compare their types. For method parameters, "subtype or supertype" means bivariance: types go both ways. This is looser than the normal function typing rule which is contravariance for parameters and covariance for returns.

All in all, I find this pretty interesting. TypeScript has both a structural and prototypal type system, so it's already pretty fascinating from a language design perspective. Allowing bivariance of parameter types is a pretty bold extension of that.

Oh, if you'd like to see this for yourself, here's how:

    $ git clone https://git01.codeplex.com/typescript
    $ cd typescript
    $ git checkout develop
    $ jake local
    $ chmod +x bin/tsc

Then you can run `bin/tsc` to compile stuff with the bleeding edge compiler. The latest spec is under `doc/TypeScript Language Specification.pdf`.
