---
title: "Solving the Expression Problem"
categories: code java language magpie
---

I started working on Magpie out of frustration with a lot of the languages I
used. One of the key itches I wanted to scratch is something called the
[expression problem][]. The original formulation of it isn't very helpful to
someone not writing a compiler, so I'll recast it to something that's a little
more tangible and relevant to the kind of code you find yourself writing.

[expression problem]: http://lambda-the-ultimate.org/node/2232

The core problem is one of extension: *How do you make it easy to add both new
datatypes and new behaviors to an existing system?*

Let's say we're writing a document editor. We've got a few kinds of documents
that it can work with: Text, Drawings, and Spreadsheets. And we've got a few
operations we need to be able to do with a document: draw it to the screen, load
it, and save it to disc. They form a grid, like so:

```asciiart
            Text       Drawing   Spreadsheet
        ┌───────────┬───────────┬───────────┐
draw()  │           │           │           │
        ├───────────┼───────────┼───────────┤
load()  │           │           │           │
        ├───────────┼───────────┼───────────┤
save()  │           │           │           │
        └───────────┴───────────┴───────────┘
```

Each cell in that grid is a chunk of code we've got to write. We need to draw
text, load a drawing, save a spreadsheet, etc. All nine combinations are
functions that need to be implemented or we'll have problems if we're trying to
deal with documents generically.

There are a couple of questions to answer:

1.  How do we organize the code for this?

2.  How do we add new columns -- new types of documents?

3.  How do we add new rows -- new operations you can perform on any document?

4.  How do we ensure all of the cells are implemented?

The way you'll answer those is strongly influenced by your choice of language.
In many ways language paradigms differ exactly in how they answer just those
questions. For our purposes, we'll only care about three flavors:

## Statically typed object-oriented languages

These are the most popular languages on the block today, and include C++, Java,
and C#. They organize code into classes, and define operations as methods on
those classes. A Java implementation of the above table looks something like:

```java
public interface Document {
  void draw();
  void load();
  void save();
}

public class TextDocument implements Document {
  public void draw() { /* Draw text doc... */ }
  public void load() { /* Load text doc... */ }
  public void save() { /* Save text doc... */ }
}

public class DrawingDocument implements Document {
  public void draw() { /* Draw drawing... */ }
  public void load() { /* Load drawing... */ }
  public void save() { /* Save drawing... */ }
}

public class SpreadsheetDocument implements Document {
  public void draw() { /* Draw spreadsheet... */ }
  public void load() { /* Load spreadsheet... */ }
  public void save() { /* Save spreadsheet... */ }
}
```

An object-oriented language answers question 1 by saying that all operations for
a single type should be lumped together. Everything you can do with a
spreadsheet&mdash; drawing, loading, and saving&mdash; goes together in the same
class and typically the same file. The downside is that the operations are
smeared across the codebase. If you want to see how all file saving is handled,
you need to look at three files.

Question 2 is easy: you define a new class that implements the interface (or
inherits from a base class). Object-oriented languages are good at this. You can
do this even if the base class or interface is in some other library.

Question 3 is a bit tougher. Let's say we decide we want to add support for
printing. We'll have to add a `print()` method to our base `Document` interface
and then touch every file that implements it. Gross. If `Document` happens to be
defined in code we don't control, we're out of luck.

Even worse, it means we tend to put things in classes that don't really belong
together. Do we really want to mix the logic for rendering and interacting with
the file system in the same class? There are solutions and patterns to mitigate
this, but they're complex and awkward (I'm looking at you, [Visitor Pattern][]).

[visitor pattern]: http://en.wikipedia.org/wiki/Visitor_pattern

But at least question 4 is easy. The compiler tells us if we don't fully
implement an interface, so if we declare that a class implements `Document` then
we can be sure that all of the cells in the grid are covered.

## Statically typed functional languages

Let's see how the other half lives. Languages in the ML family like Haskell and
F# tend to divide things up differently. Where an object-oriented language
breaks the grid along column boundaries, a functional language breaks it into
rows.

This even explains the names of the paradigms: Object-oriented languages place
emphasis on *objects* (the columns). Functional languages place emphasis on the
*functions* (the rows).

A Caml implementation of our example looks like:

```ocaml
type document
  = Text
  | Drawing
  | Spreadsheet

fun draw (Text)        = (* Draw text doc... *)
  | draw (Drawing)     = (* Draw drawing doc... *)
  | draw (Spreadsheet) = (* Draw spreadsheet... *)

fun load (Text)        = (* Load text doc... *)
  | load (Drawing)     = (* Load drawing doc... *)
  | load (Spreadsheet) = (* Load spreadsheet... *)

fun save (Text)        = (* Save text doc... *)
  | save (Drawing)     = (* Save drawing doc... *)
  | save (Spreadsheet) = (* Save spreadsheet... *)
```

