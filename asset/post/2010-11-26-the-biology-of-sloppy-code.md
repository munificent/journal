---
title: "The Biology of Sloppy Code"
categories: code
---

I'm watching the [Future of Programming Languages][] panel and a point came up
that really resonated with me. To the question, "What is the next big trend in
programming?", Guy Steele said, "Maybe it's sloppy programming."

[future of programming languages]: http://www.infoq.com/presentations/Future-of-Programming-Languages

It's hard not to recoil from that and either deny it, or at least wish it
weren't true. I believe it is true. I think it's inevitable, and, unlike
probably most of my peers, I don't think it's a bad thing.

## What does "sloppy" mean?

Let me clarify what I mean by "sloppy". You probably have an intuition, and it's
probably right, but I'll throw out some examples:

*   If you're programming in Erlang, you're doing sloppy programming. Instead of
    writing the code "right" such that it never fails, you just assume parts
    will and try to patch things up afterwards.

*   If you're programming in a dynamic language, you're doing sloppy
    programming. Instead of carefully specifying the storage and operations for
    each of your values, you just toss them in a property bag. Later, when you
    need to work with that data, you assume (or empirically test) that the bits
    you need are still stuffed in there somewhere.

*   If you pass around numbers as strings (or JSON, or XML) even though they can
    be more compactly encoded in binary, you're doing sloppy programming. If you
    then parse those back into a native int at some later point and assume it
    won't overflow, you're *really* doing sloppy programming.

*   If you `catch` an exception instead of programmatically ensuring it cannot
    occur, you're doing sloppy programming.

*   If you cast to `void*` or `Object` or `object` and back, you're doing sloppy
    programming.

*   If you're writing glue code that transliterates some data so that two
    programs can talk to each other instead of defining the One True Format so
    they can interoperate directly, you're doing sloppy programming.

*   If you retry when an operation times out, you're doing sloppy programming.

If I wrote that list right and you're not in academia, odds are you answered
"yes" to at least one of those. These days, we're all sloppy programmers at
least a little bit.

## The super science breakdown

What I'm going to describe here will sound like an analogy, but I think it's
much closer to being literally true. I believe programming is working its way
through the physical sciences.

With a lot of hand-waving, you can organize the sciences roughly in order of
increasing complexity: math, physics, chemistry, biology, psychology, sociology.
(Or maybe in order of [decreasing hubris][hubris].) Each of these sciences takes
the subject matter of the previous one and treats it as an abstraction. To a
chemist, subatomic particles just *are* and they study how they interact to form
chemicals. To a biologist, the organic chemicals just *are*, and they study how
they interact to form living organisms. Each science is an aggregation of a more
primitive one.

[hubris]: http://xkcd.com/435/

## The digital universe

Stepping back from the real world, let's look at the electronic one. The core
idea behind digital computers is that they're *discrete*: instead of working
with complex, continuous analog signals, they quantize and decimate that down to
a fixed set of possible values. It's the ultimate reductionism -- the analog
signal running through a wire carries a nearly infinite flow of information, and
we crush that down to just two possible values ticking along at a fixed clock
rate.

You can look at this as restarting the complexity progression. We start at the
complexity of chemistry and, using a bunch of [clever engineering][gate], we
build a virtual world of data simpler than even basic physics.

[gate]: https://en.wikipedia.org/wiki/Logic_gate

### Programmer-physicists

The first programmers were essentially physicists moments after the Big Bang,
studying an artificial cosmos. At the time, the universe was so simple that all
they had to work with were the program equivalents of quarks -- ones and zeroes.
Their work resembled particle physics. Lots of math, lots of reasoning from
first principles. Lots of building things [from scratch][].

[from scratch]: http://www.youtube.com/watch?v=7s664NsLeFM

As time went on and we got farther and farther from the digital Big Bang, the
artificial universe got more complex. Given the computational particles that our
forebears created (numeric representations, data structures, basic algorithms,
etc.) we started building more complex systems.

### Coder-chemists

In the early 70s, people started talking about the [software crisis][]. It
became harder and harder to handle the complexity that the expanding software
universe could sustain. Up to now, computers were so simple that you could write
programs one byte at a time. You'd fill your magnetic tape storage before you
filled your head.

[software crisis]: http://en.wikipedia.org/wiki/Software_crisis

