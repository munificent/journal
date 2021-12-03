---
title: "What the Hero Sees: Field-of-View for Roguelikes"
categories: code game roguelike
---

<style>
canvas {
  display: inline-block;
  max-width: 100%;
  cursor: crosshair;
}
</style>

This post explains the algorithm I use for field of view in my game. I've been
meaning to write about it for a *long* time. While I procrastinated, I moved
four times, got married, had two kids, and ported my roguelike to [a
language][dart] that didn't exist when I first wrote the code this post is
about. You can thank Simon Andersson for prodding me to finally write it down.

[dart]: https://www.dartlang.org/

Every good game, or genre of games, has a pyramid of rewards. From simple
pleasures that mete out a droplet of endorphins when you click the next button
up to the deep, abiding feeling of accomplishment you get from slaying the final
boss on nightmare mode.

The roguelike genre standardizes many of these, and one of my favorites is the
joy of *exploring the dungeon*. You start out on a black screen, only one tiny
room visible. As you walk around, the map incrementally fills in&mdash;a perfect
graphical representation of your own knowledge and mastery increasing.

<figure>
  <canvas id="explore">Sorry, you need canvas support for this demo.</canvas>
  <figcaption>Click and drag the hero to explore. Click walls and floors to
  alter the dungeon.</figcaption>
</figure>

There wouldn't be much to explore if your hero could see through walls. The
second they entered the dungeon, the entire map would be filled in, all of the
crypt's hidden secrets laid bare to warrior and player alike. To prevent that,
we need to simulate something that seems trivial: *walls blocking the hero's
view*.

In the roguelike scene, this is referred to as *field of view*, and there are [a
number of ways to do it][fov]. Many of the posts linked there talk about "light"
and "shadow" as well, but they calculate the same thing as visilibity. In both
cases, we're trying to find the set of tiles that can be reached by rays
emanating from some point source. I'll use both terms interchangeably.

[fov]: http://www.roguebasin.com/index.php?title=Field_of_Vision

## Brute force line-of-sight?

The simplest solution is to repurpose your line-of-sight code. You already need
code to determine if there is an open line from one point to another on the map.
You use that to tell if things like arrows and fireballs reach their target or
bounce harmlessly off the dungeon wall.

This is invariably done using [Bresenham's line algorithm][bresenham]. It's one
of the true classics of graphics programming -- an elegant, simple algorithm
from 1962 that's still useful today. (This kind of living connection to CS's
past is one of the things I love about hacking on a roguelike. How often do you
have a good reason to recode a procedure originally devised for a 1950s-era drum
plotter?)

[bresenham]: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm

As you'd imagine for an algorithm designed to run on a machine that took punch
cards, it's very efficient... for tracing a line between *two points*. But field
of view is different. We need to scan the entire dungeon -- or at least the part
that fits on the player's screen -- and calculate the visibility of *every*
tile.

You actually *can* run Bresenham a few thousand times whenever the hero moves on
a modern machine, but doing that feels like cheating to me. Can we come up with
something more efficient?

