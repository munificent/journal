---
title: "The Language I Wish Go Was"
categories: code go language
---

By all rights, I should love [Go][]. I like low-level languages. I'm comfortable
in C and have written memory managers for fun. I hate the boilerplate of Java
and the compile times of C++. I like closures and garbage collection. I think
locks and semaphores aren't the right way to do concurrency, and I really dig
[coroutines][].

[go]: http://golang.org/
[coroutines]: /2010/07/13/fibers-coroutines-in-finch/

Despite all of that, though, I've failed to warm to the language. I thought it
might be useful (for me at least) to try to clarify why Go isn't the language I
wish it was. The most constructive way I could think of to do that is to
describe that hypothetical future Go and why I think it would be an improvement.

Much of this is based on my understanding of what Go is today. If I get stuff
wrong, let me know.

**TL;DR: This post ended up way longer than I expected. Super science summary: I
wish Go had tuples, unions, constructors, no Nil, exceptions, generics, some
syntax sugar, and ponies that shoot Cheez Whiz out of their noses.**

## Syntax

Go's current syntax is a streamlined version of C, sort of like Danny DeVito
with elevator shoes. Let's aim a little higher. Smalltalk, Python, and Ruby have
all given us a slew of good ideas we can learn from to make a language more
expressive and readable. Here's a few I'd really like:

### Named/keyword arguments

Positional arguments are great for terseness, and when a function takes
arguments of different types, errors with them are rare. However, once a
function starts taking more than two or three arguments or takes arguments of
the same type, errors become common. Quick, does `substring` take a length or an
ending index? Does `find` take `needle, haystack` or `haystack, needle`?

Named or keyword arguments solve that. Smalltalk uses them for *all*
multi-argument methods, but I think that's going a bit too far. One simple bit
of syntactic sugar would be to allow a function call like:

```go
substring(from: start, to: end)
```

To be translated by the parser into:

```go
substring__from__to(start, end)
```

This would also give you a primitive form of overloading:

```go
substring(from: start, to: end)
substring(from: start, length: end)
substring(from: start)
```

These function calls would all desugar to distinct long function names, so even
though they're all `substring`, there's no overloading or name collision.
Overloading like this also covers default arguments: simply provide an overload
with some keywords missing that then forwards to the longer version, passing in
the missing argument.

### Block arguments

A lot of behavior comes in pairs: you open a file, then close it. You start a
transaction, then commit it. You lock, then unlock. In between the pairs, a
chunk of code is performed. This can be done manually, like:

```go
file := os.Open(filename)
fmt.println(file.Read())
file.Close()
```

But then you have to ensure you don't forget to close it. Go's `defer` gives you
a little help here, but you still have to *remember* to `defer` each call. In
C++, [RAII][] is the solution, but I'm particularly fond of how [Ruby][block]
solves this. We can solve the "forgetting to close" problem in Go today by
defining a function like this:

[raii]: http://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization
[block]: https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/

```go
func ReadFile(filename string, block func(f *File)) {
  file := os.Open(filename)
  block(file)
  file.Close()
}
```

Now when you need to read from a file, you just do:

```go
ReadFile(filename, func(file) {
  fmt.println(file.Read())
})
```

Now you're safely guaranteed to close the file when the operation is done. This
works because Go has lexical closures, a really nice feature. But the syntax for
this is ungainly. Ruby addresses this with block arguments. Translated to Go,
they could look something like:

```go
ReadFile(filename) do(file) {
  fmt.println(file.Read())
}
```

The block after `do` would be wrapped in a closure and passed to the preceding
function as a subsequent argument. (In other words, it desugars to exactly the
previous example.) This would, I think, give you a really simple basis for
defining scoped behavior without having to go down the route of destructors or
more complicated context management like Python's `with`.

### Operator overloading

I understand this is a religious issue for some people. Apparently, there is a
cadre of truly evil programmers out there overloading operators to do malicious
subversive things and good-hearted God-fearing coders are getting harmed by this
every day.

Somehow I've dodged that bullet. The cases where I've seen operator overloading
used have been easy to understand and valid: vectors, matrices, complex numbers,
arbitrary-precision numbers. Those, to me, sound like the exact kind of data
structures a systems language like Go would use frequently. Being able to define
operators that do what you expect on them would be nice. Call me crazy, but I
prefer:

```go
position := origin + offset + orientation * speed
```

over:

```go
position := Add(Add(origin, offset), Multiply(orientation, speed))
```

