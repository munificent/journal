---
title: "Closures and the Command Pattern"
categories: c-sharp code design
---

Like a lot of object-oriented programmers, I'm a fan of *[Design Patterns][]*.
While I don't treat it like the sacred tome that many think it is, I learned a
lot of tricks for solving design problems from it. As I've moved from C++
towards other languages, it's become clear that many patterns in the book exist
just to get around limitations in C++.

[design patterns]: http://www.c2.com/cgi/wiki?DesignPatterns

The anti-C++ crowd just uses this as evidence that C++ sucks since you have to
write a whole book to get around its shortcomings. Let's not go there.

Instead, I want to see if I can show you a bit about a language feature that C++
lacks and that you may not know ([closures][]) by getting there from something
familiar to an average C++ object-oriented programmer (the [Command Pattern][])
and changing it in stages. I'll use C# as the example language here, but any
language with closures will work: Lua, Scheme, etc.

[closures]: http://en.wikipedia.org/wiki/Closure_%28computer_science%29
[command pattern]: http://en.wikipedia.org/wiki/Command_pattern

## The Command Pattern

Let's say you're writing a chess program. You want it to support both regular
human players and built-in AI players. The core chess engine doesn't care about
what kind of players it's dealing with. All it needs to know is for a given
player, what that player's move is.

For a human player, the user interface gets the user's move selection and passes
that to the engine. For a computer-controlled player, the AI rules select the
best move and pass it in.

To represent a "move", we use the Command Pattern. The basic idea is that you
have a *command* class that encapsulates some procedure to perform and any data
that procedure needs. You can think of it like a function call and its arguments
bottled up together to be opened later by some other part of the program. A
vanilla implementation is something like:

```csharp
interface ICommand
{
    void Invoke();
}

class MovePieceCommand : ICommand
{
    public Piece Piece;
    public int   X;
    public int   Y;

    public void Invoke()
    {
        Piece.MoveTo(X, Y);
    }
}
```

We'll also create a little factory for creating the commands. This isn't
necessary now, but it'll make sense later when we start moving things around.

```csharp
static class Commands
{
    // Create a command to move a piece.
    public static ICommand MovePiece(Piece piece, int x, int y)
    {
        var command = new MovePieceCommand();
        command.Piece = piece;
        command.X = x;
        command.Y = y;

        return command;
    }
}
```

To complete this first pass, here's a little block to test our code:

```csharp
class Program
{
    public static Main(string[] args)
    {
        // UI or AI creates command.
        var piece = new Piece();
        var command = Commands.MovePiece(piece, 3, 4);

        // Chess engine invokes it.
        command.Invoke();
    }
}
```

## The first change: delegates

The first change we'll make is a pretty minor one. The `ICommand` interface only
has a single method, `Invoke()`, so there's no real reason to make an interface
for it. Since delegates in C# work fine on instance methods, we can just use
that instead. We'll define a delegate type for a function that takes no
arguments and returns nothing, just like the `Invoke()` method in `ICommand`.

```csharp
delegate CommandDel();

class MovePieceCommand
{
    public Piece Piece;
    public int   X;
    public int   Y;

    public void Invoke()
    {
        Piece.MoveTo(X, Y);
    }
}

static class Commands
{
    // Create a command to move a piece.
    public static CommandDel MovePiece(Piece piece, int x, int y)
    {
        var command = new MovePieceCommand();
        command.Piece = piece;
        command.X = x;
        command.Y = y;

        return command.Invoke;
    }
}

class Program
{
    public static Main(string[] args)
    {
        // UI or AI creates command.
        var piece = new Piece();
        var command = Commands.MovePiece(piece, 3, 4);

        // Chess engine invokes it.
        command();
    }
}
```

Not much different, although we did get to ditch the interface without any
loss in functionality.

## The second change: ditch `Invoke()`

That `Invoke()` method up there really doesn't do much. It just calls another
function. Let's see if we can pull that out. C# has "anonymous delegates", which
are basically functions defined within the body of another function. We'll try
that.

```csharp
class MovePieceCommand
{
    public Piece Piece;
    public int   X;
    public int   Y;
}

static class Commands
{
    // create a command to move a piece
    public static Action MovePiece(Piece piece, int x, int y)
    {
        var command = new MovePieceCommand();
        command.Piece = piece;
        command.X     = x;
        command.Y     = y;

        CommandDelegate invoke = delegate()
            {
                command.Piece.MoveTo(command.X, command.Y);
            };

        return invoke;
    }
}
```

Now instead of an `Invoke()` *method* we have an anonymous function stored in a
local `invoke` variable. But this local function isn't a method, so it doesn't
have a `this` reference. How does it get access to the `MovePieceCommand` that
stores the piece and location to move it to?

Like a little magic trick, the body of the `invoke` delegate actually accesses
the `MovePieceCommand` stored in `command`, a local variable defined *outside*
of itself in `MovePiece`. *That's* a closure: a local function that references a
variable defined outside of its scope.

In C#, the compiler will make sure those closed over local variables get moved
to the heap, so that our delegate still has access to them even after
`MovePiece` has returned. It actually does this by building a little class like
our old `MovePieceCommand` and turns the delegate we just made back into a
method. The advantage is that the *compiler* writes the class for us. We don't
have to. Call me lazy, but if there's anything I like, it's _doing less_.

## Clean up

By now it's clear that `MovePieceCommand` isn't doing much. It's just a bag of
data. If our anonymous delegate can access local variables outside its scope
anyway, there's no reason to bundle them into an object. Let's kill it.

To clean things up a bit more, we'll also define the delegate using C#'s newer
[lambda syntax][]. It does the exact same thing, but more tersely.

[lambda syntax]: http://msdn.microsoft.com/en-us/library/bb397687.aspx

```csharp
static class Commands
{
    // create a command to move a piece
    public static Action MovePiece(Piece piece, int x, int y)
    {
        return () => piece.MoveTo(x, y);
    }
}
```

And just like that, our whole command pattern has become a single line of
code.

## Conclusion

There are plenty of cases where it's still useful to implement a full command
pattern: maybe you need to be able to invoke the command in multiple ways, or
undo it. However, for simple problems, I go for the simple solution. If you're
working in a language with closures, it doesn't get simpler than this.
