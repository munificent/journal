---
title: "Zero to 353 Pages: Bringing My Web Book to Print and E-book"
categories: book game-dev design game-patterns
---

<figure>
  <a href="http://gameprogrammingpatterns.com/"><img class="framed" src="/image/2014/11/book.jpg"></a>
  <figcaption>Look what I made!</figcaption>
</figure>

It's a funny feeling to spend nearly six years making something and then finally
hold it in your hand. It's simultaneously, "This is *it!*" and "Is *this* it?"
How can it be so small when it feels like such a big piece of my life?

Most of that time, [the book][gpp] existed entirely on the web. It was less
"book" and more "book-length manuscript that you can read with your browser".
The web site is still the book's real home in some ways. If you want to know
more about game programming and software architecture, [take a look][contents].
You can read the whole thing online, for free, because I love you.

[book post]: /2014/04/22/zero-to-95688-how-i-wrote-game-programming-patterns/
[gpp]: http://gameprogrammingpatterns.com/
[contents]: http://gameprogrammingpatterns.com/contents.html

I already wrote [a post][book post] about the *writing* part of the process.
That was the real mountain to climb. But, once I reached the summit and decided
(1) I wanted to also have print and e-book editions and (2) I wanted to do it
all myself, I learned that one does not simply walk *out* of Mordor either.

This gratuitously, vaingloriously long post is about climbing back *down* the
mountain&mdash;all of the *stuff* required to turn a web site into a book.
Remember on Mr. Rogers Neighborhood where they would take a trip to a factory to
see how cute little piglets are turned into hotdogs or something charming like
that? This is like that, but marginally less incarnadine.

## Where it starts

On April 22nd, I finished the third draft of the last chapter of the book. The
next day, I uploaded it and modestly told a few friends. And by that, I mean I
[milked it][tweet] for [all it was worth][g plus] on all [the social
networks][reddit].

[tweet]: https://twitter.com/munificentbob/status/458811197966409728
[g plus]: https://plus.google.com/100798142896685420545/posts/HJ3J368V6Mp
[reddit]: http://www.reddit.com/r/programming/comments/23qnnc/i_finished_writing_my_free_book_on_game/

As soon as I shook out [all of the bugs readers reported][bugs], I went straight
into working on the print and e-book versions. Like I mentioned in the last post,
I work on the book every single day. Not breaking the chain has somehow been
just enough of a mindtrick to get me to overcome my usual inability to finish
anything bigger than breakfast.

[bugs]: https://github.com/munificent/game-programming-patterns/issues?q=is%3Aissue+is%3Aclosed

By this point, I was actually superstitious about breaking it. I really wanted
to hold the physical book in my hands, so until that was done, I was afraid to
take even single day's break.

<figure>
  <iframe width="560" height="315" src="//www.youtube.com/embed/sb7uzrKnAGA" frameborder="0" allowfullscreen></iframe>
  <figcaption>I did break the chain on <em>one</em> day. It was my birthday in
  Kauai. I spent the morning playing on the beach with my kids, the afternoon
  snorkeling with sea turtles, the evening grilling burgers for my friends, and
  the night boozing it up. The book kinda slipped my mind.</figcaption>
</figure>

The first step was doing yet another editing pass over the manuscript. At this
point, I'd done three drafts of each chapter, but ink on paper is a lot harder
to fix than a website, so I wanted to give it one more round of scrutiny.

This was also, strangely, the first time I'd read the book *front to back*. The
chapters are relatively unconnected, sort of like recipes in a cookbook, and I
wrote them out of order. Every time I finished a chapter, the next one I started
was the one that seemed like the most fun right then.

I found a bunch of places where I said the same thing twice near each other in
the book, but years apart in my life when I wrote them. I fixed those, and tons
of other style and tone issues. Then I found a freelance copy editor and got her
to do a pass over it.

Despite having done four drafts at this point, she still found dozens of
mistakes that I managed to miss. If you ever write book, I *highly* recommend
this step. You'll be astonished at how much you miss that a good editor will
find.

## E-books, ugh

I'm going to mix up the chronology here and talk about the e-book version first.
In reality, I interleaved working on this and the print version and going back
and forth over chapters with my copyeditor, Lauren. The e-book stuff is less
exciting than the print design, so let's just get it out of the way.

I was actually in pretty good shape going in to this. I wrote the book [in
Markdown][md], and had [a little Python script][format] that takes those files,
some CSS, and an HTML template, and burps out the web site.

[md]: https://github.com/munificent/game-programming-patterns/tree/master/book
[format]: https://github.com/munificent/game-programming-patterns/blob/master/script/format.py

