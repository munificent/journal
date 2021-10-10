---
title: "Fibers: Coroutines in Finch"
categories: code cpp finch game-dev language
---

<div class="update">
<p><em>Update 2021/10/09:</em> Finch is <a href="https://github.com/munificent/finch">on GitHub now</a>.</p>
</div>

With [this surprisingly straightforward commit][commit], I've accomplished
something I've wanted to do for a long time: I've implemented [coroutines][] in
a programming language. I call them [fibers][] in Finch, mainly for brevity, but
the idea is the same. Since I think coroutines are both really cool and not very
well known, I thought it would be worthwhile to show how they work in Finch and
why I added them.

[commit]: https://github.com/munificent/finch/commit/e2c73911a9d0e8d87d9aa598325a95f6c2a83231
[coroutines]: http://en.wikipedia.org/wiki/Coroutine
[fibers]: http://en.wikipedia.org/wiki/Fiber_%28computer_science%29

If you like textbook definitions, here's one for you:

> Fibers are a lightweight cooperative multi-tasking construct that let you
> switch between multiple flows of execution.

If you're familiar with threads this might explain it better: Imagine a system
where all of your threads run at the highest priority so that when one thread is
running, all others get *zero* CPU time. In that scenario, the only way another
thread can execute is if the running one explicitly calls `sleep()`. Now imagine
that a call to `sleep()` requires an argument: the next thread to take over when
this one sleeps. Now you've got the idea.

## Some code

I can only read about two paragraphs in a blog post without code before I get
bored, so here's some:

```finch
' Create a fiber.
fiber <- Fiber new: {
  writeLine: "fiber started"
  Fiber yield
  writeLine: "fiber resumed"
}

' Transfer control from this fiber (the main one) to it.
writeLine: "main started"
fiber run
writeLine: "main resumed"
fiber run
writeLine: "done"
```

If you run this, it outputs:

```text
main started
fiber started
main resumed
fiber resumed
done
```

The two fibers interleave together like dance partners. There are three
important steps in this tango. First off, we need to create a fiber. The fiber
constructor, `Fiber new:` takes one argument, the block that makes up the body
of the fiber and returns a new fiber. Note that it *doesn't* start the fiber
running. The new fiber is just standing off to the side of the dancefloor
patiently waiting to catch the eye of a partner.

Once you have some fibers, there are two methods to transfer control between
them. The first one is `run`:

```finch
someFiberObj run
```

When you send that message to a fiber object, it starts running and the current
fiber pauses. The sister to `run` is `yield`:

```finch
Fiber yield
```

That pauses the current fiber and transfers control *back* to the fiber that ran
this one.

The *only* difference between `run` and `yield` is that `run` is called directly
on a fiber object to control which fiber to switch to where `yield` implicitly
switches to whatever fiber previously started this one. (In fact, if you look at
the code, you'll see they're both implemented in terms of a single
`switchToFiber:` primitive.)

## Communication

That's the basic system, but there's one more handy feature mixed in: you can
pass data between fibers when you switch control. In addition to `Fiber yield`,
there is also `Fiber yield:` which takes a single argument. The value passed to
that will be sent back to the resuming fiber as the return value from the call
to `run`. An example will really help here:

```finch
fiber <- Fiber new: {
  Fiber yield: "a marmot"
}

result <- fiber run
writeLine: result
```

That will print out "a marmot", as you'd hope. When you call `run`, the time
stops in that fiber. It doesn't resume until the fiber you ran yields. When the
clock starts again, the call to `run` finally completes, returning the value
passed to `yield:`.

This may remind you of [generators][] in Python or [iterators][] in C#.
Coroutines are a superset of both of those, so now Finch has generators too.
Unlike generators or iterators, communication also works going the other
direction. You can pass data *to* a fiber when you run it like this:

[generators]: http://www.python.org/dev/peps/pep-0255/
[iterators]: https://docs.microsoft.com/en-us/dotnet/csharp/iterators

```finch
fiber <- Fiber new: {
  result <- Fiber yield
  writeLine: result
}

fiber run
fiber run: "a dingo"
```

An extra call to `run` is needed here at the beginning. That runs the fiber up
to the first `yield`, which returns control back. Like in our previous example,
time stops for the fiber in the middle of its call to `yield`. The second `run:`
resumes the fiber, passing in a value which becomes the return value for the
`yield` method.

That probably sounds a little confusing. Play around with it a bit and it'll
make more sense.

## Why is this cool?

The reason I like coroutines is that they're a perfect fit for simulating
multiple entities simultaneously. And by that I mean *games*. In most games,
you've got a bunch of stuff going on at the same time: multiple enemies walking
around, the player, various projectiles and special effects, etc.

The way that's typically implemented is the game loop gives each actor a tiny
slice of time each turn. Each entity will have an `Update()` method that takes
one step and then returns, so a monster that just patrols back and forth,
waiting a bit at each end will have something like:

```cpp
Patroller::update() {
  switch (state_) {
    case WALK_LEFT:
      x_ -= WALK_SPEED;
      if (x_ <= MIN_X) {
        state_ = WAIT_LEFT;
        wait_ = WAIT_FRAMES;
      }
      break;

    case WAIT_LEFT:
      wait_--;
      if (wait_ == 0) state_ = WALK_RIGHT;
      break;

    case WALK_RIGHT:
      x_ += WALK_SPEED;
      if (x_ >= MAX_X) {
        state_ = WAIT_RIGHT;
        wait_ = WAIT_FRAMES;
      }
      break;

    case WAIT_RIGHT:
      wait_--;
      if (wait_ == 0) state_ = WALK_LEFT;
      break;
  }
}
```

You can see that the logic has to be split up into separate pieces and a bunch
of data has to be pushed into member variables like `state_` and `wait_` so that
it persists across frames. It's harder to tell what the intent of the behavior
is even in this absolutely trivial example. Imagine what it's like when the
entity is trying to walk a complex path or follow some strategy.

If your system supports coroutines, you've got a much easier way to do this --
simply spin up a fiber for each entity and have them yield once per turn. The
patrol behavior example turns into:

```finch
Patroller :: behavior {
  ' Walk left.
  from: MaxX to: MinX do: {|x|
    _x <- x
    Fiber yield
  }

  ' Wait.
  from: 1 to: WaitTime do: { Fiber yield }

  ' Walk right.
  from: MinX to: MaxX do: {|x|
    _x <- x
    Fiber yield
  }

  ' Wait.
  from: 1 to: WaitTime do: { Fiber yield }
}
```

Even better, because fibers maintain their own entire callstacks, you can switch
between them even from within other function calls. This lets us refactor code
that uses them into smaller functions, so the previous could would likely be
something like:

```finch
Patroller :: (
  behavior {
    self walkFrom: MaxX to: MinX
    self wait: WaitTime
    self walkFrom: MinX to: MaxX
    self wait: WaitTime
  }

  walkFrom: a to: b {
    from: a to: b do: {|x|
      _x <- x
      Fiber yield
    }
  }

  wait: frames {
    from: 1 to: WaitTime do: { Fiber yield }
  }
)
```

Now our top-level code for patrolling is practically pseudocode for what we want
the entity to do. Pretty swell!
