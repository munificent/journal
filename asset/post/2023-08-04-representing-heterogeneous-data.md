---
title: "Representing Heterogeneous Data"
tags: language vgs
---

As I mentioned in the [last post][], I'm working on taking my little videogame
scripting language and turning it into a statically typed one. As much as
possible, I'm trying to make the language simple and familiar. But sometimes
those goals are in opposition and the most familiar solution to a problem is
kind of a mess.

[last post]: /2023/01/03/type-checking-if-expressions/

So, I'm also exploring novel approaches and delving deeper into programming
language history to scavenge forgotten ideas.

## The heterogeneous data problem

One problem every language has to solve is giving users a way to represent
*heterogeneous data*. By that, I mean:

*   **Data that might or might not be present.** Imagine you have a record for
    storing a street address:

    ```vgs
    rec Address
      var number Int
      var street String
      var apartmentNumber Int
      var city String
      var zipCode Int
      var state String
    end
    ```

    But some addresses don't have apartment numbers. How do you store the
    apartment number when an address has one but also support its absence?

*   **Data that might be in one of several different forms.** You're making a
    game where a hero can wield weapons. Melee weapons like swords have a single
    number for how much damage they do. Ranged weapons like crossbows have a
    pair of numbers for the minimum and maximum range they can reach. How do
    different kinds of weapons have different fields?

These are two sides of the exact same coin. You can treat optional data as data
that can be in one of two forms: present with an associated value or absent with
no value attached. Functional languages with an [option or maybe type][] do
exactly that: The language directly supports data that can have one of multiple
forms, and they model absent data using that.

[option or maybe type]: https://en.wikipedia.org/wiki/Option_type

Conversely, you could model data being in one of several different forms by
having separate fields for all possible forms it could be in. At any point in
time, only one of the fields has a value and the others are all absent. If
you've ever found yourself building a struct or class and writing a comment that
says "If this field is blah then this other field will be null." then you've
taken this path (and probably felt a little gross doing it).

## What other languages do

I don't know if broad language tours are your thing, but so much of my job
working on [Dart] involves researching how other languages solve a problem that
I can't help myself anymore.

[dart]: https://dart.dev

There are a handful of solutions to the problem. I'll just throw out the ones I
know:

*   **Null.** The [most famously maligned][billion] approach is to allow any
    reference variable to potentially refer to "null", "nil", or nothing. This
    means every reference type can directly also represent an absent value. Of
    course, the problem is that many data fields *aren't* heterogeneous and
    *should* always be present. If you make every single reference nullable,
    you've lost the ability to distinguish ones that can be absent from ones
    that really shouldn't be.

    [billion]: https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/

    This is why many newer statically typed languages either don't support
    null at all (Rust and most other statically typed functional languages) or
    support [non-nullable types] (Dart, Kotlin, and TypeScript).

    [non-nullable types]: https://en.wikipedia.org/wiki/Nullable_type

*   **Variant types.** A "variant" type is a type that can hold a value of one
    of multiple different types. You can think of nullable references as a
    limited variant type that can hold either a value of one specific type or
    the special `null` value but that's it. Some languages have looser variants
    that let you store values of any type in the same variable.

*   **Untagged unions.** C lets you define a data structure whose fields all
    share overlapping memory. If you have a few different pieces of data that
    are *disjoint* -- you should only ever have one of them and not the others
    -- then this avoids the memory overhead of storing them all separately.

    However, in C, the language itself doesn't keep track of *which* piece of
    data you have in the union. It will freely let you write one field and then
    read out another and it will happily just reinterpret the bits in memory as
    that other type. Efficient, yes. Safe? No.

*   **Sum types.** Functional languages going all the way back to [ML] have a
    feature also sometimes confusingly called "unions" that is fairly different.
    Again, you have an object that can store one of a few different kinds of
    data. But the language also stores a *tag* in there so that it knows at
    runtime which piece of data you have. (This is why they're also called
    "tagged unions" or "discriminated unions".)

    [ml]: https://en.wikipedia.org/wiki/ML_(programming_language)

    The language uses [pattern matching][] to cleverly prevent you from
    accessing the data as the wrong type.

    [pattern matching]: https://dart.dev/language/patterns#algebraic-data-types