If you've never done an e-book before (you lucky devil, you), they come in two
predominant flavors: EPUB and MOBI. Most of the world uses EPUB, but Kindle
demands MOBI in some sort of gigantic distributed prank on the entire writing
community.

An EPUB file is basically a zip file containing a web site. Seriously. Take your
static site and run this on it:

```sh
cd my_awesome_site
zip -X0 my_awesome_site.epub mimetype
zip -Xur9D my_awesome_site.epub *
```

Now you're 90% of the way to having an e-book. It's the other 10% that makes you
want to claw your eyes out. See, e-books are a lot like web sites... circa 2004.
Instead of this fancy HTML5 stuff which is clearly, like, living in the future
with all of its new tags that don't need to be closed, EPUB requires XHTML, the
evil mutant offspring of HTML and XML. The turducken of the markup world.

Worse, e-book readers handle CSS about as well as Netscape Navigator and IE4
did. If you lived through the horror show that was web design in the '90s where
you had three browsers open all day, you know what I'm talking about. Except
that now each of those "browsers" is a separate physical device that you have to
jump through hoops to get your "site" on.

Getting an updated `.mobi` file into the Kindle app on my tablet involved some
combination of Dropbox, an Android file manager, going to the Amazon website to
delete the previous version, sending an email to a mysterious dead drop address
granted me by Amazon, waiting for the Kindle app to crash a few times, and, on
occasion, blood sacrifice.

The things I do for love.

Oh, and did I mention the XML? SO MUCH XML. The [EPUB format][epub] was clearly
written by uptight pencil-pushers whose OCD was permanently triggered by the
chaos of the web. You need a `content.opf` XML manifest that lists *every single
file* in your e-book. You also need a `container.xml` manifest that points to
that `.opf` file. You need a manifest for your manifest.

[epub]: http://idpf.org/epub

The `.opf` file needs a `<spine>` tag containing the ordered list of stuff in
the book. And a `<guide>` containing... an ordered list of the stuff in the
book. Also, there's a separate&mdash;mandatory, of course!&mdash;`toc.nxc` file
containing, you guessed it, an ordered list of the stuff in the book. Not only
that, each item in the TOC is not just in order but *explicitly manually
numbered*:

```xml
<navPoint id="copyright" playOrder="1">
  <navLabel><text>Copyright</text></navLabel>
  <content src="copyright.html" />
</navPoint>

<navPoint id="acknowledgements" playOrder="2">
  <navLabel><text>Acknowledgements</text></navLabel>
  <content src="acknowledgements.html" />
</navPoint>

<navPoint id="dedication" playOrder="3">
  <navLabel><text>Dedication</text></navLabel>
  <content src="dedication.html" />
</navPoint>
```

See those little `playOrder` attributes? It's like double-entry bookkeeping,
minus the fun and excitement of double-entry bookkeeping.

But, despite my ranting here, it's not really *hard*. It's sort of like counting
to a thousand by hitting `+` and `1` over and over on your calculator. (I had a
fun childhood.) Once you've got a happy little EPUB file, you throw it at
KindleGen, a rancorous old app from Amazon which begrudgingly converts it to a
MOBI for you. Behold:

<figure>
  <img class="framed" src="/image/2014/11/ebooks.png">
  <figcaption>It took me almost six years to make these two files.</figcaption>
</figure>

If you ignore the fact that it took about a hundred iterations to please the
[EPUB validator][] Gods, this was straightforward. Now, let's talk about the fun
stuff!

[epub validator]: http://validator.idpf.org/

## My dirty little secret

Warning: Seriously ardent exposition on design lies ahead. The rest of this post
will be like watching two of your best friends who after years of awkward sexual
tension finally hook up and now aren't so much blasting you with public displays
of affection as they are public displays of not-always-entirely-dry humping. I
really *really* like fonts.

When I first started the book, I wrote a little promise to myself in my pink
locked diary that I never show anyone. (Except now you, I guess, Dearest
Reader.) That promise was, "If I can finish writing this whole damn manuscript,
I will let myself typeset it."

I know that probably sounds strange but if you haven't figured out I'm a bit off
center by now, you must be skimming this post for the pictures.

<figure>
  <img class="framed" src="/image/2014/11/pumpkin.jpg">
  <figcaption>Here's one of a tiny pumpkin pie I baked!</figcaption>
</figure>

Most of my life, I had one cranial hemisphere in the artist bucket and one in
the logical bin. I grew up drawing and painting, but usually on graph paper.

A quick trip down my résumé makes stops at computer animator, web designer, UI
designer, part-time UI programmer, *full*-time UI programmer, and tools
programmer, before finally landing on regular full-on programmer. My left brain
metastasized and took over pretty much the whole light show upstairs.

