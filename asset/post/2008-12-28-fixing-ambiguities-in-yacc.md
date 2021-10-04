---
title: "Fixing Ambiguities in Grammars"
categories: code f-sharp language parsing
---

For kicks, I've been writing a little toy programming language using [F#][],
[lex][] and [yacc][] (fslex and fsyacc, specifically, although everything here
should apply to [any lex and yacc][]). If you've tried doing this, inevitably
you've run into the issue of ambiguity in your grammar. This means there's more
than one equally valid way to parse an input string, so the parser can't decide,
gets very upset, and starts writing on its [LiveJournal][] about how unfair life
is.

[f#]: https://www.apress.com/gp/book/9781484207413
[lex]: http://en.wikipedia.org/wiki/Lex_programming_tool
[yacc]: http://en.wikipedia.org/wiki/Yacc
[any lex and yacc]: http://dinosaur.compilertools.net/
[livejournal]: http://snarkmarket.com/blog/snarkives/briefly_noted/the_poetry_of_livejournal/

The two areas where you'll run into problems are *associativity* and
*precedence*. This is so common that yacc has [support built-in][prec] to
address them, but unfortunately `%left` and `%right` don't always work as well
as you'd like. Instead, I'll show you some techniques I figured out from the
[1985 C ANSI reference grammar][c] for how to resolve these using just basic
grammar rules. First, definitions:

[prec]: http://www.cs.man.ac.uk/~pjj/cs2121/ho/node5.html#SECTION00054000000000000000
[c]: http://www.lysator.liu.se/c/ANSI-C-grammar-y.html

## Associativity

Associativity means that, given a run of the same operator, should it go left to
right, or right to left? For example:

```c
1 + 2 + 3
```

One of those additions needs to be performed first. Should it be `(1 + 2) + 3`
or `1 + (2 + 3)`? Left-associative operators pick the first, and
right-associative ones take the other. Most operators you see in math are
left-associative. Also, most produce the same result in either order.
Subtraction, like `3 - 2 - 1`, is one example where associativity *does* matter.

## Precedence (AKA order of operations)

Precedence is the other bugaboo. The question here is, given a few different
operations, which are performed first? For example:

```c
1 + 2 * 3
```

Should that be `(1 + 2) * 3`, or `1 + (2 * 3)`? yacc doesn't know your [Dear
Aunt Sally][sally], so you have to tell it. I'm using arithmetic expressions as
examples here, but this applies to *all* facets of expressions and statements:
Given `result = foo.x + 2` should we do the assignment (`=`), field access
(`.`), or addition (`+`) first?

[sally]: http://everything2.com/e2node/Please%2520Excuse%2520My%2520Dear%2520Aunt%2520Sally

## A toy language

For our exercise, we'll consider a little toy language. It supports integer
literals, functions that take and return a single integer, and binary operators.
Functions are any normal identifier name like `foo` or `rockMeAmadeus`.
Operators can be any punctuation character like `+` or `&`. Statements end with
a semicolon (`;`), and parentheses (`( )`) can be used for grouping.

Function application is higher precedence than operators, such that `foo 1 + 2`
should apply `1` to `foo` first and then add `2` to the result.

Binary operators are left-associative and all have the same precedence. In other
words, unlike in arithmetic, `+` and `*` have the same order of operations. Here
are some examples:

```c
123;                // An int.
foo bar 1;          // Pass 1 to bar, pass the result to foo.
6 + 2 * 3 / 4;      // Binary operators (result = 6).
foo 1 + bar 2;      // Mix operators and functions.
foo (1 + bar 2);    // Parentheses for grouping.
```

Pretty simple, but already you can see the trouble spots. In the third example,
how does the grammar know to make it left-associative? In the fourth, how does
it know to do the function application before the addition?

## Lexing and parsing (briefly)