*   **Subtyping.** The object-oriented dual to sum types is subtyping: either
    inheritance or interface implementation. In an object-oriented language, we
    could model our weapon example like:

    ```dart
    interface class Weapon {}

    class MeleeWeapon implements Weapon {
      int damage;

      MeleeWeapon(this.damage);
    }

    class RangedWeapon implements Weapon {
      int minRange;
      int maxRange;

      RangedWeapon(this.minRange, this.maxRange);
    }
    ```

    Code that wants to work with weapons generally uses the `Weapon` supertype.
    The two subtypes for melee and ranged weapons each store the fields they
    need. If you want to go all the way to an object-oriented style, these
    fields would be private and then you'd have abstract methods in `Weapon`
    that are overridden in the subclasses to use them.

    It's a complex, heavyweight approach, but a powerful and flexible one.

There may be a couple of other weirder language features you can use to model
varied data, but I think these are the big ones. Languages tend to pick and
choose from this list:

*   **Dynamically typed languages** essentially treat *all* variables as variant
    types. And all the ones I know also go ahead and allow null too. If you're
    not going to have any static checking anyway, you may as well be maximally
    permissive, I guess.

*   **Statically typed functional languages** lean really hard on sum types.

*   **Object-oriented languages** obviously primarily use subtyping, though most
    also have nullable reference types.

*   **C** makes pointer types nullable and supports untagged unions. It doesn't
    have (checked) variants or subtyping, but it can approximate both by
    allowing pointers to be cast to different types. **C++** takes everything C
    has and also explicitly supports subtyping.

Newer, bigger multi-paradigm languages like C# and Swift tend to take just about
all of the approaches.

## Whither for my little language?

OK, so what's the right approach for my aspirationally simple and elegant
statically typed game scripting language?

I quite like object-oriented programming in general, but subtyping adds a *lot*
of complexity to a static type system, so my current plan is to not have
subtyping in the language at all. That rules out that approach.

My goal is for the language to be fairly high level and expressive. It's
supposed to be a language that makes making games *fun*, not necessarily a
high-performance machine for engineering giant AAA games. I want you to have a
good time tinkering on pixelly 2D games, not write the next Unreal Engine in it.
To that end, the language is garbage-collected. That means memory safety, which
rules out untagged unions.

Back when this language was dynamically typed, it had `nil`, so that's an
obvious approach. But I've spent, like, [way too much of my time][dart old]
[rooting out nullable references from Dart][dart new] and the last thing I want
to do with my hobby project is to go back to square one.

[dart old]: /2011/10/29/a-proposal-for-null-safety-in-dart/
[dart new]: https://medium.com/dartlang/announcing-dart-3-53f065a10635

That basically just leaves sum types and variant types. Given that my language
is statically typed and not object-oriented, sum types are the obvious approach.
Everyone who uses sum types loves them, myself included. Algebraic datatypes are
just *cool.*

And, in fact, I went ahead and implemented a protype of sum types and pattern
matching and destructuring in my language. It worked. It was... just OK. To
explain why requires a little context

## An imperative, procedural language

My language is unabashedly imperative. I *like* imperative programming,
especially for scripting little games. Games are giant balls of mutable state.
I've watched my kids and many others learn to program, and imperatively
modifying stuff seems to be a natural way to think about defining a process.

When you read a recipe for cake, you don't see steps like: "Produce a new bowl
of batter which is the previous bowl of batter and 2 cups of sugar." It just
says "Add 2 cups of sugar to the bowl."

Now, I know all of the problems with mutation of state and imperative code when
programming in the large. I get it. But this is supposed to be a fun little
language for fun little games and, to me, imperative programming fits that to a
tee.

The basic vibe I have for the language is similar to Pascal, C, or BASIC: In
other words, a classic procedural language. Structures and functions. It looks
like this:

```vgs
rec MeleeWeapon
  var damage Int
end

def attack(weapon MeleeWeapon, monster Monster, distance Int)
  if distance > 1 then
    print("You are out of range.")
    return
  end

  var damage = rollDice(weapon.damage)
  if monster.health <= damage then
    print("You kill the monster!")
    monster.health = 0
  else
    print("You wound the monster.")
    monster.health = monster.health - damage
  end
end
```

What's cool about simple procedural code is that even though I have no idea what
language you know and you *certainly* have never programmed in *this* one, I'm
still pretty confident that you understand this code.

## With sum types

Let's see how it looks with something like sum types:

```vgs
rec Weapon
case MeleeWeapon
  var damage Int
case RangedWeapon
  var minRange Int
  var maxRange Int
end

def attack(weapon Weapon, monster Monster, distance Int)
  var isInRange = match weapon
  case MeleeWeapon(damage) then distance == 1
  case RangedWeapon(min, max) then distance >= min and distance <= max
  end

  if !isInRange then
    print("You are out of range.")
    return
  end

  var damage = match weapon
  case MeleeWeapon(damage) then rollDice(damage)
  case RangedWeapon(min, max) then max - min
  end

  if monster.health <= damage then
    print("You kill the monster!")
    monster.health = 0
  else
    print("You wound the monster.")
    monster.health = monster.health - damage
  end
end
```

The sort of weird `rec` syntax is defining a sum type, `Weapon`, with type
constructors `MeleeWeapon` and `RangedWeapon`. I'm still noodling on the syntax.

Now, the code here works. And it's safe. The compiler and the structure of the
pattern matching code itself prevent you from accessing the wrong fields from a
weapon of a different kind. That's cool.

But it's so much *weirder* than the previous code. In a procedural language, the
idiomatic way to access fields on records is simply `record.field`. That syntax
is in almost every programming language all the way back to Algol. But once you
hop over to sum types, you lose that syntax entirely and have to instead sort of
"invert" the code and use pattern matching and destructuring.

I do love pattern matching and destructuring -- I just spent the past year of my
life [adding it to Dart][patterns]. But for *this* language, I'm pushing really
hard on simplicity. If possible, I don't want *two* different ways to access
state on a value, depending on whether the field is case-specific or not.

[patterns]: https://github.com/dart-lang/language/blob/main/accepted/3.0/patterns/feature-specification.md

More to the point, there's no graceful way to handle *mutable* sum type fields
using pattern matching. SML eschews mutability in general and then works around
it by allowing you to define explicit mutable ref types. But that's definitely
not how my language rolls.

## Variant records

There is *one* other approach to heterogeneous data that I found that I didn't
put in the list up there because, as far as I can tell, it's basically a dead
end in the evolutionary history of programming languages.

Some versions of Pascal have a thing called "variant records". A record in
Pascal is your basic "collection of fields" struct type. A *variant* record says
that *some* of those fields are only accessible when the record is one of a few
different enumerated states.

In C, it's common to wrap an untagged union in a struct along with a tag enum
indicating which branch of the union is active:

```c
typedef enum {
  WEAPON_MELEE,
  WEAPON_RANGED
} WeaponType;

typedef struct {
  WeaponType type;
  union {
    struct {
      int damage;
    } melee;
    
    struct {
      int minRange;
      int maxRange;
    } ranged;
  } as;
} Weapon;
```

Using it looks something like:

```c
Weapon weapon;
weapon.type = WEAPON_MELEE;
weapon.as.melee.damage = 6;
```

