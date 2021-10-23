---
title: "ML-Style Pattern Matching in C#"
categories: c-sharp code f-sharp language
---

There's nothing like travelling abroad to make you see your home country with
new eyes. While your first fascination with everything new and different in the
foreign land may enventually be replaced by homesickness, you always want to
bring back a souvenir, a little bit of the best of where you've been.

C# is my home country these days, but I've been vacationing in F#. There's a lot
there that's absolutely brilliant, like [currying][] and [partial
application][], [workflows][], and [option types][] (no more
[NullReferenceExceptions][]!). But one of the first things I fell in love with
in the language was pattern matching. Pattern matching in F# (and its ancestors
ML and OCaml) is something like `switch/case` on steroids. Here's a simple
example of a `switch/case` in C#:

[currying]: http://en.wikipedia.org/wiki/Currying
[partial application]: http://ejohn.org/blog/partial-functions-in-javascript/
[workflows]: http://www.infoq.com/articles/pickering-fsharp-workflow
[option types]: http://www.markhneedham.com/blog/2009/01/02/f-option-types/
[nullreferenceexceptions]: https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/

```csharp
int i = 2;
switch (i)
{
    case 0:  Print("zero");
    case 1:  Print("one");
    case 2:  Print("two");
    default: Print("some other value");
}
```

Here's what the same logic would look like in F#:

```fsharp
let i = 2
match i with
| 0 -> Print("zero")
| 1 -> Print("one")
| 2 -> Print("two")
| _ -> Print("some other value")
```

You can probably infer what's going on. Pretty similar to our familiar
`switch/case`. It checks each value and executes the clause on the right the
first time it finds a match. The `_` bit on the last line is equivalent to
`default` in a `switch/case`: it always gets matched if we get that far. Basic
stuff, but pattern matching can do so much more. Before I can explain *that*,
though, we'll need to take a little side trip to see another F# feature:
[discriminated unions][].

[discriminated unions]: http://en.wikipedia.org/wiki/Variant_record

## Discriminated unions

Where C# has enums, F# has discriminated unions. The main difference between the
two is that each value in the union can have additional data fields. Imagine you
want to enumerate the different kinds of [image macros][]:

[image macros]: http://en.wikipedia.org/wiki/Image_macro

```csharp
enum ImageMacro
{
    Lolcat,
    Lolrus,
    ORlyOwl
}
```

Pretty basic. Now if it's a [lolcat][], we also want to note the text of the
caption, and if it's a [lolrus][], we want to note how many buckets it has. In
C#, we'd have to ditch the enum and resort to a class hierarchy:

[lolcat]: http://en.wikipedia.org/wiki/Lolcat
[lolrus]: http://icanhascheezburger.com/2007/01/14/i-has-a-bucket/

```csharp
abstract class ImageMacro { }

class Lolcat : ImageMacro
{
    public string Caption;
    public Lolcat(string caption) { Caption = caption; }
}

class Lolrus : ImageMacro
{
    public int Buckets;
    public Lolrus(int buckets) { Buckets = buckets; }
}

class ORlyOwl : ImageMacro { }
```

Classic OOP design, and it gets the job done. In F#, you can simply add fields
to a discriminated union and accomplish the exact same thing:

```fsharp
type ImageMacro =
    | Lolcat    of string
    | Lolrus    of int
    | ORlyOwl
```

The `of string` says that when you make a Lolcat ImageMacro (and *only* a
Lolcat) that you must also provide a caption. Likewise, the `of int` says that a
Lolrus needs a number of buckets.

## Pattern matching discriminated unions

These two features, pattern matching and discriminated unions, go together in F#
like gondolas and striped shirts. Each is much less awesome without the other.
Now let's get back to pattern matching and see something it can do that a
`switch/case` definitely can't. Given our above ImageMacro type, let's say we
want to print it out:

```fsharp
let image = Lolcat("I made you a cookie")
match image with
| Lolcat(caption) -> Print("Lolcat says '" + caption + "'")
| Lolrus(buckets) -> Print("Lolrus has " + buckets + " buckets")
| ORlyOwn         -> Print("O RLY?")
```

Now *that's* pretty nice. Not only does it switch on what kind of image macro
it is, it also pulls out the data associated with each one ("destructures" in
the local parlance). This would definitely be nice to have in C#.

