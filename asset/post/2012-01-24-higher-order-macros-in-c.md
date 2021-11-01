---
title: "Higher Order Macros in C++"
categories: code c cpp
---

My hobby project lately has been working on a little [bytecode interpreter][]
for [Magpie][] in C++. As an ex-game programmer, I'm pretty sad at how rusty my
C++ has gotten. To try to make things a bit easier on myself, I've been
borrowing from the masters whenever possible. That means I usually have [V8][]'s
source code open in another window.

[bytecode interpreter]: https://github.com/munificent/magpie
[magpie]: http://magpie-lang.org/
[v8]: https://github.com/v8/v8

(Aside: if you're interested in programming languages, it is *so awesome* that
implementations like V8 and [Spidermonkey][] are open source and just a click
away. Learning from them is a bit like taking your first martial arts lesson
from an angry Bruce Lee, but it's still amazing that industry-leading codebases
are just there waiting for your perusal.)

[spidermonkey]: http://hg.mozilla.org/mozilla-central/file/1982c882af0f/js/src

In all honesty, my usual process looks a bit like:

1.  "Hmm, I need to code up a floobinator. V8 has one. Let me see how they do
    it."

2.  *Hunt through V8 code...*

3.  "Ah, here it is."

4.  OH GOD, WHAT WIZARDRY IS THIS.

About 90% of it is [over my head][], but I figure 10% of v8 is still a pretty
good chunk of smart. There is one clever technique I learned from them that I
*do* understand: macros that take macros as arguments. That's the point of this
post.

[over my head]: https://github.com/v8/v8/blob/main/src/codegen/ia32/assembler-ia32.cc

## The problem

C++ is a pretty powerful language for defining abstractions which let you get
rid of redundancy. Functions and methods address duplicate chunks of imperative
code. Base classes let you reuse data definitions. Templates let you do...
well... [almost anything][].

[almost anything]: http://crazycpp.wordpress.com/category/template-metaprogramming/

Even so, there are still often hunks of repetition that you can't seem to
eliminate. For example, let's say we're working with a language's syntax.
Typically, the [parser][] generates an [AST][] which then gets passed to the
[compiler][]. The compiler walks the AST using [Ye Olde Visitor
Patterne][visitor pattern] and generates some [lower-level
representation][bytecode] for it.

[parser]: https://github.com/munificent/finch/blob/master/src/Syntax/Parser.h
[ast]: http://en.wikipedia.org/wiki/Abstract_syntax_tree
[compiler]: https://github.com/munificent/finch/blob/master/src/Compiler/Compiler.h
[visitor pattern]: http://en.wikipedia.org/wiki/Visitor_pattern
[bytecode]: https://github.com/munificent/finch/blob/master/src/Compiler/Block.h

Depending on how rich your language is, you'll have quite a few different AST
classes to represent the different syntactic elements: literals, unary
operators, infix expressions, statements, flow control, definitions, etc. V8,
for example, has [40][ast2] classes to cover everything you can express in
JavaScript.

[ast2]: https://github.com/v8/v8/blob/main/src/ast/ast.h

These are relatively simple types. A (greatly!) simplified one looks a bit like:

```cpp
class BinaryOpExpr : public Expression {
  BinaryOpExpr(Expression* left, Expression* right)
  : left(left),
    right(right) {}

  virtual void accept(AstVisitor& visitor) {
    visitor.visitBinaryOpExpr(this);
  }

  Expression* left() { return left; }
  Expression* right() { return right; }

private:
  Expression* left;
  Expression* right;
};
```

Imagine thirty-something-odd more classes like this and you've got the right
idea. There isn't *too* much we can do in C++ to simplify these definitions
themselves. Each class is different enough that it's simplest and clearest to
just write them out.

Where the tedium really comes in is all of the surrounding code that *uses*
these classes. First up is the aforementioned [visitor][]. To make it easy for
the compiler to dispatch to different code based on the different AST classes,
you typically define a class like:

[visitor]: https://github.com/v8/v8/blob/main/src/ast/ast.h#L2680

```cpp
class AstVisitor {
public:
  ~virtual AstVisitor() {}

  virtual void visitBoolLiteral(BoolLiteral* expr) = 0;
  virtual void visitNumLiteral(NumLiteral* expr) = 0;
  virtual void visitStringLiteral(StringLiteral* expr) = 0;
  virtual void visitUnaryOpExpr(UnaryOpExpr* expr) = 0;
  virtual void visitBinaryOpExpr(BinaryOpExpr* expr) = 0;
  virtual void visitAssignmentExpr(AssignmentExpr* expr) = 0;
  virtual void visitConditionalExpr(ConditionalExpr* expr) = 0;
  virtual void visitIfThenStmt(IfThenStmt* expr) = 0;
  // 30 more of these, you get the idea...
};
```

That code really *is* just repetitive boilerplate. There's more. It's useful to
also have an enum for each AST node type so that we can also `switch` directly
on the type of a node without having to go through a visitor for everything.
Something like:

```cpp
enum AstType {
  kBoolLiteral,
  kNumLiteral,
  kStringLiteral,
  kUnaryOpExpr,
  kBinaryOpExpr,
  // again, you get the idea...
};
```

