---
title: "Checking Flags in C# Enums"
categories: c-sharp code
---

<div class="update">
<p><em>Update 2021/09/22:</em> The Enum class has a built-in <a href="https://docs.microsoft.com/en-us/dotnet/api/system.enum.hasflag?view=net-5.0"><code>HasFlag()</code></a> method now.</p>
</div>

I like C# [enums] and I also like using them as [bitfields][], even though
apparently [not everyone does][dislike]. I realize they aren't perfectly
typesafe, but then I don't think that's the problem [Abrams][] and company were
trying to solve anyway.

[enums]: https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/enum
[bitfields]: https://docs.microsoft.com/en-us/dotnet/api/system.flagsattribute?view=net-5.0
[dislike]: http://cleveralias.blogs.com/thought_spearmints/2004/01/more_c_enum_wac.html
[abrams]: http://blogs.msdn.com/brada/

Here's an example one:

```csharp
[Flags]
public enum Fruits
{
    Apple       = 1,
    Banana      = 2,
    Cherry      = 4,
    Date        = 8,
    Eggplant    = 16
}
```

Nice, clean syntax. The way they solved C++'s name collision issues with enum
values is genius: `Fruits.Apple`. Clearly these guys are using the old noggin.

## The annoying bit (argh, a pun)

The one thing that *does* annoy me about flag enums is the syntax to see if a
given flag (or set of flags) is set:

```csharp
if ((myFruit & Fruits.Date) == Fruits.Date)
```

I'm not afraid of bitwise operators, but there's some serious lameness in
here. Needing to specify the explicit `==` for type safety and having to use
the parenthesis because the operator precedence puts `==` before `&` first?
Gross.

## For every nail there is a hammer

Behold the solution:

```csharp
public static class FruitsExtensions
{
    public static bool IsSet(this Fruits fruits, Fruits flags)
    {
        return (fruits & flags) == flags;
    }
}
```

With that, you can just do:

```csharp
if (myFruit.IsSet(Fruits.Date))
```

Much nicer. For kicks, here's some other useful methods:

```csharp
public static class FruitsExtensions
{
    public static bool IsSet(this Fruits fruits, Fruits flags)
    {
        return (fruits & flags) == flags;
    }

    public static bool IsNotSet(this Fruits fruits, Fruits flags)
    {
        return (fruits & (~flags)) == 0;
    }

    public static Fruits Set(this Fruits fruits, Fruits flags)
    {
        return fruits | flags;
    }

    public static Fruits Clear(this Fruits fruits, Fruits flags)
    {
        return fruits & (~flags);
    }
}
```

Useful, no?

## Why solve one when you can solve *n*?

So, if you're like me and [this guy][bennage], right now you're thinking, "This
just fixes one enum. Can I solve it for all enums?" Ideally, you'd do something
like:

[bennage]: https://web.archive.org/web/20120423104722/http://devlicious.com/blogs/christopher_bennage/archive/2007/09/13/my-new-little-friend-enum-lt-t-gt.aspx

```csharp
public static class EnumExtensions
{
    public static bool IsSet<T>(this T value, T flags) where T : Enum
    {
        return (value & flags) == flags;
    }
}
```

Unfortunately, that doesn't fly. You can't use `Enum` as a constraint.
Likewise, there's no way to require a typeparam to implement an operator (like
`&` above). You *can* implement a generic solution for this:

```csharp
public static class EnumExtensions
{
    public static bool IsSet<T>(this T value, T flags)
        where T : struct
    {
        Type type = typeof(T);

        // only works with enums
        if (!type.IsEnum) throw new ArgumentException(
            "The type parameter T must be an enum type.");

        // handle each underlying type
        Type numberType = Enum.GetUnderlyingType(type);

        if (numberType.Equals(typeof(int)))
        {
            return Box<int>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(sbyte)))
        {
            return Box<sbyte>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(byte)))
        {
            return Box<byte>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(short)))
        {
            return Box<short>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(ushort)))
        {
            return Box<ushort>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(uint)))
        {
            return Box<uint>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(long)))
        {
            return Box<long>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(ulong)))
        {
            return Box<ulong>(value, flags, (a, b) => (a & b) == b);
        }
        else if (numberType.Equals(typeof(char)))
        {
            return Box<char>(value, flags, (a, b) => (a & b) == b);
        }
        else
        {
            throw new ArgumentException(
                "Unknown enum underlying type " +
                numberType.Name + ".");
        }
    }

    /// Helper function for handling the value types. Boxes the
    /// params to object so that the cast can be called on them.
    private static bool Box<T>(object value, object flags,
        Func<T, T, bool> op)
    {
        return op((T)value, (T)flags);
    }
}
```

...but, yeah, it's not exactly fun using reflection for this.
