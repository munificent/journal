---
title: "Iteration Inside and Out, Part 2"
categories: code language magpie ruby dart lua go python
---

*You'll probably want to read [part one][] first unless you're feeling brave.*

[part one]: /2013/01/13/iteration-inside-and-out/

In our last episode, we learned that iteration involves two chunks of code: one
generating values, and one consuming them. During a loop, these two chunks take
turns in a cycle of generate, consume, generate, consume, like some sort of
weird incremental Ouroboros. This means that one chunk has to fully return and
unwind its stack frames before it can hand off to the next one.

We also learned that external and internal iterators each nail some problems and
totally fail at others. The discrepency boils down to which chunk of code has
more useful stuff to store on the callstack.

With external iterators, the code *consuming* values has control over the stack,
so it works well with problems where most complexity is in consuming values. For
example, short-circuiting or interleaving multiple iterators is trivial in an
external iterator.

Conversely, internal iterators put the code *generating* values in control. They
excel when generating values is complicated, like walking a tree and iterating
over the nodes.

Now we'll see some techniques to deal with each style's shortcomings. The basic
idea is [*reification*][reify]. If you've got some data on the callstack that
you want to hang onto, you need to find a place to store it.

[reify]: http://en.wikipedia.org/wiki/Reification_(computer_science)

## Iterators and generators

Say we want to define a method that concatenates two sequences. We don't want to
actually create a data structure that contains the elements of both, we just
want to return an iterator that walks the first sequence and then the second
one. Here's how you could do that in C#:

```csharp
IEnumerable Concat(IEnumerable a, IEnumerable b)
{
  return new ConcatEnumerable(a, b);
}

class ConcatEnumerable
{
  IEnumerable a;
  IEnumerable b;
  ConcatEnumerable(IEnumerable a, IEnumerable b)
  {
    this.a = a;
    this.b = b;
  }

  IEnumerable GetEnumerator()
  {
    return new ConcatEnumerator(
        a.GetEnumerator(), b.GetEnumerator());
  }
}

class ConcatEnumerator
{
  IEnumerator a;
  IEnumerator b;
  bool onFirst = true;
  ConcatEnumerator(IEnumerator a, IEnumerator b)
  {
    this.a = a;
    this.b = b;
  }

  bool MoveNext()
  {
    // Which sequence are we on?
    if (onFirst)
    {
      // Stay on first.
      if (a.MoveNext()) return true;

      // Move to the next sequence.
      onFirst = false;
      return b.MoveNext();
    }

    // On second.
    return b.MoveNext();
  }

  Object Current
  {
    get { return onFirst ? a.Current : b.Current; }
  }
}
```

Oof, that seems like a pile of code for such a simple goal. The problem is that
we've got all of this state to maintain: the two sequences being iterated, which
one we're in, and where we are in it. Since this is an *external* iterator, we
can't just store that as local variables on the stack because we have to return
from `MoveNext()` between each item.

But but but! C# has something called *iterators*. (A confusing name. What other
languages call "iterators", C# calls "enumerators". So "iterator" means
something special in C#-land.) The above code can also be written:

```csharp
IEnumerable Concat(IEnumerable a, IEnumerable b)
{
  foreach (var item in a) yield return item;
  foreach (var item in b) yield return item;
}
```

How's that for an improvement? (Note: if your employer pays you by the line,
you'll want to avoid this.) The magic here is `yield return`. When a method
contains it, the compiler turns the method into an *iterator*. You can think of
it sort of as a "resumable method". When you call `Concat()`, it runs to the
first `yield return`, then stops. Then when you resume it, it picks up where it
left after the `yield return`.

So here it iterates through the first sequence, stopping at each item and
returning it. Then it does the same thing with the second sequence. But what
does it mean to "resume" a method?

The return type here clarifies that. When you call `Concat()`, what you get back
is an `IEnumerable`. This is C#'s [iterable sequence type][ienumerable]. So what
you get back is a "collection". "Resuming the method" just means "get the next
value in the sequence".

[ienumerable]: http://msdn.microsoft.com/en-us/library/system.collections.ienumerable.aspx

So, given the above, we've got a nice solution to our original problem. We can
use it like so:

```csharp
foreach (var item in Concat(stuff, moreStuff))
{
  Console.WriteLine(item);
}
```

Using `yield return` lets us store all of the interesting state -- the two
sequences and our current location in them -- just as local variables right in
the `Concat()` method. C# will *reify* that stuff for us so that when the
`Concat()` method "returns", that data gets squirreled away somewhere safe.

You may wonder how C# does that reification. That's kind of the funny bit. In
the case of C#, the answer is that the compiler itself [automatically generates
a little hidden class][hidden] exactly like our ConcatEnumerator up there. The
actual runtime (the [CLR][]) doesn't have any support for `yield return`. It's
done purely by automatically generating code at compile time. It's a large,
delicious lump of [syntactic sugar][].

[hidden]: http://startbigthinksmall.wordpress.com/2008/06/09/behind-the-scenes-of-the-c-yield-keyword/
[CLR]: http://en.wikipedia.org/wiki/Common_Language_Runtime
[syntactic sugar]: http://en.wikipedia.org/wiki/Syntactic_sugar

In the last post, I crafted some glorious ASCII art showing where all of the
state is being stored. The main problem was that the state for the code
generating values and the state for the code consuming them both live on the
stack. Using an iterator, though, gives you this:

```asciiart
  stack                       heap
┌─────────────────────┐
│ iterator.MoveNext() │
├─────────────────────┤     ┌───────────────────┐
│ loop body           │ ──> │ DesugaredIterator │
└─────────────────────┘     └───────────────────┘
  ...

  main()
```

So the stack has the state for the code consuming values. But the state needed
to generate values lives on the *heap*. There's an instance of this little class
that the compiler created for us. When `MoveNext()` returns, we don't trash the
state because it's still over there in the heap available the next time we call
`MoveNext()`.