For debugging, it's handy to be able to get a string representation for an AST
node's type too:

```cpp
const char* typeString(AstType type) {
  switch (type) {
    case kBoolLiteral:  return "BoolLiteral";
    case kIntLiteral:   return "IntLiteral";
    case kNumLiteral:   return "NumLiteral";
    case kUnaryOpExpr:  return "UnaryOpLiteral";
    case kBinaryOpExpr: return "BinaryOpLiteral";
    // yup...
  }
}
```

C++'s usual abstraction facilities don't help us here -- in all of these cases
the repetition is in the *middle* of some type definition or statement. C++ is
really only designed to let you abstract over entire statements (by making
functions) or types (by making templates or base classes).

## Let's get dirty

But there is, of course, one grease-covered rusty tool in the C and C++ toolbox
that doesn't give a damn about actual syntactic elements: *the preprocessor.* It
doesn't even know what a statement *is*. It just sees chunks of text.

More often than not, that fact makes it too blunt of an instrument to be wielded
indiscriminately without risking bloodshed but here it's just what we need. In
all of our problem examples, we want to be able to say "for each AST node type,
generate this chunk of code but with the node's class name inserted in a few
places."

Let's try doing something like this:

```cpp
#define DEFINE_VISIT(type)  \
    virtual void visit##type(type* expr) = 0
```

With this, we can simplify our visitor class to:

```cpp
class AstVisitor {
public:
  ~virtual AstVisitor() {}

  DEFINE_VISIT(BoolLiteral);
  DEFINE_VISIT(NumLiteral);
  DEFINE_VISIT(StringLiteral);
  DEFINE_VISIT(UnaryOpExpr);
  DEFINE_VISIT(BinaryOpExpr);
  DEFINE_VISIT(AssignmentExpr);
  DEFINE_VISIT(ConditionalExpr);
  DEFINE_VISIT(IfThenStmt);
  // 30 more of these, you get the idea...
};
```

That's a *little* better, I guess. But not really. This trick doesn't help at
all with the enum, and only helps a little in `typeString()`. The problem is
that it's the "for each AST type" part of our problem where the repetition
really is. It's the *loop itself* we want to abstract over more than the loop
*body*.

What we want is a macro that will *itself* walk over all of the types, like:

```cpp
#define AST_NODE_LIST   \
    BoolLiteral         \
    NumLiteral          \
    StringLiteral       \
    UnaryOpExpr         \
    ...
```

But of course, that one doesn't do anything useful. We don't want it to just
expand to the type names themselves. It needs to do something with them. But
that something is different for each problem area. We need it to take a
parameter that is the chunk of code that we generate for each type. Like:

```cpp
#define AST_NODE_LIST(code) \
    code(BoolLiteral)       \
    code(NumLiteral)        \
    code(StringLiteral)     \
    code(UnaryOpExpr)       \
    ...
```

## Macros taking macros... we must go deeper

Now the fun part. When we use that `AST_NODE_LIST` macro, what is that `code`
argument going to be? It needs to be a thing that's available at preprocess
time, can take an argument, and can generate a chunk of code. That leaves only
one answer: a macro.

Until I saw this in V8, I didn't even know you *could* pass macros to macros.
But indeed you can. Using the `AST_NODE_LIST` macro we just defined, our visitor
becomes:

```cpp
class AstVisitor {
public:
  ~virtual AstVisitor() {}

  #define DEFINE_VISIT(type) \
      virtual void visit##type(type* expr) = 0

  AST_NODE_LIST(DEFINE_VISIT)

  #undef DEFINE_VISIT // Clean it up since we're done with it.
};
```

When `AST_NODE_LIST` is expanded, it expands to one call to `DEFINE_VISIT` for
each of the AST node types. Then *those* are in turn expanded to define the
visitor method for that type.

Likewise, our enum becomes:

```cpp
#define DEFINE_ENUM_TYPE(type) k##type,

enum AstType {
  AST_NODE_LIST(DEFINE_ENUM_TYPE)
};

#undef DEFINE_ENUM_TYPE
```

That's the whole thing in its entirety. Finally, the function for converting it
to a string:

```cpp
#define DEFINE_TYPE_STRING(type) case k##type: return #type;

const char* typeString(AstType type) {
  switch (type) {
    AST_NODE_LIST(DEFINE_TYPE_STRING)
  }
}

#undef DEFINE_TYPE_STRING
```

Note that we're using [stringification][] and [token pasting][] here to not only
substitute in the AST node class's name, but also to use it as a string literal,
or to build a larger identifier (like `kBinaryOpExpr`) from it.

[stringification]: https://gcc.gnu.org/onlinedocs/gcc-4.8.5/cpp/Stringification.html
[token pasting]: https://gcc.gnu.org/onlinedocs/cpp/Concatenation.html

This gets rid of some tedious code, but it has another nice side-effect. If you
later need to add a new node class, you just add it to `AST_NODE_LIST`. Once
it's there, every place that's using that will automatically pick it up. That
way you don't have to remember to touch `AstVisitor`, `AstType` and
`typeString()`.

I can't tell if this is crazy awesome, or just plain crazy, but it's not
something you see every day. What other interesting stuff is hiding inside your
favorite open source project?