You and I are both smart enough to [figure out][lex tut] how to lex the above.
Let's assume we've got a working lexer that emits following tokens: `INT`,
`FUNCTION`, `OPERATOR`, `LPAREN`, `RPAREN`, and `SEMI`.

[lex tut]: http://www.google.com/search?hl=en&#038;q=lex%20tutorial

Likewise, I'm not going to cover setting up yacc or discuss the [AST][ast]
emitted by it. Assume the action steps do what you want, know that the entry
point for our grammar is `start:`, and we shall proceed...

[ast]: http://en.wikipedia.org/wiki/Abstract_syntax_tree

## From the bottom up

We're going to build the full grammar for the toy language above with the
proper precedence and associativity from the bottom up. We'll start with
integers:

### Integers

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Primary                       { $1 }

Primary:
    | INT                           { Int $1 }
```

This is a little more complicated than necessary, but it'll make sense later.
Our entrypoint says we're parsing a single expression terminated with a
semicolon. An expression in turn can only be one thing (right now): a "primary
expression". A primary expression is just an integer. Magical. We can now parse
`123`. Break open the champagne bottles.

### Operators

Let's throw operators in:

```text
Expression:
    | Primary                        { $1 }
    | Expression OPERATOR Expression { Operator ($1, $2, $3) }
```

Try compiling that and watch a yacc barf on your screen. yacc can handle
recursive rules pretty well, but that operator one is a doozy. Not only is it
recursive, but it provides *two* paths to recurse and no guidance for which one
to choose.

Congratulations, you just hit the associativity problem. The issue is, given the
text `1 + 2 * 3` yacc looks at that rule and says: "Well `1 + 2` is an
expression and `*` is an operator, and `3` is an expression, so I could parse
that way. But wait, `1` is also an expression, and `+` is an operator, and `2 *
3` is an expression, so the rule works that way too. [Oh noes!][no]"

[no]: http://lolabrigada.files.wordpress.com/2008/03/oh-noes-pillow-hat-too-heavy.jpg

### Specifying associativity

We fix it by simply specifically ruling out one of those cases. If one side of
an operator can *only* be an integer, then half of that ambiguity disappears.
Behold:

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Primary                       { $1 }
    | Expression OPERATOR Primary   { Operator ($1, $2, $3) }

Primary:
    | INT                           { Int $1 }
```

Note that the `Operator` rule now has `Primary` on the right of the operator
now. What we've done is allowed the `Operator` rule to recurse only on *one*
side and force it to cascade down a level on the other. By putting the
same-level recursive `Expression` to the *left* of the `OPERATOR`, we've chosen
to make operators *left*-associative. Switch it around to `Primary OPERATOR
Expression` and you've got a right-associative rule. So that's how to solve half
our ambiguity problems.

### Functions

Let's throw functions in. Consider just this:

```text
Expression:
    | Primary                       { $1 }
    | FUNCTION Expression           { Function ($1, $2) }
```

Now an expression can either be an integer, or a function applied to an
expression. Making the function rule recursive lets us handle not only `foo 123`
but chained function calls like `foo bar 123`.

Pretty good. Now mix it in with our operator rule:

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Primary                       { $1 }
    | FUNCTION Expression           { Function ($1, $2) }
    | Expression OPERATOR Primary   { Operator ($1, $2, $3) }

Primary:
    | INT                           { Int $1 }
```

yacc vomit covers your screen. Given `foo 1 + 2`, yacc says, "Well `foo` is a
function and `1 + 2` is an expression so I can pick the function rule. But `foo
1` is an expression and `2` is a primary, so I could pick the operator rule
instead. I'm feeling queasy!" Actually, yacc, like a good party guest, will
clean up their own vomit and let you proceed with this conflict by trying to
guess at your preferred precedence, but it's unwise to rely on that.

What we need is to tell yacc to always do function application first. `foo 1 +
2` should always be read as `(foo 1) + 2`.

### Specifying precedence

We can fix this similarly to how we handled associativity. Remember how I
described the rules as a cascading series from complex to simple? Another way to
look at those is as *explicit order of operations*, from last to first. Let's
split out the rules a bit:

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Primary                       { $1 }
    | Function                      { $1 }
    | Operator                      { $1 }

Operator:
    | Expression OPERATOR Function  { Operator ($1, $2, $3) }

Function:
    | FUNCTION Expression           { Function ($1, $2) }

Primary:
    | INT                           { Int $1 }
```

