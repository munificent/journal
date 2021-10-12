---
title: "What I Learned at the Emerging Languages Camp"
categories: code language parsing
---

I just got back from the unbelievably awesome Emerging Languages Camp at
[OSCON][]. I wish I could come up with a good way to get across how cool of an
experience it was. All I can say was that for the first time in a long time, I
felt like I was really around my people. A programming language nerd is a really
specific kind of nerd and I don't really know many who share my obsession. For
the last two days, I was in a room packed with people who did.

[oscon]: http://www.oscon.com/

It's hard to summarize two intense days of full-on nerdery, but I thought I
would talk a bit about something good I got from some of the talks. This doesn't
mean I agreed with them all (frankly, I found the Go talk myopic), or that
anyone I omitted here *wasn't* interesting. I'm exhausted this morning, so I
only have so much steam.

## Rob Pike (Go)

The theme that comes up frequently when I read about [Go][] or hear Rob talk
about it is this sense of pragmatic feature economy. Any time someone asks, "why
doesn't Go have Foo", his answer tends to be "We found in practice that we don't
miss it."

[go]: http://golang.org/

Language designers can be [magpies][], wanting to cram in all of our favorite
features just because they're shiny or to have a longer bullet list than the
competition. If those features don't help real people solve real problems,
you're wasting your time and making things more complex for them. While I don't
always agree with the specific choices that the Go designers make, I do agree
with the "let's see if we can get by without them" approach that leads to them.

[magpies]: http://magpie-lang.org

## Phil Mercurio (Thyrd)

Phil's talk was one of a few on visual programming. Most of my experience with
visual languages is that they're either toys or incomprehensible timecube-esque
crankware.

Phil got up and humbly walked through [his visual language][thyrd]. When he
asked for questions at the end, there was a long pause before any hands went up.
From talking to people afterward, I think the consensus was that we were all
thinking, "Holy crap, he actually did it."

[thyrd]: http://thyrd.org/

He managed to find a small kernel for a visual language (nested grids and
triads) and build something out of it that really works. It's *really* hard to
pull something like this off, and I think it's cool that's he had the insight
and tenacity to keep cranking away at it.

## Alan Eliasen (Frink)

Alan stressed that [Frink][] is a general-purpose language with user-defined
functions and stuff but its *raison d'etre* is doing arithmetic with units,
which it does so unbelievably comprehensively that it boggles the mind. From his
talk, I can only assume that Alan's house is packed floor-to-ceiling with
yellowing almanacs and dusty IEEE standards reports. Calling his knowledge of
measure "encyclopedic" is giving encyclopedias too much credit.

[frink]: http://futureboy.homeip.net/frinkdocs/

What I found interesting about Frink is that by limiting its focus to a single
domain, Alan has ended up with a language that's *more* powerful and useful.
When asked what their language is good for, many designers would say
"everything" which really means "nothing". Frink embodies the principle of doing
one thing and doing it well.

## Gilad Bracha (Newspeak)

The camp was an even mix of academics and hackers. A lot of academic talk is
over my head so the mortarboard team is underrepresented in this post. Gilad's
talk was in that category: a lot of it was too high-level for my primitive
monkey brain to grasp.

One thing really stuck with me though. [Newspeak][] doesn't have namespaces,
modules, or a lot of other OOP features. What it does have is classes, and
classes nest. That simple core is flexible enough to do duty as a module system,
an abstraction system, a namespace system etc. I love the idea of getting one
simple concept and letting it fully unfold to cover a bunch of different problem
solutions.

[newspeak]: http://bracha.org/Site/Newspeak.html

## Jeremy Ashkenas (Coffeescript)

I totally didn't pay attention to Jeremy's talk because I was busy slapping
together slides for mine. This sucks because I think [Coffeescript][] is
fantastic. I love its obsession with aesthetics and clarity. Both the language
and its documentation are a testament to the philosophy that beautiful is
usable. I wish more language designers would pay heed to that.

[coffeescript]: https://coffeescript.org/

## Steve Folta (Trylon)

Steve's talk embodied two ideals that I think are often overlooked. The first
thing he said when he got up was, "Trylon doesn't do anything new." That puts
[Trylon][] in the same space as Python, Ruby, and almost every popular language
today. If you want to publish papers and advance the art, breaking new ground is
key. If you want a language for people to use, there's real value in staying
away from the borderlands.

[trylon]: http://github.com/stevefolta/trylon

The other thing he said that struck me was, "When I get home I program in Trylon
because it's the language that feels the most fun to me." A well-worn truism in
writing is "write for yourself". Trying to make a language that's all things to
all people is futile and exhausting. I love that Steve just made the language
that *he* wanted.

## Amos Wenger (ooc)

Any domain has two levels of knowledge: the core ideas for the domain, and the
*cultural* wisdom *around* those ideas. The first tells you how to do stuff. The
latter often tells you which stuff not to do. Any well-versed programming
language person can tell you about both recursive-descent parsers and generated
parsers. They'll also tell that generated parsers are the "right" way to do
that.

Most of the time that advice will save you from wasted effort, but sometimes I
think it keeps people from going down paths that may actually be fruitful.
Sometimes the thing that everyone knows is true isn't. (For example, every
language I know of with a lot of real-world users actually does use a hand-
written parser.)

Amos is a young French iconoclast. If he'd been born in a different time, I
expect he'd be a brick-tossing anarchist. One advantage that attitude gives him
is that he and the others working on [ooc][] pour features into the language
while the rest of us are still sitting around fretting about minutia. I think a
lot of us could use some of that "let's just fucking do it" spirit.

[ooc]: http://ooc-lang.org/
