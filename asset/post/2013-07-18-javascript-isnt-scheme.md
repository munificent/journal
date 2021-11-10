---
title: "JavaScript Isn't Scheme"
categories: code language js scheme
---

It seems like I can't spend five minutes on reddit these days without someone
playing the [JS-is-Scheme is card][thread]. I see everything from the innocuous,
"JavaScript has a lot in common with Scheme", all the way up to, "JavaScript is
basically Scheme." This is basically crazy. Or, at least it has a lot in common
with crazy.

[thread]: http://www.reddit.com/r/programming/comments/1g7gw7/the_angular_team_is_porting_angularjs_to_dart/cahzqav

Before I convince you that it's crazy, let's step back a bit and ask why would
JS adherents make a statement like this to begin with? You don't hear people
saying, "Yeah, FORTRAN is basically Icon" or "Sather has a really solid SNOBOL
core," do you? Why this arbitrary pairing? After meticulous scientific research,
I've discovered two historical reasons and one weird psychological one.

## A creation myth

Way back in the misty primordial days of the web when "under construction"
banners were everywhere and wild `<font>` tags roamed free, there was a mighty
programmer named Brendan Eich. There is still a mighty programmer named Brendan
Eich, but there was one then too.

He appeared, in a curling cloud of smoke, at the office of Netscape with a moral
imperative to bring Scheme to the browser. Alas, the suits shut that shit down
for reals, like they do most higher purposes. What he ended up slapping together
in ten fevered days instead was JavaScript, a language designed to look like
Java and act like anything but.

Given that it didn't have Java's semantics, what semantics *did* it have? Later
historiographers started trying to fill in that blank. Since Scheme was Eich's
original <abbr title="best friend 4eva <3 <3 <3 ">BFF</abbr>, they surmised
that's where it gots its semantics from. The hypothesis was that Eich garbed his
creation in a sheepskin of semicolons and curly braces to appease his corporate
overlords, but that sexy wolf was inside the whole time.

This is, of course, totally wrong. The animal under that sheepskin is [Self][],
not Scheme. (And it's a cut-rate knock-off at that, with only single parent
delegation.) But who on Earth remembers Self, right? So this is myth numero uno:
Eich intended to make Scheme at first, so JavaScript must still have deep Scheme
roots hiding in there.

[self]: http://selflanguage.org/

## A Savior to Spread the Gospel

That myth wasn't created until much later, though. Before then, a funny thing
happened. One day, Netscape woke up from a truly epic bender to discover it had
jammed a scripting language onto the web and millions of people were using it.
Literally none of them liked it. Not one.

It was just this weird thing you had to deal with get that awesome rollover over
animation to sort-of work on your 640x480 "works best in Netscape 3.0" Geocities
page. That drop-down menu ain't gonna animate itself, you know.

Around that time, this weird guy came along named Douglas Crockford. Unlike most
of the teenage amateur-hour web designers at the time (your humble author
included), he was an honest-to-God computer whiz. While the rest of us meatheads
were using Dreamweaver and notepad, he was probably using emacs, or ed or, who
knows, troff. He'd worked in video, and games, and videogames. To further cement
his nerd pedigree, he was a bonafide language geek.

