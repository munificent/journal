---
title: "The Hardest Program I've Ever Written"
categories: dart code
---

<style>
.skull, .skull-note {
  border-radius: 4px;
  -moz-border-radius: 4px;
  -webkit-border-radius: 4px;

  background: hsl(35, 100%, 96%);
  color: hsl(35, 40%, 50%);

  padding: 1px;
}

.skull::before, .skull-note::before {
  content: "\01f480";
  margin-right: -2px;
}

a.skull {
  position: relative;
  top: -0.4em;
  font-size: 80%;
}

a.skull:hover, a.skull-note:hover {
  color: hsl(35, 100%, 30%);
}
</style>

The hardest program I've ever written, once you strip out the whitespace, is
3,835 lines long. That handful of code took me almost a year to write. Granted,
that doesn't take into account the code that didn't make it. The [commit
history][] shows that I deleted 20,704 lines of code over that time. Every
surviving line has about three fallen comrades.

[commit history]: https://github.com/dart-lang/dart_style/commits/master

If it took that much thrashing to get it right, you'd expect it to do something
pretty deep right? Maybe a low-level hardware interface or some wicked graphics
demo with tons of math and pumping early-90s-style techno? A likely-to-turn-evil
machine learning AI Skynet thing?

Nope. It reads in a string and writes out a string. The only difference between
the input and output strings is that it modifies some of the whitespace
characters. I'm talking, of course, about [an automated code
formatter][dartfmt].

[dartfmt]: https://github.com/dart-lang/dart_style

## Introducing dartfmt

I work on the [Dart][] programming language. Part of my job is helping make Dart
code more readable, idiomatic, and consistent, which is why I ended up writing
our [style guide][]. That was a good first step, but any style guide written in
English is either so brief that it's ambiguous, or so long that no one reads it.

[dart]: https://www.dartlang.org/
[style guide]: https://www.dartlang.org/articles/style-guide/

Go's [gofmt][gofmt] tool showed a better solution: automatically format
everything. Code is easier to read and contribute to because it's already in the
style you're used to. Even if the output of the formatter isn't great, it ends
those interminable soul-crushing arguments on code reviews about formatting.

[gofmt]: https://golang.org/cmd/gofmt/

Of course, I still have to sell users on running the formatter in the first
place. For *that*, having great output really does matter. Also, I'm pretty
picky with the formatting in my own code, and I didn't want to tell users to use
a tool that I didn't use myself.

Getting that kind of quality means applying pretty sophisticated formatting
rules. That in turn makes *performance* difficult. I knew balancing quality and
speed would be hard, but I didn't realize just how deep the rabbit hole went.

I have finally emerged back into the sun, and I'm pleased with what I brought
back. I like the output, and the performance is solid. On my laptop, it can blow
through over two million lines of code in about 45 seconds, using a single core.

## Why is formatting hard?

At this point, you're probably thinking, "Wait. What's so hard about
formatting?" After you've parsed, can't you just walk the [AST][ast] and
[pretty-print][] it with some whitespace?

[ast]: https://en.wikipedia.org/wiki/Abstract_syntax_tree
[pretty-print]: https://en.wikipedia.org/wiki/Prettyprint