I love programming, and I'm happy to spend almost all day doing stuff that's not
that visual, but, man, sometimes I really miss design. Thus the vow: if I could
complete this giant ball of logical thought, I would reward myself by fully
giving into my artistic side.

## You mean I get to pick a page size?

Of the design stuff I *have* done in the past, almost all of it has been for the
web. There's a lot to like about web design, but it's sort of like body
painting. No matter how steady you are with your airbrush, there's an inherit
squishiness and unreliability to the underlying medium.

When you can't trust the user not to futz with the size of their browser window
or even control what fonts they have access to, it's hard to design something
that looks exactly the way you want. But, *print*, now that's a different story.

The first thing I did was decide how big the pages would be. Let me repeat that
for you web folks: **I, the designer, got to *choose* the page size.** Because
Amazon is the giant gorilla of the publishing industry and [CreateSpace][] is
its cuddly orangutan buddy, I decided to go with that for handling the
print-on-demand production of the book. They have a [few different trim
sizes][trims] you can pick from.

[createspace]: https://www.createspace.com/
[trims]: https://www.createspace.com/Special/Pop/book_trimsizes-pagecount.html

I grabbed a bunch of programming books I had nearby, took my ruler out, and
measured those suckers. I wanted my book to be like a real programming book, so
I measured their dimensions, margins, line height, font size, the works. I took
some averages, settled on 7.5&quot; &times; 9.25&quot; and that was that.

## Fonts, fonts, fonts

Now that I knew how big my canvas was, it was time to start painting it. And,
for a book, that means fonts. Sweet, delicious, heavenly fonts.