## A little souvenir: `Pattern.Match`

So can we bring discriminated union pattern matching back to C#? Since C#
doesn't have discriminated unions, we'll have to make it work with the little
inheritance tree up there. Here's what I got:

```csharp
ImageMacro image = new Lolcat("I made you a cookie");
Pattern.Match(image).
    Case<Lolcat, string> (c  => Print("Lolcat says '" + c + "'")).
    Case<Lolrus, int>    (b  => Print("I has " + b + " buckets")).
    Case<ORlyOwl>        (() => Print("O RLY?"));
```

A little strange, but not *too* bad. Looks kind of like a `switch/case` but
switches based on type. For `Lolcat` and `Lolrus`, we pull out the caption and
number of buckets. How does this work? Let's build it from the bottom up.

## The `Case()` method

A single case in our pattern matcher needs to specify three things: the type
being selected (Lolcat, Lolrus, etc.), the field(s) to pull out (if any), and
the action to perform when the case is successfully matched. Let's start with
the simplest possible system: one that can only match a single value based on
type, with no fields. Here's the basic class:

```csharp
public class Matcher<T>
{
    public Matcher(T value) { mValue = value; }

    public void Case<TCase>(Action action)
    {
        if (mValue is TCase) action();
    }

    private T mValue;
}
```

The action being passed in is a delegate, and we construct it using C# 3.5's
handy lambda notation. For the ORlyOwl, it's:

```csharp
() => Print("O RLY?")
```

Aside from being a nice clean notation, the other nice thing about lambdas (and
anonymous delegates) is that they can access variables defined in the outside
scope. This lets our `Case` clauses do everything a regular `case` can do in a
vanilla `switch/case`.

### Chaining cases using a fluent interface

What we have so far is simple, but it only lets us select a single case. To be
able to chain multiple cases together, we're going to use something the hip
kids are calling a "fluent interface". The basic idea is to make methods
return `this` so that you can call multiple methods on the same object by
`chaining.Them().Like().This()`:

```csharp
public Matcher<T> Case<TCase>(Action action)
{
    if (mValue is TCase) action();
    return this;
}
```

### Preventing multiple matches

There's a problem here. A pattern should only match the *first* successful case.
If we just allow arbitrary chaining, it would be possible to have multiple
matches. Here's a solution:

```csharp
public virtual Matcher<T> Case<TCase>(Action action)
{
    if (mValue is TCase)
    {
        action();
        return new NullMatcher<T>();
    }
    return this;
}
```

Now when we have a successful match, instead of continuing the fluent
interface and returning `this`, we return a `NullMatcher<T>` As you can
probably guess, that class has the same methods as `Matcher<T>`, but never
actually matches:

```csharp
public class NullMatcher<T> : Matcher<T>
{
    public override Matcher<T> Case<TCase>(Action action)
    {
        return this;
    }
}
```

### Extracting fields

So far, we're up to being able to do this:

```csharp
Pattern.Match(image).
    Case<Lolcat> (() => Print("Lolcat says '?'")).
    Case<Lolrus> (() => Print("Lolrus has ? buckets")).
    Case<ORlyOwl>(() => Print("O RLY?"));
```

The last remaining step is to pull out the `caption` and `buckets` from the
`Lolcat` and `Lolrus` types. We'll do this by overloading `Case()`:

```csharp
public virtual Matcher<T> Case<TCase, TArg>(Action<TArg> action)
{
    IMatchable<TArg> matchable = mValue as IMatchable<TArg>;

    if ((matchable != null) && (mValue is TCase))
    {
        action(matchable.GetArg());
        return new NullMatcher<T>();
    }
    else
    {
        return this;
    }
}
```

What this new method does is both check the value's type and see if it
implements `IMatchable<T>`. That little interface lets a class expose a field
for pattern matching. (We could also do this using reflection. That would free
us up from having explicitly implement pattern matching support in classes, but
would also incur a performance penalty and bind the pattern matching to the
internals of the matched classes.) Here's the interface and its implementation
in our macro classes:

