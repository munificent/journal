---
title: "Iteration Inside and Out"
categories: code language magpie ruby dart
---

You would think iteration, you know *looping over stuff*, would be a solved
problem in programming languages. Seriously, here's some *FORTRAN* code that
does a loop and would run on a computer fifty years ago:

```fortran
do i=1,10
  print i
end do
```

So when I started designing loops in my little language [Magpie][], I figured it
would be pretty straightforward:

[magpie]: http://magpie-lang.org/

1. Look at a bunch of other languages.

2. See what the awesome-est one does.

3. Do that.

Now, of course, the first wrinkle is that this isn't just about looping a
certain number of times, or through just a range of numbers. That's baby stuff.
Hell, *C* can do that.

This is about *iteration*: being able to generate and consume arbitrary
sequences of stuff. It's not just "every item in a list," it's "the leaves of a
tree," or "the lines in a file" or "the prime numbers". So there's an implied
level of abstraction here: you need to be able to define what "iteration" means
for your own uses.

What I found when I looked around at other languages surprised me. It turns out
there's two completely separate unrelated styles for doing iteration out in the
wild. [Gafter and the Gang of Four][] (also an excellent band name) call these
"internal" and "external" iterators, which sounds pretty fancy. Each of these
styles is just beautifully elegant for some use cases, and kitten-punchingly
awful for others. They're like Yin and Yang, or maybe Kid and Play.

[Gafter and the Gang of Four]: http://gafter.blogspot.com/2007/07/internal-versus-external-iterators.html

## External iterators: OOPs, I did it again

The first side of the coin is *external* iterators. If you code in C++, Java,
C#, Python, PHP, or pretty much any [single-dispatch][] object-oriented
language, this is you. Your language gives you some `for` or `foreach`
statement, like this:

[single-dispatch]: http://en.wikipedia.org/wiki/Dynamic_dispatch#Single_and_multiple_dispatch

```dart
var elements = [1, 2, 3, 4, 5];
for (var i in elements) print(i);
```

(This is [Dart][] if you were wondering.)

[Dart]: http://www.dart.dev/

What the compiler sees is a little different. If you squint through the Matrix,
then a loop like the above is really:

```dart
var elements = [1, 2, 3, 4, 5];
var __iterator = elements.iterator();
while (__iterator.moveNext()) {
  var i = __iterator.current;
  print(i);
}
```