As a web designer, I was used to -- paraphrasing Henry Ford here -- having any
serif I wanted, as long as it was Georgia. (And I remember the days *before*
Georgia, a ghastly fever dream thankfully cured by heroic doctor [Matthew
Carter](http://en.wikipedia.org/wiki/Matthew_Carter).)

[Google Web Fonts][] turned things up a notch, but once you filter out all of
the fonts on there that [don't have italics][domine], or [have shitty
metrics][vollkorn], or incomplete character sets, or [only one
weight][garamond], what you're left with is... well, Georgia starts looking
pretty good again.

[google web fonts]: https://www.google.com/fonts
[garamond]: https://www.google.com/fonts/specimen/EB+Garamond
[vollkorn]: https://www.google.com/fonts/specimen/Vollkorn
[domine]: https://www.google.com/fonts/specimen/Domine

But, now. Now! I could just *go out and buy a fucking font and then use it*. Any
font I wanted! It was intoxicating. Incredible. Overwhelming. Paralyzing.

I spent nights in a hallucinogenic daze going through dozens of serif (for body
copy), sans serif (asides and headers), and monospace (code, naturally) fonts.
For all I know, it could have been weeks. Time had lost all meaning. When my
fugue dissipated, I had a beard, a Grateful Dead tattoo, and three fonts.

Ironically, the first two, Source Sans Pro and Source Code Pro, *are* Google Web
Fonts, and are what [the site][gpp] uses:

<figure>
  <img class="framed" src="/image/2014/11/source.png">
  <figcaption>Not pictured: beard and tattoo.</figcaption>
</figure>

I don't know if this is astute branding on my part or just a failure of
imagination, but do I think Adobe really nailed it with Source Code Pro -- even
when in print -- and it pairs just as perfectly with Source Sans as theirs names
would lead you to believe.

That just left a body font, the most important font in the book. Like I do, I over-constrained the hell out of the problem:

*  **I wanted a relatively small [x-height][].** I don't dig the current trend
   of really big x-heights, especially not in print. They look like a
   schoolgirl's loopy handwriting to me, minus hearts over the "i"s. If I'm
   going to print this bad boy at 2400 DPI, it can handle some nice small
   [bowls][].

*  **But not *too* small.** The prose is heavily seasoned with `inline code`, so
   the body and code fonts need to have similar vertical metrics or it will look
   like Danny DeVito and Arnold Schwarzenegger in *Twins*.

*  **I love [Old Style][] typefaces.** Garamond, Jenson, and Bembo are my
   homeboys. Low contrast in line thickness, angled stress and a bit of humanist
   irregularity, *aww yiss.* I can't stand the wimpy horizontal strokes of
   Didone fonts. I seriously get irrationally angered by them.

*  **But a font that's *too* calligraphic would clash with the other fonts.** A
   page should look like a cohesive whole. That won't happen if the body text
   looks enscribed by a medieval monk's quill pen while the code and headers are
   machined out by a robot.

[x-height]: http://www.typographydeconstructed.com/x-height/
[bowls]: http://www.typographydeconstructed.com/bowl/
[old style]: http://www.fonts.com/content/learning/fontology/level-1/type-families/oldstyle

If you distill that down, what I really wanted was a font with the *metrics* of
an Old Style, but the *letterforms* of a cleaner modern typeface. Also, it
needed a heavier weight and a spritely italic. I swear, italics trigger some
kind of delectable synaesthetic response in me like the electric tingle of a
battery on my bathing suit area.

After days of poring over typography blogs and font sites, lo and behold, I
found a match. My Manic Pixie Dreamgirl in OpenType Format. *Sina Nova.*

<figure>
  <img class="framed" src="/image/2014/11/sina.png">
  <figcaption>Sorry for the linguistic liberties, Vlad. I'm sure you
  understand.</figcaption>
</figure>

God, just look at it there. And wait until you see the *ligatures*. It's enough
to make a girl swoon.

I had assembled my army, now it was time to draw battlelines.

## So many grids

Some people fantasize about building [roller coasters in their
backyards][coaster] or [being smothered in pugs][pugs]. I've always dreamt of
designing using an honest-to-God [grid system][].

[coaster]: https://www.youtube.com/watch?v=PGRgXWsL-_Y
[pugs]: https://www.youtube.com/watch?v=OmX1V6_gukY
[grid system]: http://www.amazon.com/Systems-Graphic-Systeme-Visuele-Gestaltung/dp/3721201450

I've tried to approximate them for the web but it always ends up leaving me
disappointed and slightly ashamed like trying to use role-play to reinvigorate a
relationship you both know is dead. Not this time, though. I had a brand new
copy of InDesign, and I wasn't afraid to use it!

For those who don't know, a grid system organizes the content on a page. You
come up with the dimensions of an invisible grid that overlays the page and
everything slots within those. When done well, the text hangs together in placid
harmony like a zen garden.

Coming up with a good grid, especially for this book, was quite hard. Again, I had a bunch of constraints:

*   Of course, it has to take into account the page size, and the margins. Wider
    margins on the inside so you don't get to close to the spine. We're an
    actual book now!

*   If you've [read any of the book][gpp], you know it's full of asides that
    provide commentary and additional info. The [longest one][assert] is a few
    paragraphs and they often need to appear right next to certain passages of
    text.

*   Of course, being a programming book, we've got lots of code samples. Those
    need to be fairly wide so you don't have to wrap the lines very much.

[assert]: http://gameprogrammingpatterns.com/singleton.html#to-limit-a-class-to-a-single-instance

The code is particularly tricky. I like a pretty large line height (think
single- versus double-spaced) for prose, but code looks wrong if you spread it
out that much. Most grids use a single line height for the vertical rhythm of
the page, but that wouldn't work for both prose and code (or for the asides for
that matter).

After days of tinkering -- wonderful, relaxing, therapeutic, tinkering -- I had
something I liked. To get there, I picked a random chapter and mocked it up. You
can't design a layout without something to lay out, and I believe the design
should take into account the actual content, so no *lorem ipsum* for me. I ended
up with this:

<figure>
  <img class="framed" src="/image/2014/11/grid.png">
  <figcaption>Mmm.</figcaption>
</figure>

Three 2&quot; columns with a &frac14;&quot; gutter, two for the main text and
one for the asides. I used the same spacing vertically for large elements like
headers on chapter title pages.

For the main vertical rhythm, I came up with a fractional line height. The core
baseline was 4.5&thinsp;pt. Prose fell on every third line, and code and aside
every second. That let the latter snuggle in a little tighter while still having
some semblance of a vertical cadence across the entire page:

<figure>
  <img class="framed" src="/image/2014/11/lines.png">
  <figcaption>9&thinsp;pt for code and asides, 13.5&thinsp;pt for
  prose.</figcaption>
</figure>

I set up a running footer, and designed the section and chapter headers. Not
gonna lie, I was pretty pleased with myself. There may have been some
celebratory drinking.

## Oh no, XML again?

Once I had my grid and fonts, all that was left to do was typeset the whole
book. That meant bringing in all of the text. I couldn't just copy and paste the
web pages into InDesign. I'd already carefully authored (in Markdown) emphasis,
bold, lists, headers, subheaders, etc. I did *not* want to start from plaintext
and do that all over again.

Fortunately, InDesign has a feature called "XML import". You can take an
arbitrary XML document, import it to InDesign, and automatically map XML tags to
paragraph and character styles you've created in InDesign. Unfortunately, this
feature seems to have been implemented by a narcoleptic intern who sidestepped
any code review process.

It's one of the buggiest pieces of nominally commercial-grade software I've ever
used. I, on more than one occasion, managed to get it to completely corrupt an
InDesign file beyond repair. (Fortunately, help was just a `git reset` away.)

I cracked open my little Python script and hacked it up to convert the Markdown
to HTML and then, through an unholy series of regexes, mash that into something
approximating XML. Stuff like:

```python
def clean_up_code_xml(code):
  # Ditch most code formatting tags.
  code = re.sub(r'<span class="(k|kt|mi|n|nb|nc|nf)">([^<]+)</span>',
                r"\2", code)

  # Turn comments into something InDesign can map to a style.
  code = re.sub(r'<span class="(c1|cn)">([^<]+)</span>',
                r"<comment>\2</comment>", code)
```

And:

```python
def clean_up_xhtml(html):
  # Ditch newlines in the middle of blocks of text. Out of sheer
  # malice, even though they are meaningless in actual XML, InDesign
  # treats them as significant.
  html = re.sub(r"\n(?<!<)", " ", html)

  # Also collapse redundant whitespace.
  html = re.sub(r" +", " ", html)
  html = html.replace("> <", "><")

  # Re-add newlines after closing paragraph-level tags.
  html = html.replace("</p>", "</p>\n")
  html = html.replace("</h2>", "</h2>\n")
  html = html.replace("</h3>", "</h3>\n")
  html = html.replace("</li>", "</li>\n")
  html = html.replace("</ol>", "</ol>\n")
  html = html.replace("</ul>", "</ul>\n")
  html = html.replace("</pre>", "</pre>\n")
  html = html.replace("</aside>", "</aside>\n")
  html = html.replace("</blockquote>", "</blockquote>\n")

  return html
```

Forgive me Father, for I have sinned. In my defense, I wasn't writing a program
to convert *any* HTML to XML. As long as it worked on the 90k words of *my*
book, it was Correct&trade; as far as I'm concerned. This gave me a folder full
of more-or-less XML files, one for each chapter. All that was left was to
typeset them.

## I'm a designer!

Starting at chapter one, [the introduction][intro], I imported its XML into
InDesign. Then the work started. Each aside had to be pulled out of the main
body text, restyled, and put into the sidebar. I only wanted leading indentation
on paragraphs that followed previous ones, so every "first" paragraph that
followed a header or code sample needed to be styled. I could never get lists to
work in the XML, so I restyled all of those manually.

[intro]: http://gameprogrammingpatterns.com/introduction.html

Then the real work started. I redid every illustration to look sharp in a
black-and-white, high resolution medium. I brought all sixty-something of them
into Photoshop, removed the graph lines, upscaled the hell out of them, did some
shenanigans to smooth the edges (but not *too* smooth since that's part of their
charm) and then saved them as 2400 DPI TIFFs:

<figure>
  <img class="framed" src="/image/2014/11/illustration.png">
  <figcaption>Original web version on the left, upscaled and monochrome print version the right.</figcaption>
</figure>

Then the real, hard work started. You see, all of that is just grunt work. You
could probably get it done on Mechanical Turk if you wanted to, or just [let
Knuth solve it][knuth] with some clever dynamic programming. Where the *art*
comes into play is dealing with this one little problem: *where do you put the
page breaks?*

[knuth]: https://www.tug.org/TUGboat/tb21-3/tb68fine.pdf

First off, you want to minimize [widows and orphans][] -- things like when
the last line of a paragraph is at the top of the next page. InDesign can
automate this, and even handle more complex rules like:

[widows and orphans]: http://en.wikipedia.org/wiki/Widows_and_orphans

*   Keep headers with at least a line or two of the paragraph that follows them.

*   Don't let a block of code be split across pages at all.

*   If a code block follows a paragraph of body copy, keep at least the last
    line of the body text with the code.

This stuff is why people get all excited about InDesign. It rocks.

But, once I set up all of those rules, I discovered I'd basically turned
InDesign into HAL 9000. Except, instead of refusing to open the pod bay doors,
what it was forced to do was break a lot of things really *early*.

You see, once I set up all of these rules, the result was that big chunks of
text -- headers, body text, and code -- were all inseparably glued to each
other. Since I told InDesign not to split in the middle, the only thing it could
do was move the whole kit and caboodle to the next page, leaving a huge blank
area at the bottom of the previous page, like:

<figure>
  <img class="framed" src="/image/2014/11/space.png">
  <figcaption>Most of the left (verso) page is wasted space.</figcaption>
</figure>

There's no magic bullet to fix this. I just took it a page at a time and tried
to organize and distribute the whitespace as nicely as I could. Usually, I could
fill in a gap in one page by pushing a bit of stuff from earlier pages down.
Other times, I'd tweak the code to shave off a line or two, just enough to get
it to fit. On occasion, I'd break code samples into separate pieces so it could
span pages.

See for yourself:

<figure>
  <iframe width="560" height="315" src="//www.youtube.com/embed/4_4Uw_9ZMIs" frameborder="0" allowfullscreen></iframe>
  <figcaption>Now imagine this playing back 24 times slower.</figcaption>
</figure>

It was tedious, challenging work. I started on June 19th. Working every single
day, I reached the end of the last chapter [exactly two months later][log].
There was more drinking.

[log]: https://github.com/munificent/game-programming-patterns/blob/60a4f3ebf49d7c24aa8ffc3100d48d0e2486039f/note/log.txt#L39-L92

## Baby got back (matter)

So, the print edition was done, right? Nope! Real books aren't just a pile of
chapters. They've got a copyright page, title page, table of contents, and all
sorts of stuff like that. The bits of those that come before the meat of the
book are called *front matter* and the rest are, obviously, *back matter*.

I spent a few more days designing a table of contents. (I just had to make it
pretty. InDesign handled actually filling it in.) I wrote a copyright page, and
[acknowledgements][], even a dedication:

[acknowledgements]: http://gameprogrammingpatterns.com/acknowledgements.html

<figure>
  <img class="framed" src="/image/2014/11/dedication.jpg">
  <figcaption>Showing this page to my wife was one of the highlights of this
  whole adventure.</figcaption>
</figure>

Then I moved onto the back matter. I guess a non-fiction book should have an
index, right? Where's the "automatically index my whole book button?" What's
that? There isn't one? Well... *shit*.

InDesign *can* create an index for you, bless its little heart, but it doesn't
actually know English. You have to sprinkle the index references throughout your
book. What it does is figure out what pages those references are on and builds
the list of index entries at the end.

I spent two weeks going over the entire book *again*, adding index entries for
anything I could imagine someone wanting to look up. I don't promise that it's a
great index, but it *is* an index, God dammit.

While I was at it, I cross-referenced the whole book. See, the web version has
these magical things called "hyperlinks". When one chapter mentions a concept on
another one, you can "click" them with your "mouse" and the computer takes you
straight to the referenced chapter! It's like living in the future but with less
Stallone and Wesley Snipes homo-erotically punching each other.

Paper, alas, does not support web standards. Instead you just put "(see page
123)" and the reader, poor plebian, has to manually turn to that page theirself.
You can create cross references in InDesign and it will automatically track the
referenced section and keep the page number up to date. I found every place
where there was a link in the web version and manually created a
cross-reference.