That doesn't actually fix anything for us, yet. The problem is that the
`Expression`, `Operator`, and `Function` rules all recursively point to each
other. Our neat cascade is trying to flow uphill. The trick, and the fix for our
issue, is to simply *not allow any rule to reference a rule above it*:

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Operator                      { $1 }
    | Function                      { $1 }
    | Primary                       { $1 }

Operator:
    | Operator OPERATOR Function    { Operator ($1, $2, $3) }

Function:
    | FUNCTION Function             { Function ($1, $2) }

Primary:
    | INT                           { Int $1 }
```

This is better, but we just broke a bunch of stuff. Since nothing bounces back
up to `Expression`, there isn't a way to actually terminate anything with an
integer anymore. We can no longer parse `foo 1` or `1 + 2`. The problem is that
when, for example, the operator rule references `Function`, what it means is
"you can insert any function expression here", but we *want* it to mean "you can
insert any function *or higher precedence* expression here". For our purposes,
that would mean a primary expression: an integer.

We can fix that by making each precendence level have a fall-through case to the
next highest level. Thus, anywhere we can use a function, we can also use a
primary, and anywhere we can use an operator, we can also use a function. Like
so:

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Operator                      { $1 }

Operator:
    | Operator OPERATOR Function    { Operator ($1, $2, $3) }
    | Function                      { $1 }

Function:
    | FUNCTION Function             { Function ($1, $2) }
    | Primary                       { $1 }

Primary:
    | INT                           { Int $1 }
```

Congratulations, we've fixed our precedence problem. Our parser will now
correctly parse `foo 1 / bar 2 + 3` as `((foo 1) / (bar 2)) + 3`. As a nice side
effect, the order of operations (from last to first) in our language is easily
visible simply by scanning through the grammar. This is trivial in this one, but
a language like C has something like 15 different precedence levels.

## (): "Hey, you forgot us!"

One last thing: with any expression system, users will also want to be able to
use parentheses to override the default order of operations. This is fixed by
adding a simple rule at the very end:

```text
start:
    | Expression SEMI               { $1 }

Expression:
    | Operator                      { $1 }

Operator:
    | Operator OPERATOR Function    { Operator ($1, $2, $3) }
    | Function                      { $1 }

Function:
    | FUNCTION Function             { Function ($1, $2) }
    | Primary                       { $1 }

Primary:
    | INT                           { Int $1 }
    | LPAREN Expression RPAREN      { $2 }
```

All the way at the highest level of precedence, you can now use `()` to start
the cascade back over at the lowest predecence level (`Expression`). This
means that from the outside, a pair of parentheses have the highest
precedence, but are able to contain an expression of *any* precedence, thus
letting the cascade loop back on itself predictably.

Interestingly, you'll note that nothing specific needs to be done in the
action step for parentheses. Its effect is handled totally by the parser and
simply affects the shape of the AST generated.

## Conclusion

I'm still far from an expert when it comes to yacc. The reason I had to infer
this from an old C reference is because I don't have any [books](http://books.google.com/books?id=YrzpxNYegEkC&#038;dq=lex+and+yacc&#038;printsec=frontcover&#038;source=bn&#038;hl=en&#038;sa=X&#038;oi=book_result&#038;resnum=4&#038;ct=result) on the
subject, so there may be entirely inane things going on here I'm not aware of,
but I *think* this is a sound technique. For your own grammars, it's still
worth considering using the precedence and associativity built into yacc, but
if that doesn't work for you, this should be a viable alternative.
