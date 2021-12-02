---
title: "A Turn-Based Game Loop"
categories: code game-dev roguelike dart
---

<style>
canvas {
  padding: 6px;
  background: #222;
  margin: 10px auto;
  max-width: 90%;
  display: block;
}
</style>

Now that [my roguelike][hauberk] written in [Dart][] is [open source][hauberk
code], I wanted to talk about a piece of it that I put a lot of time into. Well,
I actually poured way too much of my life into lots of parts of this game. Maybe
I'll write about those too, but for now let's start where most games start: with
the *game loop*.

[hauberk]: http://munificent.github.io/hauberk/
[hauberk code]: https://github.com/munificent/hauberk
[dart]: http://dartlang.org

<figure>
  <img class="framed" src="/image/2014/08/snapshot.jpg">
  <figcaption>Here's the game I'm talking about. You can play it
  <a href="http://munificent.github.io/hauberk/">here</a>. Don't get freaked
  out by all of the text below! There's interactive demos just a few paragraphs
  down!</figcaption>
</figure>

I'm [a bit obsessed][gpp] with software architecture in games. Since this
roguelike is my hobby project, I've fully indulged myself. You know that guy who
always wanted to be a railroad engineer but ended up an accountant or something,
and then spends years in his basement endlessly tinkering on a model railroad?
I'm like that guy, but for software architecture. And roguelikes.

[gpp]: http://gameprogrammingpatterns.com/

That may be the nerdiest thing I've ever written, which is really saying
something.

I've refactored and rewritten the game loop more times than I can count (there's
probably some "iteration" metajoke hiding in this sentence), and I won't drag
you through the whole history of it. Instead, we'll go through its current form,
building it up a piece at a time.

I have a couple of high-level goals:

*   **The game engine should be *strictly* separated from the user interface.**
    I've gone back and forth between a pixel art UI and a more old school
    ACSII-based one, and it's important for me that the engine supports both.
    (The current Dart version is all ASCII-based right now, ironically rendered
    using the canvas API.) That means the engine can't be coupled to any details
    of how the game is displayed to the user. Like a business app, I want a real
    model/view separation.

*   **Monsters and player-controlled characters should be treated uniformly.**
    Most of the engine just deals with "[actors][]", the superclass of both
    [`Monster`][monster] and the player-controlled, gender-nonspecific
    [`Hero`][hero]. I want to minimize special treatment that the player's
    avatar receives and treating it like just another entity in the game does
    that implicitly.

[actors]: https://github.com/munificent/hauberk/blob/23bbc1feb2636a846b87eb0a95a2bbf3fbdc2184/lib/src/engine/actor.dart#L46
[monster]: https://github.com/munificent/hauberk/blob/23bbc1feb2636a846b87eb0a95a2bbf3fbdc2184/lib/src/engine/monster.dart#L21
[hero]: https://github.com/munificent/hauberk/blob/23bbc1feb2636a846b87eb0a95a2bbf3fbdc2184/lib/src/engine/hero/hero.dart

## Slicing up the game loop

Hauberk, like most roguelikes, is a *turn-based* game. Each actor in the game
makes a move one at a time. When it's the player's turn, all of the monsters
halt, awkwardly motionless like the world's strangest game of freeze tag, until
after the player does their thing.

At the core of the game engine is the [game loop][]. Its job is to iterate over
the actors in the level and tell each to take its turn. In a simple game, it
would look something like:

[game loop]: http://gameprogrammingpatterns.com/game-loop.html

```dart
void gameLoop() {
  while (stillPlaying) {
    for (var actor in actors) {
      actor.update();
    }
  }
}
```

However, since the engine is decoupled from the user interface, it is driven
externally. The engine has a main [`Game`][game] class. The UI owns an instance
of that and tells it to process. The engine only processes one "step" of
gameplay before returning control back to the UI.

[game]: https://github.com/munificent/hauberk/blob/fe0bdf614d5d00a5235b7a82d9d38c928928d34c/lib/src/engine/game.dart