## Getting my grubby paws on it

Phew! Book production is a lot of work! But this was finally nearing the end! I
printed the whole book, all three-hundred-plus pages of it on my laser printer.
It was heavy! I made a big heavy thing all by myself. Full of words!

I went to the store and bought a red pen. I proofread every single page. I read
my book, on paper. It, finally, after all these years, started to feel like a
real thing.

<figure>
  <img class="framed" src="/image/2014/11/pages.jpg">
  <figcaption>This took a while to print.</figcaption>
</figure>

I went back and fixed everything that got the red pen treatment, mainly just
minor formatting bugs, then I exported a PDF. (Brief interlude where I zoom in
1000% and drool over Sina Nova again.) I uploaded it to CreateSpace. Oh boy oh
boy oh boy.

Oh, crap. I'm not done yet. I forgot the cover!

## Cover me, I'm going in!

If you go by self-publishing blogs, designing a cover is the hardest, most
important, most agonized over, most terribly done part of book writing. For
every blog post telling you how important it is to not screw it up, there are a
hundred self-published books whose cover is some amalgamation of
still-watermarked screen-res stock photography, fonts that come pre-installed on
Windows 95, and a design aesthetic clearly based on the belief that if one drop
shadow is good, ten must be better.

I didn't want to be that guy.

