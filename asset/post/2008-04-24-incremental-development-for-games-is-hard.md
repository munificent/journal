---
title: "Incremental Development for Games (Is Hard)"
categories: code game-dev
---

For those who don't know, the game industry (or at least my chunk of it) is
generally about 10 years behind the rest of the software world. We're still
leery of crazy ivory tower concepts like "memory management", "testing", and
"going home at 5:00 PM". Where your hip Web 2.0 company is all aflutter about
[DSLs][], [duck typing][], and [continuations][], my company is a little more:

[dsls]: https://en.wikipedia.org/wiki/Domain-specific_language
[duck typing]: https://en.wikipedia.org/wiki/Duck_typing
[continuations]: https://github.com/seasidest/seaside

> **Brown:** I have just received a telegraph from Jenkins discussing something
> he calls, "[the Ess Tee Ell][stl]".
>
> **Watson:** Desist your crazy Moon Man talk or I shall be forced to give you a
> drubbing!

[stl]: https://en.wikipedia.org/wiki/Standard_Template_Library

It's not that we aren't trying. We're just a little more [East Berlin][east
berlin] circa 1950 than the rest of the software world. One concept that *has*
[crossed][agile] our Iron Curtain recently is this thing called "[Agile
Development][manifesto]". I can't say we really know what it means, but it is
very interesting to us.

[east berlin]: http://www.galenfrysinger.com/east_berlin.htm
[agile]: http://www.agilegamedevelopment.com/
[manifesto]: http://agilemanifesto.org/

## Games are hard

You see, developing a new game is really hard. On top of the technical reasons
(pushing the graphics hardware, strict quality control) and the business ones
(cutthroat competition, [difficult profitability][profit]), there's this other
little thing called "fun".

[profit]: http://news.bbc.co.uk/2/hi/technology/6397527.stm

If you're making [business software][ms] and it's a [pain to use][office], you
can still be totally successful because people need to use your stuff to get
their job done, like it or not. And your software can be [totally
unoriginal][apple] because people don't want to have to learn new things.
Unoriginality is actually [a bonus][jakob].

[ms]: http://www.microsoft.com/
[office]: http://office.microsoft.com/
[apple]: http://en.wikipedia.org/wiki/Apple_v._Microsoft
[jakob]: https://www.nngroup.com/videos/jakobs-law-internet-ux/#:~:text=Summary%3A%20Users%20spend%20most%20of,for%20which%20users%20are%20accustomed.

Over in Magical Game Land, though, we aren't so lucky. We're trying to get
people to shell out hard-earned cash for something that, by definition, they
*don't need*. So we have to make sure it's more fun to play than whatever else
they could be doing. We have to make sure we're offering them a *new*
experience, otherwise they'll just play an older game. At the same time, our new
game has to be easy enough to learn that it's enjoyable within the first 30
seconds.

On top of this, budgets and player expectations continue to rise, so the chance
and cost of failure keeps going up. Because of this, if a game's going to suck,
we need to know as soon as possible so we can correct course or [pull the
ejection seat lever][cancel].

[cancel]: https://en.wikipedia.org/wiki/Category:Cancelled_video_games

## Enter agile development

Agile development means a lot of things to different people, but the key part I
want to talk about is the idea of **building a game incrementally through a
series of small changes**. This idea that a month into the cycle you have a
*fun* playable game already and you just build onto that is very appealing
because it means we can immediately get feedback on what parts work and what
don't.

For a micro example, imagine you're building a [chess-like][fairy] game. In a
typical [waterfall][]-like model, you won't be able to actually play the game
until all the different pieces are designed and implemented. And then you can
play the whole thing. Sometime in alpha, after you've burned most of your
budget. Better hope the game is fun!

[fairy]: http://en.wikipedia.org/wiki/Fairy_chess_piece
[waterfall]: http://en.wikipedia.org/wiki/Waterfall_model

With a more agile method, you'd be able to play the game early in the cycle with
a couple of pieces, and then gradually add in more pieces throughout. You'll be
testing some core mechanics early in and can change things if they don't work.

## Uh-oh

Even that tiny example hints at the pitfall ahead: games are all about
*balance*. Chess is unplayable with just two kings and some pawns. Without the
other pieces, it's a fundamentally different game. So now we've gone from
"nothing to play" to "playing a totally different game that may or may not
reflect the final game". Ouch.

This is where games are different than other software. If you're making a word
processor, adding right-justification doesn't somehow "unbalance" left-
justification. Features are fairly isolated from each other and don't compete.
In a game, every feature or capability affects the overall strategy and
equilibrium. Building a game incrementally is like trying to build a [hanging
mobile][] by hanging it up *first* and then hanging successive pieces onto it.

[hanging mobile]: https://en.wikipedia.org/wiki/Mobile_(sculpture)

## Solutions?

I suspect this is one of the fundamentally hard parts of designing a new game.
That sense of "everything works in harmony" is irreducible to some extent. I'll
point out a couple of ideas to at least carve at the problem a bit.

### Separate the core from the peripheral

If we're designing minimal abstract board games, there aren't a lot of
"peripheral" features. In computer/video-games it's a bit different. Non-
interactive set decoration, some UI, extra games modes, etc. all surround the
core "mechanics" of the game. So, even if you can't do the core mechanics
incrementally, you can at least do them in one lump and then tack on the
additional stuff afterwards.

Be careful here, though. Even seemingly trivial things like UI or [VFX][vfx] can
have a massive impact on the usability of your game.

[vfx]: http://en.wikipedia.org/wiki/Particle_system

### Match pairs

If you're starting with a balanced game and you need to add features while
keeping it balanced, one obvious solution is to try to add them in opposing
pairs. For symmetric games like chess, this is fairly simple: implement the same
piece for both players. For other games, it gets trickier.

If you're adding speed boosts to a driving game, you might be able to match it
by also adding slowdown and damage for hitting the walls at the same time. For
an RPG, giving the player a new attack may require also adding monsters that
resist it.

### Accept retuning

Most games, on top of the feature set itself, have a lot of precise tuning of
numbers that happens to make it fun. Those numbers have to be tuned relative to
the current feature set. Adding a new feature can essentially detune them. If
you give your hero a shotgun, all of the sudden it may be time to double the
enemy's health. Make the AI smarter and your hero is toast.

If a fun playable game at all points through the cycle is important, it may be
worth accepting that you will need to frequently retune the same values as the
feature set changes. To some degree, this is "throwaway" work, but if it gives
you a better ability to evaluate your game, it may be worth the effort.

### Reduce innovation

Of course, all of the above assumes you're making a game with actually new
mechanics. If you're making chess on the other hand, it doesn't matter if the
game sucks with just kings and pawns. You know by the time the rest of the
pieces are in it will be cool. So the safest option is just to rely on the
established formula of your game's genre, and save your innovation for
peripheral features.
