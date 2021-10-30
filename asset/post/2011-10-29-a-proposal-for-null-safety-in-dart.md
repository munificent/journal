---
title: "A Proposal for Null-Safety in Dart"
categories: code dart language
---

<div class="update">
<p><em>Update 2021/03/03:</em> With the release of <a href="https://medium.com/dartlang/announcing-dart-2-12-499a6e689c87">Dart 2.12</a>, Dart <a href="https://dart.dev/null-safety">supports sound null safety</a>. Had to wait about ten
years, but I got it!</p>
</div>

Page 75 of the current (0.04) draft of [the Dart language spec][spec] has this
note in it:

[spec]: https://dart.dev/guides/language/spec

> Should we do something with respect to non-nullable types?

If you asked me, I'd answer a resounding yes! (Alas, no one did, but that's
never stopped me before.) So, here's my attempt at an answer. I'm posting it
here on my blog just to clarify that this is *my* strawman proposal, and not
something that's got any official Dart or Google stamp of approval on it.

## The proposal in a nutshell

By default, all types are non-nullable. If you declare a variable of type `int`,
it is a static error to try to assign `null` to it. In checked mode, it is a
dynamic error to assign `null` to a non-nullable variable.

You annotate a nullable type by adding `?` after the type name. The type `int`
is non-nullable, `int?` is nullable. Non-null types are a property of Dart's
type system, but (unlike [`Maybe`][maybe] or [`option`][option] in other
languages) not a part of its runtime behavior.

[maybe]: http://lukeplant.me.uk/blog/posts/null-pointers-vs-none-vs-maybe/
[option]: http://www.standardml.org/Basis/option.html

At runtime, Dart continues to work like a dynamic language where any variable
may hold a value of any type, including `null`. "Nullability" is as optional as
the rest of Dart's type system.

## Why default to non-nullable?

One of the first decisions a non-null proposal has to make is which is the
default: nullable or non-nullable? I prefer defaulting to non-null for a couple
of reasons:

*   Most of the time, you don't want to allow `null`. I went through
    [SwarmViews.dart][], one of the largest Dart source files that I'm familiar
    with and annotated it for nullability. I found 16 nullable variables or
    fields and 172 non-nullable ones. In other words, non-nullabille is the
    right default in that file about 90% of the time.

*   A very large number of type annotations are for atomic types (`int`, `bool`,
    etc.) and people expect those to be non-nullable like they are in other
    languages. It would be strange to have to go out of your way to say "I want
    a *non-nullable* bool".

*   In Dart, you don't have to provide a type annotation at all. It seems to me
    then that if you've chosen to go out of your way to say a variable is of
    type `Foo`, it should really be a `Foo` and not a `Foo`-or-`null`.

[swarmviews.dart]: https://github.com/dart-lang/sdk/blob/main/samples-dev/swarm/SwarmViews.dart

## Semantics

A nullable type is essentially the [union][] of the original type and the `Null`
type. In other words, `bool?` contains all of the values of the `bool` type
(`true` and `false`) as well as all of the values of the `Null` type (`null`).

[union]: http://en.wikipedia.org/wiki/Type_system#Union_types

Unlike option types, nullable types do not nest. `int??` is equivalent to
`int?`. This follows naturally from thinking of it as a union of types.
`true|false|null` is an equivalent set to `true|false|null|null`. The redundant
`null`s collapse.

## Subtyping

A non-null type is a subtype of its nullable type. In other words, you can
always pass a `Foo` to something that expects a `Foo?`.

Also, the special `Null` type is a subtype of every nullable type. This means
you can initialize nullable types with `null` like you'd expect. Since `Null` is
*not* a subtype of *non*-nullable types, you *cannot* initialize those with
`null`. That implies that all variables of non-null types must be initialized.
This is an error:

```dart
int a;
```

As is this:

```dart
class Point {
  int x, y;
  Point();
}
```

Requiring fields of non-nullable types to be initialized is a challenge in
languages like Java and Scala where you can access a field before it's been
initialized in the constructor. Fortunately, Dart already has constructor
initialization lists, and they solve this problem handily. We can fix that
`Point` class like so:

```dart
class Point {
  int x, y;
  Point() : x = 0, y = 0;
}
```

Since the constructor initializers are run before you can access `this`, we've
ensured that those fields will be initialized before *anyone* can see them.
Neat.

## Working with nullable types

One challenge with nullable types is that working with them can be tedious. With
things like [`Maybe` in Haskell and `option` in ML][option], you have to
manually unwrap the "nullable" value to get at the delicious real value hidden
inside.

[option]: http://en.wikipedia.org/wiki/Option_type

This proposal doesn't have that problem (granted, it also doesn't have some of
the benefits of option types). It tries to stick close to Dart's dynamic
sensibilities, so there are no option-like values that you have to extract the
real value from using pattern matching.

