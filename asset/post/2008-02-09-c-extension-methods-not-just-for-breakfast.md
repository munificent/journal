---
title: "C# Extension Methods: Not Just for Breakfast"
categories: c-sharp code
---

When I first started reading about C# 3.0, one of the new features that caught
my eye was extension methods. I really like `foo.Bar()` syntax because with
auto-complete it helps users find out what methods are available for a class.
With extension methods, I could add new behavior to other classes and still keep
that calling convention. Yay.

But after thinking about it for a while, I realized there's some interesting
capabilities that this simple feature provides. While at one level, extension
methods are just [syntactic sugar][], I think they open up the possibility for
some deeper architecture implications.

[syntactic sugar]: http://weblog.raganwald.com/2007/04/writing-programs-for-people-to-read.html

## The normal thing

Before I go off the deep end, let's make sure we're all together. Here's the
canonical use case for extension methods. Let's say you have some class created
by an external developer (read "Microsoft"). We'll pick String because
[everyone][string-1] [else][string-2] [does][string-3]. Let's say you want a
method to tell if a string contains only letters. Here's how you'd normally do
it:

[string-1]: http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx
[string-2]: http://www.developer.com/net/csharp/article.php/3592216
[string-3]: http://msdn2.microsoft.com/en-us/library/bb383977.aspx

```csharp
public static class StringUtils
{
    public static bool IsAlpha(string text)
    {
        foreach (char c in text.ToLower())
        {
            if (!Char.IsLetter(c)) return false;
        }
        return true;
    }
}
```

That works, but the calling convention is kind of lame:

```csharp
bool isAlpha = StringUtils.IsAlpha(someString);
```

Not only is it backwards from normal "noun.verb" OOP syntax, it's got this
useless "`StringUtils`" in there. Worse, your users have to *know* that
`StringUtils` even exists before they can find the method. `IsAlpha` is no
longer an easily discoverable property of all strings. So here's the fancy C#
3.0 way using an extension method:

```csharp
public static class StringUtils
{
    public static bool IsAlpha(this string text)
    {
        string letters = "abcdefghijklmnopqrstuvwxyz";
        foreach (char c in text.ToLower())
        {
            if (!letters.Contains(c)) return false;
        }
        return true;
    }
}
```

Not much different right? Just add a little `this` in the declaration. The
difference is in the calling convention:

```csharp
bool isAlpha = someString.IsAlpha();
```

Much better. So this is about as far as I think most people get with them.
"Extension method" = "friendlier calling convention". Now, let's see if there
are any other rabbits we can pull out of this hat.

## Reuse methods without inheritance

Ever wish you could reuse a method across five different classes that don't
share a base class? In most cases, that usually means some seriously extensive
refactoring. In many cases, it isn't even *possible* with single inheritance.
Maybe your classes already have distinct base classes for good reasons.

Here's what I'm talkin' about. Let's say you're writing a game and you've got
something like this:

```csharp
public interface IPosition
{
    float X { get; }
    float Y { get; }
}

public class Monster: Actor, IPosition { /* implementation... */ }
public class Treasure: Item, IPosition { /* implementation... */ }
```

Often, you want to look through a collection of these to find the first one at a
given position. The normal solution is to just derive your own collection and
implement it there:

```csharp
public class MonsterCollection : List<Monster>
{
    public Monster GetAt(IPosition pos) { /* ... */ }
}
```

The problem is you've now got to derive a new collection for every class with a
position and copy `GetAt()` in every one. Sure, you could do an abstract
collection for a collection of things with positions but that doesn't cover
different *kinds* of collections. What if you need lists and queues and stacks
of monsters?

Extension methods to the rescue! You can define extension methods *on
interfaces*. In fact, you can even define them on *generic* interfaces. Like
`IEnumerable<T>`. Ooh!

```csharp
public static class IPositionExtensions
{
    public static T GetAt<T>(this IEnumerable<T> col,
        float x, float y) where T : IPosition
    {
        foreach (T item in col)
        {
            if ((item.X == x) && (item.Y == y)) return item;
        }
        return default(T);
    }
}
```

Now you can do:

```csharp
List<Monster> monsters = new List<Monster>();
monsters.GetAt(1.0f, 2.0f);
```

Along with:

```csharp
Stack<Treasure> treasures = new Stack<Treasure>();
treasures.GetAt(1.0f, 2.0f);
```

Heck, even:

```csharp
Dictionary<string, Monster> monsters =
    new Dictionary<string, Monster>();
monsters.Values.GetAt(1.0f, 2.0f);
```

This means **you can define methods that say, "if this class provides this
capability, then it also has this capability"**. Whoawesome!

## Make Scott Meyers happy

One of the guidelines in [long-haired viking Scott Meyers'][meyers] legendary
tome [Effective C++][] is "[prefer non-friend non-member functions to member
functions][non-member]. You could translate that in C# to, "prefer static
methods of a helper class to instance methods".

