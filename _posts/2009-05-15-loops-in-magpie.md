---
layout: post
title: "Loops in Magpie"
categories: c-sharp code language magpie
---
I'm working on the loop syntax in Magpie right now, and I think I more or less
have the plan figured out. Looping is a bit tricky in a language: there's a
ton of different ways to do it from C's basic `for (i = 0; i < 100; i++)` to
Lisp's super-powerful (and super-complex) `loop` macro.

My goals for loops are the same as my goals for the language in general:

  * Add as few new keywords as possible.

  * Use function calls for as much of it as possible.

  * There must be no visible line between "baked-in" loop functions and user-defined ones.

  * The most common use cases should be the most terse.

The last point is especially pertinent, and is one of the guiding philosophies
of the language: the things users do the most should be the most terse. Sort
of like [Huffman encoding](http://en.wikipedia.org/wiki/Huffman_encoding) for a language.

To do that, I did a little archaeology: I looked at every place in the Magpie
C# compiler where I'm using `for` or `foreach`. The results are:

  * There are 14 `for` loops and 40 `foreach` ones.

  * 9 of the `for` loops are to iterate through two arrays in parallel.

  * 3 of the `for` loops are to iterate backwards.

  * 2 of the `for` loops are to assign to array elements.

  * 1 of the `for` loops is to iterate a certain number of times.

  * None of the `for` or `foreach` loops reuse an existing variable for the current item.

From this, it's pretty clear that I need to focus on iterating through
collections (i.e. [enumerators](http://msdn.microsoft.com/en-us/library/system.collections.ienumerable.aspx) or [generators](http://www.python.org/dev/peps/pep-0255/)), and assume that the
user wants a new variable for the current item. Also, iterating through
multiple collections simultaneously should be fairly easy to do. This leads me
to adding just one new keyword:

```magpie
for <var> <- <generator> do
    ...
end
```

In addition, multiple `for` clauses can be provided (but only one `do`) to
iterate through multiple collections in parallel. I still need to work out the
details, but I'm thinking that that will be syntactic sugar for:

```magpie
// evaluate the generator expression once
def _generator <- Generate <generator>

// advance to the first item
_generator.MoveNext
while Not _generator.IsDone do
    def <var> <- _generator.Current
    ...
    _generator.MoveNext
end
```

Using that, the use cases I have can be solved by:

```magpie
// iterating through a collection
for item <- someList do
    Print item
end

// iterating multiple collections in lockstep
for a <- someList1
for b <- someList2 do
    Print (a == b).String
end

// iterating backwards
for item <- Reverse someList
    Print item
end

// assigning to array elements
for index <- array.Indexes
    array.index <- 0
end

// iterating a fixed number of times
for i <- 50.Times
    Print i.String
end

// iterating through a range
for i <- Range (10, 30)
    Print i.String
end
```

In those examples, `Reverse`, `Indexes`, `Times`, and `Range` can all be
simple library functions. There's nothing magical about them. This may change
when the rubber meets the road as I implement it, but it feels about right so
far.