There are a few other languages that do (or will) work this way. Python calls
these "[generators][py]" and uses a similar `yield` statement. The next version
of JavaScript will have [something similar][js]. The language that invented
generators and the `yield` keyword was Barbara Liskov's [CLU][], immortalized
forever in [Tron][]. (I'm not making that up.)

[py]: http://www.python.org/dev/peps/pep-0255/
[js]: http://wiki.ecmascript.org/doku.php?id=harmony:generators
[CLU]: http://en.wikipedia.org/wiki/CLU_(programming_language)
[TRON]: http://en.wikipedia.org/wiki/List_of_Tron_characters#CLU

### Deep yields

There's a limitation here, though. You can only yield from the method itself.
Let's say (for whatever reason) we wanted to organize our C# code like:

```csharp
IEnumerable Concat(IEnumerable a, IEnumerable b)
{
  WalkFirst(a);
  WalkSecond(b);
}

IEnumerable WalkFirst(IEnumerable a)
{
  foreach (var item in a) yield return item;
}

IEnumerable WalkSecond(IEnumerable a)
{
  foreach (var item in a) yield return item;
}
```

What we *want* to have happen is that the `yield return` in `WalkFirst()` and
`WalkSecond()` causes `Concat()` itself to yield and return, but it doesn't work
that way. Iterators/generators reify a stack frame for you, but they only reify
*one*. If you want to have your iteration logic call other methods which also
yield, you have to manually reify every level yourself by walking the sequence
at each level. Something like:

```csharp
IEnumerable Concat(IEnumerable a, IEnumerable b)
{
  foreach (var item in WalkFirst(a)) yield return item;
  foreach (var item in WalkSecond(a)) yield return item;
}

IEnumerable WalkFirst(IEnumerable a)
{
  foreach (var item in a) yield return item;
}

IEnumerable WalkSecond(IEnumerable a)
{
  foreach (var item in a) yield return item;
}
```

You see how we're doing `foreach` and `yield return` both in the `Walk___()`
methods *and* in `Concat()` itself? We're explicitly making *every* level of the
callstack an iterator. That makes sure every call frame gets reified like we
need. Can we do better?

## Python 3.3: delegating generators

The above example can be translated to Python like so:

```python
def concat(a, b):
  for item in walkFirst(a): yield item
  for item in walkSecond(a): yield item

def walkFirst(a):
  for item in a: yield item

def walkSecond(a):
  for item in b: yield item
```

Aside from being more terse, this is a one-to-one mapping with the C# code. But
Python 3.3 adds [something new][380] for us here. Let's use it:

[380]: http://www.python.org/dev/peps/pep-0380/

```python
def concat(a, b):
  yield from walkFirst(a)
  yield from walkSecond(a)

def walkFirst(a):
  for item in a: yield item

def walkSecond(a):
  for item in b: yield item
```

The explicit loops in `concat()` have been replaced with a new `yield from`
statement. Nice. This makes composing generators a little cleaner. But there's
no real magic here. We still have to have `yield` at every level of our
iteration code.

In most cases, this is just a bit tedious but not a showstopper. But if you have
higher-order functions this can actually prevent code reuse. If you have some
higher-order function that takes a callback, it doesn't know if that callback
wants to yield or not, so the higher-order function doesn't know if *it* needs
to yield. You may end up having to implement that function twice, once for each
style.

So `yield from` is only a tiny improvement. Can we do better?

## Ruby: enumerables, enumerators, and fibers

If you ever find yourself in a game of "which language has a better feature than
X", Ruby is usually a safe play. Matz has culled an impressive array of features
from Smalltalk and Lisp. (And let's not forget Perl, the ugly duckling paddling
around Ruby's Pond of Inspiration.)

In Ruby, iteration is usually internal. The idiomatic way to go through a
collection is by passing a [block][block] -- more or less a callback, if you're
not familiar with Ruby/Smalltalk parlance -- to the `each` method on a
collection. But it also supports external iterators and a `for` expression.
Impressively, Ruby can convert the former to the latter. (Going the other way is
trivial in any language.)

[block]: http://eli.thegreenplace.net/2006/04/18/understanding-ruby-blocks-procs-and-methods/

Let's dig up an example from the previous post. Here's some Ruby code for
defining a tree and iterating over the nodes of the tree in order:

```ruby
class Tree
  attr_accessor :left, :label, :right

  def initialize(left, label, right)
    @left = left
    @label = label
    @right = right
  end

  def each(&code)
    @left.each &code if @left
    code.call(self)
    @right.each &code if @right
  end
end
```

We can use it like:

```ruby
tree.each { |node| puts node.label }
```

This is using internal iteration. We pass in that `{ |node| ... }` block and the
Tree class itself recursively walks the nodes and invokes the callback on each
node.

Say we want this to be an external iterator instead. Maybe we want to walk two
trees in parallel to see if they have the same labels. We can do this something
like:

```ruby
class Tree
  # Mixin all of the enumerable methods to our class.
  include Enumerable
end

a = # Some tree...
b = # Another tree...

if a.zip(b).each.all? { |pair| pair[0] == pair[1] }
  puts "Equal!"
end
```

The `zip()` method takes an enumerable on the left and another on the right and
"zips" them together one pair at a time. The result is an array of pairs of
elements. If you zip `[1, 2, 3]` and `[7, 8, 9]` together, you get `[[1, 7], [2,
8], [3, 9]]`. Neat.

Then `all?` walks an array, testing each element using the given block. If the
block returns `true` for every element, `all?` returns `true` too. Swell.

But there's a subtle problem here. The `zip()` method converts its arguments to
*arrays* before doing anything. So we've got our nice `each` method on Tree that
generates values incrementally without wasting memory, but then we throw the
iterator at `zip()` which goes ahead and allocates big arrays to store all of
these intermediate values. If the two trees we're comparing are huge, that's a
lot of wasted memory.

What we'd like is a way to walk those two trees *iteratively* without creating
any intermediate arrays. The `each()` method on Tree does that, but it's an
internal iterator. External iterators are perfect for this task. Can we convert
it? In Ruby, that's as easy as:

```ruby
a = # Some tree...
b = # Another tree...

a_enum = a.to_enum
b_enum = b.to_enum
```

That little `to_enum` method takes an object that implements `each` and returns
an external iterator. We can use these iterators like so:

```ruby
loop do
  if a_enum.next != b_enum.next
    puts "Not equal!"
  end
end
```

The protocol here is that `next` returns the next item in the sequence. If there
are no more items, it raises a StopIteration error which `loop` conveniently
catches and handles.

Double-plus good! We've got nice support for both internal and external
iterators, and we can easily convert back and forth between them. It's like
having cake *and* pie for dessert. The one remaining question is *how does this
work*? Look at what we have here:

1.  The internal iterator (the `each()` method on Tree) recursively calls itself
    and builds a deep callstack. At any point during that, it may emit values.

2.  The `to_enum` method takes that and returns an enumerable object. When you
    call `next`, it runs that recursive code then somehow suspends it whenever a
    value is generated.

3.  The next time you call `next` execution picks up exactly where it left off.
    Somehow that entire callstack gets frozen and then thawed between each call
    to `next`.

There must be some kind of data structure that represents an entire callstack.
It doesn't reify a stack *frame* like generators, it reifies the whole *stack.*

## A fiber by any other name

This mystery data structure is what Ruby calls a *fiber*. Its sort of like a
thread in that it represents an in-progress computation. It has a callstack,
local variables, etc. Unlike a "real" thread, though, it doesn't involve the OS,
kernel scheduling and all of that other heavyweight stuff.

It's also *cooperatively* scheduled instead of *preemptively*. That's a fancy
way of saying fibers have to play nice with other. If you want a fiber to run,
you have to give it control. It can't take control from you.

These constructs have been given as many names as languages that support them.
Lua calls them "[coroutines][lua]" (which is, I think, the [oldest
name][coroutine] for the idea). [Stackless Python][] calls them "tasklets". Go's
"[goroutines][]" are similar, though with some interesting differences.

[lua]: http://www.lua.org/pil/9.html
[coroutine]: http://en.wikipedia.org/wiki/Coroutine
[stackless python]: http://www.stackless.com/
[goroutines]: http://golang.org/doc/effective_go.html#goroutines

Fibers are the special sauce we need for `to_enum`. When you call `to_enum`,
Ruby spins up a new fiber. Then the interpreter runs the internal iterator on
that *new* fiber. When you call `next` on the enumerator, Ruby runs that fiber
until it generates a value. When a value is yielded, Ruby suspends the fiber,
returns the value, and runs the main fiber. When we need the next value, Ruby
just suspends the main fiber and resumes the spawned one again.

In other words, a simplified implementation of `to_enum` looks a bit like:

```ruby
class Object
  def to_enum
    MyEnumerator.new self
  end
end
```

And the MyEnumerator class (which is simplified from [this excellent
StackOverflow answer][so]) is:

[so]: http://stackoverflow.com/a/1437678/9457

```ruby
class MyEnumerator
  include Enumerable

  def initialize(obj)
    @fiber = Fiber.new do  # Spin up a new fiber.
      obj.each do |value|  # Run the internal iterator on it.
        Fiber.yield(value) # When it yields a value, suspend
                           # the fiber and emit the value.
      end
      raise StopIteration  # Then signal that we're done.
    end
  end

  def next
    @fiber.resume          # When the next value is requested,
                           # resume the fiber.
  end
end
```

## Iteration or concurrency?

I started this two-parter with a question about how you can make iteration
beautiful and easy to work with. This leads us to wanting both internal and
external iteration, and the ability to go from one to the other. The piece
needed to really make that work is *an easy way to create a new callstack*. And
fibers are a great answer for that.

But what I find interesting is where we arrived at. We started talking about
*iteration*, one of the most shallow of flow control structures. But look where
we ended up. Fibers are a *concurrency* mechanism. Concurrency is way over in
the deep end of language features.

I don't think this is a coincidence. If you look at iteration, it actually is
about concurrency. You've got two "threads" of behavior: one that's generating
values and one that's consuming them. You need to run these two threads together
and coordinate them. That *is* concurrency. We're just so used to it, that we
don't think of it that way.

## Wait, what about Magpie?

I screwed myself over here. The secret agenda of this pair of posts was to trick
you into reading about *my* language by promising to teach you something about
other languages you may actually use in real life.

If we're both lucky you did learn something, but I haven't gotten to my language
yet. Alas, I'm already 5,000 words in and I've surely exhausted your patience. I
guess Magpie will have to wait for a later post. Trust me, though. It's
*awesome*. Promise.