As computers got more powerful (and brains didn't), we reached a tipping point
where our methods of building software were no longer effective. In other
words, we couldn't make steel and bronze one atom at a time. We needed to
become chemists.

This was such a distinct transition in how software was done that they
considered it a generation change, embodied by so-called "third-generation
languages". The stress on those languages wasn't purity or fine-grained control.
It was abstraction and composability -- being able to build software out of
existing parts even at the expense of purity. In other words, what a chemist
does.

With the transition to software chemistry, the idea that you could build
software through pure reason faded to become replaced by softer empiricism. We
stopped asking if the software was right in some Platonic ideal sense and
started tracking the *rate* of defects. We went from "purity" in the
mathematical sense (it either is or isn't) to "purity" in the chemical sense
("how pure is this compound?").

### Engineer-entomologists

In the past decade, I think we've started stumbling through the next transition:
biology. Software, of course, isn't anywhere near as complex as a living thing
yet. But it's starting to reach a level of complexity, *especially* on the web
where most code is being written today, that it's more productive to think of
code as an organic material.

Where chemistry is about taking existing building blocks, tearing them apart and
reassembling them, biology generally treats its subjects as more inviolable.
When possible, biologists study living organisms as they are. Outside of the
Island of Dr. Moreau, they refrain from building new animals from parts. A
significant portion of the job of someone working in the life sciences is simply
*maintenance*: keeping the living organisms in their care alive and well.

And so it is becoming with software, especially web software. Most web
companies have "programmers" whose sole job is keeping things up and running.
They may not write a single line of code in production beyond test and batch
scripts. They're practicing software *husbandry* more than software
*engineering*.

Even the programmers who are writing production code find their work dirtier and
messier than its ever been. When the code you built your software out of was
just sitting on your disk, it was relatively easy to chop it up into the pieces
you wanted. Now that the code you deal with is sitting on some other company's
server hidden behind a web API, it may as well be a living organism. You can
interact with it, and even communicate with it, but only in its language.

Where before it didn't make sense to burn CPU cycles converting between
disparate data formats, now it's a common part of the job. A good chunk of code
running on servers right now exists just to translate the grunts of one software
animal to the chirps that another understands.

## Why the long face?

As I see it, that's what's going on in the software world. What's fascinating to
me is how much emotion and morality allegedly rational programmers imbue that
transition with. Really, there's no intrinsic rightness or wrongness about any
of this. Simple software is no "wronger" or "righter" than complex software. A
chunk of C code isn't more "real" than a bash script.

But if you look at how programmers talk about their craft, the exact opposite is
true. Almost any coder knows the archetype of the [Real Programmer][] -- someone
who can delve all the way to the [quantum level][] of code. Meanwhile,
programmers in higher-level languages (if you can even call that "programming")
are weak-willed fops, bedwetters barely better than humanities majors who
partied through school.

[real programmer]: http://en.wikipedia.org/wiki/Real_Programmer
[quantum level]: http://www.pbm.com/~lindahl/mel.html

In fact, the strongest evidence I can find for my claim that software is
mirroring the physical sciences is how perfectly the attitudes of programmers
match those of their corresponding scientists. Compare Dijkstra's "Elegance is
not a dispensable luxury but a quality that decides between success and
failure," to the aesthetic of your average physicist. Compare the stereotypical
OOP programmer's love of nouns and naming with the impossibly long catalogues of
chemical compounds. Design patterns and chemical formulae. And today, you can
look at the Rubyist waxing on about human factors and the latest methodologies
at a new convention every week and see echoes of the social scientists and their
endless manufacturing of new *-isms*.

Where this causes problems is that there's a noticeable correlation between
personality type and job type. Ask any room full of coders how many still play
with LEGOs and how many still play with modeling clay. Many programmers,
especially many older ones, are predisposed to like things that are discrete,
simple, and concrete. By their very nature, the work they enjoy is at the
physics end of the software continuum, and as programming drifts away from that,
it becomes less enjoyable for them. Their LEGOs are being ripped from their
hands and replaced with Play-Doh, and they aren't happy about it.

To make matters worse, the new crop of programmers who *are* comfortable working
at biological end are acquiring prestige at dizzying rate. For better or worse,
many of the luminaries of the software world today are on the soft end of the
spectrum. [DHH][] may have never written a linked list in his life, and he just
bought a house in Italy for *[his car][car]*. If you spent your formative years
painstakingly learning how to carve code one bit at a time and are now finding
yourself becoming outdated, that can't feel good.

[dhh]: http://en.wikipedia.org/wiki/David_Heinemeier_Hansson
[car]: http://www.autoblog.com/2010/09/07/pagani-zonda-hh-commissioner-revealed-as-30-year-old-chicago-sof/

## It's OK

I happen to be right at the chemist level: I think in OOP. I've done a bit of
assembly but it just seems tedious to me. At the same time, Javascript and Ruby,
try as I might, just don't feel like programming. There aren't even *types*
there. How can I feel like I'm getting a real code workout if I don't have a
compiler yelling at me that I'm not doing it right?

So I get the lament that programming is becoming less real and it does make me a
bit sad that so much of my time programming these days is just jamming chunks of
code together. But it doesn't get me down as much as it does some people,
because I know that programming isn't *moving* towards softer sciences. It's
simply *expanding*.

For as long as we'll need physicists, we'll still need low-level coders. The
software universe is getting bigger and it can accomodate scientists of all
persuasions. And instead of thinking that programming is getting sloppier, I
tell myself it's getting more *organic*.