A variant record in Pascal (as I understand it from the half dozen ancient
slideshows I've been able to find about it) essentially models that pattern
directly.

The cool thing about this feature is that the variant-specific fields are
accessed using the same familiar field access syntax used everywhere else. That
also means variant-specific fields can be mutable.

Of course, the *not* cool thing about using that same field syntax is that
there's nothing preventing you from accessing the *wrong* variant field:

```c
Weapon weapon;
weapon.type = WEAPON_MELEE;
weapon.as.melee.damage = 6;

printf("Min range %d\n", weapon.as.ranged.minRange); // Oops.
```

There is a type tag, but the language doesn't know and doesn't check it. This is
definitely true in C and I think true in Pascal. (It's always hard to talk about
Pascal definitively because there's no "Pascal", just a huge family of
loosely-related Pascal-ish languages.)

In a memory safe language like mine, I definitely don't want users to be able
to reinterpret memory. But that's a solvable problem.

## Record cases

Which, finally, brings us to the feature I designed for my language. It's very
close to variant records in Pascal. The type declaration looks just like the
sum type example:

```vgs
rec Weapon
case MeleeWeapon
  var damage Int
case RangedWeapon
  var minRange Int
  var maxRange Int
end
```

The difference is that you don't need to rely on pattern matching to access the
variant fields. They're just fields:

```vgs
def attack(weapon Weapon, monster Monster, distance Int)
  if weapon is MeleeWeapon and distance > 1 or
      distance < weapon.minRange or
      distance > weapon.maxRange then
    print("You are out of range.")
    return
  end

  var damage = if weapon is MeleeWeapon then
    rollDice(weapon.damage)
  else
    weapon.maxRange - weapon.minRange
  end

  if monster.health <= damage then
    print("You kill the monster!")
    monster.health = 0
  else
    print("You wound the monster.")
    monster.health = monster.health - damage
  end
end
```

Of course, you lose the compile-time safety that pattern matching gives you
where you can't access fields of the wrong type. But we don't need to go all the
way to C's level of unsafety. Instead, when you access a case-specific field on
a record, if the record's type tag is set to a different case, the access throws
a *runtime* error. This preserves memory safety.

This is a real trade-off. The feature I have here provides strictly less static
safety than using sum types. There is a slight performance cost to checking the
type tag when accessing case-specific fields. In return, you get simpler, more
familiar syntax for working with case-specific fields, including mutable ones.

Also, it allows a single record to have a mixture of shared and case-specific
fields:

```vgs
rec Weapon
  var name String
  var bonus Int
case MeleeWeapon
  var damage Int
case RangedWeapon
  var minRange Int
  var maxRange Int
end
```

Here, `name` and `bonus` can be accessed on all `Weapon` instances, but the
other fields are case specific. It sort of combines product and sum types into a
single construct. I've found this to be really handy in practice.

I haven't decided if I'm totally sold on this feature yet. But in the
(admittedly small) amount of example code I've written using it so far, it seems
to feel pretty nice. For a small game scripting language, I think it may strike
a decent balance between static safety and simplicity.

## Update: What about flow typing?

When I first posted this, the most common reply was why not do some sort of flow
typing? In code like:

```vgs
def attack(weapon Weapon, monster Monster, distance Int)
  if weapon is RangedWeapon and
        (distance < weapon.minRange or distance > weapon.maxRange) or
      distance > 1 then
    print("You are out of range.")
    return
  end

  # ...
end
```

The compiler could do control flow analysis to determine that the `.minRange`
and `.maxRange` calls are guarded by an `is RangedWeapon` and thus allow them.
But if you *don't* guard the code with that kind of check, you'd get an error:

```vgs
def attack(weapon Weapon, monster Monster, distance Int)
  if distance < weapon.minRange or # Error! Can't access .minRange here.
     distance > weapon.maxRange then
    print("You are out of range.")
    return
  end

  # ...
end
```

This is definitely a thing you can do! TypeScript, Kotlin, Flow, Dart, and
others all support it. The general technique is called "control flow analysis"
and the specific feature is called "flow typing", "smart casts", or "type
promotion" depending on which language.

Is it a good fit for my language? I do like that it makes imperative code "just
work" while being safe. But that "just" is doing a lot of heavy lifting. We do
this analysis in Dart and it is *fantastically* complex. Proving that a certain
piece of code can only be reached by going through some other piece of code
first gets hard quickly in the presence of loops and closures. It seems like
every release of Dart, we ship more extensions to flow analysis because users
keep expecting it to be smarter and smarter.

Also, it isn't sound in many cases that users expect to work. Once the variable
that you're type testing can escape the current function, the compiler generally
can't prove that it won't be mutated between when you test its type and when you
use it as the more precise type later.

Overall, my feeling is that it works out pretty well for Dart, but it's a large
sort of messy feature that feels a little too magical. A goal with my hobby
language is that you should be able to have the whole language loaded into your
head and rarely be surprised by what it does. Flow analysis in Dart still fairly
often surprises me and I *literally work on the language full-time*.

There's also the question of what you promote the tested variable *to*. In my
language as it currently stands, there is no subtyping. `MeleeWeapon` isn't a
subtype of `Weapon`, it's a case constructor. The `weapon is MeleeWeapon` syntax
looks like a type test, but it's really more like an enum case check.

So after that test, what type would `weapon` have? It would still have to be
`Weapon`. I guess I could make this work by not promoting the *type* but by
having the type checker track an extra "known case" property for each static
type and then use that. That might work. But even with that, I worry that it
would quickly become annoying. Let's say you refactor the above code to:

```vgs
def attack(weapon Weapon, monster Monster, distance Int)
  if weapon is RangedWeapon and checkRange(weapon, distance) or
      distance > 1 then
    print("You are out of range.")
    return
  end

  # ...
end

def checkRange(weapon Weapon, distance Int) Bool
  distance < weapon.minRange or distance > weapon.maxRange
end
```

That no longer works. Inside `checkRange()` the compiler has lost track that
`weapon` is always a `RangedWeapon`. You could come up with a way to annotate
that, but now we're back to subtyping and all the complexity it involves.

So, overall, yes, subtyping and flow analysis is a thing that could work here,
but I'm trying to avoid it because I feel like it's a bigger lump of complexity
than I want to take on.

I'd be more inclined to do sum types and destructuring, even though it feels a
little weird in an imperative language, then do this kind of complex control
flow analysis.
