---
title: "Multiple Inheritance in JavaScript"
categories: code javascript language
---

You know how when you stare at a hot stove you feel this weird compulsion to put
your hand on it? The longer you stare, the stronger the pull, even though you
know you'll just burn the crap out of yourself. I got a similar compulsion a
couple of days ago: *I think I can implement multiple inheritance in
JavaScript.*

I put my hand on the metaphorical burner. It turns out that you *can*, in Firefox 4 Beta, at least. Never one to shy away from a good hack, I figured I'd break it down so you can see how it works. (The whole enchilada is [here][code].) As a nice bonus, you'll get exposed to a potentially really cool feature coming down the pipe in JavaScript, and maybe even change the way you think about multiple inheritance.

[code]: https://github.com/munificent/multipleinheritance.js

## What's the problem?

Before I go into how I made this work, let me explain why I was even thinking
about this. As is often the case, frustration was the mother of this invention.
My problem was something like this:

Let's say you have a [widget library][], a hierarchy of widget classes that you
can inherit from to build your own controls. Like all good 21st century class
libraries, it strictly uses single inheritance, because multiple inheritance is
the devil. Here's a piece of that hierarchy (in full ASCII art glory):

[widget library]: https://developers.google.com/closure/library

```asciiart
       ┌────────┐
       │ Widget │
       └────┬───┘
            │
     ┌──────┴──────┐
┌────┴─────┐ ┌─────┴─────┐
│ Hideable │ │ Container │
└──────────┘ └───────────┘
```

Widget is the root class that all widgets eventually inherit from. It has the
core bits than any widget will need, maybe a name, etc. Hideable adds `show()`
and `hide()` methods for widgets that should be able to toggle their visibility.
Container is for parent widgets that can contain other child widgets. It defines
`addChild()`, `listChildren()`, etc.

