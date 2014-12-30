---
layout: post
title: "Refining Exceptions and Error Codes"
categories: code language magpie
---
I've been thinking a lot about error-handling in Magpie, and I wanted to foist
a couple of ideas out there to get some feedback.

## Kinds of Errors

When I'm designing something, I tend to start from a few representative
examples, and then I see how my idea for a solution handles those cases.
Error-handling encompasses a pretty wide range of cases, everything from "you
typed the name wrong" to "the machine is on fire". That space is pretty big,
but I think the following touch the most important corners of it. Let me know
if I missed something:

### Programmatic Errors (The Programmer Screwed Up)

When I look at code I wrote, most of the error-handling code in it is for
handling errors in *other* code. In other words, it's code contract stuff:
validation code that asserts what arguments should look like and what state
objects should be in when you try to do stuff with them.

When possible, it's good to squash those bugs *statically* so you don't need
code to handle them at all. Magpie does that with `null` reference bugs, but
there are others that are trickier: things like out of bounds array access, or
attempting to cast a variable to the wrong type.

In C and C++, these errors are usually handled using `assert()` or similar
mechanisms. Java and C# each have a set of standard exception types that are
thrown: `InvalidOperationException`, `IllegalArgumentException`, etc.

Checks for these errors are very common, so they should be lightweight in both
in code and in CPU cycles. At the same time, we don't generally *handle* these
errors, in the sense of recovering at runtime. Instead, we just want to
*notice* the error and scream and shout to the programmer to handle it by
fixing the code that causes the error in the first place. Giving diagnostic
information like a stack trace is good.

### Runtime Errors (The Real World Isn't Perfect)

I lump into this fuzzy category errors that can occur at runtime and either
can't be programmatically prevented, or where doing so is as expensive as
performing the operation itself. Some examples:

  1. Working with files or the network.

  2. Parsing, formatting, or manipulating data.

These are the kinds of things we typically think of when we think of "errors".
We want to notice when they've happened, and we will very likely need to write
code to try to recover from them gracefully at runtime.

What this category *doesn't* imply is any sort of *frequency*. Whether or not
a given error is common is entirely dependent on the application. A blog
engine probably considers text parsing a common source of errors. A game app
that just loads a single config file with a known format can safely assume
they won't happen.

This means we want to have some flexibility regarding how errors in this
category are handled. If we force a certain strategy by assuming that some
errors are common and some are rare, then we'll shaft users that aren't like
us.

### Catastrophic Errors (All Hell Breaks Loose)

The last category is errors that are so deep that we probably *can't* handle
them. These are errors are distinguished by the fact that they interfere with
our ability to execute further code: things like stack overflows or running
out of memory.

## Handling Errors