If every statement fit within the column limit of the page, yup. It's a piece of
cake. (I think that's what gofmt does.) But our formatter also keeps your code
within the line length limit. That means adding line breaks (or "splits" as the
formatter calls them), and determining the best place to add those is [famously
hard][].

[famously hard]: https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap#Knuth.27s_algorithm

Check out this guy:

```dart
experimental = document.querySelectorAll('link').any((link) =>
    link.attributes['rel'] == 'import' &&
        link.attributes['href'] == POLYMER_EXPERIMENTAL_HTML);
```

There are thirteen places where a line break is possible here according to our
style rules. That's 8,192 different combinations if we brute force them all <a
id="1" href="#1-note" class="skull">1</a>. The search space we have to cover is
*exponentially* large, and even ranking different solutions is a subtle problem.
Is it better to split before the `.any()`? Why or why not?

<div class="update">

<p><strong>What is up with the skulls?</strong></p>

<p>I had two goals with this article: to explain how dartfmt works, and to show
a realistic picture of how a real programmer solves a difficult problem with all
of the messiness that entails. Alas, the first is more than long enough to try
your patience, so I shunted all of the dead ends and failed attempts to
footnotes. Click the skulls to laugh at my misfortune.</p>

</div>

In Dart, we made things harder on ourselves. We have anonymous functions, lots
of [higher-order functions][iterable], and -- until we added [`async` and
`await`][async] -- used [futures][] for concurrency. That means lots of
callbacks and lots of long method chains. Some Dart users really dig a
functional style and appear to be playing a game where whoever writes the most
code with the fewest semicolons wins.

[iterable]: https://api.dartlang.org/133511/dart-core/Iterable-class.html
[async]: https://www.dartlang.org/articles/await-async/
[futures]: https://api.dartlang.org/1.12.1/dart-async/Future-class.html

Here's real code from an amateur player:

```dart
_bindAssignablePropsOn.forEach((String eventName) => node
    .addEventListener(eventName, (_) => zone.run(
        () => bindAssignableProps.forEach(
            (propAndExp) => propAndExp[1].assign(
                scope.context, jsNode[propAndExp[0]])))));
```

Yeah, that's four nested functions. 1,048,576 ways to split that one. Here's one
of the best that I've found. This is what a pro player brings to the game:

```dart
return doughnutFryer
    .start()
    .then((_) => _frostingGlazer.start())
    .then((_) => Future.wait([
          _conveyorBelts.start(),
          sprinkleSprinkler.start(),
          sauceDripper.start()
        ]))
    .catchError(cannotGetConveyorBeltRunning)
    .then((_) => tellEveryoneDonutsAreJustAboutDone())
    .then((_) => Future.wait([
          croissantFactory.start(),
          _giantBakingOvens.start(),
          butterbutterer.start()
        ])
            .catchError(_handleBakingFailures)
            .timeout(scriptLoadingTimeout,
                onTimeout: _handleBakingFailures)
            .catchError(cannotGetConveyorBeltRunning))
    .catchError(cannotGetConveyorBeltRunning)
    .then((_) {
  _logger.info("Let's eat!");
});
```

(The funny names are because this was sanitized from internal code.) That's a
*single* statement, all 565 characters of it. There are about 549 *billion* ways
we could line break it.

Ultimately, this is what the formatter does. It applies some fairly
sophisticated ranking rules to find the best set of line breaks from an
exponential solution space. Note that "best" is a property of the *entire
statement* being formatted. A line break changes the indentation of the
remainder of the statement, which in turn affects which other line breaks are
needed. Sorry, Knuth. No [dynamic programming][] this time <a id="2"
href="#2-note" class="skull">2</a>.

[dynamic programming]: https://en.wikipedia.org/wiki/Dynamic_programming

I think the formatter does a good job, but *how* it does it is a mystery to
users. People get spooked when robots surprise them, so I thought I would trace
the inner workings of its metal mind. And maybe try to justify to myself why it
took me a year to write a program whose behavior in many ways is
indistinguishable from `cat`.

## How the formatter sees your code

As you'd expect from a program that works on source code, the formatter is
structured much like a compiler. It has a [front end][] that parses your code
and converts that to an [intermediate representation][ir] <a id="3"
href="#3-note" class="skull">3</a>. It does some optimization and clean up on
that <a id="4" href="#4-note" class="skull">4</a>, and then the IR goes to a
back end <a id="5" href="#5-note" class="skull">5</a> that produces the final
output. The main objects here are **chunks**, **rules**, and **spans**.


[front end]: https://en.wikipedia.org/wiki/Compiler#Structure_of_a_compiler
[ir]: https://en.wikipedia.org/wiki/Intermediate_language#Intermediate_representation

### Chunks

A [chunk][] is an atomic unit of formatting. It's a contiguous region of
characters that we know will not contain any line breaks. Given this code:

[chunk]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk.dart

```dart
format /* comment */ this;
```

We break it into these chunks: `format`, `/* comment */`, and `this;`.

Chunks are similar to a [token][] in a conventional compiler, but they tend to
be, well, *chunkier*. Often, the text for several tokens ends up in the same
chunk, like `this` and `;` here. If a line break can never occur between two
tokens, they end up in the same chunk <a id="6" href="#6-note"
class="skull">6</a>.

[token]: https://en.wikipedia.org/wiki/Lexical_analysis#Token

Chunks are mostly linear. For example, given an expression like:

```dart
some(nested, function(ca + ll))
```

We chunk it to the flat list: `some(` `nested,` `function(` `ca +` `ll))`.

We could treat an entire source file like a single flat sequence of chunks, but
it would take forever and a day to line break the whole thing <a id="7"
href="#7-note" class="skull">7</a>. With things like long chains of asynchronous
code, a single "statement" may be hundreds of lines of code containing several
nested functions or collections that each contain their own piles of code.

We can't treat those nested functions or collection literals entirely
independently because the surrounding expression affects how they are indented.
That in turn affects how long their lines are. Indent a function body two more
spaces and now its statements have two fewer spaces before they hit the end of
the line.

Instead, we treat nested block bodies as a separate little list of chunks to be
formatted mostly on their own but subordinate to where they appear. The chunk
that begins one of these literals, like the `{` preceding a function or map,
contains a list of child *block chunks* for the contained block. In other words,
chunks do form a tree, but one that only reflects block nesting, not
expressions.

The end of a chunk marks the point where a split may occur in the final output,
and the chunk has some data describing it <a id="8" href="#8-note"
class="skull">8</a>. It keeps track of whether a blank line should be added
between the chunks (like between two class definitions), how much the next line
should be indented, and the expression nesting depth at that point in the code.

The most important bit of data about the split is the *rule* that controls it <a
id="9" href="#9-note" class="skull">9</a>.

### Rules

Each potential split in the program is owned by a [rule][]. A single rule may
own the splits of several chunks. For example, a series of binary operators of
the same kind like `a + b + c + d` uses a single rule for the splits after each
`+` operator.

[rule]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/rule/rule.dart

A rule controls which of its splits break and which don't. It determines this
based on the state that the rule is in, which it calls its *value*. You can
think of a rule like a dial and the value is what you've turned it to. Given a
value, the rule will tell you which of its chunks get split.

The simplest rule is a [hard split rule][hard]. It says that its chunk *always*
splits, so it only has one value: `0`. This is useful for things like line
comments where you always need to split after it, even in the middle of an
expression <a id="10" href="#10-note" class="skull">10</a>.

[hard]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/rule/rule.dart#L85

Then there is a [simple split rule][simple]. It allows two values: `0` means
none of its chunks split and `1` means they all do. Since most splits are
independent of the others, this gets used for most of the splits in the program.

[simple]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/rule/rule.dart#L104

Beyond that, there are [a handful of special-case rules][rules]. These are used
in places where we want to more precisely control the configuration of a set of
splits. For example, the positional argument list in a function list is
controlled by [a single rule][arg]. A function call like:

[rules]: https://github.com/dart-lang/dart_style/tree/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/rule
[arg]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/rule/argument.dart

```dart
function(first, second, third)
```

Will have splits after `function(`, `first,`, `second,`, and `third)`. They are
all owned by a single rule that only allows the following configurations:

```dart
// 0: Don't split at all.
function(first, second, third)

// 1: Split before the first.
function(
    first, second, third)

// 2: Split only before the last argument.
function(first, second,
    third)

// 3: Split only before the middle argument.
function(first,
    second, third)

// 4: Split before all of them.
function(
    first,
    second,
    third)
```

Having a single rule for this instead of individual rules for each argument lets
us prohibit undesired outputs like:

```dart
function(
    first, second,
    third)
```

### Constraints

Grouping a range of splits under a single rule helps us prevent split
configurations we want to avoid like the previous example, but it's not enough.
There are more complex constraints we want to enforce like: "if a split occurs
inside a list element, the list should split too". That avoids output like this:

```dart
[first, second +
    third, fourth]
```

Here, the list and the `+` expression have their own rules, but those rules need
to interact. If the `+` takes value `1`, the list rule needs to as well. To
support this, rules can *constrain* each other. Any rule can limit the values
another rule is allowed to take based on its own value. Typically, constraints
are used to make a subexpression rule force the surrounding rules to split
when the subexpression splits <a id="11" href="#11-note" class="skull">11</a>.

Finally, each rule has a *cost*. This is a numeric penalty that applies when any
of that rule's chunks are split. This helps us determine which sets of splits
are better or worse than others <a id="12" href="#12-note" class="skull">12</a>.
Rule costs are only part of how overall fitness is calculated. Most of the cost
calculation comes from spans.

### Spans

A [span][] marks a series of contiguous chunks that we want to avoid splitting.
I picture it like a rubber band stretching around them. If a split happens in
any of those chunks, the span is broken. When that happens, the solution is
penalized based on the cost of the span.

[span]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk.dart#L331

Spans can nest arbitrarily deeply. In an expression like:

```dart
function(first(a, b), second(c, d))
```

There will be spans around `a, b` and `c, d` to try to keep those argument lists
from splitting, but also another span around `first(a, b), second(c, d)` to keep
the outer argument list from splitting:

If a split occurs between `a,` and `b`, the `a, b` span splits, but so does the
`first(a, b), second(c, d)` one. However, if a split occurs after `first(a, b),`
then the `a, b` span is still fine. In this way, spans teach the formatter to
prefer splitting at a higher level of nesting when possible since it breaks
fewer nested spans.

## Parsing source to chunks

Converting your raw source code to this representation is fairly
straightforward. The formatter uses the wonderful [analyzer][] package to parse
your code to an [AST][]. This gives us a tree structure that represents every
single byte of your program. Unlike many ASTs, it even includes comments.

[analyzer]: https://pub.dev/packages/analyzer

Once we have that, the formatter does a [top-down traversal of the
tree][visitor]. As it walks, it [writes out chunks, rules, and spans][writer]
for the various grammar productions. This is where the formatting "style" is
determined.

[visitor]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/source_visitor.dart
[writer]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk_builder.dart

There's no rocket science here, but there are a *lot* of [hairy][corner1]
[corner][corner2] [cases][corner3]. Comments can appear in weird places. We have
to handle weird things like:

[corner1]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk_builder.dart#L184
[corner2]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk_builder.dart#L210
[corner3]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk_builder.dart#L283

```dart
function(argument, // comment
    argument)
```

Here, we normally would have a split after the first argument owned by an
argument list rule. But the line comment adheres to the `,` and has a hard split
after it, so we need to make sure the argument list rule handles that.

Whitespace is only implicitly tracked by the AST so we have to [reconstitute
it][] in the few places where your original whitespace affects the output.
Having a detailed test suite really helps here.

[reconstitute it]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/source_visitor.dart#L1979

Once we've visited the entire tree, the AST has been converted to a tree of
chunks and a bunch of spans wrapped around pieces of it.

## Formatting chunks

We've got ourselves a big tree of chunks owned by a slew of rules. Earlier, I
said rule values are like knobs. Now we get to dial those knobs in. Doing this
naïvely is infeasible. Even a small source file contains hundreds of individual
rules and the set of possible solutions is exponential in the number of rules.

The first thing we do is [divide the chunk list][divide] into regions we *know*
can't interfere with each other. These are roughly "lines" of code. So with:

[divide]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/chunk_builder.dart#L736

```dart
first(line);
second(line);
```

We know that how we split the first statement has no effect on the second one.
So we run through the list of chunks and break them into shorter lists whenever
we hit a hard split that isn't nested inside an expression.

Each of these shorter chunk lists is fed to the [line splitter][]. Its job is to
pick the best set of values for all the rules used by the chunks in the line. In
most cases, this is trivial: if the whole line fits on the page, every rule gets
set to zero -- no splits -- and we're done.

[line splitter]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/line_splitter.dart

When a line doesn't fit, the splitter has to figure out which combination of
rule values produces the best result. That is:

1. The one with the fewest characters that go over the column limit.

2. The one with the lowest cost, based on which rules and spans were split.

Calculating the cost for a set of rule values is pretty easy, but there are
still way too many permutations to brute force it. If we can't brute force it,
how do we do it?

## How line splitting works

Since I dropped out of college, my knowledge of algorithms was fairly, um,
rudimentary. So before I interviewed at Google, I spent two days in a hotel room
cramming as many of them -- mostly graph traversal -- in my head as I could. At
the time, I thought graphs would never come up in the interviews...

Then I had multiple interview questions that reduced down to doing the right
kind of traversal over a graph. At the time, I thought this stuff would never be
relevant to my actual job...

Then I spent the past few years at Google discovering that damn near every
program I have to write can be reduced down to some kind of graph search. I
wrote a [package manager][pub] where dependencies are a transitive closure and
version constraint solving is graph based. My [hobby roguelike][hauberk] uses
graphs for pathfinding. Graphs out the wazoo. I can do BFS in my sleep now.

[pub]: https://pub.dev/
[hauberk]: https://github.com/munificent/hauberk

Naturally, after several other failed approaches, I found that line splitting
can be handled like a graph search problem <a id="13" href="#13-note"
class="skull">13</a>. Each node in the graph represents a [solution][] -- a set
of values for each rule. Solutions can be *partial*: some rules may be left with
their values unbound.

[solution]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/solve_state.dart

From a given partial solution (including the initial "no rules bound" one),
there are edges to new partial solutions. Each edges binds one additional rule
to a value. By starting from an empty solution and walking this graph, we
eventually reach complete solutions where all of the rules have been bound to
values.

Graph search is great if you know where your destination is and you're trying to
find the best path. But we don't actually know that. We don't know what the best
complete solution *is*. (If we did, we've be done already!)

Given this, no textbook graph search algorithm is sufficient. We need to apply
some domain knowledge -- we need to take advantage of rules and conditions
implicit in the *specific* problem we're solving.

After a dozen dead ends, I found three (sort of four) that are enough to get it
finding the right solution quickly:

### Bailing early

We are trying to minimize two soft constraints at the same time:

1. We want to minimize the number of characters that overflow the line length
   limit. We can't make this a hard constraint that there is *no* overflow
   because it's possible for a long identifier or string literal to overflow in
   *every* solution. In that case, we still need to find the result that's
   closest to fitting.

2. We want to find the lowest cost -- the fewest split rules and broken
   spans.

The first constraint dominates the second -- we prefer a solution with any cost
if it fits one more character in. In practice, there is almost always a solution
that does fit, so it usually comes down to picking the lowest cost solution <a
id="14" href="#14-note" class="skull">14</a>.

We don't know *a priori* what the cost of the winning solution will be, but we
do know one useful piece of information: *forcing a rule to split always
increases the cost*.

If we treat any unbound rule as being implicitly unsplit <a id="15"
href="#15-note" class="skull">15</a>, that means the starting solution with
every rule unbound always has the lowest cost (zero). We can then explore
outward from there in order of increasing cost by adding one rule at a time.

This is a basic [best-first search][bfs]. We keep a [running queue][] of all of
the partial solutions we've haven't explored yet, sorted from lowest cost to
highest. Each iteration, we pop a solution off.

[bfs]: https://en.wikipedia.org/wiki/Best-first_search
[running queue]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/solve_state_queue.dart

If the solution completely fits in the page width, then we know we've won the
overflow constraint. Since we're exploring in order of increasing cost, we also
know it's the lowest cost. So, ta-da!, [we found the winner and can stop
exploring][bail]. Otherwise, if the current best solution has any unbound rules,
we enqueue new solutions, each of which binds one of those to a value.

[bail]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/line_splitter.dart#L171

We basically explore the entire solution space in order of increasing cost. As
soon as we find a solution that fits in the page, we stop.

### Avoiding dead ends

The above sounds pretty promising, but it turns out that there can be an
imperial ton of "low-cost but overflowing" solutions. When you're trying to
format a really long line, there are plenty of ways it can *not* fit, and this
algorithm will try basically all of them. After all, they're low cost since they
don't have many splits.

We need to avoid wasting time tweaking rules that aren't part of the problem.
For example, say we're looking at a partial solution like this:

```dart
// Blog-friendly 40-char line limit:    |
function(
    firstCall(a, b, c, d, e, f, g, h),
    secondCall("very long argument string here"));
```

There are a bunch of ways we can split the arguments to `firstCall()`, but *we
don't need to*. Its line already fits. The only line we need to worry about is
the `secondCall()` one.

So, when we are expanding a partial solution, we only bind [rules that have
chunks *on overflowing lines*][live]. If all of a rule's chunks are on lines
that already fit, we don't mess with it. In fact, we don't even worry about
rules on any overflowing line but the first. Since tweaking the first line will
affect the others, there's no reason to worry about them yet <a id="16"
href="#16-note" class="skull">16</a>.

[live]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/solve_state.dart#L28

This *dramatically* cuts down "branchiness" of the graph. Even though a partial
solution may have dozens of unbound rules, usually only a couple are on long
lines and only those get explored.

### Pruning redundant branches

This gets us pretty far, but the splitter can still go off the deep end in some
cases. The problem is that within large statements, you still run into cases
where how you format part of the statement is *mostly* independent of later
parts.

Take something like:

```dart
// Blog-friendly 40-char line limit:    |
new Compiler(
    assertions: options.has('checked-mode'),
    annotations: options.has('annotations'),
    primitives: options.has('primitives'),
    minify: options.has('minify'),
    preserve: options.has('preserve'),
    liveAnalysis: check(options.has('live'), options.has('analysis')),
    multi: options.has('multi'),
    sourceMap: options.has('source-map'));
```

Each of those named arguments can be split in a few different ways. And, since
those are less nested -- which means fewer split spans -- than that nasty
`liveAnalysis:` line, *it will try every combination of all of them* before it
finally gets down to the business of splitting that `check()` call.

The best way to split the `liveAnalysis:` line is the best way to split it
regardless of how we split `assertions:` or `annotations:`. In other words,
there are big branches of the solution space that initially differ in irrelevant
ways, but eventually reconvene to roughly the same solution. We traverse every
single one of them.

What we need is a way to prune entire branches of the solution space. Given two
partial solutions A and B, if we could say not just "A is better than B" but
"every solution we can get to from A will be better than every solution we can
get to from B" then we can discard B *and the entire branch of solutions
stemming from it*.

It took some work, but I finally figured out that you *can* do this in many
cases. Given two partial solutions, if one has a lower cost than the other and:

* They have the same set of unbound rules (but their bound rules have different
  values, obviously).

* None of their bound rules are on the same line as an unbound rule.

* None of their bound rules place constraints on an unbound rule.

Then the solution with a lower cost will always lead to solutions that also have
lower costs. Its entire branch wins. We can [discard the other
solution][overlap] and everything that it leads to. Once I got *this* working,
the formatter could line split damn near anything in record time <a id="17"
href="#17-note" class="skull">17</a>.

[overlap]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/solve_state_queue.dart#L124

### An escape hatch

Alas, that "damn near" is significant. There are still a *few* cases where the
formatter takes a long time. I've only ever seen this on machine generated code.
Stuff like:

```dart
class ResolutionCopier {
  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration toNode = this._toNode as ClassDeclaration;
    return javaBooleanAnd(
        javaBooleanAnd(
            javaBooleanAnd(
                javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(
                        javaBooleanAnd(javaBooleanAnd(
                            javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(
                                    _isEqualNodes(node.documentationComment,
                                        toNode.documentationComment),
                                    _isEqualNodeLists(
                                        node.metadata, toNode.metadata)),
                                _isEqualTokens(node.abstractKeyword,
                                    toNode.abstractKeyword)), _isEqualTokens(
                                node.classKeyword, toNode.classKeyword)),
                            _isEqualNodes(
                                node.name, toNode.name)), _isEqualNodes(
                            node.typeParameters, toNode.typeParameters)),
                        _isEqualNodes(
                            node.extendsClause, toNode.extendsClause)),
                    _isEqualNodes(
                        node.withClause, toNode.withClause)), _isEqualNodes(
                    node.implementsClause, toNode.implementsClause)),
                _isEqualTokens(node.leftBracket, toNode.leftBracket)),
            _isEqualNodeLists(
                node.members,
                toNode.members)),
        _isEqualTokens(
            node.rightBracket,
            toNode.rightBracket));
  }
}
```

Yeah, welcome to my waking nightmare. Unsurprisingly, code like this bogs down
the formatter. I want dartfmt to be usable in things like presubmit scripts
where it will have a ton of weird code thrown at it and it *must* complete in a
reliable amount of time.

So there is one final escape hatch. If the line splitter tries, like, 5,000
solutions and still hasn't found a winner yet, it just picks the best it found
so far and [bails][max].

[max]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_splitting/line_splitter.dart#L181

In practice, I only see it hit this case on generated code. Thank God.

## Finally, output

Once the line splitter has picked values for all of the rules, the rest is easy.
The formatter [walks the tree of chunks][writer], printing their text. When a
rule forces a chunk to split, it outputs a newline (or two), updates the
indentation appropriately and keeps trucking.

[writer]: https://github.com/dart-lang/dart_style/blob/3b3277668b2ff0cb7be954c3217c73264454bd7c/lib/src/line_writer.dart

The end result is a string of (I hope!) beautifully formatted Dart code. So much
work just to add or remove a few spaces!

### Footnotes

<a id="1-note" href="#1" class="skull-note">1</a> Yes, I really did brute force
all of the combinations at first. It let me focus on getting the output correct
before I worried about performance. Speed was fine for most statements. The
other few wouldn't finish until after the heat death of the universe.

<a id="2-note" href="#2" class="skull-note">2</a> For most of the time, the
formatter *did* use dynamic programming and memoization. I felt like a wizard
when I first figured out how to do it. It worked fairly well, but was a
nightmare to debug.

It was *highly* recursive, and ensuring that the keys to the memoization table
were precise enough to not cause bugs but not *so* precise that the cache
lookups always fail was a very delicate balancing act. Over time, the amount of
data needed to uniquely identify the state of a subproblem grew, including
things like the entire expression nesting stack at a point in the line, and the
memoization table performed worse and worse.

<a id="3-note" href="#3" class="skull-note">3</a> The IR evolved constantly.
Spans and rules were later additions. Even the way chunks tracked indentation
changed frequently. Indentation used to be stored in levels, where each level
was two spaces. Then directly in spaces. Expression nesting went through a
number of representations.

In all of this, the IR's job is to balance being easy for the front-end to
*produce* while being efficient for the back end to *consume*. The back end
really drives this. The IR is structured to be the right data structure for the
algorithm the back end wants to use.

<a id="4-note" href="#4" class="skull-note">4</a> Comments were the one of the
biggest challenges. The formatter initially assumed there would be no newlines
in some places. Who would expect a newline, say, between the keywords in
`abstract class`? Alas, there's nothing preventing a user from doing:

```dart
abstract // Oh, crap. A line comment.
class Foo {}
```

So I had to do a ton of work to make it resilient in the face of comments and
newlines appearing in all sorts of weird places. There's no single clean
solution for this, just lots of edge cases and special handling.

<a id="5-note" href="#5" class="skull-note">5</a> The back end is where all of
the performance challenges come from, and it went through two almost complete
rewrites before it ended up where it is today.

<a id="6-note" href="#6" class="skull-note">6</a> I started from a simpler
formatter written by a teammate that treated text, whitespace, and splits all as
separate chunks. I unified those so that each chunk included non-whitespace
text, line split information, and whitespace information if it didn't split.
That simplified a lot.

<a id="7-note" href="#7" class="skull-note">7</a> When I added support for
better indentation of nested functions, I broke the code that handled dividing
the source code into separate line-splittable regions. For a while, a single
top-level statement would be split as a single unit, even if it contained nested
functions with hundreds of lines of code. It was... not fast.

<a id="8-note" href="#8" class="skull-note">8</a> Ideally, the split information
in a chunk would describe the split *before* the chunk's text. This would avoid
the pointless split information on the last chunk, and also solve annoying
special-case handling of the indentation before the very first chunk.

I've tried to correct this mistake a number of times, but it causes a
near-infinite number of off-by-one bugs and I just haven't had the time to push
it all the way through and fix everything.

<a id="9-note" href="#9" class="skull-note">9</a> Rules are a relatively recent
addition. Originally each chunk's split was handled independently. You could
specify some relations between them like "if this chunk splits then this other
one has to as well", but you could not express things like "only one of these
three chunks may split"

Eventually, I realized the latter is what I really needed to get argument lists
formatting well, so I conceived of rules as a separate concept and rewrote the
front and line splitter to work using those.

<a id="10-note" href="#10" class="skull-note">10</a> At first, I thought hard
splits weren't needed. Any place a mandatory newline appears (like between two
statements) is a place where you could just break the list of chunks in two and
line split each half independently. From the line splitter's perspective, there
would be no hard splits.

