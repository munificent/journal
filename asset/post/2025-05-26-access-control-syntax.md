---
title: Access Control Syntax
categories: code language vgs
---

I'm still tinkering on a [scripting language for my hobby fantasy console
project][console]. I'm ashamed to admit this, but up to this point, the language
had absolutely no notion of modules. Literally every source file is dumped into
one big global namespace and compiled together.

[console]: /2023/01/03/type-checking-if-expressions/

I always planned to have some sort of module system. I just hadn't figured it
out yet because I had other, harder [language design problems][heterogeneous] to
solve. I assumed that the module system mostly didn't interact with other
language features, so I could kick it down the road for now.

[heterogeneous]: /2023/08/04/representing-heterogeneous-data/

That was true until it wasn't. I've been beating my head against the wall around
generics for.. oh God I just checked the Git history and it's three years now. I
still don't have that pinned down. Parametric types are hard.

Anyway, one of the approaches I'm exploring *does* get tangled up in modules and
scoping so now I have to figure modules out. This post is about one little
syntax design question I ran into: *how do you distinguish public and private
declarations?*

## A basic module system

Since my language is a scripting language, my ambitions for the module system
are pretty minimal. Think more like Python or Dart than Java or C#.

Every file has its own top-level scope that isn't shared with others. If you
want to access top-level declarations from another file, you import that file.
That makes its top-level declarations available in the importing file.

Of course, a module might have some declarations that are only for its own
internal use and should *not* be made available when you import it. A module
should be able to encapsulate parts of its implementation. Thus, I need a way
for users to indicate which declarations are private and which are public.

## What other languages do

Every language out there has *some* kind of module system and an ability to
control access (though it did take JavaScript about 20 years to get there, bless
its heart). In some sense, it's a solved problem. But they don't all solve it
the same way, especially if you dig into some of the more obscure corners of the
language world. Let's go on a tour...

### Modifier keywords

The approach you probably already have in mind is modifiers before declarations.
In Java, C#, PHP and others, that's `public`, `private`. Maybe also more
specific ones like `protected`, and `internal`.

It's clear, explicit, and gets the job done. It lets you support a large number
of flavors of access control if you need. It's also extremely common, so easy
for users coming to a new language to pick up.

The flip side is that it's quite verbose. Java is reviled for being too
boilerplate-heavy and wordy, and I believe that having `private` and `public`
scattered throughout every single file is a major contributor to that.

Picking the wrong defaults doesn't help. I used to program in C# professionally
for several years and in that time, I can't recall *ever* wanting a member to
have `internal` access, which is the default. So I had to write `public` or
`private` on basically everything. I think the same is true in Java land.

Rust improves the situation by having a shorter modifier, `pub`, and picking
what is arguably the right default for a language designed for Serious
Programming: private.

### Modifier sections

C++ has a strange but perhaps underappreciated spin on modifiers. It has access
modifier keywords, but they apply to *all subsequent declarations*. This lets
you write a keyword once and apply it to a whole bunch of things. That really
does cut down the verbosity.

The price to pay is that it also makes the language curiously context-sensitive.
If you're ever defined a preprocessor macro that inserts code in a class and had
to be careful *where* in the class you called the macro, you've run into this.

Access control sections mean that you can't look at a single declaration and now
what its access is. You have to know what section contains the declaration.

There's also the funny historical thing where members in struct default to
public and members in classes default to private. C++ is *weird*. Like a house
built on the back of some Eldritch being whose architecture and plumbing reveals
the unholy foundation it is mated with.

For presumably less Eldritch reasons, I believe Ada takes a similar approach.

### Sigils in the names

Modifiers are clear but verbose. If you want something more syntactically
economical, why not encode the access control directly in the name of the
declaration itself? That's what Python, Go, and Dart do.

Python's system is a mixture of informal and language supported. A leading
underscore in a name doesn't *prohibit* it from being used outside of the module
but it sends a signal to the user that they *shouldn't* use it. Sort of "velvet
rope" security. If a class member starts with *two* leading underscores, then it
really is private. The language will name mangle it to make it inaccessible.

In Go, if a declaration's name starts with a capital letter, it's public.
Otherwise, it's private. Because Go allows any Unicode letter in identifiers,
the definition of uppercase [is not trivial][lu]. Wikipedia tells me there are
1,858 uppercase letters and 2,258 lowercase letters that can be used in
identifiers on Go. Fun!

