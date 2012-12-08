---
layout: post
title: "Pattern Matching in a Dynamic OOP Language"
#categories: code
---
Another long weekend and another fun milestone for [Magpie](http://github.com/munificent/magpie). I've finally
managed to pull off something that I've wanted to support for a long time:
*real destructuring pattern matching*. Even more awesome, it uses patterns not
just in the basic `match` expression, but also for exception-handling catch
clauses, variable declarations, and function type declarations.

This is great because it means we can use the same concept to support a lot of
the language's semantics. There are fewer things for a user to learn, and if I
make that one concept more powerful, the effect is magnified across more of
the language. But I'm getting ahead of myself here.

## Pattern What?

If you've never ventured into the realm of static functional languages, it's
entirely likely you've never heard of [pattern matching](http://en.wikipedia.org/wiki/Pattern_matching), or if you have,
it was describing something else. I wrote [a really long introduction to
it](http://journal.stuffwithstuff.com/2009/05/13/ml-style-pattern-matching-in-c/) a while back, but I'll do the super science breakdown here.

What I think you'll find is that you *do* know what it is, you just don't know
you know it. Here's some examples:

### Switch

Consider the humble `switch` statement in [Ye Olde Imperative Language](http://en.wikipedia.org/wiki/C_%28programming_language%29):

{% highlight c %}
switch (i) {
  case 1:  printf("first"); break;
  case 2:  printf("second"); break;
  case 3:  printf("third"); break;
  default: printf("uh..."); break;
}
{% endhighlight %}

Pretty straightforward. The key bits are, we have a *value* being tested (here
just `i`), a series of *clauses*, and a *default clause*. Each clause has a
*body* and a value being compared against, which I'll call the *pattern*.

The semantics are equally straightforward. First, we evaluate the value
expression, then we walk down the clauses. For each one, we see if the pattern
*matches* the value. If so, we execute the body and end (we'll ignore
fallthrough here). "Match" is a pretty fuzzy term. In the context of a
`switch` statement in C, all it means is equivalence. Two values match if
they're the same value.

### Catch

Now let's switch gears and take a look a `catch` blocks in everyone's favorite
[Big Enterprise Language](http://en.wikipedia.org/wiki/Java_%28programming_language%29):

{% highlight java %}
try {
  // Do something crazy...
} catch (ParseException ex) {
  System.out.println("Parse error!");
} catch (IOException ex) {
  System.out.println("IO error!");
} catch (Exception ex) {
  System.out.println("Uh-oh!");
}
{% endhighlight %}

When an exception gets thrown in a try block, we start playing with the
`catch` blocks. The key bits here are: we have a *value* being tested (the
thrown exception) and a series of *clauses* (the `catch` blocks). Each clause
has a *body* and an exception type being compared against, which we'll again
call the *pattern*.

Sound familiar? Aside from syntax, the only real difference between exception
handling and `switch` statements is that `catch` clauses match on the
exception's *type* instead of its value. All of the other machinery is the
same.

### Destructure

Last example, and a different one from the previous two. Let's take a look at
the [Hot New Language](http://en.wikipedia.org/wiki/Javascript). The latest Mozilla-specific version that no one
actually uses (not that I'm bitter or anything) introduced a new feature
called *destructuring assignment*. It looks like this:

{% highlight javascript %}
var point = [1, 2];
var [x, y] = point; // Destructure point.
alert(x + ", " y);
{% endhighlight %}

You can probably infer what's going on here. The second line declares two new
variables, `a` and `b` and initializes them by pulling elements out of the
array `point` used as the initializer.

There's no flow control going on, but this does have some features in common
with the previous two examples. First, we have a value: `point`. And we have a
pattern that it's being matched against: `[x, y]`. In this case, we don't use
the pattern to *test* the value, we use it to *pull data out of it*.

Actually, that destructuring part isn't so different from *one* of our
examples after all. The exception-handling code does something very similar.
When it finds a matching `catch` block, it does bind the caught exception to a
new variable-- the one declared in the `catch` block's type signature.

## Patterns in Magpie

There's some other details, but what you've just seen covers 90% of the
awesomeness that is pattern-matching in the ML family of languages. The only
problem is that in the languages we've looked at, those features are all split
across unrelated constructs. A `switch` can't match on types, nor can it
destructure an array. A `catch` block can't choose to only catch an exception
if it has a certain *value* (like maybe a specific error message).

All the pieces are there, but they're scattered across the language. Let's
bring them together. We'll do this by making patterns a first-class feature of
the language. Any given pattern needs to support a couple of operations:

  1. Test to see if it matches a value.
  2. Bind new variables by pulling data out of the value.

Just like normal expressions in the language work, we'll define a couple of
core types of patterns, and then let users compose them to their heart's
content. In Magpie, those are:

### Value Pattern

The simplest pattern is just an expression that evaluates to a value. These
are like the literals after the `case` in a `switch` statement, but Magpie
lets you use pretty much any expression. These are valid value patterns:

{% highlight magpie %}
123
true
"a string"
3 + 5
{% endhighlight %}

Testing against a value is simple: it's just an equality check. A `2` pattern
matches if the value is also `2`. Magpie does this by just calling the `==`
operator, so it's even possible to use your own types here.

Value patterns don't bind any new variables at all, so that bit's easy too.

### Tuple Pattern

This is one of two patterns that has subpatterns. With this, you can start
composing bigger patterns that do more stuff. A tuple pattern is just like a
[tuple expression](http://journal.stuffwithstuff.com/2009/05/05/one-and-only-one/): it's a series of patterns separated by commas. For
example:

{% highlight magpie %}
3, "four", false
{% endhighlight %}

Here we have a tuple of three value patterns. A tuple pattern matches if all
of the fields match the fields of the value. In other words, it walks through
*its* fields while walking through the tuple fields of the value in parallel.
It's this symmetry which makes patterns so intuitive to use.

A tuple pattern by itself doesn't bind any variables, but it does recursively
give the patterns of its fields the chance to do so.

### Record Pattern

The twin brother to tuple patterns, a record pattern does the same thing, but
for a named record (or any other type with named members). Here's one:

{% highlight magpie %}
x: 1, y: 2
{% endhighlight %}

That pattern will match any object with an `x` field whose value is `1`, and a
`y` field whose value is `2`.

### Variable Pattern

Finally, the most important pattern, and the one where Magpie makes the
greatest departure from ML. A variable pattern has a *name* and an optional
*type annotation*. The name can be `_` if you don't really care about it.
Here's some:

{% highlight magpie %}
_              // no name or type
a              // name but no type
position Point // name and type
_ Int | String // no name but type
{% endhighlight %}

A variable pattern matches if the *type* of the value matches the variable
pattern's type. If the pattern doesn't have a type, it always succeeds.

Variable patterns also do the magic of creating new variables. When a variable
pattern matches, it will create a new variable with its name whose value is
the matched value. When you combine that with tuple and record patterns, you
get destructuring automagically. If we take this value:

{% highlight magpie %}
name: "Dan", pals: ("Sam", "Ed")
{% endhighlight %}

And match it against this pattern:

{% highlight magpie %}
name: n, pals: (a, b)
{% endhighlight %}

The match will succeed, and `n` will be `"Dan"`, `a` will be `"Sam"`, and `b`
will be `"Ed"`.

## Now What?

Now we've got these pattern things, where can we use them? It turns out, lots
of places. We'll start with the most obvious one: `match` expressions&mdash;
Magpie's souped-up version of `switch`. Our first example looks like this in
Magpie:

{% highlight magpie %}
match i
    case 1 then print("first")
    case 2 then print("second")
    case 3 then print("third")
    case _ then print("uh...")
end
{% endhighlight %}

The semantics are what you expect. It tests each pattern (the bit between
`case` and `then`) in turn. When a pattern matches, it binds any pattern
variables in a new scope, and executes the expression after `then` in it. A
richer example showing all of the awesome looks like:

{% highlight magpie %}
match name: "Dan", pals: ("Sam", "Ed")
    case name: "Dave" then
        "don't care about Dave's friends"
    case name: a, pals: nothing then
        "aww, " ~ a ~ " has no friends"
    case name: n, pals: (a, b) then
        n ~ " is pals with " ~ a ~ " and " ~ b
    end
end
{% endhighlight %}

Pretty handy, but we're just getting started.

### Catch

Since we can also match on type, that gives us all we need to use patterns for
selecting an appropriate catch clause when an error is thrown. The exception
example up there becomes:

{% highlight magpie %}
do
    // Do something crazy...
catch ex ParseException then print("Parse error!")
catch ex IOException    then print("IO error!")
catch _                 then print("Uh-oh!")
{% endhighlight %}

### Variables

Since patterns give us a way to bind variables, do we really need to have a
separate special case `var` expression that just creates a single named
variable? Nope. We can just make it take a single pattern. If the pattern is a
variable pattern with no type, it degenerates to a regular variable
declaration like:

{% highlight magpie %}
var i = "the queen of France"
{% endhighlight %}

But you can also use tuple and record patterns to destructure:

{% highlight magpie %}
var name: n, pals: (a, b) = name: "Dan", pals: ("Sam", "Ed")
print(n) // "Dan"
print(a) // "Sam"
print(b) // "Ed"
{% endhighlight %}

So now we've got destructuring for free. Swell!

### Functions

And there's one last trick up our sleeve. If you look at the exception example
there, it looks an awful lot like a function type declaration. That's not a
coincidence either. We can now just use a pattern to define a function's
parameter type, like so:

{% highlight magpie %}
def foo(name: n String, pals: (a String, b String))
    print(n) // "Dan"
    print(a) // "Sam"
    print(b) // "Ed"
end
{% endhighlight %}

The syntax of variable patterns was designed specifically around this. My goal
was to make the patterns used for function parameters look familiar to someone
new to the language while hiding greater flexibility under the surface. I
think most programmers can figure out what this means:

{% highlight magpie %}
def sayAge(name String, age Int)
    print(name ~ " is " ~ age ~ " years old")
end
{% endhighlight %}

without ever realizing the `name String, age Int` is something special.

Using patterns for function types also plays really nicely with Magpie's
[static typing](http://journal.stuffwithstuff.com/2010/08/31/type-checking-a-dynamic-language/). By adding support for evaluating the *type* of a pattern,
we can use that to type-check a pattern anywhere it appears. So, we can
statically tell that this is an error:

{% highlight magpie %}
match "not an int"
    case 1 then "match a string with an int?"
end
{% endhighlight %}

because the pattern type doesn't match the value. And using that exact same
code, we can also tell that this is an error:

{% highlight magpie %}
def expectInt(i Int) print(i)
expectInt("not an int")
{% endhighlight %}

The end result of all of this is that the total amount of code in the
interpreter has gone *down*, there are fewer distinct concepts to learn in the
language, and at the same time I've added new functionality that wasn't there
before. Or, in the words of the immortal John "Hannibal" Smith:

> I love it when a plan comes together.