To check myself, I spent some time looking at other game programming book
covers. I even made a little page of thumbnails so I could put my cover mockups
in there to see how they compared:

<figure>
  <img class="framed" src="/image/2014/11/thumbnails.jpg">
  <figcaption>Where's my book hiding in there?</figcaption>
</figure>

There's a delicate art to crafting a design that gets the reader's attention,
but not in that, "What the hell was he thinking?" way.

The cover I'd had in the back of my head for a long time was something
hand-drawn. The book is full of little flowchart-y illustrations, and I like how
their informality contrasts with the technical content of the book.

After trying a bunch of different mocks for other ideas, I spent an afternoon
drawing one big illustration that combined a bunch my favorites from the book. I
took a ton of photos of it at different angles with a macro lens and then tried
to find a composition for the text that I liked. You can see the evolution here:

<figure>
  <img class="framed" src="/image/2014/11/covers.jpg">
  <figcaption>In chronological order.</figcaption>
</figure>

Hopefully, you don't hate the final one too much.

## My esteemed publisher

Oh, I left out one piece of the puzzle! Look on the bottom right corner of those
mocks. See that? Here, look closer:

<figure>
  <img class="framed" src="/image/2014/11/gb.jpg">
  <figcaption>A little logo.</figcaption>
</figure>