## The type system

Go has two really neat type system features: implicitly implemented interfaces
and a flat type hierarchy. There are two other simple additions I'd dig: tuples
and unions.

### Tuples

Go already has multiple returns, so the utility of [tuples][] -- ad-hoc data
structures for bundling a couple of values together -- is clearly appreciated.
Making tuples a first-class part of the type system would make multiple returns
feel less special and eliminate some corner cases of the language.

[tuples]: http://en.wikipedia.org/wiki/Tuple

Here's an example of what I'm talking about: Let's say you have some generator
function that's returning values. You take those returns and put them in a
container (which just stores them as `interface{}`). Later, you pull those out.

As it currently stands, that only works with generators that have a single
return. If tuples were first class, that would allow multiple returning
functions without any problems. With generics, this becomes an even more
useful property: generic functions can work with single or multiple arguments
without needing [a slew of overloads for arity][arity].

[arity]: https://docs.microsoft.com/en-us/dotnet/api/system.func-17?view=net-5.0

In other words, instead of `,` being a special _syntactic_ feature of certain
statement types (`return`, `var`, and `:=`), it would become an _expression_
that creates composite values.

The syntax would be simple: a comma creates a tuple:

```go
point := 1, 2          // Create a tuple of two ints.
doSomething(true, "s") // Pass a tuple to a function.
return value, err      // Return a tuple.
```

Multiple assignment could be used to pull fields out of a tuple:

```go
x, y := point
```

### Unions

Unions are the other compound type made famous by the ML family of languages.
Where a tuple says "this value is an X *and* a Y", a union says, "this value is
an X *or* a Y". They're useful anywhere you want to have a value that's one of a
few different possible types.

One use case that would fit well in Go is error codes. Many functions in Go
return a value on success or an error code on failure using a multiple return.
The problem there is that if there is an error, the other value that gets
returned is bogus. Using a union would let you explicitly declare that the
function returns a value *or* an error but not both.

In return, the caller specifically has to check which case was returned before
they can use the value. This ensures that errors cannot be ignored.

There are two flavors of unions in other languages. Ad-hoc unions as used in
[Pike][], [Typed Scheme][], and the [Closure Javascript Compiler][closure] don't
attach labels to each case. The more familiar [sum types][] of ML, Haskell, and
F# do. Both have their advantages. I think tagged unions are less useful in Go
since interfaces cover some of that use case.

[pike]: http://pike.ida.liu.se/generated/manual/ref/chapter_3.html#4
[typed scheme]: https://docs.racket-lang.org/ts-guide/types.html#%28part._.Union_.Types%29
[closure]: https://developers.google.com/closure/compiler/?csw=1
[sum types]: http://en.wikipedia.org/wiki/Sum_type

Here's an example of what ad-hoc unions could look like in Go. Let's say we want
to write a function that parses strings into numbers. It returns an `int` on
success, but may also fail. Using a union, you could define that like:

```go
func ParseInt(text string) int | *Error {
  // Code to parse...
  if success {
    return value;
  } else {
    return ParseError("Could not parse string.")
  }
}
```

Note the `|` in the return type declaration and that the two `return` statements
return different types. A caller would then determine if it was successful using
a type test. The syntax could be improved, but something not too far from what
Go has now could look like:

```go
parsed := ParseInt("123")
switch parsed {
case int as i:
  // Here, i is the parsed int value.
case *Error as err:
  // Here, err is the error.
}
```

This is more type-safe that it may at first appear. It's important to note that
the type of `parsed` is *not* `int`, it's `int | *Error`. That means that trying
to ignore the error and treat the value returned from `ParseInt` like a number
by doing something like `parsed + 1` will be a *compile* error. This lets us
statically ensure that errors are not ignored, which I think meshes nicely with
Go's "explicit is better" philosophy.

The other thing I like about this is that we've avoided returning some
meaningless int value on failure. If there is an error, there won't be an `int`
value at all, and we won't create a variable for it.

That's marginally useful for numbers, but for functions that may return a
complex initialized object or an error, it's nice not having to build some
zombie zero-initialized struct that shouldn't be used anyway. This is a good
segue into the next section...

## Initialization

A big part of the appeal of static languages is that they can help us avoid
errors. One common source of errors is improperly initialized values.

There's two species of initialization bugs that get lumped together. The first
is *completely* uninitialized values: a value is yanked out of the primordial
byte soup without setting a single bit. You have no idea what state it's in.
These bugs exist in C, to a lesser extent C++, and not at all in almost all
other languages.

