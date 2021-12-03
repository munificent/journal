---
title: "Zero to 95,688: How I wrote Game Programming Patterns"
categories: book game-dev game-patterns
---

<div class="update">
<p><em>Update 2014/04/28:</em> In case you missed the link, the web site for my
  book is <a href="http://gameprogrammingpatterns.com">gameprogrammingpatterns.com</a>.</p>
</div>

About an hour ago, in the quiet of my living room, alone except for a sleeping
dog next to me, I accomplished the biggest goal of my life. I finished writing
[Game Programming Patterns][]. It's a book on game programming (it would be a
strange title for a book on ornithology) that I started writing about four years
and a lifetime ago.

[game programming patterns]: http://gameprogrammingpatterns.com/

<figure>
  <img class="framed" src="/image/2014/04/100-percent.png">
  <figcaption>What I see now when I run the script that converts my Markdown
  manuscript to HTML.</figcaption>
</figure>

It feels weird writing a blog post that doesn't have any real content beyond my
own personal story, but what the hell. It's not like I have anything better to
do! I get some vicarious pleasure (mixed with heaps of envy) when I read about
other people finishing their books, so I'll try to add to the canon.

## The Call to Adventure

Like most stories, it starts with the hero having something bad happen to him.
(Did I just call myself the hero? Seriously? God, this is already going to my
head.)

About five years ago, I was a game programmer at Electronic Arts in sunny
Orlando, Florida. That's the studio that does Madden, NCAA Football, Madden,
Tiger Woods Golf, Madden, and also this football game you've probably heard of.
They did a few other one-off games too.

I'd been there seven years, which is an impressively long time to actively
dislike football while working in an office that lived and breathed it. The last
game I worked on, [Henry Hatsworth in the Puzzling Adventure][hatsworth], was an
absolute blast, the kind of dream project you imagine game development to be all
about. Just seven dudes hanging out making a cool game they all loved.

[hatsworth]: http://en.wikipedia.org/wiki/Henry_Hatsworth_in_the_Puzzling_Adventure

<figure>
  <img class="framed" src="/image/2014/04/hatsworth.jpg">
  <figcaption>My pixel art alter ego in the <a href="https://www.youtube.com/watch?v=xYztScHUmo0&index=53&list=PLqN7MzshdwZLGlQuTYkcANZFW_dWN3HIf">end credits</a>.</figcaption>
</figure>

After we shipped, EA decided to never make that kind of mistake again and
refocused on <del>suckling the withering teats of its aging cash cows</del> the
shareholder-friendly profitability of beloved annual franchises. My entire team
quit except me. I ended up bouncing around onto a bunch of different projects.

I was so burned out that chunks of char were falling off me, and I was really
frustrated by how hard it was to ramp up every time I was airdropped into a new
team and its disorganized, deeply coupled, inconsistent code. I'd find bits of
real elegance sitting just a few source files away from some hairball that would
have benefitted from the exact same structure. People just weren't talking to
each other about their craft and weren't learning.

Game dev culture, at least at the studio I was at, is kind of weird. One quirk
of it is that a lot of the programmers I worked with didn't give credence to
ideas from the larger world of software. Things like *Design Patterns* were for
Nancy-boy enterprise programmers, not *real* game coders.

On top of this stress, I'd just had a kid, an eventuality I did not plan for
when I purchased a 900' house at the peak of the housing bubble. One frustrated
drive home from work, I had an idea: I knew some basic software architecture. I
liked writing stuff down. What if I wrote a book specifically targeted towards
game developers about this? If I aimed it straight at them, maybe they wouldn't
dismiss it out of hand.

<figure>
  <img class="framed" src="/image/2014/04/notes.jpg">
  <figcaption>A few notes from when I first started thinking about the book.
  Note that even then I was pandering to the masses on reddit!</figcaption>
</figure>

(Also, let's be honest, it's not hard to write a more enjoyable read than
*Design Patterns*. I'm pretty sure the Addison-Wesley style manual explicitly
*demands* crushingly boring prose.)

Now, I am a world class project starter. I've got hard drives full of stories,
videogames, art, music, screenplays, photography projects, tabletop games,
hell, there's probably some poetry in there somewhere. But virtually none of
it's *done*. About the only thing I'd been able to get out the door at that time
is the occasional blog post.

