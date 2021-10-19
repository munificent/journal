---
title: "Ruby Blocks, Python's "with", and Magpie's Test Suite"
categories: code language magpie python ruby
---

Part of moving a language from "tiny hobby project" to "thing that I hope people
will use" is a solid test suite. [Magpie][] has a test suite now, but it's kind
of ugly and is driven mostly from Java. What I'd like is something more like
[RubySpec][] for Ruby: a highly readable executable specification for the
language, written in itself.

[magpie]: https://magpie-lang.org/
[rubyspec]: http://www.rubyspec.org/

RubySpec is built on top of RSpec, a Ruby library that provides a DSL-like API
for writing tests. Here's what a chunk of spec looks like:

```ruby
describe "The 'and' statement" do
  it "short-circuits evaluation at the first false condition" do
    x = nil
    true and false and x = 1
    x.should be_nil
  end

  it "evaluates to the first condition not to be true" do
    ("yes" and 1 and nil and true).should == nil
    ("yes" and 1 and false and true).should == false
  end

  it "evaluates to the last condition if all are true" do
    ("yes" and 1).should == 1
    (1 and "yes").should == "yes"
  end
end
```

I find that wonderful to read. This is exactly the kind of thing that I think
gets people excited about Ruby. It relies on two nice features Ruby has: open
classes, and block arguments.

Open classes let us define the "bare functions" of that DSL: `describe` and `it`
are both methods added to the base `Object` class. Inside the spec, you'll see a
lot of calls to `.should`. That's also a method that's been patched into
`Object`.

## Block arguments in Ruby

Block arguments are then what get used to create the block structure you see
where it appears that `describe` and `it` are keyword-like. The actual semantics
are delightfully simple. If you do something like this in Ruby:

```ruby
blocky("bar") do
  puts "hi"
end
```

The block after `do` gets wrapped in something like a lambda and passed to the
method (`blocky` here) as another (unnamed) argument. That code basically gets
desugared to:

```ruby
blocky("bar", lambda {
  puts "hi"
})
```

The method that receives the block can then do stuff before and after it, and
invoke it by using `yield`. It's the ability to do stuff before and after that's
particularly nice. It makes it easy to write context managers or scoped behavior
where you have some setup and teardown that you want to wrap around some
user-provided behavior.

## Context Managers in Python

When I thought "context manager", that called to mind a [similar feature][with]
in Python: `with`. Python's system is a bit more complex and more directly tied
to scoped behavior. It looks like this:

[with]: http://www.python.org/dev/peps/pep-0343/

```python
with open('somefile.text') as f:
  contents = f.read()
```

This does a few things in sequence:

1.  Evaluates the expression after `with`.

2.  If `as` is provided, binds the result to a named variable.

3.  Calls the `__enter__` method on the result. This is where the context
    manager can perform setup work.

4.  Evaluates the body of the `with` statement.

5.  Finally, calls `__exit__` on the context manager so it can do teardown.

Python's system is a good bit more complex, but it's also more object-oriented
and handles the common scenario of an object that needs to initialize and
teardown well.

## Translating Python to Ruby

Both Python and Ruby's solutions cover valid use cases, but they seem to overlap
so much that it would be overkill to add both. Fortunately, you can implement
one in terms of the other. Ruby's system is much simpler, so here's `with`
implemented using it (minus important exception-handling stuff that I'll ignore
for now):

```ruby
class Object
  def with(obj)
    obj.__enter__
    yield
    obj.__exit__
  end
end
```

With that, you can do:

```ruby
with File.open("somefile.text", "r") do |f|
  contents = f.read
end
```

(Of course, you wouldn't actually do this in Ruby since its built-in `File`
class already has a nice method to do just this.)

## Block arguments in Magpie

Given that, it seemed like supporting block arguments in Magpie would let me
cover both cases. The implementation ended up being only about a dozen lines of
code in the parser. There is a new keyword `with`. If it appears after a message
send, a subsequent block is parsed and wrapped in a function.

That function is then be added as an argument to that message. Unlike Ruby, the
block argument isn't unnamed. From the method's perspective it just becomes
another regular argument and it needs to declare a named parameter for it.

There is one other small piece of syntactic sugar: when Magpie wraps the block
in a function, it declares the function to take a single parameter: `it`. When
the method that receives the block invokes it and passes in an argument, that
will be bound to `it`.

With this in place, I can start moving Magpie's test suite to something that
looks like this:

```magpie
specify("An 'and' expression") with
  it should("return the first arg if it is false.") with
    (0 and false) shouldBe(0)
  end

  it should("return the second arg if the first is true.") with
    (0 and 1) shouldBe(1)
  end

  it should("short-circuit if the first arg is false.") with
    var called = false
    false and (called = true)
    called shouldBe(false)
  end
end
```

Here, `specify` is a global function the test infrastructure provides. It calls
the block argument and passes in a test runner object that gets bound to `it`.
The test runner has a method `should` that takes a description and the body of a
test. `specify` and `it` do the setup required to keep track of success and
failure.

The only method we have to patch into `Object` is `shouldBe` which is used to
verify expected values. The end result is, I think, pretty nice looking, and
doesn't require much language support or monkey patching.

Here's some other fun stuff it enables:

```magpie
// Functional idioms:
var waldo = people find with it name == "waldo"
var positives = numbers filter with it > 0

// Context management:
File open("name.text") use with
  while it eof not do print(it readLine)
end
```

In the last example, `use` is a method that can be mixed into a class to call
setup and teardown methods on the receiver, like:

```magpie
def File use(block)
  this setup
  block(this)
  this teardown
end
```

## Multiple arguments

Automatically binding the argument to `it` is nice for a lot of cases, but what
if you actually want to pass multiple arguments to the block? To enable that,
I'm planning to add an optional parameter list following `with`. When present,
the interpreter uses that instead of `it`:

```magpie
// Sort by name:
collection sort with(a, b) a name compareTo(b name)
```

And that's about it. Not too bad for a handful of code, eh? Now I just have to
rewrite Magpie's entire test suite to use it...
