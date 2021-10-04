---
title: "\"Constrained Compound\" Design Pattern"
categories: c-sharp code design
---

I've seen a lot of people argue that inheritance is an anti-feature in a
language and that it's never necessary. That rubs me the wrong way because I use
inheritance pretty frequently in a recurring pattern, and I think it works well.
I figured the least I could do was try to document it and add to the design
pattern language. After thinking about it a bit more, I realized actually I
*don't* need inheritance to do it anyway. So, here's a little design pattern for
you, solved with and without inheritance:

> **Problem:**
>
> Often you need to define a number of behaviors in terms of (and only in terms
> of) a small set of atomic operations that can be freely combined.

Consider a UI framework that draws widgets. Each widget needs to be drawn its
own way, but all of them are drawn using a few primitive drawing operations:
text, lines, and shapes. Since this drawing will happen frequently and at
unpredictable times, you want to encourage the widget implementers to only use
those basic operations and not call into all sorts of places in the codebase.

As the API developer, there's basically two things you want to provide to your
clients: the set of operations, and the sandbox to combine them in. If you make
both of those apparent enough, then [they'll stick to those
operations][ops].

[ops]: http://blogs.msdn.com/brada/archive/2003/10/02/50420.aspx

> **Solution:**
>
> Allow the user to define a function whose body has access to an object (either
> `this` or an explicit parameter) that contains only the operations they should
> use to implement the function.

There's two ways I've found myself providing this kind of system, one of which
uses inheritance, one of which does not.

## Operations as protected methods

The most frequent way I use the pattern is by defining a base class with a
number of protected methods and a single abstract one. The protected methods are
the atomic operations, and the abstract one is the sandbox where they're used.
By making the operations protected (but not virtual), the implication is clear
to derivers: these methods are here for your use. The abstract sandbox method
says, "here's where you do your work". If you've minimized global and static
objects then the limited parameters to the sandbox say, "you only really have
access to the methods in `this`" so just use those. Here's an example:

```csharp
public abstract class Widget
{
    // The sandbox.
    public abstract void Draw();

    protected void DrawString(string text, int x, int y) { /* */ }
    protected void DrawLine(int x1, int y1, int x2, int y2) { /* */ }
    protected void DrawRect(int x, int y, int w, int h) { /* */ }
}

public class MyWidget : Widget
{
    public override void Draw()
    {
        DrawString("MyWidget", 5, 3);
        DrawRect(0, 0, 200, 20);

        for (int x = 0; x < 200; x += 5)
        {
            DrawLine(x, 15, x, 20);
        }
    }
}
```

If you try to go down this path, one limitation you will quickly realize is that
often the base class itself doesn't have enough contextual information to
provide those atomic functions. That needs to be passed in, but you don't want
the sandbox to have it (since it could then poke at it directly). Here's a
typical way around it:

```csharp
public abstract class Widget
{
    // The external public API.
    public void Draw(DrawContext context)
    {
        // Store what we need to implement the atomic operations.
        mContext = context;

        // But don't give it to the sandbox.
        DrawInternal();

        // Done with it.
        mContext = null;
    }

    // The sandbox.
    protected abstract void DrawInternal();

    protected void DrawString(string text, int x, int y) { /* */ }
    protected void DrawLine(int x1, int y1, int x2, int y2) { /* */ }
    protected void DrawRect(int x, int y, int w, int h) { /* */ }

    private DrawContext mContext;
}
```

Now `DrawString()`, etc. have access to the DrawContext, but the derived
widget itself does not.

## Atomic operations on a parameter

If you're not a fan of OOP or inheritance, here's another way to do the pattern.
If you notice above, what we're basically doing is providing all of the atomic
operations as methods available on `this`, which is then an implicit argument to
the sandbox method `Draw()`. Instead of using `this` you can always make those
operations on an explicit parameter. Here's a way to use that to have different
widgets draw differently without using inheritance:

```csharp
public class Widget
{
    public Widget(Action<DrawOperations> drawFunc)
    {
        mDrawFunc = drawFunc;
    }

    public void Draw(DrawContext context)
    {
        mDrawFunc(new DrawOperations(context));
    }

    private class DrawOperations
    {
        public DrawOperations(DrawContext context)
        {
            mContext = context;
        }

        public void DrawString(string text, int x, int y) { /* */ }
        public void DrawLine(int x1, int y1, int x2, int y2) { /* */ }
        public void DrawRect(int x, int y, int w, int h) { /* */ }

        private DrawContext mContext;

    }

    private Action<DrawOperations> mDrawFunc;
}

public Widget MakeMyWidget()
{
    Widget widget = new Widget(
        operations =>
        {
            operations.DrawString("MyWidget", 5, 3);
            operations.DrawRect(0, 0, 200, 20);

            for (int x = 0; x < 200; x += 5)
            {
                operations.DrawLine(x, 15, x, 20);
            }
        });
    }

    return widget;
}
```

This has the advantage of letting you later change how a widget draws without
baking it into the class hierarchy, but may be a bit odd to people with only
class-based OOP language experience.

## A note on patterns

There's a lot of hype that surrounds the idea of [design patterns][]. When [the
book][gof] first came out, C++ people who were struggling to understand OOP
swarmed to it like it contained revelation from on high. After a while, people
(especially non-OOP people) rejected that outright and claimed Design Patterns
was simply a collection of boilerplate to get around the limitations of crappy
OOP languages. Neither of those were ever the intent of [Alexander's][tree]
[pattern language][] concept. Patterns are supposed to be a simple clarification
of things people are already doing, and the language of patterns is intended to
always be evolving and growing. It's neither revelation nor prescription (do
this, don't do that). It's simply "here's this problem we see often and here's a
good way we see people solve it."

[design patterns]: http://en.wikipedia.org/wiki/Design_pattern_(computer_science)
[gof]: http://en.wikipedia.org/wiki/Design_Patterns
[tree]: https://www.patternlanguage.com/archive/cityisnotatree.html
[pattern language]: http://en.wikipedia.org/wiki/A_Pattern_Language

Patterns are *not* supposed to be complex high-tech innovations (an excellent
pattern in *A Pattern Language* encourages you to put a bench by your front
door). If you read the Constrained Compound pattern above and thought, "Oh yeah,
I've done something similar a bunch of times," then *good*. That familiarity
means it's a good solution because a lot of people have used it and is worth
adding to the language. Now it has a name.
