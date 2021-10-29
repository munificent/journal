---
title: "Time for a New Blog"
categories: blog
---

I finally got tired enough of dealing with WordPress's admin interface and writing posts in HTML to do something about it, and I've redone this here blog. Now it's all [blogofile][]. I can edit in [markdown][] and preview locally. All of my content is backed up just by pushing it to [github][].

[blogofile]: http://www.blogofile.com
[markdown]: http://daringfireball.net/projects/markdown/
[github]: https://github.com/munificent/journal

It also got a facelift in the process.

## The new design

The old design was based around a 500 pixel column with 14 pixel text. As resolutions have grown, that started to look tiny. Now it's 640 pixels wide using a 16 pixel body font. Like the old site, the new one is designed to rigidly adhere to a baseline grid. This time, the grid is 24 pixels tall.

I'm using the [Google Font API][fonts] to go beyond the half dozen safe webfonts, but just barely. Titles are using [Varela Round][], but should fallback to Georgia and look OK if it's missing.

[fonts]: https://fonts.google.com/
[varela round]: https://fonts.google.com/specimen/Varela+Round

The old design was a classic two column layout. This time around, I went with a
single column. The entire site is now 640 pixels wide, almost like I was
designing in 1998! I pushed all of the navigation down to the bottom.

Two reasons: First, when reading a post I wanted to remove as much clutter as
possible. I wanted it to feel like reading a book without some constellation of
navigation and social buttons in your peripheral vision vying for your
attention.

And I figured a narrower layout would be more mobile friendly. On my phone, I
think the new design looks pretty nice.

Since this was more or less redoing things from scratch, I probably broke some
stuff. Let me know if you see something busted. In the meantime, I can get back
to actually writing about stuff again!