I was fully aware that taking on this project was pretty much doomed to failure.
But, after visiting the Pacific Northwest, my wife and I *really* wanted to
move, and a book would make for a nice bit of résumé padding to help me find a
new job.

<figure>
  <img class="framed" src="/image/2014/04/lake-crescent.jpg">
  <figcaption>How could you <em>not</em> want to live here?</figcaption>
</figure>

I felt like the book could be our ticket out west. So I needed to figure out
every psychological trick I could play on myself to actually get it done.

### The structure

If blog posts were the only thing I could finish, why not take a cue from that?
*Design Patterns* is a stack of mostly unconnected chapters. I could organize my
book the same way. Then instead of writing a whole monolithic book, it would
feel more like writing a few dozen separate articles. Less novel and more
anthology.

Likewise, each chapter in *Design Patterns* has the same top level headings and
organization. I could do the same thing, so I didn't need to come up with a
unique outline and narrative for each chapter. They'd just be recipes with
different ingredients and instructions.

### The workflow

I'm an inveterate tinkerer and I knew if I didn't put the kibosh on that, I'd
spend all day futzing with CSS or some other stupid thing that wasn't writing.
So I spent a day or two putting together [a minimal script][format] that would
take a file of Markdown for each chapter and convert it to HTML. Once I got it
working, I swore to myself that I wouldn't monkey with it (much).

[format]: https://github.com/munificent/game-programming-patterns/blob/master/script/format.py

Now I couldn't get distracted by design, style, editors, or anything. Just me, Sublime, and a handful of markdown syntax.

### The shame

One thing I'd heard was that telling your friends and family that you intend to
do something is a good way to keep yourself honest. So I totally made myself
look like an ass and told everyone, "Hey, I'm gonna write a book. Because I'm so
awesome. Don't you wish you were as erudite as me?" Maybe I didn't word it
exactly like that, but I'm pretty sure that's how it came across.

<figure>
  <img class="framed" src="/image/2014/04/shame.jpg">
  <figcaption>After working at EA for seven years, they give you seven weeks
  off. I used some for my honeymoon and then started writing.</figcaption>
</figure>

### The incentive

I'd been blogging for a year or so and one thing I'd learned is that the
possibility of a good Reddit discussion about my writing was *incredibly*
effective at getting me to complete something and put it out there. So I planned
to put each chapter online as I finished it instead of waiting for the entire
book to be done.

<figure>
  <img class="framed" src="/image/2014/04/reddit.png">
  <figcaption>One of the first chapters posted.</figcaption>
</figure>

## Crossing the Threshold

I rolled this all by my wife and, unbelievably, she agreed to it. Even though it
meant she'd have to spend even more time taking care of our infant daughter
while I wrote. Even though she knew I'd never finished much of anything before.

I'd like to think she believed in me, but maybe she just *really* wanted to move
out of that tiny bungalow. Seriously, that house was so small we had to move the
stroller into the living room every time we did laundry.

With her OK, I started working on a plan. Since padding my résumé was a primary
motivation, I needed a real publisher. I figured putting my *self*-published
book on my résumé would sound about as impressive as that "World's Best Son" mug
I got from Mom.

I spent a bunch of time reading submission guidelines. They usually want an
outline (check) and some sample chapters (oops). So I spent a couple of weeks
writing and revising a couple of chapters. This was a nice trial to see if I
could actually write something that looked like a book chapter. Miracle of
miracles, I could! For the record, the first chapter I wrote was [Object
Pool][].

[object pool]: http://gameprogrammingpatterns.com/object-pool.html