[meyers]: http://www.aristeia.com/
[effective c++]: http://www.amazon.com/dp/0201924889
[non-member]: http://www.aristeia.com/effective-c++_frames.html

His reasoning is sound. Most people agree that the more you can hide information
(i.e. prevent access to private members), the stronger and less coupled your
code. His guideline just extends that to methods of a class: If you can
implement a method just using other public methods of a class, why give it
access to the private members at all? Why not decouple even parts of the class
from itself?

At the concept level, it's good advice, until you run into some issues:

1.  You've just **changed the user's calling convention because of an
    implementation detail**. The fact that you can implement a method just using
    the public interface of the class is a facet of its *implementation*, just
    the kind of detail that encapsulation is supposed to *hide*. But now the
    user is forced to deal with that distinction because sometimes they call (in
    C#):

    ```csharp
    foo.Bar(); // needs access to private members
    ```

    and sometimes it's:

    ```csharp
    FooHelper.Bar(foo); // doesn't need access to private members
    ```

2.  You also **threw away discoverability**. Users expect to find the
    capabilities of an object through the instance methods of that object. You
    can save a lot of time reading MSDN by just typing `foo.` and seeing what it
    lets you do. Shunting stuff over in a separate class means users need to
    know about it and seek it out.

3.  Also, you just **pitched out some extensibility**. The fact that you can
    implement a method as a non-instance member *now* doesn't mean you *always
    will* be able to. If you decide that `FooHelper.Bar()` really does need to
    use that private cache inside `Foo` for performance, too bad. You either
    have to make your helper class a friend (kinda defeats the purpose) or
    worse, force all of your users to change their code.

By now, you've probably noticed that extension methods neatly address all of
those issues, while still providing the same benefits. Simply change
`FooHelper.Bar(foo)` to an extension method. Now the calling convention is the
same as an instance method (point #1), the IDE will show it in auto-complete
(#2), and since the calling convention is the same, you could move `Bar()` from
`FooHelper` into `Foo` later if you needed without having to change any calling
code (#3). Score!

## Separate your concerns

So while the points above were running through my head in a kind of "Oh, here's
an interesting abstract programming thing" way, I was dealing with a much more
tangible real problem with some projects I was working on: separating back-end
code from UI code. (Or [MVC][], or "[separating presentation and content][sep]",
or "[separation of concerns][]", or whatever buzzphrase you prefer.) Any
engineer worth their [salt] gets this concept. Smearing UI logic, or printing,
or serialization, or *whatever* throughout the rest of your code is dumb.

[mvc]: http://en.wikipedia.org/wiki/Model-view-controller
[sep]: http://en.wikipedia.org/wiki/Separation_of_presentation_and_content
[separation of concerns]: http://en.wikipedia.org/wiki/Separation_of_concerns
[salt]: http://en.wikipedia.org/wiki/Salt_%28cryptography%29

For example, let's say we have a monster. (Who wouldn't want a pet monster?)

```csharp
namespace Engine
{
    public class Monster
    {
        public float X;
        public float Y;
        public string Type;

        public void ProcessAI()
        {
            // stuff...
        }
    }
}
```

This class defines what a monster *is* in the abstract data sense. We want to
isolate it from anything specific to UI or rendering because while *right now*
the UI is kicking [old school][rephial] [ASCII][], it may get graphics in the
future. That change shouldn't affect the engine one bit.

[rephial]: http://www.rephial.org
[ascii]: http://angband.oook.cz/screen-show.php?id=1358

But our uber-modern ASCII UI needs to know what character to use to draw a given
monster. Ideally:

```csharp
public void Draw(Monster monster)
{
    Console.WriteLine(monster.Character);
}
```

We can solve our separation problem like this:

```csharp
namespace UI
{
    public static class MonsterExtensions
    {
        public static char GetCharacter(this Monster monster)
        {
            if (type == "orc") return 'o';
            if (type == "kobold") return 'k';
            if (type == "dragon") return 'd';
            return '?';
        }
    }
}
```

Now code that is using the UI namespace sees `GetCharacter()` as an intrinsic
capability of monsters, but code that only uses the engine doesn't. And since we
can define `GetCharacter()` in a separate assembly, we can *totally* separate it
from the engine even while keeping the usability of having it *seem* to be part
of `Monster`.

You can apply this to almost all of the concerns of a class, provided the
concern doesn't require its own data. If you take this is far as you can, you
end up with a core class whose job is to hold state and ensure that it's
internally consistent. Then the various capabilities of the object: display,
serialization, printing, etc. can be implemented as distinct sets of extension
methods on it, defined in separate assemblies.

## Limitations

I'm pretty excited about extension methods, but they aren't without their
limitations. The two big ones are that C# doesn't support extension properties
(boo), and that obviously extension methods can't add fields to a class. But if
all you're trying to do is add new behavior I think extension methods are a cool
way to do it while keeping things as decoupled as possible.
