---
title: "Outsourced Blog Comments"
categories: blog
---

<div class="update">
<p><em>Update 2011/08/16:</em> This post is about an older version of the blog. I used to use WordPress and redesigned the template a while back.
</p>
</div>

I just finished redoing the template for this here blog thing, and the most
significant change is that there are no longer comments on it.

I reached this decision starting from a simple engineering observation: a good
piece of software does [few things][saint] and does them well. A program
shouldn't re-invent things, and it certainly shouldn't re-invent them *poorly*.
Looking at it like that, it's obvious that the core feature of the blog is my
text (whether that feature *sucks* or not I'll leave up to you). The comment
engine is peripheral, and, frankly, not very well done. There's no threading,
up/down-voting, user information, good formatting, etc. It's pretty lame.

[saint]: http://en.wikiquote.org/wiki/Antoine_de_Saint_Exup%C3%A9ry "Perfection is attained, not when no more can be added, but when no more can be removed."

So I figured it would be better to re-use an existing comment system. [Reddit][]
is [open source][reddit source] so I could, in theory, use that. But thinking
about it a bit more, the obvious problem is that the best feature of reddit (and
[digg][]'s, [dzone][]'s, etc.) comment systems isn't the *code*, it's the
*people*. So the solution is simple: take comments off my blog and just direct
people to comment on one of those sites. Odds are good that they're already a
member of one or more of them anyway so there's isn't a lot of hassle there.

[reddit]: http://www.reddit.com/
[reddit source]: http://code.reddit.com/
[digg]: http://digg.com/
[dzone]: http://www.dzone.com

## Downsides

One of the obvious downsides is that conversation about what I write is no
longer on my territory. I lose the ability to moderate them or decide how long
they're online. If reddit kills the thread for one of my posts there's nothing I
can do about it. If some guy on digg thinks I'm an ass, I'm powerless to silence
him.

If I cared about traffic or "stickiness" or something it might also bother me
that people will no longer come to *my* site to see further comments. They'll go
to reddit, or digg, or wherever.

But I don't care about any of those. Honestly, traffic to my server is a net
negative. Bandwidth costs me money. What motivates me is writing, and having
people read it and discuss it. Deleting spam comments is not how I get my rocks
off.

## Upside

From that perspective, offloading comments makes a lot of sense. My little
[Wordpress][] blog can't hope to provide a comment UI anywhere near as good as
most news aggregators out there. Every time I saw someone posting a comment with
code on my blog followed by another comment apologizing for the way WordPress
ate its formatting, I cringed. Now I don't have that problem: reddit has
[Markdown][].

[wordpress]: http://wordpress.org/
[markdown]: http://daringfireball.net/projects/markdown/

Likewise, I don't have to moderate comments anymore. News aggregators are
centered almost precisely on that problem and they do it far better than I can.

More importantly, they provide a better community for discussing my writing than
I can. It's a bit odd, but more people will comment about a blog post of mine on
another site than they will on the post itself. The logic is obvious. You don't
get reddit karma for commenting on my blog *on my blog* but you do if you
comment on it on reddit. Since commenting on another site is clearly better, I
may as well make it the *only* choice.

## The real downside

There is one very real bad part about the change, though. If you've been kind
enough to comment on my blog before, your comment is no longer online. This
isn't because your comments weren't good. The quality of comments I received was
always stellar, even when you fought with the limitations of the system. I'm
sorry your words are no longer up here.
