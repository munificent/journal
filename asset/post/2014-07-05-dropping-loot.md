---
title: "Dropping Loot"
categories: code game-dev roguelike dart
---

I got started hacking on my own roguelike after spending several years avidly
playing [Angband][]. Like most projects, I had a few itches I wanted to scratch
and it kind of took on a life of its own. One thing that annoyed me about
Angband was how monsters dropped loot when they died.

[angband]: http://rephial.org/

In Angband, any monster that drops stuff can drop pretty much anything. Monsters
have a level, and if they drop loot, it just randomly picks any item near the
monster's level. This bugged me for two reasons:

1.  **It felt flavorless and unrealistic.** For example, the description of a novice mage is:

    ```
    The Novice mage  (Red 'p')
    === Num:38  Lev:2  Rar:1  Spd:+0  Hp:6d4  Ac:6  Exp:6
    He is leaving behind a trail of dropped spell components.
    ```

    But when you hack one to pieces, he's as likely to drop a sword as he is
    anything magical. This makes monsters feel too similar each other: each one
    is basically a spin on the one giant Wheel Of Loot.

2.  **It made it impossible for the player to seek certain items.** Let's say
    you've got a good kit of armor except you really could use some high quality
    boots. How do you fill in that gap?

    In Angband, the answer is "kill a whole ton of stuff and wade through piles
    of loot you don't care about". Especially near the end game where you're
    looking for just a few specific pieces of gear, you spend a *lot* of time
    just killing dragons and hunting through mountains of loot. 95% of it gets
    left on the ground.

I wanted to solve this by making different monsters drop different stuff. Kill a
warrior, and you should get weapons and armor. Kill a wizard, get wands and
scrolls.

## Monster-specific loot

My first pass at this was to give each monster its own set of drops. I had
already made monsters data-driven. I came up with my own little text format so
monsters were defined in text something like:

```
dwarf miner
    color     = DarkGray
    depth     = 22
    health    = 44
    attacks
        hammers = 15t5
    description
        Covered from head to toe is dust and dirt, you can barely
        make out the form of this weary dwarf.
```

For each monster (or at least, each one that drops loot), I added a "drops"
section, like:

```
drops
    hammer (50%)
```

And, behold, kill a dwarven miner and there's a fifty-fifty chance he'll drop a
hammer. But dwarves like gems too, right? So I added that in too. Only the
problem is that there's a bunch of different kinds of gems, so I ended up with
something like:

```
drops
    hammer (50%)
    amethyst (10%)
    sapphire (7%)
    emerald (4%)
    ruby (3%)
    diamond (2%)
    blue diamond (1%)
```

The game uses the percentages to pick one of the drops. Notice how the better
gems are rarer? That's fine for a miner, which is a pretty weak dwarf, but a
dwarf chieftan should tend to drop better gems:

```
drops
    amethyst (3%)
    sapphire (5%)
    emerald (8%)
    ruby (10%)
    diamond (8%)
    blue diamond (5%)
```

Now consider that there's a few different types of hammers too... Things got
pretty nasty pretty quickly. It was a huge chore to maintain these giant tuned
drop tables for each of potentially hundreds of monsters. Ugh.

The first thing I realized was that there was a lot of overlap between monsters.
Dwarven miners and dwarven warriors drop the same gems with the same frequency.
So I made "macros" in my drop language. I could define:

```
(gem)
    hammer (50%)
    amethyst (10%)
    sapphire (7%)
    emerald (4%)
    ruby (3%)
    diamond (2%)
    blue diamond (1%)
```

Then in dwarven miner and warrior, just add:

```
drops
    (gem)
```

The `(gem)` would then expand to that little weighted table of gems. That worked
fine when the probabilities of each gem were the same, but it meant I couldn't
reuse these tables across dwarves of different *difficulty*. Stronger dwarves
drop the same gems but with different probabilities.

So I came up with a different kind of drop that selects from a bunch of child
drops based on *level*. This let me define:

```
(gem)
    one near level
        amethyst (23)
        sapphire (38)
        emerald (52)
        ruby (62)
        diamond (87)
        blue diamond (95)
```

The "one near level" part would take the monster's level into account, plus a
bit of randomness, and pick a child drop from within it. Now I could reuse
`(gem)` across a range of different difficulties. Of course, I still had to
define lots of tables for all of these different "kinds" of drops. There was a
table for gems, stones, hammers, daggers, etc. Piles of data.