The other species more common today is a value that's initialized to a
well-defined but useless state. This includes things like member variables that
are `null` but shouldn't be in Java, causing NullPointerExceptions later,
strings that shouldn't be empty, etc. Anything where an object's state doesn't
meet the invariants that it requires to function properly.

Go, designed to be an improvement on C, eradicates the first species but not the
second. I'd like to go further than that. One of the things I love about static
languages is their ability to ensure at compile time that certain kinds of
errors are not present. Initialization bugs are a big class of errors we can
fix. There are a couple of ideas we can learn from other languages to help here.

### Constructors

Constructors are the obvious one. If you want to ensure your objects are in some
known state, having a function that puts it in that state is a good way to go
about it. Of course, you can write initialization functions in any language,
including C, but the clever part about constructors is that a new object *must*
go through one. Constructors are the gatekeeper for an object's state.

Any C++ user can tell you that constructors are fairly complex, but the success
of C++, Java, and C# also tells us that it isn't intractably so. A minimal
proposal for constructors is something like this:

A function declared in the same package as a type with the same name as the type
defines a constructor function. Structs can be created by value by calling the
function directly:

```go
pt := Point(2, 3);
```

Or they can be created by on the heap using `new`:

```go
pt := new Point(2, 3);
```

If a struct has no constructors, it implicitly gets a default one. If it has one
or more constructor functions, then any creation must go through one of those.

A constructor's primary responsibility is to initialize all of the fields of the
struct. It is a static error to access a field in a constructor before it's been
assigned, and also a static error to fail to assign to all fields by the end of
the method body.

That's obviously a pretty rough proposal but it's in the shape of something
that I think would help make for safer code.

### Eliminating nil

Once you have constructors and you can statically ensure that every variable has
a chance at initialization, you can start to escape one of the [most unfortunate
language misfeatures][billion] in wide use today: `null`. Following in the
footsteps of C++ and others, Go allows any pointer or reference to refer to a
value or to also potentially be `nil`.

[billion]: http://lambda-the-ultimate.org/node/3186

If your function expects a `*Foo`, you may get a pointer to a Foo, or you may
get `nil`. It's up to you to check for it at runtime, everywhere, all the time.
Fail to do so, and you run the risk of your program crashing on a null pointer.

Languages in the ML family don't have this problem. There, if a function takes a
Foo, you will always get a Foo, no matter what. The bit of special sauce to
enable that is that you must ensure that all variables are initialized. That
way, you can't create a variable of type `*Foo` without actually initializing it
with a pointer to a Foo.

If we add constructors, we'll have the opportunity to do that initialization,
and an entire class of painfully common bugs disappears.

## Error-handling

Go has two strategies for error-handling: return codes and `panic`. I like
returning error codes for cases where errors can be expected to happen
frequently in the course of normal execution -- things like parsing strings or
looking up items in a collection.

For most other operations, I've found exceptions to be more manageable than
error codes. Automatically unwinding the stack until you reach code that's ready
to handle the error is just the kind of deeply brilliant behavior that I think
is a good fit for Go's philosophy of a small number of open-ended features.

While they may not realize it, I think the Go designers actually agree with me.
Consider this code from [the article linked to][panic] on [why Go doesn't have
exceptions][exceptions]:

[panic]: https://go.dev/blog/defer-panic-and-recover
[exceptions]: https://golang.org/doc/faq#exceptions

```go
func CopyFile(dstName, srcName string) (written int64, err os.Error) {
  src, err := os.Open(srcName, os.O_RDONLY, 0)
  if err != nil {
    return
  }
  defer src.Close()

  dst, err := os.Open(dstName, os.O_WRONLY|os.O_CREATE, 0644)
  if err != nil {
    return
  }
  defer dst.Close()

  return io.Copy(dst, src)
}
```

Those two `if err != nil` blocks are exactly what exceptions do for you,
automatically and gracefully. Another example: every place I could find in the
[JSON decoder][json] that looks at an error code immediately unwinds the stack
by returning an error code in turn or panicking.

[json]: http://golang.org/src/pkg/json/decode.go

I've seen a lot of heated debates between Go fans and haters about how
exceptions are the best or worst thing ever, but scant actual elucidation as to
*why*. For what it's worth, here's my take. In addition to the aforementioned
automatic stack-unwinding, there's two other things I like about exceptions:

### No zombie variables

