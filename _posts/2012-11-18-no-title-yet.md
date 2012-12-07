---
title: "NO TITLE YET"
##categories: code, language, magpie
---

If you're designing an imperative programming language, one think you end up thinking about is loops. If your only background is C/Java/JS, this seems like a no-brainer. You'll probably start with a vanilla C-style for loop:

    for (var i = 0; i < 10; i++) {
      printf("%d\n", i);
    }

Since you're modern, you'll probably want something for iterating over collections too:

    for (var i in [1, 2, 3, 4]) {
      print(i);
    }

(This is Dart, in case you're curious.)

If you want to make things as flexible as possible, you'll have the latter work based on some sort of *iterator* abstraction. That way people can define their own [iterable](http://docs.oracle.com/javase/6/docs/api/java/lang/Iterable.html)/[enumerable](http://msdn.microsoft.com/en-us/library/system.collections.ienumerable.aspx) types that they can then use directly in loops.

This is how Java, C#, and Python roll, though each has a slightly different way of implementing it. For example, in Java, if you have a type that you want to use in a `for` loop, you implement this interface:

    interface Iterable<T> {
      Iterator<T> iterator();
    }

And then you implement the `Iterator<T>` type:

    interface Iterator<T> {
       boolean hasNext();
       T next();
    }

(I'm ignoring `remove()` here because it isn't really relevant to this post.) When you write a loop like this in Java:

    for (String name : names) {
      System.out.println(name);
    }

What the compiler actually sees is a lot more like:

    Iterator<String> __iter = names.iterator();
    while (__iter.hasNext()) {
      T name = __iter.next();
      System.out.println(name);
    }

## An Iterator Example

This is actually pretty neat. You've got a relatively simple interface and anyone can implement it and their data type feels naturally integrated into the flow control constructs of the language.

Let's try one. Let's make an interleaver. It will take two iterable objects, and return a new one that alternates values from them. So if you call it with `[1, 2, 3]`, and `[6, 7, 8]`, it would give you back an object that spits out `[1, 6, 2, 7, 3, 8]`.

We can do it with something like this:

    public class Interleave<T> implements Iterable<T> {
      public Interleave(Iterable<T> a, Iterable<T> b) {
        this.a = a;
        this.b = b;
      }

      @Override
      public Iterator<T> iterator() {
        return new InterleaveIterator<T>(a, b);
      }

      private final Iterable<T> a;
      private final Iterable<T> b;
    }

    public class InterleaveIterator<T> implements Iterator<T> {
      public InterleaveIterator(Iterable<T> a, Iterable<T> b) {
        first = a.iterator();
        second = b.iterator();
      }

      public boolean hasNext() {
        return first.hasNext();
      }

      public T next() {
        T value = first.next();

        // Swap them to read from the other one next.
        Iterator<T> temp = first;
        first = second;
        second = temp;

        return value;
      }

      private Iterator<T> first;
      private Iterator<T> second;
    }


This is a bit verbose, but it's pretty straightforward and works exactly like we want:

    List<Integer> a = Arrays.asList(1, 2, 3);
    List<Integer> b = Arrays.asList(6, 7, 8);

    for (int i : new Interleave<Integer>(a, b)) {
      System.out.println(i);
    }

Now that we use modern languages, we take this stuff for granted, but this is actually really cool. We've got this abstract interface (`Iterable`/`Iterator`) and we can use that to create types that define their own traversal semantics. We can also build on it to make things like "looping combinators" like the above example.

## A Poem as Lovely as a Tree

Speaking of data structures, let's play with one for a bit. I'll get back to the looping in short order, promise. Say we've got a binary tree type:

    public class Tree<T> {
      public Tree<T> left;
      public T value;
      public Tree<T> right;
    }

We want to print every value in it. We'll decide arbitrarily that we want to print in-order. So print the whole left branch, then the value, then the whole right branch.

One easy way is to just add a method that does just that:

    public class Trees {
      public static void print(Tree tree) {
        if (tree.left != null) print(tree.left);
        System.out.println(tree.value);
        if (tree.right != null) print(tree.right);
      }
    }

This is dead simple, but it's kind of gross. This little `print` method is mixing two operations together:

1. Doing an in-order traversal of the tree.
2. Printing an item.

We can easily imagine wanting to do an in-order traversal but not print the item. Maybe we want to serialize the tree, or count the values. Our method doesn't let us do that.

The obvious fix is to split that out, and `Iterable` is the perfect interface for that. If we make `Tree` iterable, then you can walk over the values yourself and do whatever you want to with them. Instead of baking printing directly into the traversal, you'd just do:

    void print(Tree tree) {
      for (String value : tree) {
        System.out.println(value);
      }
    }

Swell! So let's implement that. Of course, `Tree` is the easy part:

    public class Tree implements Iterable<String> {
      @Override
      public Iterator<String> iterator() {
        return new TreeIterator(this);
      }

      // Previous stuff...
    }

What is this mysterious `TreeIterator`?

    public class TreeIterator implements Iterator<String> {
      private enum Step {
        LEFT,
        VALUE,
        RIGHT
      }

      private class State {
        public State(Tree tree) {
          this.tree = tree;
          this.step = Step.LEFT;
        }
        public Tree tree;
        public Step step;
      }

      public TreeIterator(Tree tree) {
        stack = new Stack<State>();
        stack.push(new State(tree));
      }

      public boolean hasNext() {
        next = null;
        while (stack.size() > 0 && next == null) {
          State state = stack.peek();
          switch (state.step) {
          case LEFT:
            state.step = Step.VALUE;
            if (state.tree.left != null) {
              stack.push(new State(state.tree.left));
            }
            break;

          case VALUE:
            state.step = Step.RIGHT;
            next = state.tree.value;
            break;

          case RIGHT:
            stack.pop();
            if (state.tree.right != null) {
              stack.push(new State(state.tree.right));
            }
            break;
          }
        }

        return next != null;
      }

      public String next() {
        return next;
      }

      @Override
      public void remove() {
        throw new UnsupportedOperationException();
      }

      private Stack<State> stack;
      private String next;
    }

Sweet mother of God what is this abomination? Fifty lines of code? Out previous `print()` method on `Tree` was just *three* lines of code! What on Earth happened?

Well, the `print()` method had one big advantage: it could use the callstack as an ad-hoc data structure.

> The callstack is the most important data structure in every program.

When you walk a tree, you need to keep track of a bunch of stuff:

1. What tree node you're currently on.
3. What step you're in on the current tree: have you walked its left child yet. Have you handled its value?
2. All of the ancestors of that tree, back to the root one.

1. In the recursive implementation, the callstack handled all of that neatly. The `tree` parameter to `print()` stores the current tree you're printing.

2. The execution pointer itself keeps track of where we are. So it will run the first statement (traversing the left children), then the second one (printing the value), then the third (traversing the right childre).

3. Finally, when it returns, the parent callframes on the stack will store all of the ancestor nodes.

When we pulled that out into `Iterable`, we lost that convenience. Since the code *calling* our iterator is in control, we don't get to have fun with the callstack anyone.

Instead, we have to manually reify all of that data in the iterator. That's why it literally has a stack of `State` objects. The `tree` field in there is identical to the `tree` parameter to the `print()` method. And the `step` field there is just like the execution pointer.

Surely there has to be a better way then reimplementing a callstack by hand?

## Closures and Blocks

I see some hands raised in the back. Ruby programmer? Smalltalk? JavaScript? Yes, there is indeed a better way to handle this in other languages. (Hell, you can do it in Java too if you like anonymous inner classes.)

Let's do JavaScript. In JS, you could do something like this:

    function traverse(tree, callback) {
      if (tree.left != null) printTree(tree.left, callback);
      callback(tree.value);
      if (tree.right != null) printTree(tree.right, callback);
    }

So we have this `traverse` function that looks just like `print` in the Java example. The one difference is that instead of doing something with the value directly, it takes a *callback* that it will pass the value to. We can use that to print like this:

    traverse(tree, function(value) {
      console.log(value);
    });

Or if we want to count the number of values in the tree:

    var count = 0;
    traverse(tree, function(value) {
      count++;
    });



>

## TODO: Show method on tree to print it.

For whatever reason, we decide it would be super rad if `Tree<T>` implemented `Iterable<T>` so you could stick it in a loop. We want that to do an in-order traversal, so it will walk the left branch (recursively), then the value, then the right branch (also recursively). Pretty straight-forward.

Let's see what implementing that looks like. `Iterable<T>` is easy, of course:

  class Tree<T> implements Iterable<T> {
    Iterator<T> iterator() { return new TreeIterator<T>(this); }
    ...other stuff...
  }

Now let's see `TreeIterator<T>`:

  class TreeIterator<T> implements Iterator<T> {
    final Stack<Tree<T>> stack;

    public TreeIterator(Tree<T> tree) {
      stack = new Stack<Tree<T>>();
      stack.push(tree);
    }

    public boolean hasNext() {

    }

    public T next() {
      Tree<T> tree = stack.peek();
      while (tree.left != null) {
        stack.push(tree);
        tree = tree.left;
      }
    }
  }

- c-style for loops
  - three parts: initializer, advance, exit condition
  - actually gives you some abstraction: c++ stl iterator over vector
  - but syntactically verbose
    - see c++11 for syntax
    - leads to...
- java-style iterators
  - iterator interfaces
    - still same three operations: initialize, advance, exit condition
  - iterate over list
- example 1: trees
  - printing a tree
  - separating out walking and printing
  - implement iterator. ouch!
- internal iterators, callbacks
  - tree is easy now
- example 2: finding first matching item
  - hard with callbacks
  - try iterator: easy!
- non-local returns
  - returning first is easy now
- example 3: interleaving two sequences
  - holy crap hard with callbacks
  - easy with iterators
- conclusion
  - iteration means combining two things: the code to generate a sequence of
    values, and the code to act on them.
  - with external iterators, the code to act on values is in control. it pulls
    values when it wants, and can stop, start, etc.
  - with internal iterators, the code to *generate* values is in control. it
    can push values when it wants, and can call methods, or do arbitrary flow
    control in the middle of doing that.
  - if you do interesting flow control when acting on values (stop after first,
    interleave two sequences, etc.) then it's easiest if that code is in
    control.
  - if you do interesting flow control to generate values (recursion over nested
    data structures, io, etc.) then it's easiest if that code is in control.
  - issue is that you have *two* things that both want to do flow control. in
    other words, you want to have two callstacks going at the same time and
    switch between. in part 2, discuss solution...

http://gafter.blogspot.com/2007/07/internal-versus-external-iterators.html