To publish a book, you need an *ISBN number*. CreateSpace can give you a free
one, but then you can't use that anywhere else, and it associates the
"publisher" of that number with CreateSpace, which felt weird to me. I'd also
need separate ISBN numbers for the two e-book versions.

ISBNs work a bit like domain names. Each country has an appointed registrar --
the company who is allowed to distribute ISBNs to publishers in one country. In
the US, that's [Bowker][].

[bowker]: https://www.myidentifiers.com/

It's a pretty smart racket. They basically just hand out IDs, a process that
could be automated with five lines of Perl code and a copy of Apache running on
an Arduino. In return for that, they get to charge you $125 for a single ISBN
number. Or you can get 10 for $275. Since everyone publishes both print and
e-book versions, you basically always get the 10-pack. They know what they're
doing.

It's certainly the most money I've ever paid for 130 digits, but whatever. I
sent them my credit card deets and started filling out the form. Whereupon I
reached a *mandatory* field for "publisher". Apparently, "Yours Truly", "I Just
Did It Myself", "Fake Vanity Press", and "Can't I Just Skip This?" are not valid
values for that field.

There was only one thing to do: *It's business time.* I got myself a business license. I am a real deal publisher. Look, it says so right here:

<figure>
  <img class="framed" src="/image/2014/11/license.jpg">
  <figcaption>I guess this blog means I've now posted this conspicuously?</figcaption>
</figure>

Now, when I was looking at other game programming books, I saw a bunch of others
that were clearly self-published. The dead giveaways were "publishers" that were
either (a) the author's name or an anagram of such, (b) obviously the name of a
pet, or (c) one of the "we'll give you an ISBN for free" companies.

I don't think there's anything wrong with self-publishing, obviously, but it
does carry a stigma to some readers. I don't want them to see a jokey
"publisher" and think the book is some amateur hour affair. While my writing
style is light-hearted, I actually do take the content seriously.

Older, established publishers tend to agglomerate over time yielding titles like
"Harcourt, Brace & Howe", "Harcourt Brace Jovanovich", "Reed Elsevier", and
"Houghton Mifflin Riverdeep". So I picked two stuffy-sounding names and stuck
them together. Then I debated how to join them&mdash;"+" (too mathy), "\|" (too
'90s), "-" (hyphen, en-dash, or em-?), and "/" (too much like a boxing
match)&mdash;before finally settling on just a plain space.

<figure>
  <img class="framed" src="/image/2014/11/genever-benning.png">
  <figcaption>I even drew a logotype, just for kicks.</figcaption>
</figure>

Although, for the record, I *did* still name it after my pets. I just took their
names -- Ginny and Benny -- and classed them up. As the CEO and CFO of the
Genever Benning empire, they are skilled executives, though a bit prone to
farting in board meetings.

## Upload it, already!

OK, so we've got typeset chapters, front matter, back matter, a cover, ISBN
numbers, a camera-ready PDF. All systems are go go go! I uploaded everything to
CreateSpace, waited for their "manual" review process to complete and ordered a
couple of proof copies.

The next few days were like waiting for Santa and then... in his traditional
brown UPS suit, Santa arrived! The cover looked great! The back cover was even
better than I'd hoped! (Sorry, you'll have to get your hands on a copy to see
it.) The binding looked solid! It looked like a professional quality book! I was
super pumped!

Imagine you muster up the courage to crawl out of your nerd hole and ask the
captain of the cheerleading team to go to prom with you. Wonder of wonders, she
says "yes"! That's how I felt.

With my wife looking over my shoulder, I cracked it open.

Then imagine you look that cheerleader in the eye and the realization crawls
down your spine that her "yes" was laden with sarcasm you missed the first time
around. She would never in a million years go to prom with you.

Somehow, despite my meticulous measuring and scrupulous adherence to
CreateSpace's guidelines, my layout was bad. The text was too small. The top
margin too short. Worst of all, the inner margin was too narrow, making it hard
to read text near the spine.

*Merde.*