Somehow, probably involving alcohol, hard drugs, and a series of lost bets, he
went from that auspicious start to end up coding JS. Unlike almost everyone else
using JS at the time, he had seen better languages: Scheme, Smalltalk (I think),
even E. (The language, not the drug, though I wouldn't put either past him.)

Usually, touching Scheme or Smalltalk inflicts an incurable disease whose
primary symptom is involuntary sneering and derisive snorting in the presence of
any other language. Somehow, Crockford managed to fight off his infection, tear
into JavaScript, and gaze deep into the abyss at its center. What [he claims he
saw][crock] was a functional language. Scheme to be precise.

[crock]: http://www.crockford.com/javascript/javascript.html

He came back from his spirit walk, enscribed his gospels and began proselytizing
from the [Good Book][]. He told anyone and everyone, often more than once that:

[good book]: http://www.amazon.com/dp/0596517742

> JavaScript's C-like syntax, including curly braces and the clunky for
> statement, makes it appear to be an ordinary procedural language. This is
> misleading because JavaScript has more in common with functional languages
> like Lisp or Scheme than with C or Java.

Crockford has a way about him. Part of this is because his background is
legimately impressive. He has and continues to do many great things. He is a
figurative and literal graybeard, while also staying on the cutting edge. And he
has a delivery that is equal parts insight and cranky-but-lovable curmudgeon. In
other words, he's your Dad, and you damn well listen to your Dad when he's
talking to you.

## The huddled masses

Soon, a new generation of programmers found themselves in a strange position.
Many of them had stumbled onto programming as kids right when the web was new.
Their first language was the one they already happened to have on their
computer: JavaScript. It started as a toy in their youth, yet they found
themselves using it professionally years later, despite the fact that no one
seemed to take the language seriously.

Put yourself in their shoes (if you aren't already). Imagine being a
construction worker surrounded by big burly dudes, arm hair fluttering in the
winds of their swinging hammers. And you're there pushing in nails using this
ragged spit-stained blankey you've had since you were a kid. It's embarrassing,
despite the fact that your blanket does actually get those nails in. Somehow.

You feel insecure, a bit of a weakling. You're a Belieber at a Meshuggah show
and what you could really use is some street cred.

In some weird organic process, the pantheon of programming languages have
ordered themselves in terms of prestige. It's as random but undeniable as music
and fashion. Radiohead is on one end, and Nickelback is on the other. No one
knows precisely how they got there, but there they are.

On the Radiohead end, you've got Common Lisp, Scheme, Smalltalk, and a few
others. Scheme is even more Lisp than Lisp, so it's like that weird avant garde
band no one's heard of that Radiohead always claims inspired their latest album.
If Lisp is Radiohead, Scheme is Kraftwerk.

For all of the people who found themselves using JavaScript but feeling that hot
flush of shame, Crockford gave them an answer. JS wasn't some sell-out radio
rock band. It was edgy, obscure. It was Scheme.

Not just that, but it was *secretly* Scheme. So if you were into JS, not only
were you using one of the coolest languages, you were one of the select
enlightened few who knew how cool it was. You may be listening to Coldplay, but
only because Brian Eno produced it.

This "JS = Scheme" meme was hugely legimitizing to a horde of programmers
feeling unsure of themselves in the face of grizzly C programmers who allocated
their own damn memory, probably right after building their own computer out of
rocks and twigs.

## But is it true?

I may be a bit hyperbolic. Just a tad. But I think that's roughly how we got
here. Lots of programmers believe JavaScript is "basically" Scheme because it
gives them something they want to believe: that the language they choose to use
has some cachet and they don't have to feel bad about it anymore. And, honestly,
almost no one knows enough Scheme to tell if it's true or not anyway.

Well I, armed with an encyclopedic knowledge of programming languages and a
not-as-dog-eared-as-I'd-like-to-admit copy of [SICP][], *do*. We're gonna put
this myth to bed right now. Here's the defining characterists of Scheme, the
stuff whose *gestalt* makes Scheme special:

[sicp]: http://mitpress.mit.edu/sicp/

1. Minimalism.

1. [Lexical][] [block][] scope.

1. [Tail call elimination][].

1. [Continuations][].

1. [Dynamic typing][].

1. [S-expression syntax][s-exprs], and [homoiconicity][].

1. [First-class functions and closures][closures].

1. [Macros](http://c2.com/cgi/wiki?SchemeMacroExamples).

1. Distaste for mutation.

[lexical]: http://c2.com/cgi/wiki?LexicalScoping
[block]: http://docs.racket-lang.org/reference/let.html
[tail call elimination]: http://stackoverflow.com/questions/310974/what-is-tail-call-optimization
[continuations]: http://lambda-the-ultimate.org/node/86
[dynamic typing]: http://c2.com/cgi/wiki?TypingQuadrant
[s-exprs]: https://en.wikipedia.org/wiki/S-expression
[homoiconicity]: http://calculist.org/blog/2012/04/17/homoiconicity-isnt-the-point/
[closures]: http://en.wikipedia.org/wiki/Closure_(computer_science)

I know we could fight about a few things on this list, but I think that's pretty
tight. Now, for JavaScript to be "basically" Scheme, I'd expect a pretty close
correspondence there. Of that list, here's what JS has:

1. Minimalism.

1. Dynamic typing.

1. First-class functions and closures.

Don't tell me it's got lexical scope, because JavaScript's scoping is an
abomination in the face of God. Guy Steele isn't even dead and JS scope makes
him pre-emptively roll in his not-yet-occupied grave. Likewise, claiming JS is
homoiconic because you can eval strings of code is nonsense. If that's the only
criteria for homoiconicity, then C is too, since you can treat an array of bytes
as code and jump to it.

But, to be fair, it does have *some* stuff in common. So maybe it's a fair
comparison? I guess the real way to tell would be to compare Scheme to some
other languages. The big feature that everyone harps on is closures. Maybe just
having closures means you're basically Scheme.

If that's true, then C#, Lua, D, Erlang, Haskell, PHP, Scala, Go, Objective-C,
Python, Ruby, and Smalltalk are basically Scheme. In other words, if JavaScript
is Scheme by that criteria, then every language is Scheme, which of course means
none of them are.

This is why the "JS = Scheme" meme drives me crazy: it makes us dumber. It's a
[thought-terminating cliché][cliche]. It carries negative informational content
and makes people actually know less about languages than they did before.

[cliche]: http://en.wikipedia.org/wiki/Thought-terminating_clich%C3%A9

If you think JavaScript is one of the most Scheme-like languages out there, then
you're missing out on the fact that Forth is *really* minimal, Dart has great
scoping, Lua does tail call elimination, Haskell and Ruby have continuations, C#
has dynamic typing, Io is homoiconic, Go has closures, Scala has macros, and
Clojure seriously dislikes mutation.

At the same time, we're ignoring the things about JavaScript that make it *not*
Scheme. It's got a much richer syntax including a *great* notation for data. I'm
not a huge fan of prototypes (anymore), but it's an interesting dispatch model
that Scheme doesn't have.

Equating JavaScript to Scheme does Scheme a disservice, but it does JavaScript
one too. If you're going to be a JavaScript fanboy (fangirl? fanperson?), fine,
but be a *JavaScript* fanboy, not a *Scheme-by-proxy* one. Telling people it's
"basically Scheme" is still just a way of saying you're ashamed of it.

If you're ashamed of JavaScript, don't use it. (There are [plenty of
options][js] these days.) And if you *do* like it, like it for what it is, not
the tiny subset of what it is that it has in common with some other random
language.

[js]: https://github.com/jashkenas/coffee-script/wiki/List-of-languages-that-compile-to-JS