(At least, I hope that's right. Please let me know what I get wrong.)

The `document` interface has become an [algebraic datatype][] with cases for
the different concrete document types. Each operation is a single function
that uses pattern matching to select behavior appropriate for that type.

[algebraic datatype]: http://en.wikipedia.org/wiki/Algebraic_data_type

In other words, we switch up its answer to the first question. Functions are
lumped together, with a single `draw` function having the logic to draw all
different types of documents together. This keeps different kinds of behavior
nicely isolated from each other -- these functions could be put into different
files without any problem.

Question 3 is answered easily: just define a new function somewhere that handles
all of the different document types. Question 2 is where the pain is. If we add
a new document type, we have to add a new case to the datatype and touch every
function in the codebase to handle that case. If the core `document` datatype is
defined in code we don't control, we're hosed again.

Again, though, static typing helps us with question 4: the compiler will tell us
if one of these functions doesn't match a document type. So there's no net win
between the two, we've just changed how we slice the same cake. Let's look at a
third option:

## Dynamically typed languages

Way on the other side of town are dynamic languages like Python, Ruby and
Javascript (and their non-OOP progenitors like Scheme, but I'll focus on OOP
ones here because that's what I'm most familiar with). They're super flexible
and tons of fun to code in. How do they stack up?

The big win is that you can generally organize your code how you want and add
both new operations and new types with impunity. The normal case is to organize
things like a static OOP language where all of the operations for a type are
lumped together into one file.

However, the dynamism gives you more flexibility. If you want to add a new
operation to existing types, you have the freedom to do so outside of the file
where that type is defined. You can [add new methods][monkey] into existing
classes. This lets you, for example, pull the save/load logic from our document
classes out into separate *files* but then mix that back into the original
*classes* so they're still as easy to use. No visitor pattern in sight.

[monkey]: http://en.wikipedia.org/wiki/Monkey_patch

So that leaves one last question: How do we ensure all of the squares are
covered? And that's when the [sad trombone][] comes in. There is no compile-time
checking for this. The best you can do is write lots of tests and hope you're
covered.

[sad trombone]: http://www.sadtrombone.com/

Call me crazy, but I'm not happy with *any* of these solutions. I want the
simplicity of defining a class and putting its core operations all in one place.
At the same time, I want to be able to mix in new methods into classes outside
of the file where its defined. I want to group some code by row (operation) and
other code by column (type), each where it makes the most sense.

And once all that's done, I want the language to be smart enough to tell if I
forgot something or messed something up.

## Magpie = open classes + static checking

Here's how you accomplish this in Magpie. First, we define an interface that all
documents will implement:

```magpie
interface Document
  draw()
  load()
  save()
end
```

Then we create some classes that implement them:

```magpie
class TextDocument
  draw() // Draw text doc...
  load() // Load text doc...
  save() // Save text doc...
end

class DrawingDocument
  draw() // Draw drawing...
  load() // Load drawing...
  save() // Save drawing...
end

class SpreadsheetDocument
  draw() // Draw spreadsheet...
  load() // Load spreadsheet...
  save() // Save spreadsheet...
end
```

So far, this looks pretty much like the static OOP solution with a bit less
boilerplate. The biggest difference is that there's no explicit `implements
Document` on the classes. In Magpie, if a class has all of the methods that an
interface requires, then it is automatically considered to implement the
interface.

When you try to use the concrete class in a place where the interface is
expected, the interpreter checks to make sure that the class implements it. Note
that it does this *statically*, before `main()` has ever been called, like a
typical static language.

## Extending a class

Here is where it gets interesting. Now we decide we want to add printing
support. In Magpie, classes and interfaces are open for extension. So we can
just do:

```magpie
extend interface Document
    print()
end
```

If we try to run the program now, we get type check errors every place we pass a
concrete document class to something that expects the interface: the classes no
longer implement `Document` since they lack the required `print()` method. To
patch that up, we implement those:

```magpie
def TextDocument print() // Print text doc...
def DrawingDocument print() // Print drawing...
def SpreadsheetDocument print() // Print spreadsheet...
```

(`def` is one of two syntaxes for adding members to a class. It's nice for
adding a single member to a class. If you're adding a bunch of members to one
class, you can also do `extend class` which works like a regular class
definition but adds to an existing class.)

We can do this wherever we like, in any file. This lets us keep all of the code
for printing lumped together and isolated from the rest of the code just like a
dynamic language.

The magical part is that this is *statically* type checked too. The program
won't run until we've made sure that every document type now has all four
methods.

Magpie's answers for the original four questions are:

1.  **How do we organize code?** However you like. Put stuff together
    where it makes sense.

2.  **How do we add new columns -- new types of documents?** Like a typical OOP
    language: define a new class. If it has the necessary methods, it's a
    `Document`.

3.  **How do we add new rows -- new operations you can perform on any
    document?** Add new methods to the classes that need them. This can be done
    outside of the file where the class is defined.

4.  **How do we ensure all of the cells are covered?** Add the new operation to
    the interface too. The static checker will then make sure only classes that
    have the operation are used in places that expect a `Document`.

When you're defining things, you get the flexibility of a dynamic language.
Before it runs, though, you get the safety of a static language.