Which would work... except for line comments:

```dart
some(expression,
   // with a line comment
   rightInTheMiddleOfIt);
```

This has to be split as a single unit to get the expression nesting and
indentation correct, but it also contains a mandatory newline after the line
comment.

<a id="11-note" href="#11" class="skull-note">11</a> There used to be a separate
class for a "multisplit" to directly handle forcing outer expressions to split
when inner ones did. Once rules came along, they also needed to express
constraints between them, and eventually those constraints were expressive
enough to be able to handle the multisplit behavior directly and multisplits
were removed.

<a id="12-note" href="#12" class="skull-note">12</a> I spent a *lot* of time
tuning costs for different grammar productions to control how tightly bound
different expressions were. The goal was to allow splits at the places where the
reader thought code was "loosest", so stuff like higher precedence expressions
would have higher costs.

Tuning these costs was a nightmare. It was like a hanging mobile where tweaking
one cost would unbalance all of the others. On more than one occasion, I found
myself considering making them floating point instead of integers, a sure sign
of madness.

It turns out spans are what you really want in order to express looseness.
Nested infix operators then fall out naturally because you have more spans
around the deeper nested operands. The parse tree gives it to you for free.

These days, almost every chunk and span has a cost of 1, and it's the *quantity*
of nested spans and contained chunks that determine where it splits.

