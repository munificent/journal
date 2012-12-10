---
layout: post
title: "Amaranth, an Open Source Roguelike in C#"
categories: c-sharp code game-dev roguelike
---
Tonight I get to do something I've wanted to do for a really long time: I'm
open-sourcing the [roguelike](http://en.wikipedia.org/wiki/Roguelike) I've been working on for several years.
Amaranth is an old-school terminal-based roguelike written in C#. It looks
like this:

<img alt="Screenshot of Amaranth" src="/image/2010/06/amaranth.png" class="framed"/>

Because I'm crazy about decoupling, it's actually split into three separate
projects:

**[Bramble](http://bitbucket.org/munificent/bramble)** is a very small low-level library containing utility classes. It doesn't rely on anything beyond core .NET collections and provides more useful 2D [vector](http://bitbucket.org/munificent/bramble/src/tip/Bramble.Core/Vec.cs) and [rectangle](http://bitbucket.org/munificent/bramble/src/tip/Bramble.Core/Rect.cs) classes, along with some [other handy stuff](http://bitbucket.org/munificent/bramble/src/tip/Bramble.Core/Int32Extensions.cs). Even if you aren't working on a game, there may be something in here you can use, which is why it's its own project.

**[Malison](http://bitbucket.org/munificent/malison)** is the terminal library Amaranth uses for its user interface. Like many roguelikes, Amaranth doesn't have graphics. Instead, it draws the game world in ASCII like an old computer terminal. Malison is a generic library for drawing to a virtual terminal. Even if you don't care about Amaranth, Malison should be exactly what you need if you're going to write your own roguelike or other terminal-style app in C#.

One nice feature it has is that it decouples a logical terminal from a
specific renderer. It provides a renderer using [WinForms](http://bitbucket.org/munificent/malison/src/tip/Malison.WinForms/), but it should
be simple to implement other renderers on top of XNA, WPF, or Silverlight.
Code that writes to a terminal only knows about the [abstract terminal
API](http://bitbucket.org/munificent/malison/src/tip/Malison.Core/ITerminal.cs), which means you could have a single game engine that supports
rendering to a bunch of different terminal implementations.

**[Amaranth](http://bitbucket.org/munificent/amaranth)** is the actual game, or the beginnings of one. I have lots of work left to do here, but a lot is also done. I'll be writing more about interesting bits of the engine I hope. In the meantime you'll just have to dig around in the code if you're curious. Some fun stuff it supports:

  * Game engine is completely decoupled from UI. It was designed so that if I later write a graphical front-end for it, *zero* engine code would need to change.
  * [Game loop](http://bitbucket.org/munificent/amaranth/src/tip/Amaranth.Engine/Classes/Game.cs#cl-255) handles different entity speeds, decoupling from UI, makes no distinction between player-controlled and AI entities, and makes clever use of coroutines.
  * [Game content](http://bitbucket.org/munificent/amaranth/src/tip/Amaranth.Data/Data/) is data-driven and loaded from [friendly human-readable text files](http://bitbucket.org/munificent/amaranth/src/tip/Amaranth.Data/Data/Monsters/J%20-%20Jelly.txt).
  * Expected roguelike features are in there: [random dungeons](http://bitbucket.org/munificent/amaranth/src/tip/Amaranth.Engine/Classes/Dungeon/Generation/FeatureCreepGenerator.cs), [line-of-sight](http://bitbucket.org/munificent/amaranth/src/2fc3311d903f/Amaranth.Engine/Classes/Los.cs), [field-of-view](http://bitbucket.org/munificent/amaranth/src/2fc3311d903f/Amaranth.Engine/Classes/Fov.cs), [inventory](http://bitbucket.org/munificent/amaranth/src/2fc3311d903f/Amaranth.Engine/Classes/Things/Items/Inventory.cs), [stores](http://bitbucket.org/munificent/amaranth/src/2fc3311d903f/Amaranth.Engine/Classes/Dungeon/Town/), [spells](http://bitbucket.org/munificent/amaranth/src/2fc3311d903f/Amaranth.Engine/Classes/Processing/Actions/Magic/), etc.
  * The game loop was designed to support emergent behavior and interactions between entities. For example, hitting a monster could cause it to explode in a fireball which will in turn light a nearby torch, blinding an adjacent zombie. (There isn't *content* for this stuff yet, though, just engine support.)
  * [No global state](http://bitbucket.org/munificent/amaranth/src/2fc3311d903f/Amaranth.Engine/Classes/Content/Content.cs). [Singletons](http://gameprogrammingpatterns.com/singleton.html) are for amateurs.

It's all up on [bitbucket](http://bitbucket.org): [bramble](http://bitbucket.org/munificent/bramble), [malison](http://bitbucket.org/munificent/malison), [amaranth](http://bitbucket.org/munificent/amaranth).
Feel free to try it out, branch it, or whatever. In the meantime, I'll try to
find time to start writing some documentation on more interesting parts of
what's in there.