Instead we rely on the fact that a variable can hold a value of any type. A
nullable type just means the type checker won't yell at you if it knows `null`
is one of those values.

To test for null, you can just do a vanilla `if (foo == null)` statement.

To go back and forth between nullable and non-nullable types, we rely on
assignment compatibility. Dart's assignment compatibility rules are looser than
other languages. Like most, they allow implicit upcasts. Given this:

```dart
class Base {}
class Derived extends Base {}
```

Then this is allowed:

```dart
Base b = new Derived();
```

But Dart also allows implicit *downcasts* (in other words from supertype to
subtype):

```dart
Base b = new Derived();
Derived d = b; // Allowed.
```

(The reasoning here is that many times a downcast *will* work correctly at
runtime, and Dart's type system is optimistic that you know what you're doing.)

Thanks to this, nullable types are easy to work with. It is, of course, always
safe to go from a non-null type to a nullable one:

```dart
int? a = 123;
```

But it's equally easy (though not equally *safe*) to go in the other direction:

```dart
int? a = 123;
int b = a; // Allowed.
```

If you actually want to be safe, you just need to check for null first:

```dart
if (a != null) {
  int b = a; // Safe at runtime now too!
}
```

So here, as in other places in Dart, the type checker won't get in your way.

## Wait, what good is it?

You couldn't ask for a less intrusive null-tracking system, but it seems a
little *too* unintrusive. Isn't silently assigning from a nullable type to a
non-nullable one the exact thing we'd want the type checker to flag?

Well, yes, sort of. But Dart's specified static checker isn't that strict in
general. It also doesn't flag implicit downcasts, which this is just a special
case of. Even without that, I think we still get a lot of mileage out of this:

*   Gilad describes Dart as having a "documentary" type system. With nullable
    and non-nullable types, we can now use type annotations to tell users of our
    APIs which things accept `null` and which don't. In other languages you have
    no choice but to spell that out in the documentation. With this, it's right
    in the type signature for a method. If you call `method(Foo a, Foo? b)`,
    it's clear that it can handle a `null` for the second argument but not the
    first.

*   In checked mode, if you try to assign `null` to a non-nullable type, the
    runtime will throw an error. This means you'll know when a `null` snuck in
    *as soon as it happens*, and not later on in the program when you
    accidentally try to call a method on `null`. That is, I think, a big part of
    what you want `null` checking for.

*   As I mentioned before, it ensures non-nullable types are initialized. Sure,
    you can implicitly assign from a nullable type to a non-nullable one, but
    what you can't do is implicitly assign from `null` to a non-nullable type.
    This is a static error:

    ```dart
    int a = null;
    ```

    That goes a long way towards flushing out uninitialized variable bugs. In
    my experience with Dart, that's one of the most common errors I run into.

*   While the specified type check behavior allows implicit downcasting, tools
    are encouraged to do their own smarter analysis. If we get nullability
    annotations in Dart, it will be easy to have tools do data flow analysis and
    report warnings like this:

```dart
double(int? i) {
  return i * 2; // Warn that we didn't test i for null first.
}

double(int? i ) {
  if (i == null) return 0;
  return i * 2; // OK now.
}
```

## Nullables and generics

A key question that comes up with nullables is how they play with generic types.
I'm not a type system expert, so it's entirely possible that I haven't thought
this all the way through, but I think it falls out correctly from the subtyping
between nullable and non-nullable types.

Generics are covariant in Dart. That means that generics also allow subtyping
between a nullable and non-nullable type argument. In other words, this is
allowed:

```dart
List<int?> list = new List<int>();
```

