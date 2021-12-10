---
title: "Long Names Are Long"
categories: code dart
---

One smart thing Google does is rigorous code reviews. Every change, before you
can land it, gets reviewed in at least two ways. First, someone on the team does
a normal review to make sure the code does what it's supposed to.

But, then, there's a second layer of review called *readability*. It makes sure
the code is, well, readable: Is it easy to understand and maintain? Does it
follow the style and idioms of the language? Is it well-documented?

[Dart][] usage inside Google is cranking up, so I've been doing a ton of these
kind of code reviews. As a language designer, it's fascinating. I get a
firsthand view into how people use Dart, which is really useful for evolving the
language. I have a clearer picture of which mistakes are common and which
features are heavily used. I feel like an ethnographer journaling the lives of
natives.

[dart]: https://www.dartlang.org/

But, anyway, that's not what this is about. Heck, it's not even about Dart. What
I want to talk about is something I see in a lot of code that drives me up the
wall: **identifiers that are too damn long.**

Yes, names can be too short. Back when C only required external identifiers to
be unique up to the first six characters; auto-complete hadn't been invented;
and every keypress had to be made uphill, in the snow, both ways; it was a
problem. I'm glad we now live in a futuristic utopia where keyboard farts like
`p`, `idxcrpm`, and `x3` are rare.

But the pendulum has swung too far in the other direction. We shouldn't be
Hemingway, but we don't need to be Tennessee Williams either. Very *long* names
also hurt the clarity of the code where they are used. Giant identifiers dwarf
the operations you're performing on them, are hard to visually scan, and force
extra line breaks which interrupt the flow of the code.

Long class names discourage users from declaring variables of that type, leading
to massive, gnarly nested expressions instead of hoisting things out to locals.
Long method names obscure their equally important argument lists. Long variables
are annoying to use repeatedly, leading to sprawling method chains or cascades.

I've seen identifiers over 60 characters long. You could fit a haiku or a koan
in there (and likely enlighten the reader more than the actual chosen name did).
Fear not, I am here to help.

## Choosing a Good Name

A name has two goals:

* It needs to be *clear*: you need to know what the name refers to.

* It needs to be *precise*: you need to know what it does *not* refer to.

After a name has accomplished those goals, any additional characters are dead
weight. Here's some guidelines I use when I names things in my code:

### 1. Omit words that are obvious given a variable's or parameter's type

If your language has a static type system, users usually know the type of a
variable. Methods tend to be short, so even when looking at local variable whose
type was inferred, or in a code review or some place where static analysis isn't
available, it rarely takes more than scanning a few lines to tell what type a
variable has.

Given that, it's redundant to put the type in the variable's name. We have
rightfully abandoned [Hungarian notation][]. *Let it go.*

[hungarian notation]: https://en.wikipedia.org/wiki/Hungarian_notation

```dart
// Bad:
String nameString;
DockableModelessWindow dockableModelessWindow;

// Better:
String name;
DockableModelessWindow window;
```

In particular, for collections, it's almost always better to just use a plural
noun describing the *contents* instead of a singular noun describing the
*collection*. If the reader cares more about what's *in* the collection, the
name should reflect that.

```dart
// Bad:
List<DateTime> holidayDateList;
Map<Employee, Role> employeeRoleHashMap;

// Better:
List<DateTime> holidays;
Map<Employee, Role> employeeRoles;
```

This also applies to method names. The method name doesn't need to describe its
parameters or their types&mdash;the parameter list does that for you.

```dart
// Bad:
mergeTableCells(List<TableCell> cells)
sortEventsUsingComparator(List<Event> events,
    Comparator<Event> comparator)

// Better:
merge(List<TableCell> cells)
sort(List<Event> events, Comparator<Event> comparator)
```

This tends to make callsites read better:

```dart
mergeTableCells(tableCells);
sortEventsUsingComparator(events, comparator);
```

Is it just me, or is there an echo echo in here here?

### 2. Omit words that don't disambiguate the name

