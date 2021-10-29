---
title: "\"void\", \"null\", \"Maybe\" and \"nothing\""
categories: code java language magpie
---

I'm hard at work on a proof-of-concept for the new [Magpie][]. While I've got
some more work to do before I can start getting into the really interesting
parts of the language, I have one piece working now that I think is kind of
cool, and that's... *nothing*.

[magpie]: https://magpie-lang.org/

## Absence and failure

Every programming language has to provide a mechanism for two kinds of absence:
when a function *always* returns nothing, and when it *sometimes* returns
nothing. C has the `void` type for the former. A function that just performs
some side-effect like printing to the screen is declared to return `void`, like:

```c
void sayHi() {
  printf("hi!");
}
```

The compiler will check to make sure you don't do something dumb like:

```c
int a = sayHi();
```

Failing to return *sometimes* is a lot trickier. Consider a function that takes
a path and returns a handle to a file. If there is no file at the given path,
there's no `File` it can return so it needs to fail somehow. The way most OOP
languages like Java and C# handle this is by returning `null`:

```java
File openFile(String path) {
  if (isValid(path)) {
    return new File(path);
  } else {
    return null;
  }
}
```

For any reference type (like `File`), a variable can have a valid value, or it
can be `null`. In other words, `null` is this magical value that exists as a
member of every type. "Hey there" is a string, and `null` is a string. `new
File("foo/bar.txt")` is a file, and `null` is a file.

## Meta-failure

The real problem with this is that now you've lost the ability to declare that
a function *won't* fail. *Any* function that returns a reference type can in
principle return `null` even though most never do. To be safe, you end up
having to check for it everywhere. Even then, things slip through causing tons
of real-world bugs.

Tony Hoare, the guy who gets the dubious honor of inventing `null` calls this
his ["billion dollar mistake"][billion]. I don't have a billion dollars, so I
don't want to make this mistake in Magpie.

[billion]: http://lambda-the-ultimate.org/node/3186

## Maybe another solution

Fortunately, other languages don't have this problem. The ML family of
languages, including Haskell and F#, *don't* allow `null` as a value for every
type. If you have a variable of type Foo, you can sleep soundly at night knowing
it will only and always contain a valid value of type Foo.

But now we're back to our first problem. How would we implement `openFile()`
then? It can't return `File` because it might not always find the file. ML
languages handle this with a special type called [`Maybe`][maybe] (Haskell) or
[`Option`][option] (ML and everything else). This is a special wrapper that may
optionally contain a value of some type (hence the name). Our `openFile()`,
instead of returning `File`, will return `File option`.

[maybe]: http://www.haskell.org/onlinereport/maybe.html
[option]: http://www.standardml.org/Basis/option.html

Crisis averted. The only trick is that if you're the code calling `openFile()`
you've got this option thing now instead of a `File`. How do you get the file
back out? ML languages use something called "pattern matching", which is
basically a pimped out `switch` statement. I won't go into it here, but it's
swell.

## Wasn't I talking about *my* language?

Ah, yes. Magpie. Where was I? OK, so which path does Magpie follow? Well…
neither, actually. So Java and C# use `void` for functions that never return a
value and `null` for functions that might sometimes fail. ML-family languages
use something called "Unit" instead of `void` and `Option`/`Maybe` for
occasional failure.

Magpie has one concept that it uses for both: `nothing`. In Magpie, there is a
single value called `nothing` that represents the absence of a value. If you
have a function that just has side-effects, that's what it returns implicitly.
For example, this function returns `nothing`:

```magpie
var sayHi(->)
  print("hi")
end
```

The `(->)` is the type signature. In this case, it takes no arguments (there's
nothing to the left of the arrow) and it returns nothing (there's nothing to the
right). If we wanted to be more explicit, we could say:

```magpie
var sayHi(-> Nothing)
  print("hi")
end
```

Note how "Nothing" is capitalized. `nothing` is the value, `Nothing` is its
type. There is only one value of type `Nothing` and its name is `nothing`.

That much is easy. What about `openFile()`? If I had a billion dollars to blow,
it would be:

```magpie
var openFile(path String -> File)
  if path valid? then File new(path)
  else nothing
end
```

We'd let `nothing` silently masquerade as a file. But `nothing` isn't a file,
it's a `Nothing`. So the above program won't type check. What we need is a way
to say that `openFile()` can return a String *or nothing*.

## Or some other solution

I'm all about the obvious solution, so I just took that literally. So Magpie has
*or types*. (I'm guessing there may be other names for them in the literature. I
know I didn't invent them.) A correct version of `openFile()` looks like:

```magpie
var openFile(path String -> File | Nothing)
  if path valid? then File new(path)
  else nothing
end
```

My hope is that that's pretty clear and easy to understand: `openFile` takes a
string and returns a file or nothing. It reads just like you'd say it.

## But I don't want nothing!

There's one last little problem we're left with though. If we're the ones
*calling* `openFile()` now, what do we do with what we got back? If we try this:

```magpie
var myFile = openFile("path/to/file.txt")
myFile read
```

We'll get a compile error on the second line. You can't call `read` on `nothing`
and `myFile` might be just that. To address that, Magpie has [a little thing
called `let`][let]. It's a lightweight version of full pattern matching (which
the old C# Magpie has, and the new Java Magpie will at some point) to make this
exact case easy to work with. It looks like this:

[let]: /2009/12/26/conditional-binding-with-let-in-magpie/

```magpie
let myFile = openFile("path/to/file.txt") then
  myFile read
else
  print("Couldn't open file!")
end
```

A `let` combines conditional logic like `if` with defining a variable. First, it
evaluates the right-hand expression (`openFile(...)` in this case). If, and only
if, that expression doesn't return `nothing`, it will bind the result to a new
variable (`myFile` here), whose type is the type of the expression without the
`| Nothing` clause. Then it evaluates the expression after `then`.

The nice part is that `myFile` only exists within the body of the `then` clause,
and only if it isn't `nothing`. There's no way to try to call `read` on
something that isn't a valid `File`. We're totally type-safe while still keeping
things pretty simple and easy to use.