Now I come along to build my little widget. Mine is called DropDownMenu. As you
can guess, it has a collection of child widgets (the menu items). And it needs
to be shown and hidden (since it's a drop-down). You can see the problem. I
can't inherit from both Hideable and Container.

One fix is to reorganize the base classes like this:

```asciiart
 ┌────────┐
 │ Widget │
 └────┬───┘
┌─────┴─────┐
│ Container │
└─────┬─────┘
┌─────┴────┐
│ Hideable │
└──────────┘
```

Now I just inherit from Hideable and I'm good. But then tomorrow I need to make
a new Widget: Tooltip. It can be hidden and shown, but it doesn't need any
children. It will have to inherit from Hideable, but that implicitly rolls in
all this Container stuff it doesn't want, wasting memory.

Worse, it makes it more complicated to understand. Someone coming along later
may look at my Tooltip class and think it needs stuff from Container and spend
time trying to figure out what and why. Changes to Container have the potential
to break Tooltip, even though it's getting no benefit from it. Lame!

The fix for this is to rearrange things again. If some things need Hideable but
not Container, it should be above it in the hierarchy, like so:

```asciiart
 ┌────────┐
 │ Widget │
 └────┬───┘
┌─────┴────┐
│ Hideable │
└─────┬────┘
┌─────┴─────┐
│ Container │
└───────────┘
```

Fine and dandy. The day after tomorrow comes and now I'm making a new widget
again: ListBox. It doesn't hide, but it does have children. I'm right back where
I started. There is no solution for this:

**Given single inheritance, there is *no* possible class hierarchy that lets you
combine an arbitrary combination of classes.**

I spent a lot of time trying to figure out the "right" class for me to inherit
from for my widget and not knowing why I was so frustrated before the above
finally clicked in my head. It isn't me that's wrong. It isn't the class
hierarchy of the library I'm using. It's the assumption that single inheritance
is adequate.

## Prior art

Before I run off to my text editor, what about other JS class systems? I'm no
expert on JavaScript libraries, but the ones I've seen that fake classes and
inheritance do so by manipulating the prototype chain, and almost all of them
stay within the limitation that imposes: single inheritance. That's an excellent
choice in terms of simplicity and performance, but not what I'm going for.

Tom Van Cutsem's [Traits.js][] is a notable counter-example. It allows multiple
traits to be composed. I believe it does so by flattening out the traits at
composition time. If you compose two traits A and B together to form a new one,
C, then add a new member to A afterwards, C won't have it. That's better, but
still not what I wanted.

[traits.js]: https://traitsjs.github.io/traits.js-website/

I wanted to do full late-bound multiple inheritance. One of the swell things
about JavaScript is that you can extend existing prototypes. I wanted that to
work even with multiple inheritance. If I add a method to an existing base
class, every class that inherits from it should get it, even if they were
defined *before* I added my new method.

## The prototypal prototype language

Given my goals, it still isn't clear what *kind* of multiple inheritance system
I want. Should it work [like C++][cpp]? Like [mixins in Ruby][ruby]? [Traits in
Scala][scala]? Of course, if you think about it, there's really only one
answer...

[cpp]: http://www.parashift.com/c++-faq-lite/basics-of-inheritance.html
[ruby]: http://ruby-doc.com/docs/ProgrammingRuby/html/tut_modules.html
[scala]: https://docs.scala-lang.org/tour/traits.html

The Grandaddy of prototype-based languages, the one that directly inspired Eich
to create JavaScript, and (I think) the language that first coined the term
"trait" is [Self][]. Self has a way of handling multiple inheritance that --
like many things in the language -- is both surprisingly simple and surprisingly
powerful.

[self]: http://en.wikipedia.org/wiki/Self_(programming_language)

It works like this: Every object has a collection of properties, just like
JavaScript. If the name of a property ends in an asterisk (`*`), it's considered
a "parent property". When we look up a property on an object, the process is
just:

1.  If the object has the property itself, return it.

2.  Otherwise, try looking it up on the parent properties. Go through them in
    alphabetical order, and stop as soon as we find the property.

When we check a parent for a property, it may in turn look at *its* parents, so
property lookup is a depth-first search through the parent property graph.

This is almost trivially simple, but a ton of awesome stuff falls out of it like magic:

### Single inheritance

Single inheritance is easy of course: just make an object that only has one
parent property. JavaScript is basically a degenerate case of Self dispatch
where the rule for naming a parent property is "must be `__proto__`".

### Multiple inheritance

And, of course, multiple inheritance is easy. Just have more than one parent
property. Since objects are completely open bags of properties, you can tack on
as many as you want.

### Dynamic inheritance

Here's where it starts to get interesting. When we're walking the parents
looking for a property, we look at the *value* stored in that parent property.
Like any other property, you can assign a new value to it. That means, *at
runtime*, you can change an object's parents. In effect, a live object can
spontaneously change its class.

You know that whole [State design pattern][] that takes a pile of code to implement in Java? With this, it's just: `object.someParent = newState`.

[state design pattern]: http://en.wikipedia.org/wiki/State_pattern

### Controlled resolution order

One of the challenges with multiple inheritance is figuring out what actual
method gets called when there's a name collision. If MyClass inherits from two
other classes that both have `foo()`, which one do I get when I call
`myObject.foo()`?

In Self, you can control that easily -- just name the parent properties so that
the one you want to take priority comes first alphabetically.

### Simple constructors

Another annoying facet of multiple inheritance is object construction. Each of
your base classes may have its own constructor which needs to get called when
the derived class is constructed. Languages often have complex special support
just for this: constructor initialization lists in C++, `super()` in Java,
`base()` in C#, definite assignment static analysis to make sure you initialize
your members, etc.

When your "base classes" are just properties on the object, construction becomes
simply assigning some properties.

## Back to our example

So, assuming we can magically make this work, how would it look in JavaScript?

Here's my goal. I want to be able to define a couple of widget "base classes"
like this vanilla JavaScript:

```javascript
function Widget(name) {
  this.name = name;
}

Widget.prototype.getName = function() {
  return this.name;
}

function Hideable() {}

Hideable.prototype.hide = function() {
  log('hide ' + this.getName());
}

Hideable.prototype.show = function() {
  log('show ' + this.getName());
}

function Container() {
  this.children = [];
}

Container.prototype.addChild = function(widget) {
  log('addChild ' + widget.getName() + ' to ' + this.getName());
  this.children.push(widget);
}

Container.prototype.listChildren = function() {
  log('children for ' + this.getName());
  for (var i = 0; i &lt; this.children.length; i++) {
    log('- ' + this.children[i].getName());
  }
}
```

When I create my widget class, I want to inherit from all of those by creating
parent properties that contain one of each. Since I can't use `*` in a property
name in JavaScript, I'll use `_p`. So my widget's constructor should just be:

```javascript
var MyWidget = magic(function(name) {
  this.widget_p    = new Widget(name);
  this.hider_p     = new Hideable();
  this.container_p = new Container();
})
```

Aside from that little `magic` bit there, this looks like any other JavaScript constructor, but when I *use* this object, it should support all the methods those parent objects provide. In other words, this should work:

```javascript
var widget = new MyWidget('Abe');

// From Widget:
log(widget.getName());

// From Hideable:
widget.hide();
widget.show();

// From Container:
widget.addChild(new MyWidget('Ben'));
widget.addChild(new MyWidget('Cid'));
widget.addChild(new MyWidget('Dan'));
widget.listChildren();
```

Unpossible you say? Read on:

## Behold the power of proxies

One of the planned features for [Harmony][], the codename of the next version of
ECMAScript is support for [proxies][]. A proxy, as its name implies, is an
object that stands in for another. If you have a proxy object `jamesBrown` and
you do something with it like `jamesBrown.getOnUp()` the runtime will delegate
that call to a hidden proxy object.

[harmony]: https://en.wikipedia.org/wiki/ECMAScript#ES2015
[proxies]: https://tvcutsem.github.io/proxies_tutorial

On its own, that could be little more than a level of indirection, but what's
important is *how* it delegates. It does so *imperatively*. If you look up a
property on a proxy, JavaScript doesn't just automatically look up a property
with the same name on the handler object. Instead, it calls a single magic `get`
method on that handler with the name of the property being requested.

With that indirection, we have full *programmatic* control over dispatch. We can
implement *any* kind of inheritance scheme we dream up. All we need to do is
replace a regular object with a proxy that has a handler that implements our
inheritance scheme.

For Self-style parent properties, a very primitive hacked-together handler is
simply:

```javascript
function createSelfHandler(obj) {
  return {
    get: function(receiver, name) {
      // Look in the main object.
      var value = obj[name];
      if (value !== undefined) return value;

      // Look in the parents.
      // BUG: Should look in field alphabetical order.
      for (var field in obj) {
        if (field.endsWith('_p')) {
          value = obj[field][name];
          if (value !== undefined) return value;
        }
      }

      // Not found.
      return undefined;
    }
  };
}
```

Whenever we create an instance of our MyWidget class, we actually want to get an
instance of that proxy instead. We do that by proxying the constructor too:

```javascript
function magic(ctor) {
  var callTrap = function(args) {}
  var constructTrap = function(args) {
    return Proxy.create(createSelfHandler(
        new ctor(args)), Object.prototype);
  };
  return Proxy.createFunction(ctor, callTrap, constructTrap);
}
```

Ta-da! Now when we do `new MyWidget()` we get back a proxy object. When we then
look up any properties on it, the proxy shunts over to our dispatch function
that knows how to handle the parent property shenanigans. Self-style multiple
prototypes in the comfort of your very own browser.

## Is this a good idea?

The short answer is "no", of course. This little hack should never ever enter
the world of real code. I just wanted to see if I could get it to work. Proxies
are so incredibly powerful that this is just scratching the surface of what you
can do with them. (Did I hear you say "Active Record in JavaScript"? Or was that
"remote object"?). But this is truly an inglorious hack and I hate to think of
what the performance would be with an app built around this.

The more important question, though, is, "Is multiple inheritance a good idea?"
While I was a "single inheritance + interfaces" Kool-Aid drinker for many years,
I'm starting to feel like the answer is "yes".

One of the most powerful tools in the programmer's toolbox is *composition* --
making new things by combining existing parts together. Being able to compose
out of *multiple* parts gives us the ability to create `2^n` different
combinations from just `n` unique parts. We shouldn't give that power up without
good reason.

## But multiple inheritance killed my dog!

Paraphrasing a [classic quote][]:

[classic quote]: http://regex.info/blog/2006-09-15/247

> Some people, when confronted with a problem, think "I know, I'll use multiple
> inheritance." Now they have multiple problems.

It's true, there are real problems with multiple inheritance, but my hunch is
they've been blown out of proportion. The number of grizzled C++ programmers
who've been personally scarred by multiple inheritance is dwindling over time,
and tales of it now are like stories of the boogeyman told around campfires,
getting increasingly horrific with each retelling.

When you get down to it, the two major problems I know of are:

*   Getting duplicate state by having multiple paths to the same base class.

*   Getting ambiguous or confusing dispatch when multiple classes override the
    same method.

There are two simple solutions: *minimize state* and *minimize collisions*.

Minimizing state -- as we're finally learning from the functional tribe -- is a
good idea in general. The less state you have, the easier your code is to
understand. So, if you're creating a class that's intended to be inherited a
lot, try to keep the number of fields it defines to a minimum. Ideally, it will
just be a bag of methods with no state at all.

Minimizing collisions can be done by trying to keep your hierarchy as flat as
possible. Allowing multiple inheritance actually *helps* here since you don't
need deep chains of single inheritance just so your leaf classes can inherit a
bunch of stuff. They can directly inherit those pieces all in one flat list.

Good class design -- cohesion and coherence -- helps too. If your classes each
do one small thing and only one thing, odds should be good that they won't have
any methods that collide. Having name collisions should be a code smell: Why is
the same named concept smeared across a bunch of classes?

## So just use composition

What I'm describinh sounds a lot more like composition than inheritance. The way
MyWidget is constructed, we literally *are* composing it: the base classes are
properties on it directly. So why not just use that? Why shouldn't the above
example simply be:

```javascript
var widget = new MyWidget('Abe');

// From Widget:
log(widget.getWidget().getName());

// From Hideable:
widget.getHideable().hide();

// From Container:
widget.getContainer().addChild(new MyWidget('Ben'));
```

Aside from the fact that it's ugly, there's one thing I don't like about that.
The fact that MyWidget gets `hide()` from Hideable should be an implementation
detail. From the caller's perspective, `hide()` is something a MyWidget can do,
it doesn't and shouldn't care *how* or where that code is defined.

## Where to next

What all of this boils down to is how I'd like to be able to code. I want to be
able to build my classes by composing them out of a flat set of reusable traits.
I don't want framework designers to spend weeks agonizing over brittle
hierarchies that still leave some users in the cold. Instead, I want them to be
able to say, "Here's our 31 different toppings, mix in any ones you like".

At the same time, I'd like those traits/mixins/whatever to themselves be open to
extension. Let's say there's an "enumerable" trait that any traversable
collection class inherits. I want to be able to add methods like `map()` and
`fold()` directly to that class so that I can use those methods on every
*enumerable* class in my codebase without having to shunt over to [ugly useless
helper classes][collections] like `Collections.max(someEnumerable)`.

[collections]: https://docs.oracle.com/javase/7/docs/api/java/util/Collections.html

Less boilerplate, less copy and paste, flatter hierarchies, better
composability. That's what I'm going for.
