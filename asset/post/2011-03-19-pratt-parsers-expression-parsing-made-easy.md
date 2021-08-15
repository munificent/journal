---
layout: post
title: "Pratt Parsers: Expression Parsing Made Easy"
categories: code java js language magpie parsing
---

Every now and then, I stumble onto some algorithm or idea that's so clever and
such a perfect solution to a problem that I feel like I got smarter or gained
[a new superpower](http://xkcd.com/208/) just by learning it. [Heaps](http://en.wikipedia.org/wiki/Heap_%28data_structure%29) (just about the only
thing I got out of my truncated CS education) were one thing like this. I
recently stumbled onto another: [Pratt](http://en.wikipedia.org/wiki/Vaughan_Pratt) parsers.

When you're writing a parser, [recursive descent](http://en.wikipedia.org/wiki/Recursive_descent) is as easy as spreading
peanut butter. It excels when you can figure out what to do next based on the
next chunk of code you're parsing. That's usually true at the top level of a
language where things like classes are and also for statements since most
start with something that uniquely identifies them (`if`, `for`, `while`,
etc.).

But it gets tricky when you get to expressions. When it comes to infix
operators like `+`, postfix ones like `++`, and even mixfix expressions like
`?:`, it can be hard to tell what kind of expression you're parsing until
you're halfway through it. You *can* do this with recursive descent, but it's
a chore. You have to write separate functions for each level of precedence
(JavaScript has 17 of them, for example), manually handle associativity, and
smear your grammar across a bunch of parsing code until it's hard to see.

## PB & J, The Secret Weapon

Pratt parsing fixes just that. If recursive descent is peanut butter, Pratt
parsing is jelly. When you mix the two together, you get a simple, terse,
readable parser that can handle any grammar you throw at it.

Pratt's technique for handling operator precedence and infix expressions is so
simple and effective it's a mystery why almost no one knows about it. After
the seventies, top down operator precedence parsers seem to have fallen off
the Earth. Douglas Crockford's [JSLint](http://www.jslint.com/) uses one to [parse
JavaScript](http://javascript.crockford.com/tdop/tdop.html), but his treatment is one of the [very few](http://effbot.org/zone/simple-top-down-parsing.htm) remotely
modern articles about it.

Part of the problem, I think, is that Pratt's terminology is opaque, and
Crockford's article is itself rather murky. Pratt uses terms like "null
denominator" and Crockford mixes in extra stuff like tracking lexical scope
that obscures the core idea.

This is where I come in. I won't do anything revolutionary. I'll just try to
get the core concepts behind top down operator precedence parsers and present
them as clearly as I can. I'll switch out some terms to (I hope) clarify
things. Hopefully I won't offend anyone's purist sensibilities. I'll be coding
in Java, the vulgar Latin of programming languages. I figure if you can write
it in Java, you can write it in anything.

## What We'll Be Making

I'm a learn-by-doing person, which means I'm also a teach-by-doing one. So to
show how Pratt parsers work, we'll build a parser for a [tiny little toy
language called *Bantam*](https://github.com/munificent/bantam). It just has expressions since that's where
Pratt parsing is really helpful, but that should be enough to convince of its
usefulness.

Even though it's simple, it has a full gamut of operators: prefix (`+`, `-`,
`~`, `!`), postfix (`!`), infix (`+`, `-`, `*`, `/`, `^`), and even a mixfix
conditional operator (`?:`). It has multiple precedence levels and both right
and left associative operators. It also has assignment, function calls and
parentheses for grouping. If we can parse this, we can parse anything.

## What We'll Start With

