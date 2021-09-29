---
title: "Extending Syntax from Within a Language"
categories: code java language magpie parsing
---

A [big goal](http://magpie.stuffwithstuff.com/internals/the-heart-of-magpie.html) with my little language Magpie is to do as much as possible
at the library level and keep the core language small. I've been toiling for
the past few weeks and I finally moved a *huge* chunk of Magpie over to the
library side: *all infix operators are now defined and implemented in Magpie*.
As far as the core language is concerned, it doesn't even *have* operators.

Not only can you now define your own infix operators, including specifying
precedence and associativity, but other large chunks of Magpie syntax are now
defined at the library level. Take this chunk of (meaningless) code:

```magpie
def doStuff(a, b)
    if a and b then
        print("Both " ~ a ~ " and " ~ b ~ " are truthy")
    else
        print("Their sum is " ~ a + b)
    end
end
```

The operators you see there, `+` and `~` (for string concatenation) are both
[implemented in Magpie](https://github.com/munificent/magpie/blob/master/base/operators.mag). So is the `and` keyword. (It's [particularly
interesting](https://github.com/munificent/magpie/blob/master/base/syntax/AndParser.mag) because it doesn't become just a regular function call since
it needs to short-circuit.) In fact, [not even `if`](https://github.com/munificent/magpie/blob/master/base/syntax/IfParser.mag) is baked into the
language. Or `def` [for that matter](https://github.com/munificent/magpie/blob/master/base/syntax/DefParser.mag). In fact, about the only bit up there
that is part of the core syntax is `print(...)`.

If this is the kind of thing you're interested in, I'll try to walk you
through how this is possible, and how it works.

## Pratt Parsers FTW!

The real magic bit that makes this work is [Pratt parsers](http://javascript.crockford.com/tdop/tdop.html). Magpie's core
parser, which is written in Java, is a slightly OOP-ified version of a top-
down operator precedence parser. That sounds intimidating, but it's actually
the simplest parser technique I've ever seen. I kind of wish everyone knew
about them, but I'm kind of glad no one does because it makes me feel like I
have a secret weapon.

Here's the Java code that parses expressions in Magpie (which means it parses
pretty much everything since Magpie doesn't have statements):

```java
public Expr parseExpression(int stickiness) {
  Token token = consume();
  PrefixParser prefix = mGrammar.getPrefixParser(token);
  Expect.notNull(prefix);
  Expr left = prefix.parse(this, token);

  while (stickiness < mGrammar.getStickiness(current())) {
    token = consume();

    InfixParser infix = mGrammar.getInfixParser(token);
    left = infix.parse(this, left, token);
  }

  return left;
}
```

That's it, for reals. Precedence, associativity, infix operators, they all get
handled by that little chunk of code. You may be thinking that `mGrammars`
variable hides all the dirty work. That's actually pretty simple too. It's
basically a container for two dictionaries. One maps tokens to prefix parsers,
and one maps them to infix parsers. So, you give it a `+` token representing
the plus operator, and it returns a parser object that knows how to parse an
addition expression. Prefix and infix parsers are just objects that implement
one of these dead simple interfaces:

```java
interface PrefixParser {
  Expr parse(MagpieParser parser, Token token);
}

interface InfixParser {
  Expr parse(MagpieParser parser, Expr left, Token token);
  int getStickiness();
}
```

I won't go into detail about how these work (I'm trying to throw together a
more complete post about just Pratt parsers later), but the important bit is
that the grammar being parsed is decoupled from the core parsing code.

[Recursive descent](http://en.wikipedia.org/wiki/Recursive_descent) parsers have a fixed set of functions representing
each grammar production. If you're using [yacc](http://dinosaur.compilertools.net/) or [bison](http://www.gnu.org/software/bison/), you'll
have an entirely separate offline process that generates code for your grammar
and bakes it in. But with this, our grammar is just a collection of objects.
If we toss a new instance of `PrefixParser` or `InfixParser` into the grammar
dictionary, we've just extended the syntax of the language.

## Exposing this to Magpie

This gets us partway there. Now we've got a simple architecture that lets us
decouple the grammar into separate objects. This is a worthwhile exercise in
itself because it makes the parsing code written in Java less monolithic, but
you still have to hack Java code and rebuild the interpreter to extend the
syntax. Lame.

To fix that, we'll build a shim. What we need is a Java object that implements
`PrefixParser` or `InfixParser` but which actually runs Magpie code to do the
parsing. I'll pick infix here just 'cause. It looks like this:

```java
private static class MagpieInfixParser extends InfixParser {
  public MagpieInfixParser(Interpreter interpreter, Obj parser) {
    mInterpreter = interpreter;
    mParser = parser;
  }

  public Expr parse(MagpieParser parser, Expr left, Token token) {
    // Wrap the Java parser in a Magpie one.
    Obj parserObj = mInterpreter.instantiate(
        mInterpreter.getMagpieParserClass(), parser);
    Obj exprObj = JavaToMagpie.convert(mInterpreter, left);
    Obj tokenObj = JavaToMagpie.convert(mInterpreter, token);
    Obj arg = mInterpreter.createTuple(
        parserObj, exprObj, tokenObj);

    // Let the Magpie code do the parsing.
    Obj expr = mInterpreter.invokeMethod(mParser, "parse", arg);

    // Marshall it back to Java format.
    return MagpieToJava.convertExpr(mInterpreter, expr);
  }

  public int getStickiness() {
    return mInterpreter.getMember(Position.none(),
        mParser, "stickiness").asInt();
  }

  private Interpreter mInterpreter;
  private Obj mParser;
}
```

There are a couple of important bits here. The `Obj` class is the core class
in the interpreter that represents a Magpie object. If `Object` is any object
in Java land, `Obj` is any object in Magpie land.

`Interpreter` is exactly what it sounds like: the class that represents a live
Magpie interpreter. It keeps track of variables and provides helper functions
for executing code.

There are two static classes, `MagpieToJava` and `JavaToMagpie`. Their job is
to marshall objects between the two languages. They convert from Magpie `Obj`
instances to instances of appropriate "real" Java classes and back.

Given that, the shim's job is dead simple. When you call `parse` on the
`MagpieInfixParser` object, it just translates the arguments to Magpie and
invokes a `parse` method on its Magpie-side sister object. It gets the result
back (an expression) and marshalls that back to Java and returns it.

## The Other Side of the Glass

Over in Magpie, it looks like this:

```magpie
class AndParser
    def parse(parser MagpieParser, left Expression,
              token Token -> Expression)
        // Ignore a newline after "and".
        parser matchToken(TokenType line)
        var right = parser parseExpression(stickiness)
        { do
            var temp__ = `left
            match temp__ true?
                case true then `right
                else temp__
            end
        end }
    end

    get stickiness Int = 30
end

MagpieParser registerInfixParser("and", AndParser new())
```

The Magpie side of the parser is just a class with a `parse` method. The first
two lines parse the rest of the expression (the left-hand side of the operator
will have already been parsed and gets passed in as `left`). Then the last bit
in curly braces shows another neat feature of Magpie: [quotations](http://magpie.stuffwithstuff.com/objects/quotations.html).

Like the Lisp languages, Magpie lets you treat code as data, and has classes
to let you build objects that represent bits of code. Doing that manually is
kind of lame though:

```magpie
CallExpression new(MessageExpression(name: "+"),
    TupleExpression new(List of(
        IntExpression new(1), IntExpression new(2))))
```

Quotations let you write that out just like it would appear in code:

```magpie
{ 1 + 2 }
```

If you surround an expression in curlies, you'll get an object representing the
expression back, instead of evaluating it. Inside a quotation, you can unquote
using a backquote character (`` ` ``), which is like string interpolation but at
the code level, not textual. That way you can build chunks of code declaratively
and fill in the blanks with dynamically-generated stuff.

So the parser class here returns that last quotation, which contains a `match`
expression (Magpie has full destructuring pattern matching, and that *is* one
of the core primitive parts of the language).

Finally, the call to `registerInfixParser` just takes that object and passes
it over to Java. That's where we wrap it in the shim class and toss it into
the grammar dictionary.

Once this parser is all hooked up, when an `and` is encountered, the parser
will desugar it to a little pattern match that does the right thing. In other
words, if you type:

```magpie
happy and know(it)
```

It will expand to:

```magpie
do
    var temp__ = happy
    match temp__ true?
        case true then know(it)
        else temp__
    end
end
```

That looks a little weird, but if you think about it, it does the right thing.
If `happy` is truthy, it will return `know(it)`. Otherwise, it will short-
circuit and return just `happy`.

## But That's Too Hard!

Now we can extend the syntax from Magpie, which is cool. But I gotta admit,
that `AndParser` class is a bit hairy, even with quotations in there. Let's
say I want to make a `~*` operator that repeats a string a given number of
times. Do I have to write a whole class just to do that?

The answer is "no", of course. If you just want an infix operator that
desugars to a function call, look no further than:

```magpie
definfix ~* 60 (left String, count Int -> String)
    var result = ""
    for i = 1 to(count) do result = result ~ left
    result
end
```

Here `60` defines the precedence level so it knows how to parse our new
operator if you're crazy enough to mix it in with others without parentheses.
Now when the parser encounters:

```magpie
"Beetlejuice " ~* 3
```

It will transform that to a call to:

```magpie
~*("Beetlejuice ", 3)
```

You may be wondering where `definfix` comes from. Why, it's a custom parser
[written in Magpie](https://github.com/munificent/magpie/blob/master/base/syntax/OperatorParser.mag), of course! Turtles all the way down!

## OH NOES!

I got all of this working and then ran into a real snag. Let's say we have
some module that defines a new operator:

```magpie
// In repeat.mag:
definfix ~* 60(left String, count Int -> String)
    var result = ""
    for i = 1 to(count) do result = result ~ left
    result
end
```

Then we want to import it and use it in another one:

```magpie
// In summon-ghost.mag:
import("repeat.mag")

print("Beetlejuice " ~* 3)
```

Do you see the problem? Let's walk through how most interpreters (including
Magpie) handle this:

  1. The user runs `magpie summon-ghost.mag`.

  2. The interpreter starts up.

  3. It reads `summon-ghost.mag` and parses it.

  4. It starts interpreting it…

  5. It evaluates the `import` and parses and runs `repeat.mag`

  6. It evaluates the `print("Beetlejuice " ~* 3)` line.

Crap. It parses *all* of `summon-ghost.mag` before it has had a chance to
evaluate the `import` and actually define the operator we need to parse. So
the parser is going to hit `~*` and not know what to do with it.

But, a clever solution appears! It turns out that when Magpie is parsing the
top level of a file, it returns a list of expressions. In other words, a
Magpie program isn't a single giant block expression, it's a flat list of
distinct ones. (Each expression in that list may be arbitrarily big and
nested, of course, but at the top level, it's a list.)

This gives us an opening to fix this little problem. It can parse and evaluate
each expression in a file *incrementally*. Getting this working was actually
[a tiny code change](https://github.com/munificent/magpie/commit/bffe49291e9709b5bfc960420fcc6f5a4b1614bd) and means you can now extend the syntax *and then use
that extension immediately in the same file*. This is perfectly valid:

```magpie
definfix ~* 60(left String, count Int -> String)
    var result = ""
    for i = 1 to(count) do result = result ~ left
    result
end

print("Beetlejuice " ~* 3)
```

The only limitation is that you have to do this at the top-level. Given that
most languages don't let you do *any* of this, that doesn't seem like too much
to give up. In return, we can make the language dramatically more powerful at
building internal DSLs, and the core language itself becomes *simpler*.