## OK, let's do it all again

As you surely realize by now, changing any of the metrics of the book is a huge
undertaking. Sure, you can just edit the master and all of the pages update. But
that in turn affects how the text wraps, which then totally undoes all of my
careful fitting of blocks of stuff onto different pages. That grueling two-month
period where I laid out each page? Out the window now.

I went back to the drawing board. I cracked open the master. I started
re-measuring things. Part of the problem was that (unsurprisingly) I'd
over-constrained myself. In addition to needing decent margins, a good-sized
sidebar, and the right line height, I also wanted measurements that were
relatively round numbers. A column width of 1.35728261&quot; is no fun to work
with.

In the process of rounding some of those measurements to the nearest nice round
number, I'd strayed away from actual good metrics. After bumping up the text
size a bit, I spent days trying to come up with a column width, gutter size, and
line height that would fit within the page margins and be easy to read.

Eventually, I found a way out: decimal inches. Most of my print work has used...
shall we say... imperial measurements? Things like 16pt or 3/16&quot;. In other
words, usually some power of two fraction of an inch. But that's not the only
option. You can go French revolution and actually do things like 1.3&quot;.
InDesign won't bat an eye at it.

After a bunch of monkeying around, I found a new grid. Instead of a vertical
grid where prose is every three grid lines and code is every two, I bumped the
fraction to 3/4. This opened up the code and asides a bit relative to the text.
I brought down the top margin and gave myself more than enough breathing room
near the spine.

All that was left to do was update all of the pages. By this point, I was angry
and fired up. I was *so close* to thinking the book was done and I just wanted
it to be over. I *burned* through those pages, working on them practically every
waking moment. This time, I got the whole three-hundred-something pages done in
a week:

<figure>
  <iframe width="560" height="315" src="//www.youtube.com/embed/ikirNuS7jrI" frameborder="0" allowfullscreen></iframe>
  <figcaption>Fortunately, years playing Pokemon have given me fantastic
  grinding skills.</figcaption>
</figure>

I uploaded a new PDF, crossed my fingers and waited for the new proof to arrive.
When it did... God what a sigh of relief. It looked fine. Totally readable.
Hallelujah.

That readability was great because it made it much easier for me to notice all
the dumb mistakes I'd made in my hurried re-layout. Somehow, I'd managed to
break all of the cross references, and sprinkle typos through much of the code.
I did *another* proof-reading pass on the actual proof:

<figure>
  <img class="framed" src="/image/2014/11/postits.jpg">
  <figcaption>Every note is a mistake.</figcaption>
</figure>

I fixed those, and uploaded it again. And... that's it. I know there are still
mistakes lurking in there, and thinking about them *kills* me. But, at some
point, the value of getting the damn thing in people's hands outweighs the value
of trying to keep making it better.

## Kicking it out the door

The print edition was done, and I made a slew of final changes to the e-book
versions -- mainly getting the cover in and working. Finally, only three things
were left to do:

1.  Redo the front page of the site to mention the new formats.

2.  Upload everything to the various market places and put them on sale.

3.  Write this blog post.

If you're reading this, it looks like I got those done too! You can see for
youself:

*   **The [new site][gpp].**

*   **The [print version on Amazon][print].**

*   **The [Kindle version][kindle].**

*   **The [e-book at Smashwords][smash].**

[print]: http://www.amazon.com/dp/0990582906
[kindle]: http://www.amazon.com/dp/B00P5URD96
[smash]: https://www.smashwords.com/books/view/489921

iBooks should be coming soon but Apple is busy manually reviewing erotica
submissions so it may be a few weeks and I was too impatient to wait for that.

This whole production ended up taking six months. It was a ton of work, but I
don't regret doing it. For better or worse, I can now hold this book and know
that it's *mine*. From cover to cover, every word, picture, and bit of ink was
up to me. I had a ton of help from my copy editor and from every kind reader who
sent a bug report or pull request, and the book is immensely better thanks to
their input. But, ultimately, the *decisions* were all mine.

What I'm feeling now is a curious mixture of relief, gratitude, and trepidation.
Relief that it's done and I actually pulled off completing a large project.
Immense gratitude to everyone who encouraged me to keep going. I know I wouldn't
have finished without that.

But, finally, trepidation. People -- you -- have been really supportive of the
book, which is truly the best feeling in the world. But there's a big difference
between *saying* you like the book and *spending cold hard cash on it*. I've
never written this for the money, but the number of copies it sells will, in
some ways, legitimize it in my mind. And that's entirely outside of my control
now.

I feel like I'm walking on stage, alone, squinting through the footlights to see
if there's anyone in the audience.
