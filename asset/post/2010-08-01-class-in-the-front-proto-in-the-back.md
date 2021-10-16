---
title: "Class in the Front, Proto in the Back"
categories: code java language magpie
---

Inspired by what I learned and saw at the Emerging Languages Camp, I've started
working on [Magpie][] again. It's been more or less dormant while I figured out
what kind of language I wanted it to be.

[magpie]: https://magpie-lang.org/

One big change is that Magpie Redux is going to be object-oriented where the
original Magpie was procedural. Magpie was an experiment to see if a procedural
language can be as nice to use as an OOP one if you give it memory management
and a decent type system. For my purposes, the answer was that it's not too bad,
but objects are really nice to have.

So I started working on a fresh Magpie interpreter in Java that's class-based
and dynamically-typed. (As a nice bonus, Magpie going forward won't be as tied
to the MS stack as [the old C# one][csharp] is.) This post is about one
implementation detail I think is kind of interesting: even though
Magpie-the-language is class-based, under the hood, the interpreter uses
prototypes.

[csharp]: https://github.com/munificent/magpie-csharp

## What's in a class?

Before we get too far, let's make sure we're all talking about the same thing.
In Magpie, all objects are instances of a class. The class determines what
methods an object has. The pseudocode for invoking a method is:

```magpie
invoke(obj, methodName, arg)
  classObj = obj.getClass
  method = classObj.findMethod(methodName)
  method.invoke(obj, arg)
end
```

Under the hood then, a class is a bag of methods. Something like:

```java
class ClassObj {
  Map<String, Method> methods;
}
```

And an object is just a reference to its class (and some data, but we won't
worry about that here):

```java
class Obj {
  ClassObj theClass;
}
```

However, there are actually *two* kinds of methods. There are regular instance
methods, like we've seen and "static" or "class" methods that you invoke
directly on the class. These include things like constructors (which are like
Ruby's [new][] methods). For example:

[new]: http://www.devx.com/enterprise/Article/30917/0/page/3

```magpie
def foo = Foo.new   // Call a class method on Foo.
foo.toString        // Call an instance method on a Foo.
```

So our class object really needs *two* dictionaries, one for class and one for
instance methods:

```java
class ClassObj {
  Map<String, Method> classMethods;
  Map<String, Method> instanceMethods;
}
```

It also ends up needing to duplicate the API for using them: separate methods
for defining a method, looking one up, invoking one, etc. I [hate][dry]
redundancy so this rubbed me the wrong way.

[dry]: http://en.wikipedia.org/wiki/DRY

## Split-aparts

Instead of having a single class object that does *two* things, I thought why
not split that up into two separate objects? One represents the *class itself*
and has the static or class methods like constructors. The other represents
the set of methods you can call on an *instance* of the class.

My `ClassObj` type disappeared, to just be:

```java
class Obj {
  Map<String, Method> methods;
}
```

The only missing piece was that an instance of some object needed to have a
reference to the other object that contains its methods, like so:

```java
class Obj {
  Obj parent;
  Map<String, Method> methods;
}
```

Now our pseudo-code for invoking a method is:

```magpie
invoke(obj, methodName, arg)
  thisObj = obj
  loop
    method = thisObj.findMethod(methodName)
    if method != null then
      return method.invoke(obj, arg)
    end

    // Walk up the parent chain.
    thisObj = obj.parent
  end
end
```

You'll note that this pseudocode handles *both* instance and class methods. With
instance methods, `obj` will be the class object itself (since classes are
first-class objects) and it will find the method and immediately invoke it.

With instance methods, the object's parent will be the special object that holds
all of the instance methods. So we'll fail to find the method on the object
itself, walk up to its parent, find it and be done.

## Familiar?

This started to look pretty familiar. I had an object that represented a class,
and another object that represented the methods all objects of that class have
in common. There's a name for that second object: a *prototype*. In the name of
getting rid of duplicate code, I basically stumbled backwards onto the same type
system that Javascript and [Finch](http://finch.stuffwithstuff.com/) use.

The interesting part is that this is hidden completely from the user. Magpie
code is still written using classes and instances. If you have this in Magpie:

```magpie
class Foo
  def sayHi () print "hi"
end

def a = Foo.new
def b = Foo.new
a.sayHi
b.sayHi
```

At runtime, the interpreter will build this object hierarchy:

![Object hierarchy for a class Foo and two instances of it](/image/2010/08/prototype-hierarchy.png "Object Hierarchy")

Every box represents an object and is of the same Java class in the interpreter
(`Obj`). Objects `a` and `b` both have `Foo proto` as their parent, which is the
prototype object holding the instance methods. The class methods like `new` are
held in a separate object `Foo class` representing the class itself and bound to
the variable `Foo`.

The class and proto objects don't have each other as parents because they aren't
directly related -- there's no "is-a" relationship between them. Instead, the
class stores a reference to the prototype in a "proto" field so that it can find
it when it needs to create new instances. Conversely, the prototype stores a
reference to the class so that it can find it when you ask an instance what its
class is.

Doing things this way let me simplify a lot of the underlying code while still
having the convenience of classes at the user level. This is the best of both
worlds: prototypes are easier for the language implementer to code and classes
are easier for the user to use.

Of course, I still have a ton of work to do before Magpie is anywhere near
usable again and this may all be nullified by something I run into along the
way, but so far it seems to be working.