There are a [bunch of different strategies](http://lambda-the-ultimate.org/node/3896#comment-58374) languages have tried over the
years to cope with the inevitable fallibility of mankind. The two I'm most
interested for Magpie are return codes (using [unions](http://journal.stuffwithstuff.com/2010/08/23/void-null-maybe-and-nothing/)) and exceptions.
Those seem to be the workhorses for languages in wide use. (I'm interested in
other ideas, but for this post, I just want to look at those two.)

Now the question is how can we use those two features to deal with the
different categories of errors I listed up there?

### Handling Programmatic Errors

These are probably the easiest to solve (from the language design perspective)
because there's little to do: we don't plan to handle them in most cases, just
notice them. I'm comfortable with the Java and C# model of "throw an exception
that isn't expected to be caught". Aborting with a stack dump is equally
effective, and does the same thing in practice.

For example, a method for accessing an item in a collection could look like:

{% highlight magpie %}
def Collection getItemAt(index Int -> Item)
    if index < 0 or index > count then OutOfBoundsError throw()

    // do stuff with index...
end
{% endhighlight %}

That is a bit tedious, though. I'd likely refactor that into a separate
function, like:

{% highlight magpie %}
def Int checkBounds(count Int ->)
    if this < 0 or this > count then OutOfBoundsError throw()
end

def Collection getItemAt(index Int -> Item)
    index checkBounds(count)

    // do stuff with index...
end
{% endhighlight %}

Not exactly rocket science, but I think it gets the job done. Let's skip
runtime errors and move on to the other easy one:

### Handling Catastrophic Errors

Catastrophic errors are exceptional in the sense that we'll rarely be handling
them, so exceptions are a good fit here too. In fact, most of these exceptions
wouldn't even be thrown from Magpie code&mdash; they'd bubble up from the bowels of
the interpreter itself.

On the off chance that you *do* want to catch one, you can use a regular catch
block:

{% highlight magpie %}
try
    // allocate a huge array...
catch (err OutOfMemoryError)
end
{% endhighlight %}

Familiar territory. If you've used exceptions a lot, you've noticed one
annoying thing with them is that they're syntactically cumbersome: you have to
create this `try` block and push everything over a level of indentation. To
try to simplify that, I'm batting around an idea that might be clever, or
might just be really dumb: treat *every* block as a `try` block.

The basic idea is that any block can have `catch` clauses at the end of it,
and having them implicitly makes it a `try` block. That should get code like:

{% highlight magpie %}
def copy(source String, dest String ->)
    try
        // copy files...
    catch (e IOError)
        // handle error...
    end
end
{% endhighlight %}

And simplify it to:

{% highlight magpie %}
def copy(source String, dest String ->)
    // copy files...
catch (e IOError)
    // handle error...
end
{% endhighlight %}

I'll have to try it out to see if it causes any problems in the grammar, but
my hope is it will work OK. I'm curious to see if just making exceptions a
little more terse like this will make them more palatable to people who
dislike them. If you happen to have an opinion, I'd like to hear it.

### Handling Runtime Errors

Finally, the biggest class of errors. The trick with these is that there's no
easy way to bucket them into "common" and "rare". If we could, we could just
say "use exceptions for the rare ones and return codes for the common ones".
Instead, we'll need to support both.

Here's my plan. For our example, we'll consider a simple one: parsing. Let's
say we have a function to parse strings to booleans:

{% highlight magpie %}
def parseBool(text String -> Bool)
    match text
    case "true" then true
    case "false" then false
    else // ??? what do we do here?
    end
end
{% endhighlight %}

This can be called like:

{% highlight magpie %}
var b = parseBool("true")
{% endhighlight %}

Of course, the question is what happens if it fails? Since this may be common,
we want it to be easy to handle the failure case. Unions are a good fit for
that. We'll change the function to:

{% highlight magpie %}
def parseBool(text String -> Bool | Nothing)
    match text
    case "true" then true
    case "false" then false
    else nothing
    end
end
{% endhighlight %}

Now it will return a boolean value if the parse succeeds, or the special
`nothing` value if it fails. Note that this is *not* like just returning
`null`: the return type of `parseBool` is different now. That means you can't
do this anymore:

{% highlight magpie %}
var b = parseBool("true")
var notB = b not
{% endhighlight %}

The `not` method is a method on booleans, and `b` isnt' a boolean, it's a
`Bool | Nothing`. To treat it like a boolean, you first have to check its
type. The canonical way to do that in Magpie is using `let`:

{% highlight magpie %}
let b = parseBool("true")
    // in here, b is a Bool
    var notB = b not // this is fine
else
    // parse failed...
end
{% endhighlight %}

This is great for cases where parsing is likely to fail. It makes sure you
always handle the common failure case by giving you a type-check error before
the program is run if you don't check for success first.

But what if parsing rarely fails in your program? Do you really want to have
to do a cumbersome `let` block everywhere you call `parseBool` just because
that fails all the time in some other program?

In your case, failing to parse *is* exceptional, so it should throw an
exception. That way, you can ignore the cases that aren't relevant to your
problem. I think we can handle that too.

We'll just add a simple method to `Object` that tests to see if its of an
expected type. If not, it will throw, otherwise it will return itself, but
statically-typed to the expected type. Like so:

{% highlight magpie %}
def Object expecting[T]
    let cast = this as[T] then
        cast
    else UnexpectedTypeError throw(
        "Expected type " + T + " but was " + this type,
        this)
end
{% endhighlight %}

Now, if we have a function that returns a union containing an error, we can
translate that to an exception instead like this:

{% highlight magpie %}
// doesn't expect a parse error
var b = parseBool("true") expecting[Bool]
var notB = b not // ok, since b is a Bool
{% endhighlight %}

Using this, almost all functions that can have runtime errors will be
implemented by returning a union of success and an error code, like:

{% highlight magpie %}
def readFile(path String -> String | IOError)
    if pathExists(path) then
        // return contents of file...
    else IOError new("Could not find " + path)
end
{% endhighlight %}

Then code that uses it can handle the error in place if that makes sense:

{% highlight magpie %}
def printFile(path String ->)
    var result = readFile(path)
    let contents = result as[String] then
        print(contents)
    else let error = result as[IOError] then
        print("Error!")
    end
end
{% endhighlight %}

(Yes, `else let` is a bit tedious. Better pattern-matching syntax for unions
is still in the works.) Meanwhile, code that doesn't care to handle the error
right there can pass the buck:

{% highlight magpie %}
def printFile(path String ->)
    var contents = readFile(path) expecting[String]
    print(contents)
end
{% endhighlight %}

Of course, none of this is any real innovation. My goal here is just to round
off some of the sharp corners of exceptions and return codes and see if I can
make the process of dealing with errors a bit more flexible and readable.
Thoughts?