After all of that, I found it wasn't fun to play. The problem was that even with
these tables, killing a monster was... *boring*. Every time you killed a dwarf,
you knew what you were going to get. You might get a better gem (yay), but
nothing surprising.

## Simpler Sequences

A few years ago, I [ported the game][hauberk] to [Dart]. When I did, I tried to
simplify as many things as I could. I didn't want to rewrite this whole giant
DSL macro language thing. Instead, I noticed that every item seemed to be a
member of some sequence. Emeralds are always in a sequence of gems, a hammer is
in a sequence with warhammers and mattocks, etc.

[hauberk]: https://github.com/munificent/hauberk
[dart]: https://www.dart.dev/

Instead of building some complex general-purpose loot DSL and then implementing
this logic using that, I just built sequences directly into the loot code. When
defining a monster (now we're in Dart code), you'd list the drops:

```dart
breed("goblin peon", lightBrown, 16, [
  attack("stab[s]", 6)
], drop: [
  chanceOf(10, "Spear")
]);
```

The "Spear" means it tends to drop spears. But it also implicitly means it can
drop other items in the same sequence that spears are in. This lets you express
both a sequence and how deep into the sequence a monster should tend to drop. To
have a stronger monster drop items from the deep end of the sequence, just name
an item from that end.

This let me express pretty much what I could before, but it was a hell of a lot
simpler. The only limitation is that an item could only be a part of one
sequence. In practice, that works OK.

Unfortunately, though, it didn't solve the boringness problem. I learned the
hard way that a huge part of the fun of roguelikes is the "lottery effect".
Every time you kill a monster there should be a small chance of getting
something really amazing. That "maybe this one will be the big one" anticipation
is one of the key emotions in the game.

With sequences, you could get something good, but never something *surprising*.
Eventually, I hit upon a solution and, so far, I really like it.

## Item Groups

Instead of sequences of items, I now have a *hierarchy* of them. So, for
example, a stilleto is:

    equipment/weapon/dagger/Stilleto

I'm not generally a fan of hierarchies but I found it surprisingly easy to lump
almost every item into one. Items also have a "level", which describes their
relative value. Higher level stuff is better.

When specifying a drop for a monster, I can specify an item name to drop that
specific item. But I can also specify the name of part of the path and a level,
like:

```dart
breed("goblin peon", lightBrown, 16, [
  attack("stab[s]", 6)
], drop: [
  chanceOf(10, "spear:3"),
  chanceOf(5, "healing:2"),
], meander: 2, flags: "few open-doors");
```

The `"spear:3"` means "drop something from the 'spear' group around level 3".
You don't have to specify the entire path since path components are unique. So
"spear" is equivalent to "equipment/weapon/spear".

So far, this is pretty much equivalent to the sequences from before. The neat
part is what happens when the drop is generated. When picking an item, there's a
small chance that it will walk up the group chain. So "spear:3" will usually
drop a spear, but there's a chance it will drop any weapon (the parent group).
There's an even smaller chance it will drop any piece of equipment (the
grandparent).

Any monster has a chance of dropping almost any item, so you have that pleasant
anticipation. At the same time, the probabilities are weighted so that each
monster still has a unique "feel" to their drops, and you can seek out monsters
that are more likely to drop what you want.

When specifying a drop, you can also directly specify one of the parent groups. For example:

```dart
breed("goblin warrior", gray, 32, [
  attack("stab[s]", 14)
], drop: [
  chanceOf(20, "equipment:6")
], meander: 1, flags: "protective open-doors");
```

Here, the `"equipment:6"` means a goblin may drop *any* kind of equipment. This
makes it really easy to specify monsters that define wide sets of drops. That's
good for high level boss monsters that can serve up an assortment of loot.

At the same time, defining the items is pretty simple. You basically just need
to categorize and assign a level for each item. It looks like this:

```dart
group(r"\"", "equipment/weapon/spear");
weapon("Pointed Stick", 5, brown, "stab[s]", 7);
weapon("Spear", 25, gray, "stab[s]", 12);
weapon("Angon", 35, lightGray, "stab[s]", 16);
weapon("Lance", 45, white, "stab[s]", 24);
weapon("Partisan", 55, darkGray, "stab[s]", 36);
```

(The numbers after the name are their levels.) Once you do that, all of the rest
of the drop behavior falls out naturally. If I add a new item to an existing
group, every monster will then start dropping it, with the right probabilities.
