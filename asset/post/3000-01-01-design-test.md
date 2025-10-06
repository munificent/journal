---
title: Design Test
tags: design
---

This is a temporary post to test all of the CSS for the design. It contains at
least one of every kind of style that appears across all of the posts. Here is
some inline *emphasized text*, some **strong text**, and some `inline code`.
Here's "a double quote", an apostrophe -- it was before the quote -- and some em
dashes. Every now and then, I use strikethrough ~~to make a dumb joke~~ for some
important purpose.

Here is [a link](#), and a [`code link`](#). It's not common, but inline styles
can sometimes be combined. So far, I've seen *emphasis with [a link](#) inside
of it*, **bold with `code inside` of it**, **bold with [a link](#) inside of
it**, and **bold with *emphasis* inside of it**. I think I avoid *emphasis with
`code` inside it*, but here's what it looks like just in case.

There are a few pages that have their own special sauce. You'll want to
check those too:

* The skull footnote markers in ["The Hardest Program I've Ever Written"](/2015/09/08/the-hardest-program-ive-ever-written/).

* The sliders under the canvases in ["Rooms and Mazes"](/2014/12/21/rooms-and-mazes/).

* The very long title may split across three lines in ["Methods on the
  Ether..."](/2010/06/25/methods-on-the-ether-or-creating-your-own-control-structures-for-fun-and-profit/).

* Usually a heading is followed by body text, but ["Naming Things in
  Code"](/2009/06/05/naming-things-in-code/) has a few sections with code right
  after the heading.

* Headings are usually only one line, but ["One and Only One"](/2009/05/05/one-and-only-one/#hey-i-thought-you-said-functions-always-take-one-argument) has a few long ones.

* There is a table on ["Debunking C# vs C++ Performance"](http://localhost:8000/2009/01/03/debunking-c-vs-c-performance/).

## Syntax highlighting

If you are iterating on the syntax highlighting for various languages, check out
[this generated page with all of the code snippets](/code.html).

## Heading H2 with "Quotes" and `code` inside

A paragraph of text.

### Heading H3 with "Quotes" and `code` inside

A paragraph of text. Next is a horizontal rule.

## A very long H2 heading to see how it looks when wrapped to two lines

A paragraph of text.

### A very long H3 heading to see how it looks when wrapped to two lines

A paragraph of text. Next is a horizontal rule.

---

Followed by another paragraph of text.

## Lists

Here is an ordered list:

1.  The <span name="first">first</span> list item. It has a multi-line paragraph
    of text to see how paragraph of text to see how that looks.

    <aside name="first">

    This is an aside. It should be aligned with the word "first" in the first
    bullet list item. Asides can have inline styles like *emphasis*, **strong**,
    and `code`. They can also have [links](#) and [`code links`](#).

    Asides can have multiple paragraphs. This is another one with some more
    text in it.

    </aside>

    It also has multiple paragraphs within the list item to test that out as
    well. There can also be code blocks in lists:

    ```c
    void main() {
      printf("Hello, world!\n");
    }
    ```

    More text after the code block.

2.  The second list item. Short.

    1.  But it does have a nested child list.

    2.  And the second item in the nested list is long enough to split across
        multiple lines so we can see how that looks.

3.  Then a final third list item.

Here is an unordered list:

*   The first list item. It has a multi-line paragraph of text to see how
    paragraph of text to see how that looks.

    It also has multiple paragraphs within the list item to test that out as
    well.

*   The second list item. Short.

    *   But it does have a nested child list.

    *   And the second item in the nested list is long enough to split across
        multiple lines so we can see how that looks.

*   Then a <span name="final">final</span> third list item.

    <aside name="final" class="bottom">

    Asides can also be aligned where the bottom is aligned to the main text,
    like this one which should be aligned with "final" in the last bullet point.
    This style is to handle cases where an aside appears near some other
    content below it in the sidebar.

    </aside>

## Code blocks

Here is a block of highlighted code:

```vgs
def onTick()
  var d = 0
  if buttonHeld(2) then d = d - 1 end
  if buttonHeld(3) then d = d + 1 end

  if buttonPressed(0) then
    if y == 200 then
      playSequence()
      v = -10.0
    end
  end
end
```

And some ASCII art, which has a different line height to make box drawing
characters look better:

```asciiart
  stack                       heap
┌─────────────────────┐
│ iterator.MoveNext() │
├─────────────────────┤     ┌───────────────────┐
│ loop body           │ ──> │ DesugaredIterator │
└─────────────────────┘     └───────────────────┘
```

## Boxes

There are a couple of kinds of box-delimited content.

> Blockquotes look like this. They are how I reference text from other sources
> or direct quotations that others have said.
>
> Blockquotes can have multiple paragraphs and inline styles like *emphasis*,
> **strong**, and `code`. They can also have [links](#) and [`code links`](#).
>
> *   In a couple of places, there are blockquotes containing bullet lists.
>     They can be multiple lines.
>
>     Or even multiple paragraphs.
>
> *   Here's another bullet list item.
>
>     * And one post that quotes a language spec.
>
>         * Ends up with a three-level deep list in a blockquote.
>
>         * Another item to make sure Markdown wraps the list items in
>           paragraphs.

Some blockquotes have an author attached to them, like this:

<blockquote class="cited">

People put all sorts of words in my mouth that I never said. They should cut
that out.

</blockquote>
<p class="cite">Abraham Lincoln</p>

There are also update boxes:

<div class="update">

*Update 2021/09/22:* Update boxes like this one usually note changes I've made
to a post after it was published.

Update boxes can have multiple paragraphs and inline styles like *emphasis*,
**strong**, and `code`. They can also have [links](#) and [`code links`](#).

> Surprisingly enough, they can even have blockquotes in them. And to make
> things crazier, the blockquote might have `code`, or presumably other inline
> styles like *emphasis* and **strong**.
>
> And of course it can be multiple paragraphs.

Another paragraph.

<blockquote class="cited">

Just to cover our bases, make sure a cited blockquote in an update is formatted
right too.

</blockquote>

<p class="cite">Some Author</p>

</div>

## Figures

Most graphical content is nested inside `<figure>` tags. It comes in a few
forms. First, an image with no caption:

<figure>
  <img class="framed" src="/image/2021/07/speed.png">
</figure>

The same image with a caption:

<figure>
  <img class="framed" src="/image/2021/07/speed.png">
  <figcaption>This is the caption. Captions are always just one paragraph long
  to keep things simple. But they can contain <em>emphasis</em>,
  <strong>strong</strong>, and <code>code</code>.</figcaption>
</figure>

A wide image:

<figure class="wide">
  <img class="framed" src="/image/2021/07/speed.png">
</figure>

A canvas with no caption:

<figure>
  <canvas>There would be content here if the canvas did something.</canvas>
</figure>

A canvas with a caption:

<figure>
  <canvas>There would be content here if the canvas did something.</canvas>
  <figcaption>Here is the caption.</figcaption>
</figure>

A wide canvas:

<figure class="wide">
  <canvas>There would be content here if the canvas did something.</canvas>
  <figcaption>Here is the caption.</figcaption>
</figure>

An embedded YouTube video:

<figure>
  <iframe width="704" height="396" src="//www.youtube.com/embed/sb7uzrKnAGA" frameborder="0" allowfullscreen></iframe>
  <figcaption>A caption for it.</figcaption>
</figure>