I carefully looked at a range of different publishers and their compensation
packages before making an educated choice about which ones to submit to. And by
that I mean I sent it to O'Reilly because OMG having a book with an animal on it
like [Perl's camel book][camel] would be SO RAD.

[camel]: http://shop.oreilly.com/product/9780596000271.do

I emailed them the submission with butterflies in my stomach which, when you
think about it, is an absolutely pointless physiological reaction given that I
was in my house all alone staring at my computer and not being attacked by a
sabre-toothed tiger. A heightened sympathetic nervous system does not actually
make email arrive faster.

Unbelievably, they got back in touch. They were interested! I had an editor! He
had feedback! He talked to me like I was an actual writer and not some jackass
who decided he was an author because he thought it sounded cool. There was talk
of a (small) advance. I felt like hot shit.

And then... somehow... it sort of fell through. I don't remember the exact
details, but at some point they decided to not move forward after all. I reached
out to a few other publishers and found another one. I signed a contract with
Apress and was super pumped to be back in business. We had a writing schedule
and everything.

During all of this, I was still writing and managed to get a couple more
chapters done. Unfortunately (but unsurprisingly and understandably) my
publisher was a little hesitant to have me put them all online, so I didn't get
that jolt of dopamine every time someone on the Internet acknowledged my
existence.

## The Ordeal

I thought I was back on track but then something funny happened. It turned out I
didn't need to pad my résumé after all. I got a new job. Outside of the game
industry and in the city we were desperately hoping to move to.

All of a sudden, we were packing up our belongings, kid, and pets; saying
goodbye to friends and family; and moving along what is practically the [longest
straight line move][move] you can make in the continental US. I was plunged
headlong into learning all sorts of new stuff at work that had nothing to do
with games. We got another dog and had another kid.

[move]: https://www.google.com/maps/dir/Orlando,+FL/Seattle,+WA/@36.7354942,-119.5307801,4z/data=!3m1!4b1!4m14!4m13!1m5!1m1!1s0x88e773d8fecdbc77:0xac3b2063ca5bf9e!2m2!1d-81.3792365!2d28.5383355!1m5!1m1!1s0x5490102c93e83355:0x102565466944d59a!2m2!1d-122.3320708!2d47.6062095!3e4

That writing scheduled was looking a little, uh, unrealistic. Eventually, I
realized my heart just wasn't in the book anymore. I called my editor,
apologized profusely, and backed out of my deal. Without the pressure to write,
I forgot about the book almost completely. I hadn't *abandoned* it, really. I
told myself I'd get back to it *some day*. It languished for a year. Then
another.

It would have gone into my overflowing bucket of unfinished projects if it
wasn't for one thing: *people kept emailing me about it.* You see, I'd put the
entire table of contents online along with the handful of chapters I had
written. Every now and then I would get a long, wonderful email from someone
telling me how a chapter really helped some abstract concept click in their mind
and how they couldn't wait for the next chapter. Good God, their enthusiasm made
me feel terrible.

## Resurrection and Rebirth

About a year ago, I had an unpleasant realization: as I got farther and farther
from my days as a professional game developer, my expertise was getting out of
date. *I was losing the ability to finish the book.*

While all my other unfinished projects didn't bother me that much, the book was
special. I'd only ever tried to write this one, and to have it die would break
my heart. I figured it was now or never.

Around this time, I'd stumbled onto [that article about Jerry Seinfeld's trick
for staying productive][chain]. It's pretty simple: work on it every single day.
Don't break the chain of sequential days. I also met [Chris Strom][] who's been
blogging this way for something like a million years.

[chain]: http://lifehacker.com/281626/jerry-seinfelds-productivity-secret
[chris strom]: http://japhr.blogspot.com/

Without putting much thought into it, I figured I'd give it a try.  I hadn't
written a word on the book in well over a year, but on June 7th, I started a new
chapter on [game loops][game loop]. I wrote 777 words of first draft, less than
an hour of work.

[game loop]: http://gameprogrammingpatterns.com/game-loop.html

The next day, I wrote 489 words. Then a meager 178. But it wasn't *zero*. This
weird desire not to break the chain made me drag myself off my ass and at least
write *something*, and once those 178 words were done, I was that much closer to
the end. The next day, I did 889 words. The day after that, I finished the first
draft of the chapter.

## Interlude: How a Chapter is Made!

I got so wrapped up in my own little narcissistic narrative I forgot to tell you
anything useful about the actual mechanics of how I write! Since I decided to
post chapters online as I completed them, I knew I couldn't just do a first
draft of the whole book before revising anything. Trust me, *no one* wants to
read a first draft. Instead, I treat each chapter like a little standalone piece
of writing. I do it like this:

### 1. Outline the chapter