The `.iterator()`, `.moveNext()`, and `.current` calls are the *iteration
protocol*. If you want to define your own iterable thing, you create a type that
supports that protocol. Since a `for` statement compiles down (or "[desugars][]"
if you're hip to PL nerd lingo) to invoking methods on that protocol,
implementing those methods lets your type work seamlessly inside a loop.

[desugars]: http://en.wikipedia.org/wiki/Syntactic_sugar

In statically typed languages, this "protocol" is actually an explicit interface:

* Java: [`Iterable<T>`][java]

* C#: [`IEnumerable<T>`][csharp]

* Dart: [`Iterable<T>`][dart iterable]

[java]: http://docs.oracle.com/javase/1.5.0/docs/api/java/lang/Iterable.html
[csharp]: http://msdn.microsoft.com/en-us/library/system.collections.ienumerable.aspx
[dart iterable]: https://api.dart.dev/stable/2.14.4/dart-core/Iterable-class.html

In dynamically typed languages, it's more informal, like Python's [iterator
protocol][py].

[py]: http://docs.python.org/2/library/stdtypes.html#iterator-types

### Beautiful example 1: finding an item

Here's a simple example where external iterators work well. Let's write a
function that returns `true` if a sequence contains a given item and `false` if
it doesn't. I'll use Dart again because I think Dart actually works pretty well
as an *Ur*-language that most programmers can grok:

```dart
bool find(Iterable haystack, Object needle) {
  for (var item in haystack) {
    if (item == needle) return true;
  }

  return false;
}
```

Dead simple. One key property this function has is that it *short-circuits*: it
stops iterating as soon as it finds the item. This is not just an optimization,
but critical when you consider that some sequences (like reading the lines in a
file) may have side effects. The sequence may even be infinite.

### Beautiful example 2: interleaving two sequences

Let's do something a bit more complex. Let's write a function that takes two
sequences and returns a sequence that alternates between items in each sequence.
So if you throw `[1, 2, 3]` and `[7, 8, 9]` at it, you get back `[1, 7, 2, 8, 3,
9]`.

```dart
Iterable interleave(Iterable a, Iterable b) {
  return InterleaveIterable(a, b);
}
```

The function just delegates to an object, because you need some type to hang the
iterator protocol off of. Here's that type:

```dart
class InterleaveIterable {
  Iterable a;
  Iterable b;
  InterleaveIterable(this.a, this.b);

  Iterator get iterator() {
    return InterleaveIterator(a.iterator(), b.iterator());
  }
}
```

OK, again just another bit of delegation. This is because most iterator
protocols separate the "thing that can be iterated" from the object representing
the *current* iteration state. The former is not modified by being iterated
over, but the latter is. Finally we get to the real code:

```dart
class InterleaveIterator {
  Iterator a;
  Iterator b;
  InterleaveIterator(this.a, this.b);

  bool moveNext() {
    // Stop if we're done.
    if (!a.moveNext()) return false;

    // Swap iterators so we pull from the other one next time.
    var temp = a;
    a = b;
    b = temp;
    return true;
  }

  get current => a.current;
}
```

This is a bit verbose, but it's pretty straightforward. Each time you call
`moveNext()`, it reads from one of the iterators and then swaps them. It stops
as soon as either one is done. Pretty groovy.

### Kitten-punch example: walking a tree

Now let's see the ugly side of this. Let's say we've got a simple binary tree
class, like:

```dart
class Tree {
  Tree left;
  String label;
  Tree right;
}
```

Now say we want to print the tree's labels in order, meaning we print everything
on the left branch first (recursively), then print the label, then the right.
The implementation is as simple as the description:

```dart
void printTree(Tree tree) {
  if (tree.left != null) printTree(tree.left);
  print(tree.label);
  if (tree.right != null) printTree(tree.right);
}
```

Later, we realize we need to do other stuff on trees in order. Maybe we need to
convert it to JSON, or just count the number of nodes or something. What'd we'd
really like is to be able to *iterate* over the nodes in order and then do
whatever we want with each item. So the above function becomes:

```dart
void printTree(Tree tree) {
  for (var node in tree) {
    print(node.label);
  }
}
```

For this to work, `Tree` has to implement the iterator protocol. What does that
look like? It's best just to swallow the whole bitter pill at once:

```dart
class Tree implements Iterable<Tree> {
  Tree left;
  String label;
  Tree right;
  Tree(this.left, this.label, this.right);
  Iterator get iterator => new TreeIterator(this);
}

class IterateState {
  Tree tree;
  int step = 0;
  IterateState(this.tree);
}

class TreeIterator implements Iterator<Tree> {
  var stack = <IterateState>[];
  TreeIterator(Tree tree) {
    stack.add(IterateState(tree));
  }

  bool moveNext() {
    var hasValue = false;
    while (stack.length > 0 && !hasValue) {
      var state = stack.last;
      switch (state.step) {
      case 0:
        state.step = 1;
        if (state.tree.left != null) {
          stack.add(IterateState(state.tree.left));
        }
        break;

      case 1:
        state.step = 2;
        current = state.tree;
        hasValue = true;
        break;

      case 2:
        stack.removeLast();
        if (state.tree.right != null) {
          stack.add(IterateState(state.tree.right));
        }
        break;
      }
    }

    return hasValue;
  }

  Tree current;
}
```

Sweet Mother of Turing, what the hell happened here? This exact same behavior
was a *three line* recursive function and now it's a fifty line monstrosity.

I'll get back to exactly what went wrong here but for now let's just agree that
this is not a beautiful fun way to abstract over an in-order traversal. For now,
let's cleanse our palate.

## Interal iterators: don't call me, I'll call you

Right now, the Rubyists are grinning, the Smalltalkers are furiously waving
their hands in the air to get the teacher's attention and the Lispers are just
nodding smugly in the back row (all as usual). Here's what they know that you
may not: Those languages (Smalltalk, Ruby by way of Smalltalk, and most Lisps)
use *internal* iterators. When you're iterating, you have two chunks of code in
play:

1. The code responsible for generating the series of values.

2. The code that takes each value and does something with it.

With external iterators, (1) is the type implementing the iterator protocol and
(2) is the body of the `for` loop. In that style, (2) is in charge. It decides
when to invoke (1) to get the next value and can stop at any time by breaking
out of the loop.

Internal iterators reverse that power dynamic. With an internal iterator, the
code that generates values decides when to invoke the code that uses that value.
For example, here's how you print the Beatles in Ruby:

```ruby
beatles = ['George', 'John', 'Paul', 'Ringo']
beatles.each { |beatle| puts beatle }
```

That `each` method on `Array` is the iterator. Its job is to walk over each item
in the array. The `{ |beatle| puts beatle }` part is the code we want to run for
each item. The curlies define a *block* in Ruby: a first-class chunk of code you
can pass around.

This Ruby snippet bundles up that `puts` expression into an object and sends it
to `each`. The `each` method can then iterate through each item in the array and
call that block of code for each item, passing in the value.

### Beautiful example 1: walking a tree

Let's see what our ugly external iterator example looks like in Ruby. First, we
define the tree:

```ruby
class Tree
  attr_accessor :left, :label, :right

  def initialize(left, label, right)
    @left = left
    @label = label
    @right = right
  end
end
```

To walk the tree using an internal iterator style, we want this to magically
work:

```ruby
tree.in_order { |node| puts node.label }
```

Implementing that iterator in Dart (or Java, or C#) was about 50 lines of code.
Here it is in Ruby:

```ruby
class Tree
  def in_order(&code)
    @left.in_order &code if @left
    code.call(self)
    @right.in_order &code if @right
  end
end
```

Yup, that's it. It looks pretty much like the original recursive function,
because it *is* just like that function. The only difference is where that Dart
function was hard-coded to just call `print()`, this one takes a *block* --
basically a callback to invoke with each value. In fact, we can implement the
same thing in any language with anonymous functions. Here's Dart:

```dart
void inOrder(Tree tree, void Function(Tree tree) callback) {
  if (tree.left != null) inOrder(tree.left);
  callback(tree);
  if (tree.right != null) inOrder(tree.right);
}
```

You couldn't do this in Java (...[yet][lambda]), but in most object-oriented
languages you can passably support internal iterators. It's just not idiomatic
to do so.

[lambda]: http://openjdk.java.net/projects/lambda/

Internal iteration is definitely beating external style in this tree example.
Let's see how it fares on the others.

### Beatiful example 2: finding an item

OK, let's say we're using Ruby and we want to write a method that, given any
iterable object, sees if it contains some object. By "any iterable object", we
mean "has an `each`" method, which is the canonical way to iterate. Something
like:

```ruby
def contains(haystack, needle)
  haystack.each { |item| return true if item == needle }
  false
end
```

Not bad! So we're two-for-two on internal style. Let's transmogrify this into
Dart:

```dart
bool contains(Iterable haystack, needle) {
  haystack.forEach((item) {
    if (item == needle) return true;
  });
  return false;
}
```

Still pretty terse! Except there's one problem: *it doesn't actually work.*

What's the difference? In both examples, there's a little chunk of code: `return
true`. The intent of that code is to cause the `contains()` method to return
`true`. But in the Dart example, that `return` statement is contained inside a
lambda, a little anonymous function:

```dart
(item) {
  if (item == needle) return true;
}
```

So all it does is cause that *function* to return. So the callback ends and
returns back to `forEach()` which then proceeds along its merry way onto the
next item. In Ruby, that `return` doesn't return from the *block* that contains
it, it returns from the *method* that contains it. A `return` will walk out of
any enclosing blocks, returning from *all* of them until it hits an
honest-to-God method and then make *that* return.

This feature is called "[non-local returns][nonlocal]". Smalltalk has them, as
does Ruby. If you want internal iterators, and you want them to be able to
terminate early like we do here, you really need non-local returns.

[nonlocal]: http://yehudakatz.com/2010/02/07/the-building-blocks-of-ruby/

This is a big part of the reason why internal iterators aren't idiomatic in
other languages. It's really limiting if your `each` or `forEach()` function
can't short-circuit easily.

### Kitten-punching example: interleaving two sequences

The other example that worked well with external iterators was interleaving two
sequences together. It was a bit verbose, but it worked just fine and could be
used with any pair of sequences. Let's translate that to an internal style. This
post is plenty long, so I'll leave it as an exercise. Go do it real quick and
come back.

...

Back so soon? How'd it go? How much time did you waste?

Right. As far as I can tell, you simply *can't* solve this problem using
internal iterators unless you're willing to reach for some heavy weaponry like
threads or continuations. You're up a creek *sans* paddle.

This is, I think, a big reason why most mainstream languages do external
iterators. Sure, the tree example was verbose, but at least it was *possible*.
(It's also probably why languages that do internal iterators also have
continuations.)

## What's the problem?

It appears we're at a stalemate. External iterators rock for some things,
internal at others. Why is there no solution that's great at all of them? The
issue boils down to one thing: *the callstack*.

You probably don't think about it like this, but *the callstack is a data
structure*. Each stack frame -- every function that you're currently in -- is
like an object. The local variables are the fields in that object. You get
another bit of extra data for free too: the current execution pointer. The
callstack keeps track of where you are in your function. For example:

```dart
lameExample() {
  print("I'm at the top");
  doSomething();
  print("I'm in the middle");
  doSomething();
  print("Dead last like a chump");
}
```

We kind of take this for granted, but each time `doSomething()` returns to this
`lameExample()`, execution picks up right where it left off. That's handy.
Remember our recursive tree traversal:

```dart
printTree(Tree tree) {
  if (tree.left != null) printTree(tree.left);
  print(tree.label);
  if (tree.right != null) printTree(tree.right);
}
```

After calling `printTree()` on the left branch, the program resumed where it
left off, printed the label, and went to the next branch. Once you throw in
recursion, you also get the ability to represent a *stack* of these implicit
data structures. The callstack itself (hence the name) will track which parent
branches we're in the middle of traversing.

When we converted that function to an external iterator, that fifty lines of
boilerplate was just a [reification][] of the data structures the callstack gave
us for free. The `IterateState` class is exactly what each call frame stored.
The `tree` field in it was the `tree` *parameter* in the `printTree` function.
The `step` field was the execution pointer. The `stack` in `TreeIterator` was
the callstack.

[reification]: http://en.wikipedia.org/wiki/Reification_(computer_science)

The lesson here is that *stack frames are an amazingly terse way of storing
state*. You don't realize how much it's doing for you until you have to write it
all out by hand. If anyone ever asks me what my favorite data structure is, my
answer is always *the callstack*.

## Who owns the callstack?

This is the key we need to see why each iteration style sucks for some things.
It's a question of who gets to control the callstack. Earlier, I said that there
are two chunks of code involved in iteration: the code generating the values,
and the code doing stuff with them. In an external iterator, your callstack
looks like this:

```asciiart
┌────────────┐
│ moveNext() │
├────────────┤
│ loop body  │
└────────────┘
  ...

  main()
```

The method containing the loop calls `moveNext()`, which pushes it on top of the
stack. The `moveNext()` method can in turn call whatever it wants, so it
*temporarily* has free reign on the callstack. But it has to return, unwind, and
discard all of that state to return to the loop body before generating the next
value.

That's why the tree example was so verbose. Since all of that state would be
discarded if it was stored in callframes, TreeIterator had to reify it -- stick
it in that `stack` of IterateState objects. That way the state is still around
the next time `moveNext()` is called.

With an internal iterator, the stack is like this:

```asciiart
┌────────────────────────┐
│ each()                 │
├────────────────────────┤
│ method containing loop │
└────────────────────────┘
  ...

  main()
```

Now the iterator is on top. It can build up whatever stack frames it wants, and then, whenever its convenient, invoke the block:

```asciiart
┌────────────────────────┐
│ block                  │
└────────────────────────┘
  stuff...
┌────────────────────────┐
│ each()                 │
├────────────────────────┤
│ method containing loop │
└────────────────────────┘
  ...

  main()
```

The *block* now has to return to `each()` (or whatever `each()` calls). So the
iterator can keep whatever state on the callstack it wants, since it's in
control. But, as you can see, you really need non-local returns for this to work
well. Because, when the block *does* want to stop iteration, it needs a way to
unwind all the way through `each()` -- and everything `each()` calls -- all the
way back to the method.

That's the issue. Whoever gets put on top of the stack is in the weaker
position, because it must return all the way to the other one between each
generated value. In some use cases, the generator of values needs that power
(recursively walking a tree), and internal iterators work great. In others, the
consumer of values needs that power (interleaving two iterators) and external
ones win.

Since there's just one callstack, that's the best we can do. *...Or is it?*

*Check out [part two][] to see what some languages have done to try to deal with this.*

[part two]: /2013/02/24/iteration-inside-and-out-part-2/
