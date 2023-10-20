---
title: "Does Go Have Subtyping?"
categories: code go language
---

I've been [noodling on a static type system][hobby] for my current hobby
language. To try to keep the language as simple as possible, I'm trying to see
if I can live without subtyping. Since most of my programming experience is in
object-oriented languages, I've been learning more about languages that lack --
or at least claim to lack -- subyping, to see how they work.

The most intriguing one to me is Go because the authors say it doesn't have
subtyping, but when you look at interfaces, it does seem to have something
*really close* to subtyping. Is it subtyping just under another name, or is
there really something different going on?

[hobby]: /2023/01/03/type-checking-if-expressions/

This post is the answer to that question as best as I can tell. The short answer
is that no, Go doesn't have subtyping. But also, yes, it sort of does.

## What is subtyping?

If you're reading my blog, you probably already know what subtyping is, but
let's make sure we're all starting from the same place. Subtyping defines a
[*relation*][relation] between two types. Given two types A and B, it might be
the case that B is a subtype of A, or it might not be.

[relation]: https://en.wikipedia.org/wiki/Relation_(mathematics)

Since subtyping is a relation between a pair of types, it only comes into play
in a language in places where two types are involved. The main place is
assignment. You have a variable with type A and you're assigning the result of
an expression of type B to it. Is that assignment allowed?

Programming language folks usually generalize "assignment" to mean any place
where a variable is given some value. That includes assignment expressions, but
also covers initialized variable declarations and function calls where argument
values are bound to parameters at the top of the function.

There are a couple of other places where subtyping comes into play, usually
around type inference, but assignment is the main one: You have a context that
requires some type A and a value of some type B. What are the types A and B
where that code is valid?

That question is the heart of what a type checker *does*. The main user
interface of a static system is compile errors, and the most common compile
error is "I expected a value of *this* type but you gave me a value or this
other type".

## Why have subtyping?

You have a context that expects type A and you give it a value of type B. In
languages without subtyping, that's only OK if A and B are the exact same type.
In Pascal, if you declare a variable with type `int`, the only thing you can
initialize it with is a value of type `int`. Subtyping exists largely to loosen
that restriction -- to allow *multiple* different types to flow into some
context. Why might a language want to permit that?