Some people tend to cram everything they know about something into its name.
Remember, the name is an *identifier*: it points you to *where* it's defined.
It's not an exhaustive catalog of everything the reader could want to know about
the object. The definition does that. The name just gets them there.

When I see an identifier like `recentlyUpdatedAnnualSalesBid`, I ask:

* Are there updated annual sales bids that aren't recent?

* Are there recent annual sales bids that were not updated?

* Are there recently updated sales bids that aren't annual?

* Are there recently updated annual bids not related to sales?

* Are there recently updated annual sales things that are not bids?

A "no" for any of these usually points to an extraneous word.

```dart
// Bad:
finalBattleMostDangerousBossMonster;
weaklingFirstEncounterMonster;

// Better:
boss;
firstMonster;
```

Of course, you can go too far. Shortening that first example to `bid` might be a
little *too* vague. But, when in doubt, leave it out. You can always add
qualifiers later if the name proves to cause a collision or be imprecise but
it's unlikely you'll come back later to trim the fat.

### 3. Omit words that are known from the surrounding context

I can use "I" in this paragraph because you can see this post is by Bob Nystrom.
My dumb face is right up there. I don't need to keep saying “Bob Nystrom”
everywhere here (despite Bob Nystrom's temptation to aggrandize Bob Nystrom by
doing so). Code works the same way. A method or field occurs in the context of a
class. A variable occurs in the context of a method. Take that context for
granted and don't repeat it.

```dart
// Bad:
class AnnualHolidaySale {
  int _annualSaleRebate;
  void promoteHolidaySale() { ... }
}

// Better:
class AnnualHolidaySale {
  int _rebate;
  void promote() { ... }
}
```

In practice, this means that the more deeply nested a name is, the more
surrounding context it has. That in turn means it usually has a shorter name.
The effect is that identifiers with shorter scopes have shorter names.

### 4. Omit words that don't mean much of anything

I used to see this a lot in the game industry. Some people succumb to the
temptation to inflate their identifiers by adding Serious Business sounding
words. I guess it makes their code feel more important and, by extension, makes
*them* feel more important.

In many cases, the words carry no meaningful information. They're just fluff or
jargon. Usual suspects include: `data`, `state`, `amount`, `value`, `manager`,
`engine`, `object`, `entity`, and `instance`.

A good name paints a picture in the mind of the reader. Calling something a
"manager" doesn't convey any image to the reader about what the thing does. Does
it do performance evaluations? Lean over your cubicle and ask for TPS reports?

Ask yourself "Would this identifier mean the same thing if I removed the word?"
If so, the word doesn't carry its weight. Vote if off the island.

## Applying the Guidelines... to Waffles

To give you a feel for how these rules work in practice, here's an example that
breaks all of these rules. This contrived example is tragically close to real
code I've seen in reviews:

```dart
class DeliciousBelgianWaffleObject {
  void garnishDeliciousBelgianWaffleWithStrawberryList(
      List<Strawberry> strawberryList) { ... }
}
```

We know from the type that it takes a list of strawberries (#1), so let's cut
that out:

```dart
class DeliciousBelgianWaffleObject {
    void garnishDeliciousBelgianWaffle(
        List<Strawberry> strawberries) { ... }
}
```

Unless our program has foul-tasting Belgian waffles, or waffles of other
nationalities, we can drop those adjectives (#2):

```dart
class WaffleObject {
  void garnishWaffle(List<Strawberry> strawberries) { ... }
}
```

The method is inside a ```WaffleObject```, so we know what it's going to garnish
(#3):

```dart
class WaffleObject {
  void garnish(List<Strawberry> strawberries) { ... }
}
```

Obviously it's an object. Everything is an object. That's kind of what
"object-oriented" means (#4):

```dart
class Waffle {
  void garnish(List<Strawberry> strawberries) { ... }
}
```

There, much better.

I think these are pretty simple guidelines. You may think it's pointless to
worry about this stuff, but I believe that [naming things][] is one of the most
fundamental tasks we do when programming. Names are the structure we impose on
the formless sea of bits that is computing.

[naming things]: /2009/06/05/naming-things-in-code/