The answer is, of course, "yes". (It would be a short post if it wasn't.) And,
in fact, a lot of others have already done so. But, one lazy sunny Saturday
morning in 2006, I didn't see any I liked and wanted to come up with one that
made more sense to me.

## Pieces of eight

If you have the mind of a programmer, the first thing you do when presented with
a problem is to break it into multiple (hopefully) smaller problems. Our goal is
to calculate the entire field of view surrounding the hero, but we can slice
that 360&deg; problem into 45&deg; pie pieces. One wedge looks like this:

<figure>
  <canvas id="octant">Sorry, you need canvas support for this demo.</canvas>
  <figcaption>Click to paint a wedge.</figcaption>
</figure>

This wedge is called an [*octant*][octant], and it's common in 2D algorithms. We
can paint every tile in that triangle like so:

[octant]: https://en.wikipedia.org/wiki/Octant_(plane_geometry)

```dart
for (var row = 1; row < maxDistance; row++) {
  for (var col = 0; col <= row; col++) {
    var x = hero.x + col;
    var y = hero.y - row;

    paint(x, y);
  }
}
```

If we take that wedge and apply some transformations, we can cover the entire
field around the hero. The above code is most of the way there. If you squint,
you can see there are two coordinate systems. The `row` and `col` variables are
in the octant's coordinate space. Meanwhile, `x` and `y` are in real tile
space&mdash;what you see on screen.

The first two lines inside the loops map octant space to tile space. Using just
`+` and `-` and `row` and `col`, there are eight ways to calculate `x` and `y`.
Each represents a reflection or 90&deg; rotation of the original octant. If we
enumerate them all, we get:

```dart
Vec transformOctant(int row, int col, int octant) {
  switch (octant) {
    case 0: return Vec( col, -row);
    case 1: return Vec( row, -col);
    case 2: return Vec( row,  col);
    case 3: return Vec( col,  row);
    case 4: return Vec(-col,  row);
    case 5: return Vec(-row,  col);
    case 6: return Vec(-row, -col);
    case 7: return Vec(-col, -row);
  }
}
```

Each case represents a different octant, starting at the top and going clockwise
around the circle. Painting them all covers the whole view (with a bit of
innocuous overlap):

<figure>
  <canvas id="octants">Sorry, you need canvas support for this demo.</canvas>
  <figcaption>Click to paint the whole view.</figcaption>
</figure>

From here on out, we only have deal with a single triangle's worth of `row` and
`col`, and we can cover the entire field of view just by running the same code
eight times, once for each octant.

## A Line of Shadows

Another way to simplify a problem is solve its negation, and that's what this
algorithm does. Instead of calculating which tiles are visible, it figures out
which are hidden, which puts it in a family of algorithms that do "shadow
casting". Before I explain it, try it out yourself:

<figure>
  <canvas id="shadow-cast">Sorry, you need canvas support for this demo.</canvas>
  <figcaption>Drag the slider up to advance the shadow line. Click anywhere
  else to change the dungeon.</figcaption>
</figure>

We start at the hero and work upwards one row at a time. As we sweep through the
octant, we incrementally update a data structure called the *shadow line*. It's
the white line you see next to the slider. It tracks which parts of the row are
in the shade of opaque tiles on previous rows and which aren't.

The shadow line is a series of segments, each representing one obscured region
of the line. We can define it like so:

```dart
class ShadowLine {
  final List<Shadow> _shadows = [];
}

class Shadow {
  num start;
  num end;

  Shadow(this.start, this.end);
}
```

The interesting question is, "What is the *range* of `start` and `end`?" The
naïve answer is to use tile coordinates. If we're five rows in and the shadow
line is five tiles long, the segment coordinates would range from 0 to 5.

The problem is that since light expands outwards from a point, the shadows
stretch out as they get farther away. We don't want to have to recalculate the
segment positions each time we advance a row and the rays spread out.

Instead, we store their *slopes*. Regardless of what row we're on, they always
range from 0 (the short vertical edge of the octant) to 1 (the diagonal edge).
Slopes are distance-independent. This is what the black line in the demo above
shows. As you click to add and remove walls, you can see new shadows appear, but
the black lines don't move or grow as you sweep the row up and down.

## Projecting a tile

The tricky part is calculating those slopes given some tile in the octant. There
are a couple of corner cases to consider. Literally. A tile is a square, and the
shadow it projects goes from one corner of the square to another.

Given our canonical octant, we know the tile will be above and to the right of
the hero. That means the projected shadow's extent will always be from the
top-left corner of a tile to the bottom-right corner. The other two corners lie
in the middle of the shadow. (This isn't strictly true if the tile is straight
up from the hero, but we can safely ignore that.)

What we need, then, is to calculate the slopes of those two corners of a tile.
The math is a kind of fussy, but it's:

```dart
/// Creates a [Shadow] that corresponds to the projected
/// silhouette of the tile at [row], [col].
Shadow projectTile(int row, int col) {
  var topLeft = col / (row + 2);
  var bottomRight = (col + 1) / (row + 1);
  return Shadow(topLeft, bottomRight);
}
```

This function has two uses. The obvious one is that we call this for each opaque
tile and add its result to the shadow line. But the projection comes into play
before that too.

You can think of the result of this function as the shadow that the tile casts
*past* itself, but it also describes the projection from the hero *to* this
tile. In other words, it describes which angles need to be unblocked for this
tile to be visible.

When we scan a row, we call `projectTile()` on every tile -- transparent or
opaque -- and compare it to the existing shadow line. If the tile's projection
is covered by the shadow line, we know it can't be seen. If it isn't, it can.

An interesting edge case is tiles whose projection is *partially* covered by the
shadow line. Different games take different approaches here. Mine is considered
*permissive*: if you can see any part of a tile, it's visible. A tile's
projection has to be totally covered by the shadow to be hidden. If you want
something less permissive, this algorithm is easy to tweak.

Let's code! First, we'll add a method to see if one shadow totally covers
another:

```dart
class Shadow {
  /// Returns `true` if [other] is completely covered by this shadow.
  bool contains(Shadow other) {
    return start <= other.start && end >= other.end;
  }

  ...
}
```

Then we use that to see if any shadow in the line covers the tile:

```dart
class ShadowLine {
  bool isInShadow(Shadow projection) {
    for (var shadow in _shadows) {
      if (shadow.contains(projection)) return true;
    }

    return false;
  }

  ...
}
```

Using that, we can determine the visibility of every tile in a row. Given a
ShadowLine in `line`, and a set of tiles in `tiles`, it's:

```dart
for (var col = 0; col <= row; col++) {
  var projection = _projectTile(row, col);
  var pos = start + transformOctant(row, col, octant);
  tiles[pos].isVisible = !line.isInShadow(projection);
}
```

## Inky pools of shadows

We can calculate which tiles are obscured by the shadow line, but that isn't
very useful since our shadow line is always empty right now. Let's fix that.

As we trace the row, each time we hit an opaque tile, we add it to the shadow
line. If the shadow line was a simple list of these little shadow segments, the
list would get longer and longer. In a dense dungeon, the hero may be near
hundreds of solid tiles. Having to walk through an increasingly long list of
shadow segments to see if a tile is obscured would get slower and slower.

Fortunately, I have a simple fix that makes the algorithm get *faster* as tiles
occlude more of the view. *This* is the part where I think my algorithm is
pretty cool, and it's why I'm excited to share it with you.

Often, when a new segment is added to the shadow line, it overlaps other
shadows. When that happens, we *merge* it with the existing shadows. The end
result is that the shadow line will have a single `Shadow` object for each
*contiguous* range of obscured area.

This does mean adding a new shadow to the line is more complex. There are a
handful of cases:

1.  **The shadow is contained within an existing one.** That means the new
    shadow doesn't cover any new territory, so we can discard it.

    ```
    old:    ..[======]..
    new:    ....[===]...
            ------------
    result: ..[======]..
    ```

2.  **The shadow doesn't overlap any other ones.** In this case, we insert it in
    sorted order between the segments that come before and after it.

    ```
    old:    [=].....[==]
    new:    ....[=].....
            ------------
    result: [=].[=].[==]
    ```

3.  **The shadow overlaps another shadow on its starting edge.** We take the
    previous shadow and grow it to encompass the new shadow's endpoint and
    discard the new one.

    ```
    old:    [===]....[=]
    new:    ...[===]....
            ------------
    result: [======].[=]
    ```

4.  **The shadow overlaps another shadow on its ending edge.** Do the same
    thing, but in reverse: grow the following shadow to cover the new one.

    ```
    old:    [=]....[===]
    new:    ....[===]...
            ------------
    result: [=].[======]
    ```

5.  **The shadow overlaps shadows on *both* ends.** This is the fun one. We take
    the previous shadow and extend it to cover the *next* shadow's endpoint.
    Then we discard both the new shadow and that next one.

    ```
    old:    ..[=]..[==].
    new:    ...[====]...
            ------------
    result: ..[=======].
    ```

The first case doesn't change the list of shadows at all. In the second case,
the list of shadows gets longer. In the next two, adding a new shadow doesn't
grow the list, it just shifts an endpoint. The last case is the fun one: there,
the list gets *shorter*.

(Pop quiz! Why don't we have to worry about cases where a shadow overlaps more
than two existing ones?)

Here's the entire method to add a shadow to the line:

```dart
class ShadowLine {
  void add(Shadow shadow) {
    // Figure out where to slot the new shadow in the list.
    var index = 0;
    for (; index < _shadows.length; index++) {
      // Stop when we hit the insertion point.
      if (_shadows[index].start >= shadow.start) break;
    }

    // The new shadow is going here. See if it overlaps the
    // previous or next.
    var overlappingPrevious;
    if (index > 0 && _shadows[index - 1].end > shadow.start) {
      overlappingPrevious = _shadows[index - 1];
    }

    var overlappingNext;
    if (index < _shadows.length &&
        _shadows[index].start < shadow.end) {
      overlappingNext = _shadows[index];
    }

    // Insert and unify with overlapping shadows.
    if (overlappingNext != null) {
      if (overlappingPrevious != null) {
        // Overlaps both, so unify one and delete the other.
        overlappingPrevious.end = overlappingNext.end;
        _shadows.removeAt(index);
      } else {
        // Overlaps the next one, so unify it with that.
        overlappingNext.start = shadow.start;
      }
    } else {
      if (overlappingPrevious != null) {
        // Overlaps the previous one, so unify it with that.
        overlappingPrevious.end = shadow.end;
      } else {
        // Does not overlap anything, so insert.
        _shadows.insert(index, shadow);
      }
    }
  }

  ...
}
```

OK, so that's kind of hairy, but it's not deep magic, just a bunch of different
cases to handle. Clever readers are probably wondering why we don't do a binary
search to find the insertion point. The list is sorted after all. If you want to
be super smart, go for it. In practice, I don't think it makes much of a
difference. The maximum size of the list is small enough that a linear search
may actually be faster.

(Pop quiz two! What *is* the maximum size of the list? Show your work.)

Very clever readers may have noticed we don't check for the first case, a
completely contained shadow here. That's because we've already done that check.
Earlier, when we detect if this tile is visible, that also tells us if it's
shadow is contained. If it is, we don't bother calling `add()`.

There's another simple optimization we can do. If we get to the point where the
shadow line is a single segment from 0 to 1 -- in other words, the whole line is
in shadow -- then we can skip all of the projection calculation, updating, etc.
Every tile will be hidden after that. Here's how we detect that:

```dart
class ShadowLine {
  bool get isFullShadow {
    return _shadows.length == 1 &&
        _shadows[0].start == 0 &&
        _shadows[0].end == 1;
  }

  ...
}
```

In practice, this case happens often. Dungeons tend to be small rooms and twisty
passages, so at some distance from the hero you typically reach a point where
all tiles are occluded.

## Putting it all together

OK, so we have code to:

1. Walk over every octant.

2. Walk every tile in an octant.

3. Update the tile's visibility.

4. Update the shadow line if the tile is opaque.

Let's stitch the last few pieces together along with a dash of bounds checking.
Building on top of what we have above, here's the top-level code to update the
visibility of the whole dungeon:

```dart
void refreshVisibility(Vec hero) {
  for (var octant = 0; octant < 8; octant++) {
    refreshOctant(hero, octant);
  }
}

void refreshOctant(Vec hero, int octant) {
  var line = ShadowLine();
  var fullShadow = false;

  for (var row = 1;; row++) {
    // Stop once we go out of bounds.
    var pos = hero + transformOctant(row, 0, octant);
    if (!tiles.bounds.contains(pos)) break;

    for (var col = 0; col <= row; col++) {
      var pos = hero + transformOctant(row, col, octant);

      // If we've traversed out of bounds, bail on this row.
      if (!tiles.bounds.contains(pos)) break;

      if (fullShadow) {
        tiles[pos].isVisible = false;
      } else {
        var projection = projectTile(row, col);

        // Set the visibility of this tile.
        var visible = !line.isInShadow(projection);
        tiles[pos].isVisible = visible;

        // Add any opaque tiles to the shadow map.
        if (visible && tiles[pos].isWall) {
          line.add(projection);
          fullShadow = line.isFullShadow;
        }
      }
    }
  }
}
```

And there we have it. It runs very fast in wide open areas since there will be
few shadow segments and the list is short. Likewise, it runs fast in closed
areas since the shadow list will also be short -- it will contain a small number
of long segments. It performs the worst in "spotty" areas with lots of small
trees or pillars, but even there, the performance is pretty solid.

I'd love to say I implemented a bunch of other algorithms and this one came out
the winner, but honestly I was too lazy to do that. I will say that this has
never shown up as a performance bottleneck when I've profiled the game. That's
good enough for me, and I hope this will be helpful for you too.

If you want to see all of the code for these demos, it's [here][demo]. Or, in
the context of [my game][hauberk] [here][game].

[demo]: https://github.com/munificent/fov
[hauberk]: https://github.com/munificent/hauberk
[game]: https://github.com/munificent/hauberk/blob/afb52670ab0650aff97cb112d752a6b49f8593a4/lib/src/engine/stage/fov.dart

<script type="application/dart" src="/code/2015-09-07-what-the-hero-sees/main.dart"></script>
<script src="/code/2015-09-07-what-the-hero-sees/packages/browser/dart.js"></script>