Most of the chapters have the same top level structure, but within those
headings, I do a pretty detailed outline of what points I want to cover and how
they flow together. By the end, I have basically all of the material for the
chapter, just with no actual punctuation or grammar. It's everything I want to
say, said really poorly.

Here's a chunk of outline from the [Game Loop][] chapter:

```
- old programs used to be batch: ran and quit
- then came interactive programs. these ran forever,
  which meant loop
- if you write gui app, the os has event loop
  - you receive ui event, handle it, and return to event loop
  - js is a great example
  - you don't see loop, but it's there
  - when app isn't handle user input, it isn't doing
    anything, just sitting there
  - this can work for simple games (minesweeper, solitaire)
```

I don't think those bullet points or indentation even mean anything. It's just
word salad.

### 2. Write the code

The outline will hint at the example code so I know what blocks of code need to
be written. Then I come back and write the actual code. Sometimes I'll
interleave this with writing the text, other times I'll do all of the code up
front.

I write the code in [separate C++ source files][cpp] so that I can compile it
and make sure it's free of errors. For some chapters, I even wrote unit tests.
The script that converts the Markdown to HTML pulls in the code snippets
directly from those files.

[cpp]: https://github.com/munificent/game-programming-patterns/tree/master/code/cpp

Here's a bit of markdown for the [Prototype][] chapter:

[prototype]: http://gameprogrammingpatterns.com/prototype.html

```
To create a ghost spawner, we just create a prototypical ghost
instance, and then create a spawner holding that prototype:

^code spawn-ghost-clone

One neat part about this pattern is that it doesn't just clone
the *class* of the prototype, it clones its *state* too...
```

The little `^code` tells my script to hunt in the C++ code until it finds:

```cpp
void test()
{
  //^spawn-ghost-clone
  Monster* ghostPrototype = new Ghost(15, 3);
  Spawner* ghostSpawner = new Spawner(ghostPrototype);
  //^spawn-ghost-clone
  use(ghostSpawner);
}
```

It stitches in those two lines of code and we're good!

### 3. Write the first draft

I *hate* first drafts. I hate the blank page. I do a detailed outline up front
to try to make this easier. And then I rush through this as quick as I can to
get it over with. Even so, this part takes the longest and I usually only get
about 500 words a day on it.

I try to silence my internal critic during this phase so I can keep making
forward progress. I rely heavily on later revisions. Knowing I will edit later
gives me the freedom to *not* edit now.

### 4. Do the second draft

As soon as the first draft is done, I circle back and do the second. This
involves fixing all of the mistakes, bad grammar, and poor flow of the first
draft. Sometimes, there's major surgery here when I decide something I crammed
in just isn't working. I make a *lot* of changes:

<figure>
  <img class="framed" src="/image/2014/04/second-draft.png">
  <figcaption>A chunk of <a href="https://github.com/munificent/game-programming-patterns/commit/911cb7606937d890c774d5503cb712b22bf1b08b">
  the diff from the first to second draft</a> of
  <a href="http://gameprogrammingpatterns.com/architecture-performance-and-games.html">
  the last chapter</a> I wrote.</figcaption>
</figure>

The second draft is shorter than the first. Writing to me is like pottery. I
slap all the clay on the wheel in a big blob and then gradually work it down to
the final piece. I can get about 1,000 words of this done a day.

I *love* this part. Feeling the prose get tigher and clearer is exactly as
satisfying as refactoring messy code. It's less stressful because I feel like
anything I do now just makes it better but the chapter is safely *complete*
regardless. There's no more scary blank page, so editing is just pure goodness.

### 5. Do the third draft

This is the home stretch. At this point, the chapter is almost in its final
form. For this last pass, what I'm looking for is mistakes and rhythm.

I read the entire chapter *out loud*. I can't stress enough how helpful it is.
You can read something ten times and think it's fine but the first time you run
it through your lips you'll find all of the wrinkles. This fixes awkward
repetition and bad cadence. When the prose *reads* naturally and easily, that's
not because it was easy and natural to *write*. It's because I edited the hell
out of it.

### 6. Illustrations

The last thing I do is draw a few illustrations for the chapter. I think visuals
are *hugely* important for making abstract concepts concrete in the user's mind.

I spent a lot of time trying to figure out how I wanted to illustrate the book.
I'd done a few illustrations in Photoshop, but didn't like how the text looked
pixellated. It also made it a real pain to change the design of the site, and
looked terrible when retina displays came on the scene.