(I'm being intentionally vague about "step" here. If I get a chance, I'll write
a follow-up post about how the engine's game loop and the browser event loop
interact. It's pretty tricky.)

What this means is that `Game` needs to track the last actor who took a turn so
it can pick up where it left off. Something like:

```dart
class Game {
  final actors = <Actor>[];
  int _currentActor = 0;

  void process() {
    actors[_currentActor].update();
    _currentActor = (_currentActor + 1) % actors.length;
  }
}
```

Astute readers like yourself are probably thinking this sounds like a good case
for a [generator][]. Indeed, in the previous C# incarnation of my game, [I did
exactly that][amaranth]. When Dart gets generators, I'll probably use them. In
the meantime, it's just a bit more verbose.

[generator]: http://en.wikipedia.org/wiki/Generator_(computer_programming)
[amaranth]: /2008/11/17/using-an-iterator-as-a-game-loop/

## Actions for actors

We've got a little resumable game loop now. When each actor's turn comes up, its
`update()` is called and the actor does whatever it does. A monster might pick a
direction to walk. Next, the consequences of that have to be handled. The
monster may walk into another actor, which triggers combat. The monster also
needs to handle walking into a wall or a door.

All told, even for a simple bit of behavior like "take a step", there's a decent
amount of logic, but you'll note that all of that applies equally well to
monsters and heroes. Brave warriors can stumble into walls too, and the
consequences are the same. It would be good to share code for this.

The obvious answer is to push the walking code up into the shared `Actor` base
class. But if we do that for everything -- walking, melee combat, ranged
attacks, inventory management, magic, etc. -- we end up with an `Actor` class
that contains damn near the whole game. Super gross.

Instead, we'll make a classic game architecture decision. We'll separate
*deciding* what behavior to perform from *executing* the behavior. In other
words, we'll use the [Command pattern][]. In Hauberk, these are called
*actions*.

[command pattern]: http://gameprogrammingpatterns.com/command.html

The game loop asks each actor to give it an action, then it tells the action to
execute *itself*, like:

```dart
void process() {
  var action = actors[_currentActor].getAction();
  action.perform();
  _currentActor = (_currentActor + 1) % actors.length;
}
```

There are different action classes for each atomic thing an actor in the world
can do. There is a [`WalkAction`][walk], [`OpenDoorAction`][open],
[`EatAction`][eat], etc.

[walk]: https://github.com/munificent/hauberk/blob/53719994a29ba7b750bb78643f8b92d1f5516685/lib/src/engine/action_base.dart#L109
[open]: https://github.com/munificent/hauberk/blob/53719994a29ba7b750bb78643f8b92d1f5516685/lib/src/engine/action_base.dart#L154
[eat]: https://github.com/munificent/hauberk/blob/53719994a29ba7b750bb78643f8b92d1f5516685/lib/src/engine/action_base.dart#L192

This architecture pulls all of that behavior out of the base `Actor` class. Even
better, it separates all of the actions from *each other*. If you're adding or
changing a thing that actors can do, you can just poke at one isolated little
action class. It feels nice and decoupled and it's easy to add new actions to
the game. (As of today, there are nineteen different actions, and I expect to
add a bunch more.)