[lu]: https://en.wikipedia.org/wiki/Unicode_character_property#Casing

Dart only allows ASCII in identifiers and follows Python: If an identifier
starts with `_`, it's private. Otherwise it's public. Unlike Python, this is
strictly enforced by the language. Private names are completely inaccessible
outside of the library where the declaration appears.

I don't have enough Python experience to have an opinion there aside from
finding `__` pretty long. I work full-time on Dart and have only tinkered in Go
so I'm highly biased, but Go's approach has always felt strange to me. I'm sure
it's mostly habit, but my monkey brain really wants case to be used to
distinguish kinds of declarations: leading capitals for types and lowercase for
functions. Seeing types with lowercase names or functions with capital names
gives me the same squishy feeling in my gut as watching [The Polar Express][].
Dumb subjective biases aside, though, it seems to work fine in practice.

[The Polar Express]: https://en.wikipedia.org/wiki/The_Polar_Express_(film)

I'm much more used to Dart's style. I don't love it, but, eh, it gets the job
done.

These approaches both have the advantage of being very terse. No modifiers, no additional reserved words. There are two strikes against them:

*   **They're obscure.** If you're new to Java and you see the word `private`,
    you probably don't know what it does, but you can guess it has something to
    do with "privacy". With Go, if you see that some names are capitalized and
    some aren't, that tells you absolutely nothing about what's going on.
    Historical baggage? Weird personal preference? Maybe the author is German
    and prefers capitalizing nouns?

    Likewise, if you're skimming some Dart code, why do some of the names start
    with `_`? Do you pronounce that when you say the name out loud?

    You just have to be told what's going on because the language's own syntax
    doesn't guide you towards an explanation.

*   **They show up at the use sites.** Access control is a property of a
    *declaration*. So, in principle, any syntax for specifying it should only
    appear at that declaration. When you go to use a name, either you can access
    it (in which case no syntax is necessary) or you can't (in which case
    there's nothing you could say). But with Go and Dart, every place you
    mention the name also carries the access control.

    In theory, this could be a major problem if you want to *change* the access
    control of a declaration. You have to fix the identifier at every single use
    site! In practice, this doesn't actually cause much pain. If a name is going
    from private to public, then every existing use site is already confined to
    one file, so you can rename those without affecting the rest of the program.
    If an identifier is going from public to private, again all uses must
    already be confined to that file or you *can't* make it private without
    actually breaking things.

I used to say that if I had a time machine, I would go back and change Dart to
not use `_` for privacy. But I have mellowed on that opinion over the years and
now I'm not sure. I don't like how it shows up at every use site, but it *is*
terse, which is nice.

### Export manifests

Modifers put access control at the declaration. Sigils put it at the declaration
and the use sites. The third major approach puts it at *neither*.

Someone will tell me this generalization is wrong but I think most functional
languages including the ML family and Lisps (including Scheme) have some kind of
separate syntax for listing *exports*. Within a module, you declare all the
functions and types you want without worrying about modularity. Then at the top
of the file, the language gives you some dedicated syntax to list the things
that should be made visible outside of the module.

For example, in Scheme, the syntax for defining a module looks like:

```scheme
(library library-name
  (export list-of-names-to-export...)
  declarations-in-library...)
```

SML and its spawn have a notion of a [signature][sml signature] which is
declared separately from the module. You could also argue that header files in C
and C++ are this pattern.

[sml signature]: https://smlhelp.github.io/book/docs/start/module-syntax

A cool thing about export manifests is that they keep all the access control
logic in one place. When you're writing declarations, you don't have to worry
about access control then. You just write declarations. As a *user* of a library,
you can look at just the export section to see what the module lets you do
without digging in to the implementation at all.

It does a good job of *firmly* separating interface from implementation.

On the other hand, it's *quite* verbose. You end up saying the name of every
exported declaration twice. Maybe even the full type signatures too. Since the
export manifest is separate from the declarations, they have to be manually kept
in sync. Rename an exported function and you have to remember to rename it in
the manifest too.

I ragged on JavaScript for not having its act together, but I gotta say when
they did add modules, they came up with a clever blended approach. You can use
`export` as a modifier right on a declaration:

```javascript
export function area(width, height) {
  return width * height;
}
```

But you can also use the `export` keyword to export a set of declarations that
are already declared elsewhere:

```javascript
export { area };

// Code...

function area(width, height) {
  return width * height;
}
```

