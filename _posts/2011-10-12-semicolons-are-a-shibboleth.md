---
title: "Semicolons are a Shibboleth"
#categories: code, dart
---

For better or worse, anything that Google does attracts a ton of attention. New programming languages also bring out the inner critic in most people. Type systems are prone to enraging the [LtU](http://lambda-the-ultimate.org/node/4377) set, especially [unsound ones](http://www.dartlang.org/articles/optional-types/). And doing anything that [approaches JavaScript](http://www.2ality.com/2011/09/google-dart.html) is bound to infuriate a set of people that are passionately devoted to JS and The Way of the Prototype.

So, really, [Dart](http://www.dartlang.org/) was a perfect storm. It's been strangely fun watching the complaints, critiques, feature requests and condemnation roll in. One particular issue has incited way more attention than I expected given its significance in the grand scheme of things: semicolons.

Dart requires semicolons as statement terminators just like C, C++, Java, and C# do. (And JavaScript unless you're <strike>brave</strike> insane enough to use <abbr title="Automatic Semicolon Insertion">ASI</abbr>.) Making them optional is currently [the second-most starred bug](https://code.google.com/p/dart/issues/detail?id=34) on the tracker. It's one of the most frequently discussed points on [this insanely long reddit thread](http://www.reddit.com/r/programming/comments/l6uwv/dart_programming_language/).

Whatever your opinion of them, you have to admit they're a relatively innocuous language feature. Making them optional has very little impact on your code, and there isn't anything you can express without them that you couldn't with (and vice versa). What's the big deal?

Here's my theory: **semicolons are a shibboleth to tell which language camp the designers come from.** If you don't know the term, "[shibboleth](http://en.wikipedia.org/wiki/Shibboleth)" comes from this passage in the Old Testament:

> Gilead then cut Ephraim off from the fords of the Jordan, and whenever
> Ephraimite fugitives said, 'Let me cross,' the men of Gilead would ask, 'Are
> you an Ephraimite?' If he said, 'No,' they then said, 'Very well, say
> "Shibboleth" (שבלת).' If anyone said, "Sibboleth" (סבלת), because he could
> not pronounce it, then they would seize him and kill him by the fords of the
> Jordan. Forty-two thousand Ephraimites fell on this occasion.

<p class="cite">Judges 12:5-6, NJB</p>

## The Two Camps

I hate generalizations, and I particularly hate dichotomies, so I apologize for doing both right here. There is a huge amount of untruth to what I'm about to say, but I hope enough truth for this to be worth your time. Here's two opposing philosophies for programming languages:

1.  A language is a tool to tame the complexity of the problems we're solving.
    It should protect me from my fallibility (and more importantly the
    fallability of the jack-asses on my team). The more it can help me control
    things and prevent problems, the better. *Good fences make good neighbors.*

2.  A language is a tool for expressing my ideas. It should amplify
    my creativity (and that of the smart people writing the cool libraries I
    use). The fewer restrictions it gives me, the better. *We're all consenting
    adults here.*

I think you can divide languages pretty effectively into those two camps. The former gets the "serious business" languages: Fortran, C++, Java, C#. The latter gets you the hipster languages: JavaScript, Ruby, Python, Lisp.

Which camp is Dart in? Usually the presence of a static type system alone is enough to toss it into the first camp, but Dart's type system is so... *optional*, that it sort of hovers in the [uncanny valley](http://en.wikipedia.org/wiki/Uncanny_valley) between static and dynamic.

If you're trying to figure out whether you should give a damn about Dart, you'll want to know if its philosophy lines up with yours. You can look at the language today, but it's hard to know how much that tells you since the it's clearly not done yet.

## Semicolons

So you ask the shibboleth question: "mandatory semicolons?"

By itself, semicolons mean little to the language, but almost all of the second camp languages make them optional or eschew them completely. They say punctuation is ugly, makes the code less beautiful, and is needless boilerplate since they are almost always at the ends of lines anyway. Requiring them is just making the programmer do mindless gruntwork.

But a "serious business" programmer likes them: they are simple and unambiguous to parse. You don't have to worry about some other guy's weird coding style making it impossible for you to understand their code. We've been using semicolons for years, why stop now? They're safe and familiar.

Asking which way Dart is going to with semicolons is, I think, a way of asking which group of programmers the language wants to cater to. Either choice carries an implied signal about how other choices in the language will likely be made: will it favor individual expressiveness over group consistency? Freedom over safety?

## So How Does Dart Pronounce It?

So the question is, what will Dart do?

I honestly have no idea. I'm not one of the designers, and I think they may be split on the issue. I have my own personal preference, but that carries about as much weight as yours. Even if they were to make semicolons optional, I don't think that necessarily says much about your or my other pet features being included.

I think Dart really is trying to inhabit the ground between these two camps, so each attempt to pull in one direction or the other will be handled individually.

But, like everyone else, I hope they decide to go with *my* preference, which is of course the right one.
