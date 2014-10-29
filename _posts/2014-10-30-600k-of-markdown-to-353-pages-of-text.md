---
layout: post
title: "Zero to 353 Pages: Bringing My Web Book to Print (and eBook)"
categories: book game-dev design
---

Now that I'm nearing the end, it's hard to know where to start. If you're coming at this cold (hi, new reader!), you might want to read my [previous post on the book] first. The TL:DR; is that I wrote a book on Game Programming. But, by "book", I really mean "book-length manuscript that you can read on the web". It's about ninety thousand words and some HTML and CSS window dressing.

**TODO: link**

This post is about how I took that 587,920 bytes and turned it into this:

**TODO: book**

Oh, and this too:

**TODO: ebooks**

Remember on Mr. Rogers Neighborhood where they would take a trip to a factory to see how live baby pigs are turned into hotdogs or something? (Maybe I'm mistaking Mr. Rogers Neighborhood for my nightmares.) Either way, this is like that, but less incarnadine.

## Where it Starts

We'll pick up right where we left off. On April 22nd, I finished the third draft of the last chapter of the book. The next day, I uploaded it, slapped together a blog post, and milked it for all it was worth on all the social networks. I mean, uh, quietly told a few friends.

Of course, "done" apparently means "riddled with bugs", so I spent the next week or so fixing all of the dumb obvious mistakes that the raft of new readers noticed. Once that settled down, I moved straight into the next phase: *Operation: Print and Ebook Editions*.

By "straight", I really mean without interruption. Like I mentioned in the last post, I work on the book every single day. Not breaking the chain has somehow been just enough of a mindtrick to get me to overcome my usual inability to finish anything bigger than breakfast. By this point, I was actually superstitious about breaking it. I really wanted to hold the physical book in my hands, so until that was done, I was afraid to take even single day's break.


**TODO: turtles**


## More Revisions, Really?

The first step was doing yet another editing pass over the manuscript. At this point, I'd done three drafts of each chapter, in addition to a pile of bug fixes sent in by readers. But once ink has been put on paper, it's a lot harder to fix mistakes, so I wanted to give it one more round of scrutiny.

This was also, interestingly, the first time I'd read the book *in order*. The chapters are sort of like recipes and are relatively unconnected, and I wrote them out of order. Everytime I finished a chapter, the next one I started was the one that seemed like the most fun right then.

Now, I went through it front to back. That revealed places my style, voice, and structure had drifted over the five years I spent writing. (Pro tip: don't take five years to write a book.) I spent a couple of weeks on this.

Next, I planned to hire a freelance copyeditor to do a pass over it. I wasn't sure how to find one, but with timing so uncanny you'd scoff if it happened in a movie, Lauren Briese emailed out of the blue the day I started looking for one. I threw some cash at her and she found dozens of mistakes that I still managed to miss.

## eBooks, Ugh

I'm going to mix up the chronology here and talk about the eBook version first. In reality, I interleaved working on this and the print version and going back and forth over chapters with Lauren. The eBook stuff is (I think) was less exciting than doing the print design, so let's just get it out of the way.

I was actually in really good shape for this. I wrote the book using markdown, then wrote a little Python script that took those files, some CSS and an HTML template and spit out the web site for the book.

**TODO: link**

If you've never done eBook stuff before (you lucky devil, you), they come in two main formats, EPUB and MOBI. Kindle uses MOBI, as some sort of gigantic distributed prank against the entire author community, and the rest of the world uses EPUB.

An EPUB file is a zipped up directory containing a web site. Seriously. Take your static site and run this on it:

**TODO: format**

cd my_awesome_site
zip -X0 my_awesome_site.epub mimetype
zip -Xur9D my_awesome_site.epub *

And you're 90% of the way to having an eBook. It's the other 90% that makes you want to claw your eyes out.

See, eBooks are a lot of like web sites... circa 2003. Instead of this fancy HTML5 stuff which is clearly, like, living in the future with all of its new tags that don't need to be closed, EPUB requires XHTML, the evil mutant offspring of HTML and XML. The turducken of the markup world.

Worse, eBook readers handle CSS about as well (and as compatibly) as Netscape and IE4 did. If you lived through the horror show that was being a web designer in the '90s where you had seven browsers open all day, you know what I'm talking about.

Except that now each of those "browsers" is a separate physical device that you have to jump through hoops to get your "site" on. Since each <strike>anti-competitive corporate walled garden</strike> delighfully unique device wants to provide its own "eBook library management", none of them are optimized for just opening a damn file that changes every five minutes. In iBooks, you have to right-click and delete the book from your library before you can add it again.

Getting an updated .mobo file on my Kindle involved some combination of DropBox, an Android file manager, going to the Amazon website to delete the previous version, emailing myself from a mysterious email address granted me by Amazon, waiting for the Kindle app to crash a few times, and, on occasion, blood sacrifice.

The things I do for love.

Oh, and did I mention the XML? SO MUCH XML. The EPUB format was clearly written by uptight pencil-pushers horrified by the chaos of the web. I'm not even kidding. You can tell they *tried* to write a dry spec, but their anal-retentiveness and smug sense of superiority drips from between every "MUST" and "SHALL".

**TODO: link http://idpf.org/epub **

You need a `content.opf` XML manifest that lists every file in your eBook. And a `container.xml` manifest that points to your `.opf` manifest. Your manifests have manifests.

The `.opf` file has a `<spine>` tag containing the ordered list of stuff in the book. And a `<guide>` containing... an ordered list of the stuff in the book. Also, there's a separate, mandatory, `toc.nxc` file containing, you guessed it, an ordered list of the stuff in the book. Not only that, each item in the TOC is not just in order but *manually numbered*:

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

See those little `playOrder` attributes? It's like double-entry bookkeeping, but without all of the fun and excitement of double-entry bookkeeping.

But, despite my ranting here, it's pretty easy. Sort of like counting to a thousand by hitting `+` and `1` over and over on your calculator. Once you've got a happy little EPUB file, you can throw it at "KindleGen", a lovable curmudgeon of a program that Amazon gives out, and it begrudgingly converts it to a MOBI for you.

**TODO: EPUB and MOBI files**

If you ignore the fact that it took about a hundred iterations to please the EPUB and MOBI validator Gods, this was straightforward. Now let's talk about the fun stuff.

## My Dirty Little Secret

Warning: I'm going to get embarrassingly effusive about design stuff. If you keep reading, it will be like watching two of your best friends who after years of awkward sexual tension finally hooked up and now aren't so much showering you with public displays of affection as they are public displays of the mating ritual of *Homo sapiens*. I really *really* like fonts.

Here's the thing. When I first first started writing the book, I wrote a little promise to myself in my pink locked diary that I never show anyone. (Except now you, I guess, Dearest Reader.) That promise was, "If I can finish writing this whole damn manuscript, I will let myself typeset it."

I know that probably sounds strange but if you haven't figured out I'm a bit off center by now, you must be skimming this post for the pictures.

Most of my life, I had one cranial hemisphere in the artist bucket and one in the logical bin. I really like drawing pictures. Usually on graph paper.

I started my career as a computer animator then a web designer, then a UI designer, then a part-time UI programmer, then a full-time UI programmer, then a tools programmer, and finally just a programmer. My left brain metastasized and took over pretty much the whole light show upstairs.

I love programming, and I'm happy to spend almost all day doing stuff that's not that visual, but, God, sometimes I really miss type and color and form. So, if I could complete this monument to abstract logical thought, I would reward myself by fully basking in visual design.

## Oh, God, You Mean I Get To Pick a Page Size?

Most of the design I have done in the past decade has been for the web. There's a lot to like about web design, but it's a bit like body painting. No matter how steady you are with your airbrush, the medium you're working on is inherently squishy.

When you can't trust the user not to futz with the size of their browser window or even control what fonts they have access to, it's hard to design something that looks exactly the way you want.

But, *print*, now that's a different story.

The first thing I did was decide how big the pages would be. Let me repeat that for you web folks: I, the designer, got to pick the page size.

Because Amazon is the giant gorilla of the publishing industry and CreateSpace is its cuddly orangutan buddy, I decided to go with that for handling the print-on-demand production of the book. They have a few different page sizes you can pick from.

I grabbed a bunch of programming books I had nearby, took my ruler out, and measured those suckers. I wanted my book to be like a real programming book, and that starts with dimensions. I settled on **___** and As It Was Written, So Shall It Be Done.

**TODO: link**

**TODO: size**

## Fonts, Fonts, Fonts

Now that I knew how big my canvas was, it was time to start painting it. And, for a book, that means fonts. Sweet, delicious, heavenly fonts.

As a web designer, I was used to (paraphrasing Henry Ford here) having any serif font I wanted, as long as it was Georgia. (And I remember the days *before* Georgia. Thank God Matthew Carter saved us from that hell hole.)

Google Web Fonts turned things up a notch, but once you filter out all of the fonts on there that don't have italics, or have shitty metrics, or incomplete character sets, or only one weight, what you're left with is... well, Georgia starts looking pretty good again.

But, now. Now! I could just *go out and buy a fucking font and then use it*. Any font I want! It was intoxicating. Incredible. Overwhelming. Paralyzing.

I spent several nights in an opiate fugue going through dozens of serif (for body copy), sans serif (asides and headers), and monospace (code, naturally) fonts. For all I know, it could have been weeks. Time had lost all meaning.

When I came too, I had a beard and three fonts:

* Source Sans Pro
* Source Code Pro
* Sina Nova

**TODO: link**

The first two, ironically, *are* web fonts, and are what the site uses. I don't know if that's a bit of great branding on my part or just a failure of imagination. But I think Adobe really hit it out of the partk with Source Code Pro&mdash;even when in print&mdash;and it pairs just as perfectly with Source Sans as the name would lead you to believe.

That just left a body font, the most important font in the book. Like I do, I over-constrained the hell out of it:

* It had to have a relatively small x-height. I'm not a fan of the modern trend of really big x-heights in serifs, especially in print. They just look like a seventh-grade girl's handwriting to me, *sans* hearts over the `i`s. If I'm going to print this bad boy at 2400 DPI, we can handle some nice small bowls.

* At the same time, the x-height can't be *too* small. The book has `inline code` pretty frequently, and the body and code fonts need to have roughly similar vertical metrics for that to not look like Danny DeVito and Arnold Schartzenegger in Twins.

* I love Old Style serifs. Garamond, Jenson, Bembo, et. al are my homeboys. Low contrast in line thickness, angled stress and a bit of humanist irregularity, aww yiss. Sorry, Bodoni, but you can kiss my ass with your little wimpy verticals.

* But a font that looks *too* calligraphic will clash horribly with the modern sans serif font used for the asides and, even moreso, the code. A page should look like a cohesive whole. That won't happen if half the letters look like they were put down by a medieval scribe's quill pen while the other half were machined out by a robot.

If you distill that down, what I really wanted was a font with the *metrics* of an Old Style, but the letterforms of a more modern, cleaner typeface.

Finally, to balance that all out, a couple of heavier weights that reach out of the page and punch you, but in a friendly punch-on-the-arm sort of way. And, of course, an italic that triggers a damn near synthesthetic response in me. Seriously, just thinking about italics brings to mind the electric tickle of a battery on my tongue.

Did I mention I really like fonts?

After days of searching, lo and behold, I found just such a font. My Manic Pixie Dreamgirl in OpenType Format. *Sina Nova.*

Sina Nova, light of my life, fire of my loins. My sin, my soul. Si-na No-va: the tongue taking a trip of fours steps down the palate to tap, at four, on the teeth. Si. Na. No. Va.

**TODO: screenshot**

If I had any shame left at this point, I'd blush at how often I would zoom in to 1000% on a page just to see how a a paragraph of it hung together. Dieter Hofrichter is a genius as far as I'm concerned. I get tired of everything, and I'm still not tired of Sina Nova.

I had assembled my army, now it was time to draw battlelines.

## So Many Grids

Some people fantasize about building roller coasters in their backyards or being smothered in puppies. I've always dreamt of coming up with an honest-to-God grid system.
**TODO: links!**

I've tried to approximate them for the web but it always ends up not working and leaving me feeling sullied in some hard to pin down way. Not this time. I had a brand new copy of InDesign, and I wasn't afraid to use it!

For those who don't know, a grid system is a way of organizing the content (words and pictures) on a page. You come up with the dimensions of an invisible grid that overlays the page and everything slots within those. When done well, everything on the page floats in placid harmony like a zen garden.

Coming up with a good grid, especially for this book, was quite hard. I had a bunch of constraints:

* Of course, it has to take into account the page size, and the margins. Wider margins on the inside so you don't get to close to the spine. We're an actual book now!

* If you've read any of the book, you it's full of asides that provide commentary and additional info. The longest one is a few paragraphs and they often need to appear right next to certain passages of text.

* Of course, being a programming book, we've got lots of code samples. Those need to be fairly wide so you don't have to wrap the lines very much.

The code is particularly tricky. I like a pretty large line height&mdash;think single- versus double-spaced&mdash;for prose, but code looks wrong if you space it out that much. Most grids use a single line height for the vertical rhythm of the page, but that wouldn't work for both prose and code (and for the asides for that matter).

After days of tinkering&mdash;wonderful, relaxing, theraputic, tinkering&mdash;I had something I liked. To get there, I picked a random chapter and mocked it up. You can't design a layout without something to lay out, and I believe the design should take into account the actual content, so no lorem ipsum for me.

What I ended up with was this:

**TODO:original grid**

Three columns with a **__** gutter between them. **__** inner margin, **__** outer. For the vertical grid, what I came up with was a fractional line height. I used a **__** vertical grid. Prose lines were every three of those, and code (and aside) lines every two. That let the code snuggle in a little tighter while still having some semblance of a vertical rhythm.

**TODO: screenshot of prose and code with baseline grid**

I set up a running footer, and designed the section and chapter headers. Not gonna lie: I was pretty pleased with myself. There may have been some celebratory drinking.

## OH NO, XML Again?

Once I had my grid and fonts, the next step was to set up a few *master pages*. You can think of them sort of like a template. If you're a programmer, masters are your classes, and each real page is an instance of one. The idea is that this lets you later make changes to the master which then percolate automatically through your pages.

All that was left to do was typeset the whole book. That meant bringing in all of the text. I couldn't just copy and paste entire web pages into InDesign. I'd already carefully authored (in markdown) emphasis, bold, lists, headers, subheaders, etc. I did *not* want to start from plaintext and do that all over again.

Fortunately, InDesign has a feature called XML import! You can take an arbitrary XML document, import it to InDesign, and freely associate the styles you've created in InDesign with different tags.

Unfortunately, this features seems to have been implemented by a narcoleptic intern with a propensity for shorting Adobe **TODO: ticker** stock. It's one of the buggiest pieces of ostensibly commercial-grade software I've ever used. I, on more than one occasion, managed to get it to completely corrupt and InDesign file beyond repair.

(Fortunately, help was just a `git reset` away. You're damn right I put this all in git! It's the first time I've ever created a 471.4MB `.git` directory. Binary files don't diff very well.)

But, once again, my little Python script came to the rescue. I hacked it up to convert the markdown to HTML and then through an unholy series of regexes, mash then into something approximating XML.

Stuff like:

  def clean_up_code_xml(code):
    # Ditch most code formatting tags.
    code = re.sub(r'<span class="(k|kt|mi|n|nb|nc|nf|nl|o|p)">([^<]+)</span>',
                  r"\2", code)

    # Turn comments into something InDesign can map to a style.
    code = re.sub(r'<span class="(c1|cn)">([^<]+)</span>',
                  r"<comment>\2</comment>", code)

And:

  def clean_up_xhtml(html):
    # Ditch newlines in the middle of blocks of text. Out of sheer malice,
    # even though they are meaningless in actual XML, InDesign treats them
    # as significant.
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

**TODO: highlight**

Forgive me Father, for I have sinned.

In my defense, I wasn't write a program to convert up *any* HTML to XML. As long as it worked the 90k words of my book, it was Correct&tm; as far as I'm concerned.

That gave me a folder full of more-or-less-decent XML files, one for each chapter. All that was left was to typeset them.

## I'm a Designer!

Starting at chapter one, the introduction, I cloned my template InDesign file, imported that chapter's XML and then dropped it onto the pages. Then the real work began. Each aside had to be pulled out of the main body text, restyled, and put into the sidebar. I only wanted leadining indentation on paragraphs that followed previous ones, so every "first" paragraph that followed a header or code sample needed to be styled. I could never get the lists to work in the XML, so I just restyled all of the bullet and number lists manually.

Then the hard work started. I needed to redo every illustration to play nice in a black-and-white high resolution medium. I brought all sixty-something of them into Photoshop, removed the graph lines, upscaled the hell out of it, did some shenanigans to smooth the edges (but not *too* smooth since that's part of their charm) and then saved them as 2400 DPI TIFFs. I brought those back into InDesign, placed them in the right spot, and added captions.

Then the real hard work started. You see, all of that is just grunt work. You could probably get it done on Mechanical Turk if you wanted to. Or just let Knuth solve it with some clever dynamic programming. Where the *art* comes into play is dealing with this one little problem: *where do you put the page breaks?*

**TODO: TeX**

First off, you want to minimize [widows and orphans](http://en.wikipedia.org/wiki/Widows_and_orphans)&mdash;things like when the last line of a paragraph is at the top of the next page. InDesign can automate the easy stuff. Tell it you don't want your body text paragraph style to allow a single line on its own, and it will ensure the last line drags a line or two with it when it gets wrapped to the next page.

You can&mdash;and I did&mdash;do powerful stuff like, "Make sure a header always stays with at least a line or two of the paragraph that follows it". And, "Don't let a block of code be split across pages at all", and "if a code block follows a paragraph of body copy, keep at least the last line of that with the code." This is why people get all excited about InDesign. It rocks.

But, once I set up all of those rules, I discovered I'd basically turned InDesign into HAL 9000. Except, instead of refusing to open the pod bay doors, what it was forced to do was break a lot of things really early.

I'd have pages where the bottom half was blank because it couldn't jam a code block, and the paragraph before it, and the subheader all in the space. Since that stuff was glued together, the whole thing got schlepped to the next page, leaving a big nasty gap. Equally tricky problems happened with trying to get images to fit near the prose they related to, and dealing with long asides that were married to a bit of body text near the bottom of a page.

**TODO: illustration**

There's no easy answer for this stuff. You just take it a page at a time and try to organize and distribute the whitespace as nicely as you can. Sometimes you can fill in a gap in one page by pushing a bit of stuff from earlier pages down. Other times I'd tweak the code to shave off a line or two. Just enough to get it to fit. On occasion, I'd break code samples into separate pieces so it could span pages.

It was tedious, challenging work. I started on June 19th. Working every single day, I reached the end of the last chapter exactly two months later. There was more drinking.

**TODO: link to log range**

## Baby Got Back (Matter)

So, the print edition was done, right? Nope! Real books aren't just a pile of chapters. They've got a copyright page, title page, table of contents, and all sorts of stuff like that. The bits of those that come before the meat of the book are called front matter and the rest are, you guessed it, back matter.

I spent a few more weeks designing a table of contents. (I just had to make it pretty. InDesign handled actually filling it in.) I wrote a copyright page, and acknowledgements, even a dedication:

**TODO: links and dedication pic**

Then I moved onto the back matter. I guess a non-fiction book should have an index, right? Where's the "automatically index my whole book button?" What's that? There isn't one? Well... *shit*.

InDesign *can* create an index for you, bless its little heart, but it doesn't actually know English. You have to sprinkle the index referenes throughout your book. What it does is figure out what pages their own and build the list of index entries at the end.

I spent two weeks going over the entire book *again*, adding index entries for anything I could imagine someone wanting to look up. I don't promise that it's a great index, but it *is* an index, God dammit.

While I was at it, I cross-referenced the whole book. See, the web version has these magical things called "hyperlinks". When one chapter mentions a concept on another one, you can "click" them with your "mouse" and the computer takes you straight to the referenced chapter! It's like living in the future but with less Stallone and Wesley Snipes homoerotically punching each other.

Paper, alas, does not support web standards. Instead you just put "(see page 123)" and the reader, poor plebian, has to manually turn to that page theirself. You can create cross references in InDesign and it will automatically track the referenced section and keep the page number up to date. I found every place where there was a link in the web version and manually created a cross-reference.

## Getting My Grubby Paws On It

Phew! Book production is a lot of work! But this was finally nearing the end! I printed the whole book, all three-hundred-plus pages of it on my laser printer. It was heavy! I made a big heavy thing all by myself. Full of words!

I went to the store and bought some red pens.

**TODO: pens**

I proofread every single page. I read my book, on paper. It, finally, after all these years, started to feel like a real thing. I went back and fixed everything that got the red pen treatment, mainly just minor formatting bugs.

I exported a PDF. (Brief interlude where I zoom into 1000% again and drool over Sina Nova.) I uploaded it to CreateSpace. Oh boy oh boy oh boy.

Oh, shit. I'm not done yet. I forgot the cover!

## Cover Me, I'm Going In!

If you go by self-publishing blogs, designing a cover is the hardest, most important, most agonized over, most terribly done part of book writing. For every blog post telling you how important it is to not fuck it up, there are a hundred self-published books whose cover is some amalgamation of still-watermarked screen-res stock photography, fonts that come pre-installed on Windows 95, and a design aesthetic clearly based on the belief that if one drop shadow is good, ten must be better.

I didn't want to be that guy.

To check myself, I spent some time looking at other game programming book covers. I even made a little page of thumbnails so I could put my cover mockups in there to see how they compared. There's a delicate art to crafting a design that gets the readers attention, but not in that "what the hell was he thinking?" way.

I went through a bunch of mocks, some more baked than others:

**TODO: mocks**

But the idea I'd had in the back of my head for a long time was to do something more hand-drawn. The book is full of little flow-charty illustrations, and I like how their *human-ness* constrasts with the technical nature of the book. I spent a couple of afternoons drawing one big illustration that combined a bunch my favorite drawings from the book. The kind of thing I could imagine covering a whiteboard next to some aspiring game programmer's desk.

**TODO: pics**

I took a ton of photos of it at different angles with a macro lens and then tried to find a composition for the text that I liked. What I eventually settled on was:

**TODO: cover**

Hopefully, you don't hate that too much.

## My Esteemed Publisher

Oh, I left out one piece of the puzzle! Look on the bottom right corner. See that? Here, look closer:

**TODO: gb**

When you publish a book, you need an ISBN number. CreateSpace can give you a free one, but then you can't use that anywhere else, and it associates the "publisher" of that number with CreateSpace, which felt weird to me. I'd also need separate ISBN numbers for the two eBook versions.

ISBNs work a bit like domain names. Each country has an appointed registrar: a company who is allowed to distribute ISBNs to publishers in that country. In the US, that's Bowker.

**TODO: link**

It's a pretty sweet setup. They basically just hand out IDs, a process that could be automated with five lines of Perl code and a copy of Apache running on an Arduino. In return for that, they get to charge you $125 for a single ISBN number. Or you can get 10 for $275. Since everyone publishes both print and eBook versions, you basically always get the 10-pack. They know what they're doing.

It's certainly the most money I've ever paid for 130 digits, but whatever. I sent them my credit card deets and started filling out the form. Whereupon I reached a *mandatory* field for "publisher". Apparently, "Yours Truly", "I Just Did It Myself", "Fake Vanity Press", and "Can't I Just Skip This?" are not valid values for that field.

There was only one thing to do: *it's business time.* I got myself a business license. I am real deal publisher. Look, it says so right here:

**TODO: license**

Now, when I was looking at other game programming books, I saw a bunch of others that were obviously self-published. The dead giveaway was "publishers" that were either (a) the author's name or an anagram of such, (b) obviously the name of a pet, or (c) one of the "we'll give you an ISBN for free" companies.

I don't think there's anything wrong with self-publishing, obviously, but it does carry a stigma to some readers. I didn't want them to see a jokey "publisher" and think the book was low quality.

Older, established publishers tend to amalgamate themselves together over time giving use names like "Harcourt, Brace & Howe", "Harcourt Brace Jovanovich", "Reed Elsevier", and "Houghton Mifflin Riverdeep". (These are all names that just Harcourt has gone under at one point in time!) So I picked two stuffy sounded names and stuck them together. Then I debated how to join them: "+" (too mathy), "|" (too `90s), "-" (hyphen, en-dash, or em-?), and "/" (too much like a boxing match) for joining them before finally settling on just a plain space.

And, for the record I *did* still name it after my pets. My dog Ginny is named after the drink, whose historic name is "genever", and "benning" is a classed-up version of "Benny". What can I say? I couldn't resist.

## Upload it, Already!

OK, so we've got typeset chapters, front matter, back matter, a cover, ISBN numbers, a camera-ready PDF. All systems are go go go! I uploaded everything to CreateSpace, waited for their "manual" review process to complete and ordered a couple of proof copies.

The next few days were like waiting for Santa and then... in his traditional brown UPS suit, Santa arrived!

**TODO: proof**

The cover looked great! The back cover was even better than I'd hoped! (Sorry, you'll have to get your hands on a copy to see it.) The binding looked solid! It looked like a professional quality book! I was super pumped!

Imagine you muster up the courage to crawl out of your nerd hole and ask the captain of the cheerleading team to go to prom with you. Wonder of wonders, she says "yes"! That's how I felt.

With my wife looking over my shoulder, I cracked it open.

Then imagine you look that cheerleader in the eye and realized slowly creeps down your spine that he "yes" was laden with sarcasm you missed the first time around. Somehow, despite my meticulous measuring and scrupulous adherence to CreateSpace's guidelines, my grid was bad. And I felt bad.

The text was too small. The top margin too short. Worst of all, the inner margin was too narrow, making it hard to read text near the spine.

Well, crap.

## OK, Let's Do it All Again

As you can surely realize by now, changing any of the metrics of the book is a huge undertaking. Sure, you can just edit the master and all of the pages will update. But that in turn affects how the text wraps, which then totally undoes all of my careful fitting of blocks of stuff onto different pages. That grueling two-month period where I laid out each page? Out the window now.

I went back to the drawing board. I cracked open the master. I started re-measuring things. Part of the problem was that (unsurprisingly) I'd over-constrained myself. In addition to needing decent margins, a good-sized sidebar, and the right line height, I also wanted measurements that were relatively round numbers. A column width of 1.35728261" is no-one's idea of a good time.

In the process of rounding some of those measurements to the nearest nice round number, I'd strayed away from actual good metrics. After bumping up the text size a bit, I spent days trying to come up with a column width, gutter size, and line height that would fit within the page margins and be easy to read.

Eventually, I found a way out: decimal inches. Most of my print work has used... shall we say... imperial measurements? Things like 16pt or 1/16". In other words, usually some power of two fraction of an inch. But that's not the only option. You can go French revolution and actually do things like 1.3". InDesign won't bat an eye at it.

After a bunch of monkeying around, here's what I came up with:

**TODO: new grid**

Instead of a vertical grid where prose is every three grid lines and code is every two, I bumped the fraction to 3/4. This opened up the code and asides a bit relative to the text. I made brought down the top margin and gave myself more than enough breathing room near the spine.

All that was left to do was update all of the pages. By this point, I was angry and fired up. I was *so close* to thinking the book was done and I just wanted it to over. I *burned* through those pages working on them practically every waking moment. This time, I got it done in a week.

I uploaded a new PDF, crossed my fingers and waited for the new proof to arrive. When it did... God what a sigh of relief. It looked fine. Totally readable. Hallelujah.

That readability was great because it made it much easier for me to notice all the mistakes I'd made in my hurried re-layout. Somehow, I'd managed to break all of the cross references, and sprinkle typos through much of the code. I did *another* proof-reading pass on the actual proof:

**TODO: post its**

I fixed those, and uploaded it again. This time, I'm not going to bother getting a proof printed. As far as I can tell, it's solid. Third time's the charm, right?

## Kicking it Out the Door

The print edition was done, and I made a slew of final changes to the eBook versions&mdash;mainly getting the cover in and working. Finally, only three things were left to do:

1. Redo the front page of the site to mention the new formats.
2. Upload everything to CreateSpace and the various eBook market places and put them for sale.
3. Write this blog post.

If you're reading this, it looks like I got those done too! You can see for youself:

* The new site.
* The print version on Amazon.
* The Kindle version.
* eBook versions on Smashwords and iBooks.

**TODO: links**

When I decided to self-publish, it was partially because I wanted to get a feel for what the whole production process was like. If you've made it this far, I think you'll agree that it was a good bit of work. I've been hacking on this book for over 500 days, not to mention the several years of intermittent work before that. I'm really looking forward to being able to saying I'm *done* and taking a break.

And, after that? Well, to be honest, this was kind of fun. I just might do it again, but not any time soon.
