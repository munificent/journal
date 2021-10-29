---
title: "Type Checking a Dynamic Language"
categories: code java language magpie python
---

If you're going down the strange path of building a language that's half-
dynamic and half-static, one obvious question you have to answer is, "When the
hell do I do the type checking?" The general answer is, of course, "after the
types are defined, but before the program runs." This post talks about what I
think that means for Magpie.

To frame the question, lets look at a couple of other languages to see how they
work. First, Java, a typical static OOP language:

## The two languages of Java

If you look at a Java source file, there are almost two distinct languages mixed
together. Consider this simple program:

```java
public class Hello {
  public static void main() {
    Hello hello = new Hello();
    hello.say("Hello!");
  }

  public void say(String greeting) {
    System.out.println(greeting);
  }
}
```

At the top level is the language of *definitions*. This language owns keywords
like `public`, `class`, and `implements`. It's used for creating types, methods,
and fields. It defines the *static* structure and types of a program.

Nestled within that inside method bodies is the language of *statements*. This
is what we normally think of as "code" -- the imperative statements that a
program executes at runtime.

In a static language, these two languages are clearly and intentionally
separated. This is important because the language of definitions is executed at
compile time, and the language of statements is executed at runtime. Clearly
delineating them in the code helps the user understand when their code will run.

Type-checking is straightforward too. The compiler parses each source file, and
"executes" the definitions by building an internal symbol table that has the
name and definition of each class and method. Once that entire symbol table is
built, it then type checks the method bodies (the statements) against what's
declared in that symbol table.

After that process has successfully completed, bytecode is generated and the
program runs.

## Everything is imperative

In contrast, a dynamic language like Python only has a single language: the
language of statements. Consider this little script:

```python
class Hello:
    def say(self, greeting):
        print greeting

hello = Hello()
hello.say("Hello!")
```

It does pretty much the same thing as the Java program, but there's an important
distinction. Instead of having a special `main()` method that gets invoked, we
just put code at the top-level. Unlike Java, you can put regular statements at
the top level of a script -- it has no definition/statement distinction.

In fact, even the `class` bit that *looks* like a definition, is just a
statement. It gets executed at runtime to create a class. If we moved the `hello
= Hello()` line to the top of the script, it wouldn't work. The `Hello` class
would not have been defined *yet*.

In a dynamic language, classes and types are just another thing you can create
by executing statements, at any point in the life of a program. Since there's no
type checking anyway, it makes sense to give the user this freedom, even though
in practice most classes are created at the top-level in a fairly static
fashion.

## The Magpie answer

So now we're back to Magpie. Magpie is primarily a dynamic language, so it
follows in Python's footsteps. There is no special definition/statement
dichotomy, and classes are created, extended, and modified imperatively at
runtime. This is a valid Magpie program and runs without any type checking:

```magpie
class Hello
end

def Hello say(greeting) print(greeting)

var hello = Hello new
hello say("Hello!")
```

If we *did* want to type check it, only a simple change is needed (in addition
to actually adding some type annotations, of course): create a `main()`
function:

```magpie
class Hello
end

def Hello say(greeting String ->) print(greeting)

var main()
  var hello = Hello new
  hello say("Hello!")
end
```

This program will now type check that the argument you pass to `hello()` matches
the declared type, `String`. It will do this *before* `main()` is called. So the
general strategy is, if you want to write a dynamic program, put everything at
the top-level. If you want type checking, put all of your definitions at the
top-level, and the move the code you want to run after type checking into
`main()`.

## The evaluation model

More precisely, Magpie's evaluation model is:

1.  **Evaluate the scripts dynamically.** The script and any scripts it imports
    are executed top-down without any type checking. Magpie is basically a
    dynamic language here. (One way to look at Magpie is as a static language
    with a *really* powerful preprocessor.)

    The assumption is that most of this code will be defining classes, methods,
    and functions and binding them to global variables, but you can do anything
    you want here, including writing entire programs if you don't care to type-
    check.

2.  **Type-check.** Once the interpreter has finished evaluating the scripts, it
    looks in the global scope to see if you've defined a function called
    `main()`. Doing so is the trigger that says, "I want to type check."

    If it finds `main()`, the interpreter then type checks everything that's
    defined in global scope: classes, their methods, and functions. (In other
    words, Magpie uses the global scope as the compiler's symbol table.) If
    there are errors, it prints them out here and stops. Otherwise...

3.  **Run `main()`.** Assuming there weren't any type errors, now the
    interpreter calls `main()` which can then instantiate classes, call
    functions, or do whatever, safe in the knowledge that we won't get here
    unless all of the type checks passed.

## What happens if you cheat?

Astute readers at this point have noticed a problem. If we can imperatively
modify classes at any point, and we can execute any imperative code after
type checking, then what's to prevent us from modifying a class after it's been
type checked into something that will no longer work? For example:

```magpie
class Foo
end

Foo bar() print "called bar"

var main(->)
  // Break Foo!
  Foo removeMethod("bar")

  // Now try to call it!
  var foo = Foo new
  foo bar
end
```

When `main()` is type checked, `Foo` has a method called `bar` so it looks
fine. But by the time we get to executing it, we've actually yanked that
method out and the call will fail. Uh-oh!

Thankfully, this isn't the end of the world. Because Magpie is dynamic, this
won't trash memory or go off into the weeds like a static language. You'll
just get a "method not found" error at runtime.

But the bigger question is, how should we address this situation? I've got
three options I'm considering:

1.  **Don't worry about it.** This is the current solution. Acknowledge that
    users can break things, but trust that they won't. This is pretty much how
    every dynamic language works, and yet programmers manage to survive.
    Magpie's philosophy is "better type checking than a dynamic language", not
    "perfect bulletproof type checking", so this fits.

2.  **Don't allow classes to be modified in ways that can break type checking.**
    This is a safer solution that takes a little power from programmers. Magpie
    could allow you to add methods to a class, but not *remove* them once added.
    That would ensure that you can't imperatively break a class's type guarantee
    after it's been checked.

3.  **Freeze classes after type checking.** This is the strictest solution. Once
    a class has been type checked, mark it as frozen. After that, any attempts
    to modify it at runtime would fail. You could create new unfrozen classes
    after type checking, but everything that's gone through the checker gets
    locked down.

I'm leaning towards the first option because it's simplest and most flexible,
but I'm open to thoughts one way or the other.

## Thoughts?

So that's what I came up with. The code that's structured like a dynamic
language runs dynamically. The code that's called from `main()` runs after
type checking like a static language. The implementation is still very rough,
but it seems to actually kind of work, strangely enough.
