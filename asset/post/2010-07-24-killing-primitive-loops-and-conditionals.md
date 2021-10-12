---
title: "Killing Primitive Loops and Conditionals"
categories: code finch language
---

The challenge I had giving my talk on [Finch][] at the Emerging Languages Camp
yesterday was knowing that I had nothing original to say that the megabrains in
front of me didn't already know. Worse, my unscheduled talk was during what was
originally a break, so not only did I have to compete with [Rich
Hickey][clojure] and [Gilad Bracha][newspeak], I had to compete with *going to
take a leak or maybe having some ice cream*.

[finch]: http://finch.stuffwithstuff.com/
[clojure]: http://clojure.org/
[newspeak]: http://bracha.org/Site/Newspeak.html

I figured since I couldn't outwit them, I'd go for zany shenanigans, which
seemed to work pretty well. I only managed to say one patently dumb thing that
I'm aware of. Late in the talk, I mentioned that a language only needed two
primitive flow control constructs: `if` for jumping forward, and `while` for
jumping back. A couple of voices in the audience immediately called me on it,
saying "You don't even need those!"

I stammered some awkward reply and went on to something else. It turns out
knowing more about implementing programming languages than 99.99% of the world
is a small consolation when the remaining 0.01% are sitting in the audience in
front of you.

In the shower this morning, it finally dawned on me what they were getting at.
As of this evening, Finch [no longer][commit] has *any* primitive flow control
constructs. Here's how:

[commit]: https://github.com/munificent/finch/commit/338391bfc252fc2da051c36ebdb5eb963d1ce5a1

## Conditions

Unless you're writing some batch script that just does X, Y, Z, you're going to
eventually need two things: to *not* do something, and to do something *more
than once*. `if:then:else:` calls in Finch handle the former. They look like
this:

```finch
if: rapper = vanilla ice then: {
  writeLine: "Too cold"
} else: {
  writeLine: "Wack MC"
}
```

If you aren't familiar with Finch, I can translate that into something a little
more vanilla. What you see there is a single call to an `if:then:else:`
function, passing in three arguments. The first is the condition -- the result
of evaluating `rapper = vanilla ice`. The other two are "blocks", what other
languages call lambdas or closures.

All `if:then:else:` needs to do is invoke the first block argument if the
condition is true, and the second if it's false. How can we do this using the
building blocks Finch already has?

The one thing Finch has that's like `if` is dynamic dispatch: Finch
intrinsically knows how to send the same message to different objects and have
them behave differently. It's pretty straightforward to get conditionals working
in terms of that. We'll define two `ifTrue:else:` methods. The version on
objects that are truthy will always evaluate the "then" block argument (with no
conditional logic needed). The version bound to false objects will always
evaluate the "else" argument.

In Finch, all objects are implicitly false except for the one magic `True`
object, so the code looks like this:

```finch
Object prototype :: ifTrue: then else: else { else call }
True :: ifTrue: then else: else { then call }
```

The first line defines `ifTrue:else:` on the prototypical object that all others
inherit from. All it does is invoke the "else" block. The second line overrides
method that for the `True` global object to instead invoke the "then" block.

(I should note here that this is exactly how Smalltalk works. All condition
logic is done with message sends to Boolean objects. So, uh, I really should
have known this the whole time.) Because I'm not crazy about how Smalltalk
syntax looks for this, we'll go ahead and wrap it in [a method on Ether][ether]
to make it look a little more normal:

[ether]: /2010/06/25/methods-on-the-ether-or-creating-your-own-control-structures-for-fun-and-profit/

```finch
Ether :: if: condition then: then else: else {
    condition ifTrue: then else: else
}
```

All that does is bounce the call over as a message on the condition object, and
we've got `if:then:else:` working without needing any hard-coded support beyond
message dispatch. Swell!

## Loops

Now that we can do stuff less than one time, let's see how to do stuff *more*
than one time. Everyone who took Scheme in college now has their hand waving
furiously in the air. Yes, I'm going to call on you. Yes, you have the right
answer. First, here's a while loop:

```finch
while: { mother burnedDown? not } do: {
    writeLine: "Burn, baby, burn"
    writeLine: "Disco inferno"
}
```

If you don't have looping built in, there's only one way for something to happen
more than once: it has to invoke *itself* recursively. I've known about using
tail recursion for loops for a long time but for some reason it fell off my
radar. Maybe because Finch didn't get proper [tail call optimization][] until
recently, or maybe it's all the alcohol.

[tail call optimization]: http://en.wikipedia.org/wiki/Tail_call_optimization

Now that Finch *does* have it, we can use it like so:

```finch
Ether :: while: condition do: block {
    if: condition call then: {
        block call
        while: condition do: block
    }
}
```

All it does is check the condition. If `True`, it evaluates the block and then
recursively calls itself. The TCO will ensure that it can loop as long as it
needs like this without worrying about blowing the stack.

The end result of all of this is that I got to delete a good chunk of C++ code
and replace it with a little Finch code. And I learned a little lesson about
making blanket assertions when standing in front of a bunch of really smart
people.