I thought about using SVG, but that seemed like a huge time sink to get the
level of quality I wanted. Eventually, I hit upon the idea of going in the
*other* direction. I decided to hand-draw and scan the illustrations. I could
scan them at a high enough resolution to look sharp on a retina screen. More
importantly, their *intentional* imperfection would help turn off the OCD part
of my brain that would be unsatisfied with anything less than perfect [Edward
Tufte][]-quality diagrams.

[edward tufte]: http://www.edwardtufte.com/tufte/

<figure>
  <img class="framed" src="/image/2014/04/illustrations.jpg">
  <figcaption>Some of the 66 hand-drawn illustrations.</figcaption>
</figure>

### 7. Publish and fix bugs

At this point, I think the chapter is done. I put it online and tell the world,
and immediately they point out a bunch of glaringly obvious bugs that somehow
survived several rounds of editing. I fix those, and *now* the chapter is mostly
solid.

## The Long Road

OK, where were we? I started logging each day's work in [a little text
file][log]. Less than two weeks later, the chapter was done:

[log]: https://github.com/munificent/game-programming-patterns/blob/master/note/log.txt

```
2013-06-18 - Finish third draft of Game Loop
2013-06-17 - 1,280 words revised in third draft of Game Loop
2013-06-16 - ~1,000 words revised in third draft of Game Loop
2013-06-15 - Finish second draft of Game Loop
2013-06-14 - Revise couple of paragraphs of Game Loop
2013-06-13 - Revise ~500 words of second draft of Game Loop
2013-06-12 - Revise ~900 words of second draft of Game Loop
2013-06-11 - Finish first draft of Game Loop
2013-06-10 - 489 words on first draft of Game Loop
2013-06-09 - 178 words on first draft of Game Loop
2013-06-08 - 889 words on first draft of Game Loop
2013-06-07 - 777 words on first draft of Game Loop
```

I spent some time redoing the design of the site not to be totally busted on
mobile devices and then started the next chapter. Now, if this was a movie, this
is when the eighties instrumental rock would start and the montage would kick
in. Before you know it, the book would be done.

But, I tell you what, I *lived* that montage, and it did *not* pass quickly.
Working on this damned book was a pain in the ass *every single day*. I work
full time, and have two small kids. We bought a house and all of the work that
that entails and it turns out that, holy crap, it's pretty easy to fill an
entire day with stuff that's *not* writing a book.

I started getting up early in the morning before the kids so I could have some
quiet time. Ostensibly, I would write then, and sometimes I did. But, more often
than not, I'd just drink coffee and stare at the Internet while I slowly roused
myself. Then, after I'd worked, made dinner, gotten the kids cleaned up and
ready for bed, read them books, gotten them milk, cleaned up a bit and gotten
them in bed, *then*, I'd still have to write.

Yet, strangely, I would. I've never demonstrated an ounce of self-discipline in
my *entire life*, but for some reason I just didn't want to skip a day. Even
though I was often dog tired, I would scrape up just enough energy to put in
barely half an hour of writing. I would look at the pathetic word count and feel
bad before going to sleep exhausted.

But here's the thing. Even tiny amounts of effort add up if you keep at it. I'd
have entire weeks where I felt like I didn't have a single good writing day, but
after two of those weeks... that's a whole chapter.

Because I was writing *every* day, it made it easier to build it into the
routine. I never had a chance to get used to *not* writing. It was just this
thing that *must* be in the schedule, like brushing my teeth or eating, even
when I traveled or did outings with the kids. I gave [a talk at Strange
Loop][loop] last year, and every evening after dinner, while others were out at
bars socializing, I went back to my hotel room so I could write. When I flew to
another office for all-day meetings, I wrote on the plane.

[loop]: http://www.infoq.com/presentations/dart-introduction

The only insurmountable problem I ran into was a camping trip. I couldn't
imagine bringing a laptop to the woods and charging it in my car or something.
Instead, I did what comic strip artists do: I banked some days. For two days
leading up to the trip, I wrote two sessions a day. Then I wrote early in the
morning before leaving, so I only ended up skipping one day. I basically loaned
myself the time, with interest.