Given that modules were added later to the language, I'm guessing this makes it
easier to add modularity to a large existing JS library.

### Sigils at the declaration

In poking around the annals of language history, I found one last approach in
Niklaus Wirth's magnum opus language [Oberon][].

[oberon]: https://oberon.org/en

In Oberon, top-level declarations are private by default and only accessible
to the containing module. If you want to make a declaration public, you mark
the declaration with an asterisk:

```oberon
MODULE Hello;
  IMPORT Out;

  PROCEDURE SayHello*;
  BEGIN
    Out.String("Hello World!");
    Out.Ln;
  END SayHello;
END Hello.
```

Here, the `*` after `PROCEDURE SayHello` means that `SayHello` is public. Note
that this marker is only at the declaration. It's not part of the name. At
callsites, the name is just `HelloWorld`.

This has the same inscrutability that Python, Go, and Dart have. If you're a new
Oberon programmer and you see `*`, you have no idea what it means. Fortunately,
there are no new Oberon programmers, so this is not a problem in practice.

This approach has the advantage of only appearing at the declaration. You don't
have to repeat the sigil every time you use the thing.

## Any syntax at all?

I'm sure there are interesting tweaks and refinements in various languages, but
I think that mostly covers the approaches in use out there. (If you're aware of
any others, do tell.) Which approach is the right one for *my* little scripting
language?

A deeply related question is the choice of *defaults*. Java has `public` for
public stuff and `private` for private stuff, but it also has a syntax for
package private declarations: nothing at all. If you don't specify anything,
C++ makes your struct members public and your class members private.

It's hard to beat "zero syntax at all" when it comes to brevity, so the choice
of what access control a declaration gets by default is an important one.

When I put on my rigorous software engineer hat -- probably some kind of
construction site hard hat -- the obvious right default is private. No one can
fit an entire huge program in their head, so code needs to be broken into
smaller isolated pieces you can reason about locally. Defaulting to private
encourages users to make smaller independent modules.

If I was making a language for big mission-critical infrastructure software, I
would definitely do that. I think Rust made the right choice by defaulting to
private and requiring you to opt in to public with `pub`.

But I am making, like, the opposite of that. A hobby project that may never see
the light of day for people to make their own hobby games that, realistically,
also may never see the light of day. If anything, I want to encourage
(hypothetical) users of my (currently mostly vaporware) language to *get things
done*. Access control can get in the way of that.

### Class modifiers in Dart

A few years ago, we added a slew of [class modifiers][] to Dart. These are not
directly tied to public and private, but in the process of designing those, I
spent a lot of time talking to users about how they use the language and what
defaults they prefer.

[class modifiers]: https://dart.dev/language/class-modifiers

Dart defaults to public. You have to opt in to private by prefixing a name with
an underscore. It turns out that most users actually do prefer public being the
default. And after looking at mountains of Dart code, what I see is that most
Dart code is relatively small applications. Those apps are built on top of a set
of frameworks and libraries, but compared to the volume of application code out
there, those libraries make up a fairly small fraction of the entire Dart
ecosystem.

These apps are the leaves of the dependency tree. Nothing depends on them or
imports them. The authors of most of those are just trying to slap some UI
together and ship a thing. And for most of those, defaulting to public keeps the
language out of their way.

## Syntax for privacy

That all leads me to feel that my scripting language should default to public
and have a way to opt in to private. How do to that?

### No export manifests

I know I don't want export manifests. They are much too verbose. Also, there is
some extra language complexity and error reporting that gets sucked in. Since
the manifest is separate from the declaration, the compiler has to handle cases
where you try to export a name that doesn't exist. My language also has
overloading, which means when exporting a function, you would need to a way to
specify which of the overloads to export and which to leave private.

Export manifests are just way more machinery than fits for a scripting language.
This approach is out.

### No modifier sections

The C++ approach is nice in that it's clear while still being pretty terse. You
only need to write a modifier and can apply it to a bunch of declarations in the
same scope.

But at least in C++ (not sure about Ada), that only works within a type
declaration. My language isn't really object oriented. It's more procedural.
Sort of "structs plus functions" like C. Instead of classes, you have records.
But a record declaration tends to be pretty small with only a handful of fields
in it. There's not enough *stuff* inside a single record to benefit from reusing
a modifier for a bunch of nested declarations.

