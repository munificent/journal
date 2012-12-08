---
layout: post
title: "Conditional Binding with \"let\" in Magpie"
#categories: code, language, magpie
---
Magpie, as an imperative language, has the usual flow control structures you
expect to see: `while`, `if`, and `for` (although they're a little different
from their C counterparts). However, Magpie has one other flow control
construct you probably haven't seen before: `let then`, the conditional
binder.

## A Motivating Example or Two

Before I explain it, let's go over a couple of examples in other languages
where it would be useful. First up: converting strings to other types. In C#,
you'd do something like:

{% highlight csharp %}
int value = Int32.Parse("1234");
// do something with value
{% endhighlight %}

That's fine and dandy except that the parse can fail and throw an exception.
If you don't want to deal with the exception, the easier solution is to use
the conveniently provided `TryParse` function:

{% highlight csharp %}
int value;
if (Int32.TryParse("1234", out value))
{
    // do something with value
}
{% endhighlight %}

That's the idiomatic way to convert strings to ints in C#. Aside from the
cumbersome out parameter, what's lame about it is that `value` is scoped
*outside* of the `if` block where we actually want to use it. If the
conversion fails, we have this weird unassigned `value` variable floating
around.

Here's another example: downcasting. Let's say we have a variable of type
`Base` and we want to downcast it to a `Derived` subclass. The normal way to
do this is:

{% highlight csharp %}
Derived derived = someBase as Derived;
if (derived != null)
{
    // do something with derived
}
{% endhighlight %}

A third and final example: looking up a value in a dictionary. If you aren't
sure the key exists, the typical solution is:

{% highlight csharp %}
Dictionary<string, int> dict = // get dictionary...

int value;
if (dict.TryGetValue("key", out value))
{
    // do something with value
}
{% endhighlight %}

You're seeing the pattern by now. All of these have the exact same structure.
We have some operation that may return a value or may fail for some reason. If
it succeeds, we want to do something with the returned value.

## Let

The `let` keyword in Magpie lets you implement that pattern directly, without
the gross scoping issues or output parameters. The above examples in Magpie
would look like:

{% highlight magpie %}
// parse
let value <- "1234".AsInt then
    // do something with value
end

// downcast
let derived <- someBase.As'Derived then
    // do something with derived
end

// look up in dictionary
let value <- Find (dict, "key") then
    // do something with value
end
{% endhighlight %}

The way this works is pretty simple. Magpie has an `Option` type, which is the
same as F#'s [option](http://msdn.microsoft.com/en-us/library/dd233245%28VS.100%29.aspx) or Haskell's [Maybe](http://en.wikibooks.org/wiki/Haskell/Hierarchical_libraries/Maybe). A `let` expression looks
like:

{% highlight magpie %}
let <variable> <- <expression> then <body>
{% endhighlight %}

The `<expression>` is expected to return an `Option` value. If it evaluates to
`Some`, then the value is extracted and assigned to `<variable>` and the
`<body>` is evaluated. If `None` is returned instead, the variable isn't bound
and the body is skipped. Pretty straightforward.

What's nice about it is that the bound variable is scoped to the body of the
`let` expression and disappears afterwards. This means that if the expression
fails and returns `None`, the variable disappears entirely. It's syntactically
impossible to access that variable incorrectly when the expression fails.

## What Else?

Because `let` is essentially another kind of `if`, it also supports an `else`
clause:

{% highlight magpie %}
// parse
let value <- "1234".AsInt then
    // do something with value
else
    Print "Couldn't parse string."
end
{% endhighlight %}

## A Bit on Naming

I probably spend more time than I should thinking about the minutia of
language syntax. I chose `let` because to me that implies *permission*: it
*may* "let" you do something or it may not, which lines up with the
conditional nature of the construct. Using `then` to separate the expression
from the body both reinforces that this is an "if-like" conditional block and lets me reuse an existing keyword.

Of course, programmers of the ML-family will likely recognize `let` as a poor
man's pattern matching. This isn't far from the truth, but I do think Magpie's
"light" version is kind of nice in its own regard.