My favorite aspect of exceptions is that they can, just by the shape of the
code, prevent you from doing something incorrect. Consider this:

```java
try {
  File file = openFile(filename);
  file.read();
} catch (RuntimeException ex) {
  System.out.println("Oh noes!");
}
```

What exceptions give you here is the absolute guarantee that `file` will *never*
hold anything except the value of a *successful* return from `openFile`. You
don't have to check an error code. You don't have to check if it's `null`. If
you make it to the `file.read()`, you know you have a valid file. In other
words, we get to use blocks to limit the scope of variables to only exist when
it's *correct* for them to do so.

### Type safety without coupling

There's another nice feature of exceptions, but it's a bit elaborate to explain.
Let's say I'm passing an object of a type I defined to some third-party library,
which then calls a method on the object. So the callstack looks something like:

```text
1: MyObject::doSomething()
2: ThirdPartyLib::callMyObject()
3: MyCode::passObjectToLib()
4: main()
```

Now let's say that `doSomething()` method fails and throws an exception of type
`MyException`, which I catch in `passObjectToLib()`. The third-party library has
*no awareness of that type at all*. What's cool about exceptions is that this
works just fine: I can catch my own exception type with complete type safety
even though it unwinds the callstack *through* a layer that's completely
oblivious to that type.

If you try to do the same thing with error codes where `callMyObject()` manually
takes the error returned by `doSomething()` and returns it back to
`passObjectToLib()`, then the third party library has to store that error in
some `interface{}`-like untyped variable since it doesn't know the actual type.
When the error is handed back to `passObjectToLib()`, the receiving code has to
do a dynamic cast. In other words, we have to give up type safety.

So, my preferred solution here is obvious, if boring: just use exceptions like
C++, C#, Java, Python, Ruby, Smalltalk, and most other languages do. It's been
proven successful, and it's familiar to millions of programmers. It's popular
for a reason.

## Generics

Go may be the only static language created in the past decade that *doesn't*
have generics and the lack is a painful omission. Programmers skilled in C++,
Java, and C# (not to mention the ML family!) have learned that you can write
code that is both flexible *and* type-safe using type polymorphism. The absence
of it in Go takes a major tool out of the toolbox.

One clear example of how onerous its absence is the vector type in Go. There are
three separate vector types, one for [ints][], one for [strings][], and one for
[`interface{}`][interface]. You'll notice the code for all three is identical
except for the types. Indeed:

[ints]: https://github.com/golang/go/blob/e6ecf9765ae8aca669f192aff9a112b6fa10dfcb/src/pkg/container/vector/intvector.go
[strings]: https://github.com/golang/go/blob/e6ecf9765ae8aca669f192aff9a112b6fa10dfcb/src/pkg/container/vector/stringvector.go
[interface]: https://github.com/golang/go/blob/e6ecf9765ae8aca669f192aff9a112b6fa10dfcb/src/pkg/container/vector/vector.go

```go
// CAUTION: If this file is not vector.go, it was generated
// automatically from vector.go - DO NOT EDIT in that case!
```

I can't think of a clearer indicator that a feature is missing. Actually, I can:
`map`. Go has a hashtable collection type which *is* generic, precisely because
it's built into the language. It's special.

The rationale I've read ("one map is all you need") feels out of place in Go.
It's *only* in low-level languages like C and C++ that I've had strange
requirements that prevented me from using standard components. I can understand
that reasoning in Java or C#, but in a systems language I'd be honestly
surprised if one map *was* all I needed.

The solution -- adding generics to the language -- is certainly non-trivial, but
it isn't rocket science either. There's a slew of existing languages with
support for generics out there, and a wide body of literature to pull from.

As strange as it sounds, something like C++ templates are probably the closest
fit for Go: they play nice with value types, give excellent runtime performance,
and can lean on the fact that Go compiles really fast. By not being bound to C's
syntax and antiquated textual `#include` compilation model, I believe Go could
get much of the power of templates while still being simpler and less finicky
than C++.

## Future-proofing

Bertrand Meyer coined something he calls the "[uniform access principle][]"
which states:

[uniform access principle]: http://en.wikipedia.org/wiki/Uniform_access_principle

> All services offered by a module should be available through a uniform
> notation, which does not betray whether they are implemented through storage
> or through computation.

In other words, a built-in field on a type should be indistinguishable at the
use site from a calculated property. This is important because it lets you start
simple using direct fields but then replace them with calculated properties
later without having to touch every callsite.