I could allow `private` at the top level and have it apply to everything after,
but that feels like it errs too far in the other direction. It would be really
confusing to have a thousand line file and not realize that half of it is
private because some modifier way offscreen above flipped the access control.

Modifier sections are out.

### No sigils in identifiers

Sigils in identifiers do have a sort of terse, scripty feel. No extra keywords.

I can't do Go's approach because my language already makes identifier leading
case significant. It supports [destructuring pattern matching][]. Like some
functional languages, it uses case to distinguish when a pattern is binding a
new local variable (lowercase) versus matching against a type or constant
(uppercase).

[destructuring pattern matching]: https://en.wikipedia.org/wiki/Pattern_matching#Tree_patterns

Now I'm not sure that corner of the language will stick, but it's there right
now.

I could do Python/Dart's approach and use a leading underscore. But I'd really
prefer to not have to mention the sigil at every single use site. After having
written probably a million lines of Dart code, I know it's not intolerable. But
it feels like an annoying tax. And for a language I'm designing for my own joy,
I'd like to eliminate as many annoyances as possible.

### Maybe modifiers

That leaves two approaches and is where I'm currently at. Approach one is the
typical solution to use an access control modifier at the declaration.
Unfortunately, defaulting to public makes this harder. In Rust, `pub` is a
really nice little keyword to flip to public when the default is private, but
there is no obvious converse. `private` would be the longest keyword in my
language. `pri` doesn't read like anything. `priv` is... strange. I suppose that
`pvt` is the well-established abbreviation for "private" but that feels a tad
militaristic.

I can't find any other synonyms for "private" that admit reasonable
abbreviations either. So I'm open to taking this path, but I'm simply failing to
come up with a good keyword for it.

(A silly goblin part of my brain suggested I use `shh` to mean "private", like
the declaration is being whispered and can't be heard outside of its module.)

### Maybe sigils at the declaration

This leaves Oberon's weird approach. There are several advantages here:

*   It is maximally terse. Zero syntax at the use site, and only a single
    character at the declaration site.

*   No additional reserved words which might get in the way of user identifiers.

*   By defaulting to public, the opacity of the syntax is less of an issue. Yes,
    the sigil won't immediately convey what it does, but if you're just starting
    to use the language, you don't need to even know it exists at first. You
    can just make everything public.

So there is some appeal. I don't think I can literally take Oberon's syntax
with `*` following the name. My language lets you define operators and it would
be confusing to have `*` right after other punctuation:

```vgs
def +*(left Vec, right Vec)
  Vec(left.x + right.x, left.y + right.y)
end
```

This is declaring a private `+` function. It would probably look equally weird
to have `*` after the name in a record declaration:

```vgs
rec Vec*
  val left Int
  val right Int
end
```

That led me to thinking the sigil should be by the declaration keyword. In my
language, every declaration form does start with a leading keyword (unlike, say,
C where function declarations don't have one), so it's feasible. Something like:

```vgs
rec* Vec
  val left Int
  val right Int
end

def* sayHi()
  print("Hello!")
end
```

I don't hate it. But using `*` feels weird for "private". If anything, it seems
to emphasize the declaration (which is what it does in Oberon where it means
"public").

### Maybe alternate keywords

That led to my last idea which I can't decide if I like or not. Given Python and
Dart, it seems like underscore vaguely conveys "private" to some people. So
maybe use that? It looks like:

```vgs
rec_ Vec
  val left Int
  val right Int
end

def_ sayHi()
  print("Hello!")
end
```

It looks odd, but I don't *hate* it. Or at least I don't hate it any more than
any novel programming language syntax usually triggers revulsion.

However, there's sort of a problem. Underscore is a valid identifier character.
So the [lexer][] is not going to scan `rec_` as a `rec` keyword token followed
by a `_` token. Instead of will treat `rec_` as a single identifier.

But then... I could just let it do that. I'd then define a separate set of
reserved words for all of the private declaration keywords: `def_`, `rec_`,
`var_`, and `val_`.

[lexer]: https://craftinginterpreters.com/scanning.html

So now instead of a modifier or sigil to control access, you explicitly choose
one of two declaration keywords. One makes it public and one makes it private.
This technically means adding a handful more reserved words, but they aren't
ones that are particularly useful for users anyway.

I keep trying to talk myself out of this approach because it's so unusual but so
far it seems to be lodged in my head better than any of the alternatives I've
considered. What do you think?