It also, of course, helps us treat monsters and heroes uniformly. Since the
`Action` classes all work on instances of `Actor`, they can all be used by
monsters and heroes alike. (There are some exceptions since heroes have some
capabilities monsters don't have. Right now, monsters don't have inventory so
all of the inventory management actions don't apply to them.)

## Acting at speed

We've got a basic loop working now, but our game is a bit *too* turn-based.
Every monster and the hero all proceed in lockstep. You move one step, they all
move one step, kind of like the ancient [Robots][] game. You can never outrun or
be outrun. See for yourself:

<figure>
  <canvas id="same-speed" tabindex="1">Sorry, you need canvas support for this
  demo.</canvas>
  <figcaption>Use arrow keys or <code>iopkl;,./</code> to move. Press
  <code>t</code> to teleport.</figcaption>
</figure>

To fix that, we want actors to move at different *speeds*.

[robots]: http://en.wikipedia.org/wiki/Robots_(BSD_game)

Of course, this is "speed" in the turn-based sense, not literally moving quicker
in realtime. What it means is that a "faster" actor gets to take turns more
*frequently* than other actors. If you're twice as fast as a green slime, then
you'll get two turns for every one it receives.

This mechanic is *de rigueur* in roguelikes, and the literature is [rife][speed
1] [with][speed 2] [ways][speed 3] [to][speed 4] implement it. The system I'm
using is almost exactly [what Angband uses][angband speed], because it's
awesome.

[speed 1]: http://www.roguebasin.com/index.php?title=An_elegant_time-management_system_for_roguelikes
[speed 2]: http://www.roguebasin.com/index.php?title=A_priority_queue_based_turn_scheduling_system
[speed 3]: http://doryen.eptalys.net/forum/index.php?topic=1596.0
[speed 4]: http://ironypolicy.wordpress.com/2014/02/05/possession-2-speed-systems-in-roguelikes/
[angband speed]: http://www.faqs.org/faqs/games/roguelike/angband-faq/

It works like this: Every actor has an *energy* level. When the game loop
reaches an actor, it grants the actor a bit of energy. When the actor's energy
reaches a certain threshold, it has enough to take a turn and perform an action.
Otherwise, the game loop just moves on to the next actor. It may take several
cranks through the game loop before an actor accumulates enough juice to
actually take a turn. (And, in fact, for all but the fastest actors, it does.)

When the actor performs an action, that burns energy, and they're back in the
"waiting to get enough energy to go" state. Right now, all actions consume the
same amount of energy, which means every action takes the same amount of "time"
to perform. I *could* vary this so that, for example, archers could shoot arrows
more frequently than they swing a sword.

The way *speed* comes into play is simple: *faster actors get more energy each
turn.* That means they cross the threshold in fewer revolutions of the game
loop, so they get to move more often. It's as simple as that.

The neat thing about it is that by accumulating energy over several turns, you
can have actors that move at arbitrary fractions of each other's speed. You
could have an actor that gets five moves for every seven moves another actor
gets if you wanted. (Of course, what you'd see during game play is that every
now and then the second actor would get a double turn. It's just that the "every
now and then" averages out to 7/5 over time.)

Enough verbiage, let's see it in action:

<figure>
  <canvas id="speed-bars" tabindex="2">Sorry, you need canvas support for this
  demo.</canvas>
  <figcaption>Same controls before but the game loop is slowed down so you can
  watch it parcel out energy.</figcaption>
</figure>

The `>` points to the actor whose turn it is. It's usually stuck waiting on you.
After you make a move, you can watch the game loop race around, doling out bits
of energy. When an actor's bar reaches the right edge, it takes a move and the
bar resets.

The cool thing about this system is that applies to all *actors*. Some game
engines update the hero separately from monsters in the main game loop, but that
makes speed much trickier to handle. By treating the hero as just another actor,
the hero can be both slower and faster than other monsters automatically.

## The one special thing about heroes

Treating the hero as just another actor is mostly swell, but there *is* one
thing about heroes that makes them unique -- they're controlled by the player.
The game loop I showed runs fine as long as actors generate their own actions.
That's true in the case of AI-driven monsters, but the hero can't see through
your glassy computer screen and discern your intentions through cyber-telepathy.
It needs user input.

We already have two constraints that make this harder:

1.  Because we want to separate the engine from the user interface, the engine's
    game loop can't directly call into input handling code.

2.  Because the game runs in a browser, it can't *block* waiting for user input.
    The browser don't play 'dat. You have to return to the event loop and let
    the browser tell *you* when an event comes in.

When the game loop asks a hero for its action, the hero can't just stop the game
and wait for the player to push a button. Instead, we let the user interface
*inject* input into the game. The input handling code can create an action for
the hero *ex-nihilo* and jam it in the engine's piehole, like this:

```dart
void handleInput(Keyboard keyboard) {
  switch (keyboard.lastPressed) {
    case KeyCode.G:
      game.hero.setNextAction(new PickUpAction())
      break;

    case KeyCode.I:         walk(Direction.NW); break;
    case KeyCode.O:         walk(Direction.N); break;
    case KeyCode.P:         walk(Direction.NE); break;
    case KeyCode.K:         walk(Direction.W); break;
    case KeyCode.L:         walk(Direction.NONE); break;
    case KeyCode.SEMICOLON: walk(Direction.E); break;
    case KeyCode.COMMA:     walk(Direction.SW); break;
    case KeyCode.PERIOD:    walk(Direction.S); break;
    case KeyCode.SLASH:     walk(Direction.SE); break;
  }
}

void walk(Direction dir) {
  game.hero.setNextAction(new WalkAction(dir));
}
```

That call to `setNextAction()` stuffs the given action into a field in the hero.
When the game loop asks the hero what it wants to do, it barfs the action back
up:

```dart
class Hero extends Actor {
  Action _nextAction;

  void setNextAction(Action action) {
    _nextAction = action;
  }

  Action getAction() {
    var action = _nextAction;
    // Only perform it once.
    _nextAction = null;
    return action;
  }

  // Other heroic stuff...
}
```

(In the actual game, there's actually a level of indirection here to handle
[multi-step behaviors like running][running], but we'll ignore that here.)

[running]: https://github.com/munificent/hauberk/blob/11c5ca5d258dfdae20118c7a4dcc82e50ceb67de/lib/src/engine/hero/hero.dart#L301

This keeps the engine from reaching out to the user interface and lets the UI
pass input to the engine at its leisure. The only problem is what happens when
the game engine is told to process the hero's turn and the UI hasn't given it an
input yet.

To handle that, the loop just checks for the actor failing to cough up an
action. When that happens, it bails and returns control back to the user
interface:

```dart
void process() {
  var action = actors[_currentActor].getAction();

  // Don't advance past the actor if it didn't take a turn.
  if (action == null) return;

  action.perform();
  _currentActor = (_currentActor + 1) % actors.length;
}
```

If the interface tells the game engine to process but hasn't given instructions
to the hero, the engine does nothing and bounces control back to the UI. Note
how `setNextAction()` can be called at any point in time. This works seamlessly
with the speed system without the UI having to be aware of it. It just throws
hero actions at the engine and tells it to process. The engine takes care to
ensure the simulation only ratchets forward at the right time.

In fact, now that I think about it, if you had multiple player-controlled heroes
driven by different inputs, it would automatically handle that too. They could
even be coming over a network and the engine won't care. Groovy.

The way this interacts with the browser's own event loop is actually a good bit
more complex than this when you take into account visual effects, but I think
I'll have to save that for another post. For now, let's keep our attention on
the pristine confines of the engine.

## Fat fingers

We're pretty far along with our game loop now. We've got it doing the stuff it
*needs* to do, so we can start looking at making the game more pleasantly
usable. Usability means *fallibility*. People make mistakes, and usability is
about accommodating that.

For example, let's say the player tries to make the hero walk into a wall. Right
now, that creates a walk action. When the action is processed, it prevents the
hero from walking through the wall, but it still *burns that turn*. If the hero
is trying to run away from a foul beastie, that slip up could cost the hero
their life. Some games are OK with that, but I don't want to be that punishing.
Roguelikes are unforgiving enough as it is.

The demos so far work this way now. Go back and try running into a wall. See how
your mortal enemies approach in the midst of your ineptitude? That's what we
want to fix. When the player tries to perform an action that isn't possible, we
want to make sure we don't waste a turn on it.

One way to handle that would be to validate the turn in the user interface. In
the input handling, we check the tile that the hero wants to walk into and make
sure it's a floor tile. If it isn't, the user interface shows an error and
doesn't send an action to the game. From the engine's perspective, it only
receives sanitized, correct user actions.

But doing that validation is actually pretty complex. Maybe the hero has an
insubstantiation spell and *can* walk through walls right now. Maybe the tile
isn't floor but is something the hero can tunnel through, but only if they have
a shovel in their inventory.

What I'm describing are *game mechanics*, and game mechanics belong in the
engine. In particular, most of them belong in actions. We'll put the solution to
this problem in there too. When an action is processed, we'll let it return a
value indicating success. If it fails, the game loop considers it to have never
happened. It's as simple as:

```dart
void process() {
  var action = actors[_currentActor].getAction();
  if (action == null) return;

  var success = action.perform();

  // Don't advance if the action failed.
  if (!success) return;

  _currentActor = (_currentActor + 1) % actors.length;
}
```

This makes the engine more robust: you can throw arbitrary actions at it and it
will handle them gracefully. It also keeps all of the code for a single
mechanic, including validation, in one place: in the relevant action. Yay for
encapsulation!

Now, try braining yourself against the dungeon's stone boundary:

<figure>
<canvas id="safe-fail" tabindex="3">Sorry, you need canvas support for this demo.</canvas>
</figure>

## Do what I mean, not what I said

Success/failure handles cases where the action the player picked is totally
bogus, but sometimes the game can infer out what they were *trying* to do. For
example, if you try to make the hero walk into a closed door instead of using
the dedicated "open door" command, odds are pretty good you want to open the
damned door. Likewise, if you try to walk into a monster, that's a good time to
consider swinging a sword.

I know this sounds obvious, but you'd be surprised how many roguelikes don't do
this. Improving usability is one of my main goals for my game, so I care about
this stuff. I've got a pretty simple solution too.

When an action is validating itself, it can fail outright like we saw, but it
can also respond with an *alternate action*. It lets the action say, "no, you
really mean this".

Since the `perform()` method on `Action` can return success, failure, or another action, we'll make a little class to wrap that up:

```dart
class ActionResult {
  static const success = ActionResult(true);
  static const failure = ActionResult(false);

  /// An alternate [Action] that should be performed instead of
  /// the one that failed.
  final Action alternative;

  /// `true` if the [Action] was successful and energy should
  /// be consumed.
  final bool succeeded;

  const ActionResult(this.succeeded)
  : alternative = null;

  const ActionResult.alternate(this.alternative)
  : succeeded = true;
}
```

When an action is executing, it returns `ActionResult.success` to say everything
went fine, `ActionResult.failure` to say nothing happened, or it can return an
`ActionResult` with `.alternate` pointing to a new action to perform instead.

The game loop processes that:

```dart
void process() {
  var action = actors[_currentActor].getAction();
  if (action == null) return;

  while (true) {
    var result = action.perform();
    if (!result.succeeded) return;
    if (result.alternate == null) break;
    action = result.alternate;
  }

  _currentActor = (_currentActor + 1) % actors.length;
}
```

We do this in a loop because an alternate may itself return an alternate, so we
keep trying until we bottom out on an action that succeeds or fails. This turns
out to be a handy feature for a number of things in the full game:

*   When you use an item, the "use item" action looks up the specific thing the
    item does (shoot a fireball, teleport, etc.) and returns that as an
    alternate. When you "use" an equippable item, it returns the "equip" action
    as an alternate.

*   If an actor "walks" but in no direction, it becomes a "rest" action which
    regains a bit of health.

*   If an actor walks into a door, it returns the "open door" action as an
    alternate.

*   If an actor tries to walk into another, it returns the "attack" melee action
    as an alternate.

The last three are particularly handy because they're equally applicable to
monsters. The monster AI code doesn't have to check for doors or opponents.
Instead it just tries to make the monster walk where it wants to go and the
action system handles opening doors to get there and attacking the hero when it
reaches them. When the monster can't figure out where to go, it rests
automatically.

Believe me, anything you can do to simplify your AI code is a good idea. Enough
jibber-jabber, let's see it in action:

<figure>
<canvas id="alternate" tabindex="4">Sorry, you need canvas support for this
demo.</canvas>
</figure>

Notice the little room has a door now. If you try to walk into it, the game loop
will go through the walk's alternate action to do the open. You can close it by
pressing "C" when standing next to it.

The wizard is smart enough to open doors too (sorry, troll and slug, no Mensa
membership for you) and no changes to the pathfinding AI were needed to enable
it. He just tries to walk *through* the door and miraculously succeeds.

## The end... *or is it?*

Crap, I've already burned three thousand words of your attention and there's
still cool stuff to talk about! I'm gonna have to split this into a two parter.

What we have now is a pretty solid (in my opinion, naturally) game loop.
Defining behavior in actions lets us treat the player-controlled hero and
monsters uniformly. We've got a flexible speed system, and it's all nicely
separated from the user interface.

If you're building a relatively simple turn-based game, this is probably enough.

But, while ASCII-art-based roguelikes aren't known for their visual spectacle, I
want something that with a bit more pizazz than what I described here can dish
up. I want the player to see an arrow arc across the room before plunking into
the meaty face of a troll. I want fireballs to flare outwards in a ring of
death. And when that flame touches incendiary items laying on the ground, those
should in turn trigger a cascading conflagration.

The game loop I have in the full game can do that. When I can find the time to
carve out a few more standalone demos and hack up some prose, I'll show you how.
In the meantime, the code for the game is [here][hauberk code], and the code for
the demos in this post are [here][demos].

If you want to try out the game, you can [play it here][hauberk].

[demos]: https://github.com/munificent/a-turn-based-game-loop

<script type="application/dart" src="/code/2014-07-15-a-turn-based-game-loop/main.dart"></script>
<script src="/code/2014-07-15-a-turn-based-game-loop/packages/browser/dart.js"></script>