As long as you use your types in a way that makes covariance safe (i.e. you read
from them and don't write to them) this will work as well for nullable types as
it does with subclassing.

The other question is how using a type parameter in an annotation plays with
nullability. For example:

```dart
class SomeClass<T> {
  T? someField;
}
```

This is *really* beyond the edge of my type system fu, but I think the fact that
nullable types flatten (`A??` becomes `A?`) will alleviate some of the nasty
corner cases this may lead to. I'm not sure though, and this is definitely
something I'd like feedback on.

## Two corner cases

There are two types in Dart where nullability will work a little strangely:
`Null` and `Object`. The former's behavior is pretty obviously weird. Given that
a nullable type is the union of some type and `Null`, there's no dinstinction
between `Null` and `Null?` (since nullability flattens). Likewise, you can't
have a non-nullable `Null` type (since no possible values could inhabit it).

The other case is a bit more surprising. You can't have a non-nullable `Object`
type. `Object` is the [top type][] which means *every* object is an instance of
`Object`, including `null`. In practice, I think this works OK. If you have a
variable of type `Object`, the only operations you can perform on it are ones
that all types support, like `toString()`. Even `null` supports those, so a
non-nullable `Object` type isn't needed to avoid type errors.

[top type]: http://en.wikipedia.org/wiki/Top_type

That covers most of the implications of the proposal as far as I can tell. To
get more concrete, let's see how we'd need to modify the spec and libs to
support it:

## Spec changes

I definitely don't have the skills Gilad has at specifying these semantics
precisely, but I'll at least make an honest try. Most of the changes, as you'll
see, are simplifications. Null shows up as a special case in much of the spec.
One of the reasons I like this proposal is that it eliminates most of those.

### Section 10.2

Change:

> The static type of null is ⊥.

to:

> The static type of null is Null.

### Section 10.16 Assignment

In both:

> In checked mode, it is a dynamic type error if o is not null and the interface
> induced by the class of o is not a subtype of the actual type (13.8.1) of v.

and:

> In checked mode, it is a dynamic type error if o is not null and the interface
> induced by the class of o is not a subtype of the static type of C.v.

remove "o is not null and".

### Section 10.13.2 Binding Actuals to Formals

From:

> In checked mode, it is a dynamic type error if oi is not null and the actual
> type (13.8.1) of pi is not a supertype of the type of oi,i ∈ 1..m.

remove "oi is not null and". And from:

> In checked mode, it is a dynamic type error if om+j is not null and the actual
> type (13.8.1) of qj is not a supertype of the type of om+j,j ∈ 1..l.

remove "om+j is not null and".

### Section 11.9 Try

From:

> A catch clause catch (T1 p1, T2 p2) s matches an object o if o is null or if
> the type of o is a subtype of T1."

remove "o is null or".

Then we need to add a section:

### 13.9 Nullable Types

> A *nullable type* is a parameterized type that allows both values of the type
> parameter's type or the singleton value of type *Null*, `null`.
>
> Let *A?* be the nullable type of type *A*. Nullable types do not nest or wrap:
> *B??* is equivalent to *B?* for any type *B*. The subtype relations are:
>
> *   *A* <: *A?* (non-nullable is a subtype of a nullable)
>
> *   *Null* <: *A?* (non-nullable is also a subtype of Null)
>
> It is a static error to declare a variable of a non-nullable type without
> giving it an initializer whose static type is assignment compatible with the
> variable's type.

## Core library changes

This proposal implies some modification to the core lib APIs to be null-aware.
There are two kinds of changes we'd need: minor changes to type annotations and
a few actual semantic changes.

### Type annotation changes

The minor change is that a few type annotations need to be tweaked. Operations
that are defined to return something "or null" need to be made explicitly
nullable.

For example, the [`Map<K,V>` interface][map] has a subscript operator
(`map[key]`) that returns `null` if the key isn't found. Right now its return
type is declared to be `V`, the value type. It needs to be `V?` instead to
explicitly permit that `null`.

[map]: https://api.dart.dev/stable/2.14.4/dart-core/Map-class.html

Likewise, there are a number of methods that take named optional parameters
whose types aren't nullable, like:

```dart
class Expect {
  static void isFalse(actual, [String reason = null])
  // more...
}
```

Here, that `String` will need to be made nullable.

### Semantic changes

The more intrusive change is that operations that implicitly create `null`
entries in collections might need to be modified. For example, if you do:

```dart
var list = new List<int>(4);
```

then you create a list whose four elements are automatically set to `null`.
That's a problem here because the element type (`int`) is non-nullable.

The safest way to handle this is to change the constructor to let the user
explicitly provide the value to initialize the new entries with. So instead of
the above, you could do:

```dart
var list = new List<int>(4, fill: 1);
print(list); // [1, 1, 1, 1]
```

or maybe:

```dart
var list = new List<int>.generate(4, (index) => index * 2);
print(list); // [0, 2, 4, 6]
```

I may have missed something, but I believe `List` is the only type that needs
any real API changes like this.

## Summary

If you made it this far, you deserve a reward. Sadly, the best I can offer is a
bullet list of what you've already read:

*   All types are non-nullable by default.

*   You define a nullable type by adding `?` after the type.

*   Nested nullable types flatten: `A?? -> A?`.

*   A non-nullable type is a subtype of its nullable type.

*   No nullable *values*: no `option` or `Maybe`.

*   Can assign back and forth between nullable and non-nullable types.

*   Must initialize non-nullable variables to non-null values.

*   Lets types document which things expect null.

*   Catches invalid nulls early in checked mode.

*   Most spec changes are just removing "or null".

*   Most corelib changes are making some annotations nullable.

*   Probably want to change `List` constructor to avoid implicit null fill
    values.

*   This proposal is awesome.

Do I have that right? Thoughts?
