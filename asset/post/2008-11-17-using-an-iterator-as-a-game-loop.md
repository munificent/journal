---
title: "Using an Iterator as a Game Loop"
categories: c-sharp code game-dev roguelike
---

If you've ever worked on a game before (and if you code, you probably have, at
least on your own), you've seen the venerable [game loop][]. It's the core loop
in the executable that iterates as long as the game is running. In GUI apps, an
[event loop][] accomplishes the same goal of keeping the executable running
indefinitely. A simple game loop looks like this:

[game loop]: https://dewitters.com/dewitters-gameloop/comment-page-1/
[event loop]: http://en.wikipedia.org/wiki/Event_loop

```csharp
void GameLoop()
{
    while (mPlaying)
    {
        HandleUserInput();
        UpdateGameState();
        Render();
    }
}
```

Pretty straightforward, and it's reassuring to think that even the most advanced
blockbuster game on the market has some code quite similar to this in it
somewhere.

## Separating out the UI

However, my game project is a [turn-based roguelike][rephial]. This means
`HandleUserInput()` blocks indefinitely until the user has chosen a move. Also,
I'm a design purist, so I want to not have engine code (which is where the game
loop lives) directly call into UI-land code (`HandleUserInput()`). Right now the
game is ASCII, but if I ever add graphics I don't want to change the engine.

[rephial]: http://rephial.org/

So what I did was move the loop back into UI-land (i.e. the normal event loop
GUIs have). `GameLoop()` in the engine now updates one step of the game and
returns.

Likewise, instead of explicitly calling `Render()`, I let the engine raise
events when things happen -- monsters move, items are used, etc. The UI can hook
into those and render the parts it needs to. So *...hand-waving...* don't worry
about rendering.

```csharp
void ProcessGame(UserInput input)
{
    HandleUserInput(input);
    UpdateGameState();
}
```

Still pretty dumb. Let's delve into updating the game state.

## Monsters!

The game has a dungeon with a bunch of monsters and the player-controlled hero.
Something like:

```csharp
void UpdateGameState()
{
    Hero.Move();

    foreach (Monster monster in Monsters)
    {
        monster.Move();
    }
}
```

This works for games like checkers where everyone takes exactly one turn. Here's
where it gets a bit more complex. In my game, each entity moves at its own speed
so some may get more than one turn before others go. In addition, the hero is
basically the same thing as a monster except the player controls him instead of
AI doing it. Like this:

```csharp
void UpdateGameState()
{
    // Entities has the hero in it too.
    foreach (Entity entity in Entities)
    {
        entity.Move();
    }
}
```

The tricky bit is because of speed, the UI may need to call `ProcessGame()`
multiple times before the hero actually needs user input. If the hero is slower
than monsters, some monsters will take multiple steps before the hero takes one.
This means there is no longer a 1-1 correspondence between `ProcessGame()` calls
and `HandleUserInput()`. In fact, the UI has to ask the engine if it's time to
provide user input. So `ProcessGame()` really become "process the game in a loop
until we need user input to continue":

```csharp
void ProcessGame()
{
    while (true)
    {
        Entity entity = Entities[mCurrentEntity];

        if (entity.NeedsUserInput)
        {
            return;
        }
        else
        {
            entity.Move();
            mCurrentEntity = (mCurrentEntity + 1) % Entities.Count;
        }
    }
}
```

Fairly simple. We loop through the entities, wrapping around and keep going
until we reach the hero who needs a move. But you'll notice we had to create a
field, `mCurrentEntity`, where we were just using a local `foreach` loop before.
That lets us pick up where we left off the last time we called the function.

## It gets worse

That isn't so bad, but I also added processing for items (if you lay a burning
torch on the ground, it needs to process so it can eventually burn out):

```csharp
void ProcessGame()
{
    while (true)
    {
        if (mInEntities)
        {
            Entity entity = Entities[mCurrentEntity];

            if (entity.NeedsUserInput)
            {
                return;
            }
            else
            {
                entity.Move();

                mCurrentEntity++;

                if (mCurrentEntity >= Entities.Count)
                {
                    mCurrentEntity = 0;
                    mInEntities = false;
                }
            }
        }
        else
        {
            Item item = Items[mCurrentItem];
            item.Move();

            mCurrentItem++;

            if (mCurrentItem >= Items.Count)
            {
                mCurrentItem = 0;
                mInEntities = true;
            }
        }
    }
}
```

*Yeesh.* Now we've got another field to track the current item, and another one
just to track which of the two loops we're in. It's getting hairy and this still
isn't as complex as my actual game's process function, which includes single
moves which are multiple steps and some other shenanigans.

But, there's hope. Remember when I said, "lets up pick up where we left off the
last time we called it". Those member variables exist basically to get us to
jump back to the last place we were in the function. Sound familiar?

## Enter iterators

Here's an iterator:

```csharp
IEnumerable<int> Fibonacci()
{
    int a = 0;
    int b = 1;

    while(true)
    {
        yield return a;

        int swap = a;
        a = b;
        b = swap + b;
    }
}
```

`yield return` lets us pick up where we left off, and we didn't have to create
any members to keep track of `a` and `b` because the `IEnumerable<int>` created
automatically by the compiler encapsulates that. A perfect fit! Let's turn the
game processing into the same thing:

```csharp
IEnumerable<bool> ProcessGame()
{
    while (true)
    {
        foreach (Entity entity in Entities)
        {
            if (entity.NeedsUserInput)
            {
                yield return true;
            }
            else
            {
                entity.Move();
            }
        }

        foreach (Item item in Items)
        {
            item.Move();
        }
    }
}
```

Much simpler, and we let the language take care of encapsulating the state
needed to return for us. Less code for us to monkey with.

## The final bit

The only annoying bit left now is that the UI actually needs to call
`ProcessGame()` *once* and then iterate through the returned iterator
afterwards. To make things nicer, we can let the game handle that so that
`ProcessGame()` works exactly like it used to:

```csharp
void ProcessGame()
{
    if (mIterator == null)
    {
        mIterator = CreateProcessIterator().GetEnumerator();
    }

    mIterator.MoveNext();
    bool dummy = mIterator.Current;
}

IEnumerable<bool> CreateProcessIterator()
{
    while (true)
    {
        foreach (Entity entity in Entities)
        {
            if (entity.NeedsUserInput)
            {
                yield return true;
            }
            else
            {
                entity.Move();
            }
        }

        foreach (Item item in Items)
        {
            item.Move();
        }
    }
}
```

You'll note that in the above example, we're using `IEnumerable<bool>`. The
`bool` there is pretty much arbitrary because the values of the `IEnumerable`
are irrelevant here. It's the [side effect][] of enumerating (i.e. updating the
game state) that matters. In the game, `Process()` actually does return
something so that the UI knows whether the game needs user input, or just to
pause for tick while showing an animation.

[side effect]: http://en.wikipedia.org/wiki/Side_effect_(computer_science)