In languages that don't support this, like Java, you end up speculatively
wrapping *everything* in an abstraction (in this case getters and setters) just
*in case* you find yourself needing that later. I consider this
[future-proofing][] and I think it's one of the biggest sources of the detested
boilerplate that led the designers to create Go in the first place.

[future-proofing]: /2010/09/18/futureproofing-uniform-access-and-masquerades/

### Other kinds of future-proofing

Uniform access talks just about properties but I consider that part of a much
larger question: "Can I replace built-in functionality with a user-defined
abstraction without having to change each callsite?" Wherever the answer is
"no", you find boilerplate. For example, in most languages a constructor call
must always return the named type henceforth and forever. To get around that,
you see people hide them behind abstract factories or factory methods.

Reducing boilerplate has been called out as a major motivator behind Go, and you
can see they've taken steps towards mitigating future-proofing. An existing type
can retroactively implement a new interface, which is really cool. Likewise, you
can add methods to existing types.

But for many other things, Go has taken steps *backwards*:

*   **Field access** is different from method calls (which always take `()`).
    You can't make a calculated property that looks like a field, unlike C# and
    most dynamic languages.

*   **Subscript syntax** like `array[index]` cannot be overloaded (unlike C++
    and C#). This means that if you start off using an array, slice, or a map
    and later decide to used a higher-level collection, you'll have to touch
    every callsite.

*   **Object allocation** uses special `new` syntax and can only zero-initialize
    the object. If you later need more complex initialization, you'll have to
    replace every `new(Foo)` call with `NewFoo()`.

The solutions for these are fairly straightforward: allow users to overload the
syntax. In all cases, all that needs to happen is that some piece of Go syntax
gets desugared to a regular method or function call. The way to specify these
"special" methods is a [bikeshed][] question, but something like this would work
without adding any keywords:

[bikeshed]: http://www.bikeshed.com/

```go
// Property getter like `vector.Magnitude`:
func (vector *Vector) Magnitude__get__() float {
  // Calculate the magnitude of a vector...
}

// Property setter like `rect.Width = 4`:
func (rect *Rect) Width__set__(value int) {
    // Set the width of the rectangle...
}

// Subscript operator like `list[index]`:
func (s *StringList) Subscript__(index int) string {
  // Get the element at index...
}

// Subscript operator in assignment like `list[index] = "value"`:
func (s *StringList) SubscriptSet__(index int, value string) string {
  // Set the element at index to value...
}

// Initialization function automatically called after `new(Thing)`
// creates a zero-valued object.
func (t *Thing) Init__() {
  // Initialize the value...
}
```

Minimalists will argue that this just adds needless complexity to the language.
My only counter-argument is that it was Java's attempts to *simplify* C++ that
leads to code like:

```java
book.getChapters().put(book.getChapters().size() - 1,
  ChapterFactory.instance().create("Prologue"));
```

Instead of:

```java
book.chapters[book.chapters.size - 1] = new Chapter("Prologue");
```

Sometimes a little syntactic sugar goes a long way.

Right now, Go avoids this by having a culture of not future-proofing. That
culture is only sustainable as long as all of the code that your code touches is
very easy for you to modify. That's true within some small or very agile
organizations, but once Go starts moving to wider enterprise use, I fear we'll
start seeing "best practices" like "always wrap every field in a getter method"
and "always hide constructors behind `New__`" functions and then it's Java all
over again.

## Where to go from here

If you made it this far, I owe you a beer or something. So, where does this long
piece of armchair language design leave us?

For you, if the language I've described sounds like what you want, you may
want to take a look at [BitC][]. John Shapiro has recently kicked the dust
off of it and started working on it again. It aims to go much farther down the
path of low-level control + modern types than other languages I've seen.

[bitc]: https://github.com/repos-bitc/bitc

<div class="update">
<p><em>Update 2021/10/17:</em> BitC is dead, but today the low-level systems
language that scratches almost all of the itches here is clearly
<a href="https://www.rust-lang.org/">Rust</a>.</p>
</div>

If you just want a low-level language with lots of expressive tools and most of
the features I listed here, then there's always C++. The stuff that's bad about
it is still there, and still bad, but it's the only game in town if you want
control over memory and generics.

For me, I'm gonna get back to working on [my little language][magpie].
Meanwhile, if there's anything here that the Go community is interested in, I'm
more than up for the challenge of actually implementing it.

[magpie]: https://magpie-lang.org/