```csharp
interface IMatchable<TArg>
{
    TArg GetArg();
}

class Lolcat : ImageMacro, IMatchable<string>
{
    public string Caption;
    public Lolcat(string caption) { Caption = caption; }

    string IMatchable<string>.GetArg() { return Caption; }
}

class Lolrus : ImageMacro, IMatchable<int>
{
    public int NumBuckets;
    public Lolrus(int numBuckets) { NumBuckets = numBuckets; }

    int IMatchable<int>.GetArg() { return NumBuckets; }
}
```

I'm using explicit interface implementation here, because users only really
care about using `GetArg()` when they're doing pattern matching. Otherwise,
there's no reason to make it a visible part of the class's interface.

## The `Pattern` class

We've built back almost up the to the top. The last little bit left is the
simplest:

```csharp
Pattern.Match(image)
```

`Pattern` is simply a static class with one method `Match()`:

```csharp
class Pattern
{
    public static Matcher<T> Match<T>(T value)
    {
        return new Matcher<T>(value);
    }
}
```

The Pattern class exists simply because C# requires all functions to be in a
class. However, constructing Matchers through `Match<T>` does have one nice
side-effect: it lets the compiler infer the type parameter so you don't have to
explicitly write it out like you would when calling a constructor.

With this little bit in place, we've reached our goal of being able to get
something like matching discriminated unions working in C#:

```csharp
Pattern.Match(image).
    Case<Lolcat, string>(c  => Print("Lolcat says '" + c + "'")).
    Case<Lolrus, int>   (b  => Print("I has " + b + " buckets")).
    Case<ORlyOwl>       (() => Print("O RLY?"));
```

## But wait, that's not all!

This is only the beginning of what we can do with our little matching class.
Here are a few other things the full code lets you do:

### Extracting multiple fields

In the example above, we only pull a single field out of a given case. F#
supports multiple fields as well, as does the Matcher class (up to four):

```csharp
Case<Loldog, string, int> ((caption, dogs) =>
    Print("'" + caption + "', says " + dogs + " hotdogs")).
```

### A default case

It's also useful to have a `default`-like case that will always succeed if no
other case matches:

```csharp
Pattern.Match(image).
    Case<Lolrus, int> (b  => Print("I has " + buckets + " buckets")).
    Default           (() => Print("Default"));
```

### Equality matching

Another way to match values is if they are equal. We can do this generically
since `Equals()` is part of the .NET framework.

```csharp
Pattern.Match("a string").
    Case("not",      () => Print("should not match")).
    Case("a string", () => Print("should match"));
```

The example here uses strings, but this works with any type as long as it
implements `Equals()` correctly.

### Matching on any predicate

As you can see, there are a bunch of different ways users may want to match
data, and it's futile to try to bake all of them into the class. The most
obvious solution then is to simply let users pass in an arbitrary predicate (a
predicate is a function that returns a bool) and have the match succeed based
on that:

```csharp
Pattern.Match(123).
    Case(value => value < 100, () => Print("less than 100")).
    Case(value => value > 100, () => Print("greater than 100"));
```

You'll note that in the final code below, all of the other matching types are
built on top of this.

### Returning a value

F#, unlike C#, treats everything as an expression, even flow control
statements like `if/then` and `match`. This means a match can return a result:

```fsharp
// F#:
let isTwo = match 2 with
            | 2 -> true
            | _ -> false
```

In C#, you'd have to do an assignment:

```csharp
// C#:
bool isTwo;
switch (2)
{
    case 2:  isTwo = true;
    default: isTwo = false;
}
```

Our pattern matching class can do this too, even within C#:

```csharp
bool isTwo = Pattern.Match<int, bool>(2).
                 Case(2,  true).
                 Default( false);
```

## Conclusion

They say you never know your home until you travel abroad. I've been enjoying F#
a lot, but C# still feels more comfortable to me. However, it's always useful to
see how other languages solve problems, and see what new techniques can be
brought home with you. While our pattern matching class isn't quite as clean in
C# as it is in F#, I think it's a useful tool in its own right.

<div class="update">
<p><em>Update 2021/10/05:</em> Moved it to <a href="https://github.com/munificent/pattern_matching">GitHub</a>.</p>
</div>

If you'd like to play with it, [I've put it up on GitHub][code]. Have fun!

[code]: https://github.com/munificent/pattern_matching