The reason is *polymorphism*: Subtyping lets you write a piece of code and reuse
that same code with a range of different (but related) types. In languages
without subtyping, you can often find yourself copy/pasting the same function to
work with multiple different input types. (Generics can help, but that's another
form of polymorphism that we'll ignore for this post.)

In say, Java, if you define a method that takes an `Iterable`, then you can pass
a `List` to it, a `Stack`, etc. You get to amortize the usefulness of that
method across all types that implement the `Iterable` interface. Subtyping is a
force multiplier for your code.

(Of course, that benefit isn't without significant costs in terms of language
complexity, which is why I'm hoping to avoid it.)

## Does Go have subtyping?

If you search the (extremely well-written!) [Go language spec][go spec] for
"subtype", you get zero results. So the answer is a clear "no" at the textual
level.

[go spec]: https://go.dev/ref/spec

Java does have subtyping. Now, if you were to make a new language named "Blava"
that was a literal copy/paste of the Java language specification with every use
of "subtype" replaced with "blubtype", would you say that Blava has subtyping?
It behaves indistinguishably from a language with subtyping, so I'd be inclined
to say yes.

The Go spec doesn't mention "subtype", but it does have a notion of
["assignability"][assignability]. When you have a context that expects some type
and you give it a value of some other type, assignability determines which set
of other types are allowed. Concretely, the rules are:

[assignability]: https://go.dev/ref/spec#Assignability

>   *   A non-interface type T is assignable to an interface type I if T
>       implements I.
>
>   *   An interface type A is assignable to interface type B if A's methods
>       are a subset of B's.

You know, that sounds an *awful lot* like subtyping. Is "assignable to" just Rob
Pike's idiosyncratic way of saying "subtype of"? Does Go have subtyping in
everything except name? To fully answer that, we'll need to look at all of the
kinds of types in a program.

## Composite types and variance

If the only types in Go's type system were primitives like numbers, structs, and
interface then I think you'd have a good argument that Go does have subtyping,
just spelled differently. But once you start looking at slice types and function
types, the story changes. (And array and channel types too, but slices and
functions are enough to make the point.)

The thing that these latter kinds of types have in common is that they *contain
other types*. A slice type has an inner type for the slice elements. A function
type has a list of parameter types and a list of return types.

You ready for some more computer science jargon? We've been talking about
relations on pairs of types like "is subtype" and "is assignable". But now we
have types that contain other types. That raises the question of whether a
relation on the inner types of two composite types says anything about the
relation between the two outer types.

For example, let's say we have two slice types `[]E1` and `[]E2` that are slices
of elements of `E1` and `E2`, respectively. If `E1` is assignable to `E2` does
that mean that `[]E1` is assignable to `[]E2`? Does the assignability
"propagate" from the inner types to the outer types?

Computer scientists call this property (meta-property?) *variance*. They phrase
the question like "how does assignability of slice types *vary with respect to
their element types*?". There are a few possible answers to a question like
this.

### Variance of slice types

For slice types in Go specifically, there are a handful of assignability rules,
but the only one that can apply to slice types is:

>   *   <p>V and T are identical.</p>

In other words, for two slice types to be assignable, they have to be the exact
same type. That in turn means they must have the exact same element types. Even
if two element types are assignable, slices of those two types are not.

Judging by an endless series of confused people asking questions on
StackOverflow, that behavior is unintuitive to programmers, both in Go and in
other languages. Let's say you have this Go program:

```go
type Dog struct {
  name string
}

type Barker interface {
  Bark()
}

func (d Dog) Bark() {
  fmt.Println("Woof!")
}
```

Here we have a `Dog` concrete type, which is assignable to the interface
`Barker`. So this is fine:

```go
func speak(barker Barker) {
  barker.Bark()
}

func main() {
  speak(Dog{"Sparky"})
}
```

Given that, you might expect this to work too:

```go
func speakAll(barkers []Barker) {
  for _, barker := range barkers {
    barker.Bark()
  }
}

func main() {
  dogs := []Dog{Dog{"Sparky"}, Dog{"Fido"}}
  speakAll(dogs)
}
```

But, no. The type system giveth and the type system taketh away:

```
example.go:29:11: cannot use dogs (variable of type []Dog) as
[]Barker value in argument to speakAll
```

If the type system didn't yell at you, this program *would* be fine at runtime.
So what's the deal? In this case, the program is *coincidentally* fine because
`speakAll()` is only reading from the slice. But what if we wrote:

```go
type Tree struct {
  species string
}

func (t Tree) Bark() {
  fmt.Println("Rough (but not ruff)!")
}

func appendTree(barkers []Barker) []Barker {
  return append(barkers, Tree{"Elm"})
}
```

There's nothing wrong with this `appendTree()` function. It adds a `Tree` to
the given slice. Since `Tree` is assignable to `Barker`, that's fine. But if
you were to call this and pass in a `[]Dog`, you'd end up with an array of dogs
that had a tree stuck in it! That would violate the soundness of the language.

This is why Go only treats two slice types as assignable if they have the exact
same element types. In PL parlance, slice types are *invariant* with respect
to their element types. And, for a mutable data structure like slices, that
rule makes sense.

(A reasonable person might wonder then why Java and C# *don't* have this rule
and instead say that array types *are* assignable if their element types are.
And then, because as you can see, it isn't safe to do so, they have to add
[runtime][arraystore] [checks][arraytype] if you try to stuff an element of the
wrong type into the array.)

[arraystore]: https://docs.oracle.com/javase/8/docs/api/java/lang/ArrayStoreException.html
[arraytype]: https://learn.microsoft.com/en-us/dotnet/api/system.arraytypemismatchexception?view=net-7.0

So, OK, it makes sense for slice (and array) types to be invariant. What about
function types?

### Variance of function types

To keep things simple, first we'll consider just functions that don't take any
parameters and have a single return type. Given two function types like that,
when are they assignable? Again, the only rule in the Go language spec that
matches function types is `V and T are identical`. So two function types are
only assignable if they have the exact same return types. Even if the return
types are themselves assignable, if they are different types, the functions
aren't assignable.

Do we need to be that strict to preserve soundness? Actually, no! Here's an
example:

```go

func returnDog() Dog {
  return Dog{"Rex"}
}

func useCallback(callback func() Barker) {
  barker := callback()
  barker.Bark()
}

func main() {
  useCallback(returnDog)
}
```

So we have a function, `returnDog` that returns a value of type `Dog`. We pass a
reference to that function that expects a function that returns a `Barker`. The
`Dog` type does implement `Barker`. If this program were run, it would be
perfectly safe. And, in fact, there's nothing you could put inside
`useCallback()` that would make passing `returnDog` violate the soundness of the
type system.

It's theoretically safe... but Go disallows it:

```
./prog.go:49:14: cannot use returnDog (value of type func() Dog) as
func() Barker value in argument to useCallback
```

Every other language I know that has subtyping and function types allows this. A
function type `A` is a subtype of another function type `B` if the return type
of `A` is a subtype of the return type of `B`. So the subtyping relation of the
return types propagates out to determine the subtype relation of the function
types. We call this *covariance* and say that function types are *covariant in
their return types*. The "co-" prefix means that the subtyping relation between
the inner types goes in the "same direction" as the subtyping relation it
implies about the outer types.

That direction matters because relations like subtyping and assignability aren't
symmetric. The `Dog` type is assignable to `Barker`, but `Barker` is *not*
assignable to `Dog`. The underlying value might be a `Tree`!

Are there cases where the variance of an inner type doesn't go in the same
direction as the outer types? Indeed there is, and they're right there next to
us. Instead of return types, let's look at parameter types. Now let's say we
only care about functions that accept a single parameter and return nothing.
Here's an example:

```go
func acceptBarker(barker Barker) {
  barker.Bark()
}

func useCallback(callback func(Dog)) {
  callback(Dog{"Laika"})
}

func main() {
  useCallback(acceptBarker)
}
```

Note that the parameter types are flipped compared to the return type example.
Here, the callback type in `useCallback()` takes a more precise type of `Dog`.
The function we pass to it, `acceptBarker` has a parameter whose type is
`Barker`.

You may feel a slight disorientation here. The code feels weird and sort of
backwards. Wait a minute and the dizziness will pass. Dramamine might help.

While this definitely isn't as intuitive as return types being covariant, if you
think about it carefully, you'll see that the above program is completely sound.
In other languages with subtyping, function type `A` is a subtype of function
type `B` if the parameter types of `B` are subtypes of the parameter types of
`A`. Note how `A` and `B` are reversed in the second half of that sentence. The
variance of parameter types is reversed. In technical terms, we say that
function types are *contravariant in their parameter types*. The prefix
"contra-" means "against".

(You might wonder what happens when you have a function type with a parameter
whose type is itself a function type with some parameter type. How does *that*
flow out? When there's two levels of nesting it flips around to going in the
same direction as the outermost type. The way I think about it is that
contravariance is a 180° flip in the direction of the relation. If you nest
contravariant types, you flip it twice and get back to the original direction.)

Contravariant parameter types are sound, but again Go doesn't allow them. Two
function types are only assignable if their parameter types are *exactly the
same*.

## Invariance in Go

In every language I know with subtyping, function types are [covariant in their
return types and contravariant in their parameter types][fn variance]. But in
Go, function types are invariant.

[fn variance]: https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)#Function_types

Go is not a language known for getting in the programmer's way when they want to
do something, so why are function types more restrictive than would be necessary
for soundness?

It's not just function types either. *All* composite types are invariant in Go:
arrays, slices, channels, maps, functions. So *ground* types -- types that don't
contain any other type -- have some subtype-like notion of assignability. But
once you wrap a type in another, any notion of assignability goes away.

Why did the designers of Go do that? If you're going to bother having interfaces
and assignability, why not go all the way and have assignability for functions
and other composite types where its sound?

If all the designers cared about was semantic correctness and having a beautiful
elegant specification written in LaTeX, then they probably would have supported
variance, at least for functions. (The other types all *should* be invariant
since they are mutable. When types can flow both in and out, any other variance
isn't sound.)

But Go was designed from day one to be a high-performance systems language. It's
the exact opposite of an ivory tower language designed for proofs and
publications. The goal of the language is to let real users ship real
applications. And, importantly, be able to ship *fast* applications and *reason
about the performance of their code*.

## Representing values

Up to this point, we've only been concerned with how types flow through the type
checker at compile time. But -- assuming there are no compile errors -- the
compiler eventually excretes some code which gets executed at runtime. When that
happens, all of the types the type checker poked at have cracked out of their
chrysalides and emerged as beautiful runtime value butterflies flitting around
in memory.

The choice of how values of different types are represented in memory has a
massive effect on performance. So how do the rules around assignability and
subtyping interact with those representation choices?

In many object-oriented languages (Java, C#, Python, etc.) values of object
types are represented by pointers to a heap-allocated structure. That structure
has some header information for garbage collection and runtime type tracking,
maybe some kind of pointer to a [vtable][] for virtual method dispatch, then
(finally!) the memory used to store the instance's fields.

There are differences between language implementations, of course, but objects
are generally both:

1.  Slow to create since they are allocated on the heap.

2.  Fairly large with some additional bookkeeping information stored for every
    single object.

3.  Indirect, where a variable or field whose type is an object holds only a
    pointer to that object, which is always on the heap. Accessing state on an
    object always requires a pointer indirection which can be slow due
    to [poor locality and cache misses][locality].

[locality]: https://gameprogrammingpatterns.com/data-locality.html

### Struct types

Those are unnacceptable costs for a systems language like Go. When you *want*
runtime polymorphism, of course, you have to pay for it somehow. But if you're
just storing data in memory, Go doesn't want to make you pay for something you
aren't using. To that end values of struct types in Go store just the bytes
needed for the struct's own fields.

If a field of a struct is itself some struct type, the inner struct's fields are
splatted directly into the surrounding struct's contiguous memory. If you have a
local variable of a struct type, the fields are stored right on the stack
(unless you take a pointer to the struct which escapes the function).

This reduces memory overhead for structs and (probably more importantly for
performance) reduces pointer indirections. In a typical Java program, the heap
ends up being a huge spiderweb of tiny objects all pointing to each other and
the poor CPU an exhausted spider traipsing all over that web trying to find the
actual bits of data it wants to eat.

In a typical Go program, more state is stored directly on the stack, and the
heap is "chunkier" with fewer, larger blobs of memory. The CPU does fewer hops
around the heap and chews on bigger cookies of data every time it does. That
makes memory access more cache friendly and also lightens the load on the
garbage collector since there are fewer individual allocations to traverse.

(Java does something similar for primitive types, as does C# for struct types.)

### Interface types

So structs are fast, great. But Go does feature runtime polymorphism in the form
of interfaces. How does interface method dispatch work if a value is stored
directly inline with no extra data to track its runtime type or method
implementations?

The answer is that interfaces have a [completely different runtime
representation][interface rep]. A variable of interface type takes up two words:

1.  A pointer to the type information used for runtime dispatch of the interface
    methods (in other words, basically a [vtable][]).

2.  A pointer to the actual data used by the concrete type implementing the
    interface. (In cases where the data is just a single word, I think it's
    stored inline.)

[interface rep]: https://research.swtch.com/interfaces
[vtable]: https://en.wikipedia.org/wiki/Virtual_method_table

The cute industry term for a representation like this is "fat pointer": instead
of a single word with a single pointer, it's a pair of them, one for data and
one for some kind of metadata or bookkeeping information.

One of the really cool things about Go is that you only use this representation
-- you only pay for the increased memory and indirection cost of this
representation -- when you ask for it and when you need it. In places where you
need some virtual dispatch, you use an interface type and accept the overhead of
a fat pointer and indirection. But in places where you just want to store a
single concrete type, you use its underlying type and the memory is stored
directly inline.

C# supports a similar distinction with classes and structs. But that's mostly a
"declaration time" choice. Once you've decided something is a class, every
variable of that class's type will store it as a reference to a heap-allocated
object. Conversely, if you've declared something as a struct, it will always be
stored inline on the stack or in the containing object (unless you go out of
your way to box it).

In Go, the distinction between stored inline versus stored indirectly is made at
each use site. That leads to some additional complexity for the user: they
always have to think "should I use an interface, pointer, or struct type here?",
but it gives them more fine-grained control over how they spend memory and
pointer indirection costs.

## Implicit conversions

We're close to understanding why Go lets you assign a struct to an interface
but not a slice of those same structs to a slice of that same interface.

If structs and interfaces have entirely different memory representations, how
does assignability work at all? When you do:

```go
type Dog struct{
  name string
}

type Barker interface {
  Bark()
}

func main() {
  var barker Barker = Dog{"Rex"}
}
```

Shouldn't that just mangle memory when it tries to treat the memory
representation of a struct as if it were an interface? The answer is of course
no. When compiling your code, Go knows the type of every variable and every
expression. At every assignment, variable declaration, or parameter binding,
it reports an error if the value isn't assignable to the destination.

When the value is assignable, it still also knows whether or not those types are
the same. If they're exactly identical, then the assignment can be compiled to a
single register move or memory copy. When they are different but still
assignable types, the compiler *silently inserts code to convert the value
type's memory representation to the destination type's representation.*

When you assign a value of a struct type to an interface type, the compiler
inserts code to build a fat pointer, wire up its method table pointer to the
right interface implementation, move the struct's data onto the heap, etc.

Likewise, if you assign one interface type to another, the compiler inserts code
to copy the data pointers over but look up the correct method table for the
destination interface given the type information of the value's interface type.

This right here is the reason that all composite types are invariant in Go.
When assigning a single value to a related but different type, the compiler
can easily insert fixed-cost code to convert the value's runtime representation
to the destination type's. But to convert a slice of some struct type to a
slice of an interface type would require an `O(n)` traversal of the entire
slice to convert each element.

Function types are even harder. In order to support covariant return types and
contravariant parameter types, the compiler would need to insert conversion code
*somewhere*, but there's no right place to put it. Putting it inside the
function itself doesn't work because it might be called with a variety of
different parameter types and we don't know what to convert it from. Putting it
at the callsite before the parameters are passed likewise wouldn't work because
we don't know what types every callback might require.

There is potentially something clever you could do by supporting multiple
entrypoints to functions for each pair of source and destination types, but
with multiple parameters you quickly run the risk of exponential code size
explosions.

This is why languages that do support subtyping and variance almost always have
a uniform memory representation for all objects that participate in the subtype
hierarchy.

## Does Go have subtyping?

If you make it this far, congratulations. This ended up being a much deeper dive
than I expected. I learned a lot exploring this corner of the language space and
I hope you learned something too.

Getting back to the original question, I think we could accurately describe Go's
subtyping story in two equivalent ways:

*   **Yes, Go has subtyping, but it has no support for variance and all
    composite types are invariant.** This is, I think, how someone who is
    focused only on the abstract semantics of the language would describe it. If
    you were writing papers about type systems and needed to model Go's you
    might adopt this perspective. If you didn't care about how Go could be
    efficiently implemented because you were treating it purely as an
    abstraction, then this is a good way to look at it and compare it to other
    languages.

    The main problem with the looking at the language this way is that it
    obscures *why* every composite type is invariant.

*   **No, Go doesn't have subtyping, but it does have implicit conversions
    between some pairs of types.** This is how the designers of Go describe the
    language. It's the way you'd want to look at the language if you were tasked
    with sitting down and writing a production quality implementation of it. It
    describes what the language *actually does mechanically* at compile time and
    runtime.

    The challenge I found with this perspective is that it made it harder for me
    to relate Go's design choices to other more explicitly object-oriented
    languages. You can look at this entire long article as my process of trying
    to figure out the first interpretation in terms of this one.

I started digging into this not because I'm an active Go user and want to know
what's going on under the hood. [My job][dart] and hobby is designing
programming languages, so I want to know how other languages work to see what
good ideas are out there to be harvested.

[dart]: https://dart.dev/

So the question always on my mind at this point is, "*Why* did they design it
this way and does that choice make sense in other languages?" And for this
specific design choice, I think it's pretty cool. You can imagine a language
wanting three things:

*   **Non-uniform representation:** Values in memory take up only as much space
    as they need and avoid pointer indirection when possible to maximize
    runtime efficiency.

*   **Polymorphism:** The ability to reuse code to work with a range of values
    of different types.

*   **Variance:** Sort of the "lifted" form of polymorphism: The ability to
    reuse code to work with composite types that contain a range of inner types.

Those are all nice to have features, but it's really hard to get all three at
once. Most object-oriented languages sacrifice the first one to get the other
two. That gives you flexibility and expressiveness but at a pervasive runtime
cost spread throughout the entire program.

Some simpler statically-typed languages like C, Pascal, and SML give up
polymorphism and variance which can give you more efficient representations at
the cost of less code reuse.

Languages like C++ and Rust more or less give you all three at the expense of
the compiler monomorphizing and generating specialized versions of every
function that can work with multiple types, which makes compilation much slower
and can have some runtime costs from all of the extra code sitting around in
memory.

Go is aiming for a sweet spot where they give you fast compiles, efficient
runtime execution, and as much flexibility as they can get away with. It
sacrifices variance but keeps polymorphism at the individual value level. That
married with implicit conversions enables non-uniform representation. Of the
three, variance is probably the least valuable for users, so I think that's a
pretty smart trade-off.