<a id="13-note" href="#13" class="skull-note">13</a> I had known that
[clang-format][] worked this way for a long time, but I could never wrap my head
around how to apply it to dartfmt's richer chunk/rule/span system.

[clang-format]: http://clang.llvm.org/docs/ClangFormat.html

I took a lot of walks along the bike trail next to work trying to think through
a way to get graph search working when the two numbers being optimized (overflow
characters and cost) are in direct opposition, and we don't even know what the
goal state looks like. It took a long time before it clicked. Even then, it
didn't work at all until I figured out the right heuristics to use to optimize
it.

<a id="14-note" href="#14" class="skull-note">14</a> For a long time, overflow
and cost were treated as a single fitness function. Every overflow character
just added a very high value to the cost to make the splitter strongly want to
avoid them.

Splitting overflow out as a separate metric turned out to be key to getting the
graph search to work because it let us order the solutions by cost independently
of overflow characters.

<a id="15-note" href="#15" class="skull-note">15</a> I went back and forth on
how an unbound rule should implicitly behave. Treating it as implicitly split
gives you solutions with fewer overflow characters sooner. Treating it as
unsplit gives you lower costs.

<a id="16-note" href="#16" class="skull-note">16</a> Oh, God. I tried a million
different ways to reduce the branchiness before I hit on only looking at rules
in the first long line. I'm still amazed that it works.

I could also talk about how controlling branchiness lets us avoid reaching the
same state from multiple different paths. After all, it's a *graph*, but
everything I've described talks about it like it's a tree. By carefully
controlling how we extend partial solutions, we ensure we only take a single
path to any given complete solution.

Before I got that working, I had to keep a "visited" set to make sure we didn't
explore the same regions twice, but just maintaining that set was a big
performance sink.

<a id="17-note" href="#17" class="skull-note">17</a> Discarding overlapping
branches is the last macro-optimization I did and its behavior is very subtle.
Correctly detecting when two partial solutions overlap took a *lot* of
iteration. Every time I thought I had it, one random weird test would fail where
it accidentally collapsed two branches that *would* eventually diverge.

That bullet list was paid for in blood, sweat, and tears. I honestly don't think
I could have figured them out at all until late in the project when I had a
[comprehensive test suite][tests].

[tests]: https://github.com/dart-lang/dart_style/tree/3b3277668b2ff0cb7be954c3217c73264454bd7c/test