All we care about is parsing, so we'll ignore the tokenizing phase. I slapped
together [a crude lexer](https://github.com/munificent/bantam/blob/master/src/com/stuffwithstuff/bantam/Lexer.java) that works and we'll just pretend that tokens are
raining down from heaven or something.

A token is just a chunk of meaningful code with a type and a string associated
with it. Given `a + b(c)`, the tokens would be:

```text
NAME "a"
PLUS "+"
NAME "b"
LEFT_PAREN "("
NAME "c"
RIGHT_PAREN ")"
```

Likewise, we won't be *interpreting* or *compiling* this code. We just want to
parse it to a nice data structure. For our purposes, that means our parser
should chew up a bunch of [`Token`](https://github.com/munificent/bantam/blob/master/src/com/stuffwithstuff/bantam/Token.java) objects and spit out an instance of
some class that implements [`Expression`](https://github.com/munificent/bantam/blob/master/src/com/stuffwithstuff/bantam/expressions/Expression.java). To give you an idea, here's a
simplified version of the class for a [conditional expression](https://github.com/munificent/bantam/blob/master/src/com/stuffwithstuff/bantam/expressions/ConditionalExpression.java):

```java
class ConditionalExpression implements Expression {
  public ConditionalExpression(
      Expression condition,
      Expression thenArm,
      Expression elseArm) {
    this.condition = condition;
    this.thenArm   = thenArm;
    this.elseArm   = elseArm;
  }

  public final Expression condition;
  public final Expression thenArm;
  public final Expression elseArm;
}
```

(You gotta love Java's "please sign it in quadruplicate" level of bureaucracy
here. Like I said, if you can do this in Java, you can do it in *any*
language.)

We'll be building this starting from a simple [`Parser`](https://github.com/munificent/bantam/blob/master/src/com/stuffwithstuff/bantam/Parser.java) class. This owns
the token stream, handles lookahead and provides the basic methods you'll need
to write a top-down recursive descent parser with a single token of lookahead
(i.e. it's LL(1)). This is enough to get us going. If we need more later, it's
easy to extend it.

OK, let's build ourselves a parser!

## First Things First

Even though a "full" Pratt parser is pretty tiny, I found it to be a bit hard
to decipher. Sort of like [quicksort](http://en.wikipedia.org/wiki/Quicksort),
the implementation is a deceptively-simple handful of deeply intertwined code.
To untangle it, we'll build it up one tiny step at a time.

The simplest expressions to parse are prefix operators and single-token ones.
For those, the current token tells us all that we need to do. Bantam has one
single-token expression, named variables, and four prefix operators: `+`, `-`,
`~`, and `!`. The simplest possible code to parse that would be:

```java
Expression parseExpression() {
  if (match(TokenType.NAME))       // return NameExpression...
  else if (match(TokenType.PLUS))  // return prefix + operator...
  else if (match(TokenType.MINUS)) // return prefix - operator...
  else if (match(TokenType.TILDE)) // return prefix ~ operator...
  else if (match(TokenType.BANG))  // return prefix ! operator...
  else throw new ParseException();
}
```

But that's a bit monolithic. As you can see, we're switching off of a
`TokenType` to branch to different parsing behavior. Let's encode that
directly by making a `Map` from `TokenTypes` to chunks of parsing code. We'll
call these chunks "parselets", and they will implement this:

```java
interface PrefixParselet {
  Expression parse(Parser parser, Token token);
}
```

An implementation of this to parse variable names is just:

```java
class NameParselet implements PrefixParselet {
  public Expression parse(Parser parser, Token token) {
    return new NameExpression(token.getText());
  }
}
```

We can use a single class for all of the prefix operators since they only
differ in the actual operator token itself:

```java
class PrefixOperatorParselet implements PrefixParselet {
  public Expression parse(Parser parser, Token token) {
    Expression operand = parser.parseExpression();
    return new PrefixExpression(token.getType(), operand);
  }
}
```

You'll note that it calls back into `parseExpression()` to parse the operand
that appears after the operator (i.e. to parse the `a` in `-a`). This
recursion takes care of nested operators like `-+~!a`.

Back in `Parser`, the chained `if` statements are replaced with a cleaner map:

```java
class Parser {
  public void register(TokenType token, PrefixParselet parselet) {
    mPrefixParselets.put(token, parselet);
  }

  public Expression parseExpression() {
    Token token = consume();
    PrefixParselet prefix = mPrefixParselets.get(token.getType());

    if (prefix == null) throw new ParseException(
        "Could not parse \"" + token.getText() + "\".");

    return prefix.parse(this, token);
  }

  // Other stuff...

  private final Map<TokenType, PrefixParselet> mPrefixParselets =
      new HashMap<TokenType, PrefixParselet>();
}
```

To define the grammar we have so far (variables and the four prefix
operators), we'll make this helper method:

```java
void prefix(TokenType token) {
  register(token, new PrefixOperatorParselet());
}
```

And now we can define the grammar like:

```java
register(TokenType.NAME, new NameParselet());
prefix(TokenType.PLUS);
prefix(TokenType.MINUS);
prefix(TokenType.TILDE);
prefix(TokenType.BANG);
```

This is already an improvement over a recursive descent parser because our
grammar is now more declarative instead of being spread out over a few
imperative functions, and we can see the actual grammar all in one place. Even
better, we can extend the grammar just by registering new parselets. We don't
have to change the `Parser` class itself.

If we *only* had prefix expressions, we'd be done now. Alas, we don't.

## Stuck In the Middle

What we have so far only works if the *first* token tells us what kind of
expression we're parsing, but that isn't always the case. With an expression
like `a + b`, we don't know we have an add expression until after we parse the
`a` and get to `+`. We'll have to extend the parser to support that.

Fortunately, we're in a good place to do so. Our current `parseExpression()`
method will parse a complete prefix expression including any nested prefix
expressions and then stop. So, if we throw this at it:

```java
-a + b
```

It will parse `-a` and leave us sitting on `+`. That's exactly the token we
need to tell what infix expression we're parsing. The only difference between
an infix expression and a prefix one here is that there's another expression
*before* the infix operator that it needs to have as an argument. Let's define
a parselet that supports that:

```java
interface InfixParselet {
  Expression parse(Parser parser, Expression left, Token token);
}
```

The only difference is that `left` argument, which is just the expression we
parsed before we got to the infix token. We'll wire this up to our parser by
having another table of infix parselets.

Having separate tables for prefix and infix expressions is important because
we'll often have both a prefix and infix parselet for a single `TokenType`. For
example, the prefix parselet for `(` handles grouping in an expression like `a
* (b + c)`. Meanwhile, the *infix* parselet handles function calls like
`a(b)`.

Now, after we parse the prefix expression, we hand it off to any infix one
that subsumes it:

```java
class Parser {
  public void register(TokenType token, InfixParselet parselet) {
    mInfixParselets.put(token, parselet);
  }

  public Expression parseExpression() {
    Token token = consume();
    PrefixParselet prefix = mPrefixParselets.get(token.getType());

    if (prefix == null) throw new ParseException(
        "Could not parse \"" + token.getText() + "\".");

    Expression left = prefix.parse(this, token);

    token = lookAhead(0);
    InfixParselet infix = mInfixParselets.get(token.getType());

    // No infix expression at this point, so we're done.
    if (infix == null) return left;

    consume();
    return infix.parse(this, left, token);
  }

  // Other stuff...

  private final Map<TokenType, InfixParselet> mInfixParselets =
      new HashMap<TokenType, InfixParselet>();
}
```

Pretty straightforward. We can implement an infix parselet for binary
arithmetic operators like `+` using something like:

```java
class BinaryOperatorParselet implements InfixParselet {
  public Expression parse(Parser parser,
      Expression left, Token token) {
    Expression right = parser.parseExpression();
    return new OperatorExpression(left, token.getType(), right);
  }
}
```

This also works for postfix operators. I'm calling them "infix" parselets, but
they're really "anything but prefix". If there's some expression that comes
before the token, it will be handled by an infix parselet, and that includes
postfix expressions and mixfix ones like `?:`.

Postfix is as easy as a single-token prefix parselet: it just takes the `left`
expression and wraps it in another expression:

```java
class PostfixOperatorParselet implements InfixParselet {
  public Expression parse(Parser parser, Expression left,
      Token token) {
    return new PostfixExpression(left, token.getType());
  }
}
```

Mixfix is easy too. It's pretty much a familiar recursive descent parser:

```java
class ConditionalParselet implements InfixParselet {
  public Expression parse(Parser parser, Expression left,
      Token token) {
    Expression thenArm = parser.parseExpression();
    parser.consume(TokenType.COLON);
    Expression elseArm = parser.parseExpression();

    return new ConditionalExpression(left, thenArm, elseArm);
  }
}
```

Now we can parse prefix expressions, postfix, infix, and even mixfix. With a
pretty small amount of code, we can parse expressions like `a + (b ? c! :
-d)`. We're done, right? Well… almost.

## Excuse You, Aunt Sally

Our parser *can* parse all of this stuff, but it doesn't parse it with the
right precedence or associativity. If you throw `a - b - c` at it, it will
parse it like `a - (b - c)`, which isn't right. (Well, actually it is
*right*&mdash;associative that is. We need it to be *left*.)

And this *last* step is where Pratt parsers go from pretty nice to totally
radical. We'll make two simple changes. We'll extend `parseExpression()` to
take a *precedence*&mdash;a number that tells which expressions can be parsed by
that call. If it encounters an expression whose precedence is lower than we
allow, it just stops parsing and returns what it has so far.

To make that check we need to know the precedence of any given infix
expression. We'll do that by letting the parselet specify it:

```java
public interface InfixParselet {
  Expression parse(Parser parser, Expression left, Token token);
  int getPrecedence();
}
```

Using that, our core expression parser becomes:

```java
public Expression parseExpression(int precedence) {
  Token token = consume();
  PrefixParselet prefix = mPrefixParselets.get(token.getType());

  if (prefix == null) throw new ParseException(
      "Could not parse \"" + token.getText() + "\".");

  Expression left = prefix.parse(this, token);

  while (precedence < getPrecedence()) {
    token = consume();

    InfixParselet infix = mInfixParselets.get(token.getType());
    left = infix.parse(this, left, token);
  }

  return left;
}
```

That relies on a tiny helper function to get the precedence of the current
token or default if there's no infix parselet for it:

```java
private int getPrecedence() {
  InfixParselet parser = mInfixParselets.get(
      lookAhead(0).getType());
  if (parser != null) return parser.getPrecedence();

  return 0;
}
```

And that's it. To use this, we'll set up a little precedence table:

```java
public class Precedence {
  public static final int ASSIGNMENT  = 1;
  public static final int CONDITIONAL = 2;
  public static final int SUM         = 3;
  public static final int PRODUCT     = 4;
  public static final int EXPONENT    = 5;
  public static final int PREFIX      = 6;
  public static final int POSTFIX     = 7;
  public static final int CALL        = 8;
}
```

To make our operators correctly handle precedence, they'll pass an appropriate
value back into `parseExpression()` when they call it recursively. For
example, the [`BinaryOperatorParselet`](https://github.com/munificent/bantam/blob/master/src/com/stuffwithstuff/bantam/parselets/BinaryOperatorParselet.java) instance that handles the `+`
operator will pass in `Precedence.SUM` when it parses its right-hand operand.

Associativity is easy too. If an infix parselet calls `parseExpression()` with
the *same* precedence that it returns for its own `getPrecedence()` call,
you'll get left associativity. To be right-associative, it just needs to pass
in *one less* than that instead.

## Go Forth and Multiply

I've rewritten the [parser for Magpie](https://github.com/munificent/magpie/blob/master/src/com/stuffwithstuff/magpie/parser/MagpieParser.java) using this and it worked like a
charm. I'm also working on a JavaScript parser based on this and again it's
been a great fit.

I find parsing like this to be simple, terse, extensible (Magpie, for example,
uses this to [let you extend its own syntax](http://journal.stuffwithstuff.com/2011/02/13/extending-syntax-from-within-a-language/) at runtime), and easy to
read. I'm at the point where I can't imagine writing a parser any other way. I
never thought I'd say this, but parsers are easy now.

To see for yourself, just take a look at [the complete program](http://github.com/munificent/bantam).
