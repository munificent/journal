---
title: "Amaranth, an Open Source Roguelike in C#"
categories: c-sharp code game-dev roguelike
---

<div class="update">
<p><em>Update 2021/10/08:</em> I moved the code to GitHub and updated the links
below. I also ported it all to <a href="http://dart.dev">Dart</a>:
<a href="https://github.com/munificent/piecemeal">Piecemeal</a> (was Bramble),
<a href="https://github.com/munificent/malison">Malison</a>, and
<a href="https://github.com/munificent/hauberk">Hauberk</a> (was Amaranth). The
game is still nowhere near being done.</p>
</div>

Tonight I get to do something I've wanted to do for a really long time: I'm
open-sourcing the [roguelike][] I've been working on for several years. Amaranth
is an old-school terminal-based roguelike written in C#. It looks like this:

[roguelike]: http://en.wikipedia.org/wiki/Roguelike

<img alt="Screenshot of Amaranth" src="/image/2010/06/amaranth.png" class="framed"/>

Because I'm crazy about decoupling, it's actually split into three separate
projects:

**[Bramble][]** is a very small low-level library containing utility classes. It
doesn't rely on anything beyond core .NET collections and provides more useful
2D [vector][] and [rectangle][] classes, along with some [other handy
stuff][ext]. Even if you aren't working on a game, there may be something in
here you can use, which is why it's separated into its own project.

[bramble]: https://github.com/munificent/bramble-dotnet
[vector]: https://github.com/munificent/bramble-dotnet/blob/master/Bramble.Core/Vec.cs
[rectangle]: https://github.com/munificent/bramble-dotnet/blob/master/Bramble.Core/Rect.cs
[ext]: https://github.com/munificent/bramble-dotnet/blob/master/Bramble.Core/Int32Extensions.cs

**[Malison][]** is the terminal library Amaranth uses for its user interface.
Like many roguelikes, Amaranth doesn't have graphics. Instead, it draws the game
world in ASCII like an old computer terminal. Malison is a generic library for
drawing to a virtual terminal. Even if you don't care about Amaranth, Malison
should be exactly what you need if you're going to write your own roguelike or
other terminal-style app in C#.

[malison]: http://github.com/munificent/malison-dotnet

One nice feature it has is that it decouples a logical terminal from a specific
renderer. It provides a renderer using [WinForms][], but it should be simple to
implement other renderers on top of XNA, WPF, or Silverlight. Code that writes
to a terminal only knows about the [abstract terminal API][term], which means
you could have a single game engine that supports rendering to a bunch of
different terminal implementations. I wrote about the design of the terminal API
in [this post][api].

[winforms]: http://github.com/munificent/malison-dotnet/blob/master/Malison.WinForms/
[term]: http://github.com/munificent/malison-dotnet/blob/master/Malison.Core/ITerminal.cs
[api]: /2008/02/26/avoiding-overload-hell-in-c/

**[Amaranth][]** is the actual game, or the beginnings of one. I have lots of
work left to do here, but a lot is also done. I'll be writing more about
interesting bits of the engine, I hope. In the meantime you'll have to dig
around in the code if you're curious. Some fun stuff it supports:

[amaranth]: https://github.com/munificent/amaranth

*   The game engine is completely decoupled from UI. It was designed so that if
    I later write a graphical front-end for it, *zero* engine code would need to
    change.

*   The [game loop][] handles different entity speeds, decoupling from UI, makes
    no distinction between player-controlled and AI entities, and makes [clever
    use of coroutines][coro].

*   [Game content][] is data-driven and loaded from [friendly human-readable
    text files][jelly].

*   Expected roguelike features are in there: [random dungeons][],
    [line-of-sight][], [field-of-view][], [inventory][], [stores][], [spells][],
    etc.

*   The game loop was designed to support emergent behavior and interactions
    between entities. For example, hitting a monster could cause it to explode
    in a fireball which will in turn light a nearby torch, blinding an adjacent
    zombie. (There isn't *content* for this stuff yet, though, just engine
    support.)

*   [No global state][global]. [Singletons][] are for amateurs.

[game loop]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Game.cs#cl-255
[coro]: /2008/11/17/using-an-iterator-as-a-game-loop/
[game content]: https://github.com/munificent/amaranth/tree/master/Amaranth.Data/Data/
[jelly]: https://github.com/munificent/amaranth/tree/master/Amaranth.Data/Data/Monsters/J%20-%20Jelly.txt
[random dungeons]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Dungeon/Generation/FeatureCreepGenerator.cs
[line-of-sight]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Los.cs
[field-of-view]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Fov.cs
[inventory]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Things/Items/Inventory.cs
[stores]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Dungeon/Town/
[spells]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Processing/Actions/Magic/
[global]: https://github.com/munificent/amaranth/tree/master/Amaranth.Engine/Classes/Content/Content.cs
[singletons]: http://gameprogrammingpatterns.com/singleton.html

It's all up on GitHub: [Bramble][], [Malison][], [Amaranth][]. Feel free to try
it out, fork it, or whatever. In the meantime, I'll try to find time to start
writing some documentation on more interesting parts of what's in there.