## Refusal of the Return

Once I started putting chapters online again, people started noticing. I got
that feedback and encouragement that I thrive on and I was delighted to have
stuff to talk about on Reddit again.

Around this time, an editor at another publisher reached out to me. Now that I
was working on the book again, would I be interested in a publishing deal? She
was super nice and was very willing to work with me. I could keep the book
online. I could be involved in the design and layout. It could be everything I
wanted and more.

I kind of dragged my feet for a while before I finally realized my reluctance
was trying to tell me something. When I'd had publishers before, the power
relationship felt really strange. O'Reilly and Apress were both great, but I
felt like they were in charge, which is bizarre when you think about how much
effort the author puts into it compared to the publisher.

What I was finding was that I really liked it being *my* book. I'm not doing
this for the money, which means I'm doing it for my personal satisfaction. And
what's most satisfying to me is feeling like I got to put as much of my own
creativity into it as possible without someone else calling the shots.

That's not to say I don't like collaboration. I've gotten about 130 bug reports
along with a bunch of pull requests, not to mention lots of comments and email.
I absolutely treasure all of that, and the book is way better than it would be
without that.

I really like working *with* readers and contributors, but I'm not really
interested in working *for* a publisher. About halfway through the book, I
decided to self-publish. That meant I needed to start doing the things a
publisher does. In my mind that's:

1.  **Developmental editing.** When you get a book deal, this is what the editor
    you work with does. It's their job to guide the overall direction of the
    book to make sure it lines up with what audiences want.

2.  **Marketing, advertising, and distribution.** Basically, getting the book in
    front of people and in stores. Making it exist and making people know it
    exists.

3.  **Copyediting, proofreading, illustrations, and design.** The sort of blue
    collar stuff that turns a manuscript into a book.

I'd been putting chapters online and interacting directly with my audience since
I started the book, so I felt like I had a better handle on what they wanted
than most editors would. Having an inbox with hundreds of emails from people is
pretty helpful when you're trying to figure out what they want.

All of the manual labor side of things -- editing and design --are some of my
favorite parts. Before I was a programmer, I was a graphic designer, and I've
dreamed of typesetting and laying out a book. Bug reports from readers helped do
some of the work of copyediting. (Special shout-out to mystery superhero
[colms][] who basically line-edited the entire book free of charge.) Finding a
freelance proofreader didn't seem too hard.

[colms]: https://github.com/colms

Of course, distribution is a mostly solved problem now. Especially with
technical books, people buy them from Amazon or get e-books. I can do those just
as well as any New York publisher. You don't need deals or shelf space any more
(though it certainly doesn't hurt).

That left marketing and advertising -- making sure people knew about the book.
So I created a mailing list. I added a little blurb to the top of each page on
the book's site saying the book was a work-in-progress and to sign up if you
want to know when chapters come out. As of this morning, I have a little over
3,000 subscribers, which is probably more reach than a "real" publisher would
have given me.

## Finishing the Damn Thing

Once I had that decided and squared away, all that was left was to write the
rest of the chapters. So I wrote. And wrote. And wrote. Every single day. I
wrote while my wife gave the kids a bath. I wrote at five in the morning before
we went on day trips. I wrote when I was sick. I wrote on Halloween,
Thanksgiving, Christmas, and New Year's.

When I finished a chapter, I'd spend a few days where "writing" consisted of
fixing bugs, responding to email and other minutia. But then I'd get to the next
chapter.

After a while, writing the book receded into the back of my mind. It wasn't
something I thought much about during the day. When people asked what I did
outside of work, I'd forget to include it sometimes. It was just ever-present
background noise. Exactly 322 days after I started the first draft of Game Loop,
all of these little slices of low thread priority background work on the book
added up.

95,688 words. 21 chapters. 66 illustrations. 133 fixed issues. Hundreds of
commits. Yesterday, I [committed the third draft of the last chapter][last] and
the manuscript was complete.

[last]: https://github.com/munificent/game-programming-patterns/commit/5613f47f844e9911a31db49869ce097ab351a8df

I've wanted to be able to claim that I've written a book for so long that it
feels weird to finally be on the other side of the finish line. I wrote a book.
Not "want to write". Not "will write". Not even "am writing". *Wrote.*
