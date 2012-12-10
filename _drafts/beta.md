---
title: "Have We Been Doing Overriding Wrong the Whole Time?"
categories: code language
---

Over the weekend, I was reading one of the excellent papers on [Self](http://selflanguage.org/), [Parents are Shared Parts of Objects: Inheritance and Encapsulation in SELF](http://selflanguage.org/documentation/published/parents-shared-parts.html). If you're interested in prototypes, or you're a Javascripter (and those should be synonymous) you owe it to yourself to read some of these papers. Each one is an eye-opener.

But this post isn't about prototypes, it's about something they mention in passing:

> In BETA, virtual functions are invoked from least specific to most specific, with the keyword `inner` being used to invoke the next more specific method. This mechanism is a product of the philosophy in BETA that subclasses should be behavioral extensions to their superclasses and therefore specialize the behavior of their superclasses at well-defined points (i.e. at calls to `inner`).

It took me a while to tease out what this is saying, but once I did, it was like a light bulb turned on in my head.

## What's BETA?

Before I get into the lightbulb part, a bit a history. [BETA](http://daimi.au.dk/~beta/) is a language that came out of the "Scandinavian School" in Denmark, the [same people](http://en.wikipedia.org/wiki/Kristen_Nygaard) that brought you [Simula](http://en.wikipedia.org/wiki/Simula) and kicked off the object-oriented revolution. Simula was the language that inspired Smalltalk and C++. The odds are very good that the language you were coding in before you started slacking and reading this post was inspired by these guys.

Then they made BETA. As far as I can tell, it never became well-known outside of academia, and doesn't appear to have been widely used. (Maybe I'm wrong here.) I see it mentioned in papers from time to time, but haven't heard of anyone actually *using* it.

Part of this may have to do with terminology. Instead of *class* and *method*, BETA has *patterns* which subsume both, somehow, and aren't related to other uses of the term in other languages. The [BETA book](http://daimi.au.dk/~beta/Books/index.html#betabook_download) is a bit... dense.

Or maybe it's just that the syntax is so unlike other languages:

    :::text
    Account:
      (# balance: @integer;
        Deposit:
          (# amount: @integer
          enter amount
          do balance+amount->balance
          exit balance
          #);

        Withdraw:
          (# amount: @integer
          enter amount
          do balance-amount->balance
          exit balance
          #);
      #)

I *think* if you translated that to JavaScript, it would be something like:

    :::javascript
    var account = {
      balance: undefined,

      deposit: function(amount) {
        return balance += amount;
      },

      withdraw: function(amount) {
        return balance -= amount;
      }
    };

The impression I get is that there's lots of wisdom hiding in the language, but it takes some spelunking to pull it out. Fortunately, the Self guys did that for us and left this little nugget in their paper.

## Overriding and super()

Let's cover one last bit of context before I get to the point. If you're using any OOP language, you're hopefully familiar with overriding methods. Details vary between languages, but the two main points are:

1. A subclass can *override* a method in its superclass. When you invoke the method on an instance of the subclass, the derived method gets called *first*.

2. In the body of the overriding method, it can invoke the base class method directly in order to chain the two methods together. In Java, you do so by calling `super.someMethod()`. In C# it's `base.someMethod()`. In CLOS, you use `call-next-method`. You get the idea.

I'm using class terminology here, but all of the above applies equally well to prototypal languages too, with a couple of names changed.

Here's an example:

    :::java
    class Account {
      int balance = 0;
      int deposit(int amount) {
        return balance += amount;
      }
    }

    class CrappyBankAccount extends Account {
      int deposit(int amount) {
        // Service charge, sucker!
        CrappyBank.mainAccount.deposit(2);
        super.deposit(amount - 2);
      }
    }

So now, if you do something like this:

    :::java
    Account account = new CrappyBankAccount();
    account.deposit(23);

First, it invokes `CrappyBankAccount#deposit()`. Then, when that calls `super.deposit()`, it chains to the base `Account#deposit()` method.

## Who's in Charge Here?

What this means is that the *subclass* is in control of the dispatch chain. When you override a method in Java, you get to decide if you do stuff before calling `super` or after. You can change the arguments you pass to it, or even skip calling it entirely.

This is great for flexibility, but as an API designer, that can be frustrating. When I'm making a class that's designed to be subclassed, I often have constraints that I want my class to ensure.

For example:

    :::java
    class GameObject {
      float x, y;

      void render(Renderer renderer) {
        renderer.setTransform(x, y);
      }
    }

    class ScaryMonster extends GameObject {
      void render(Renderer renderer) {
        super.render(renderer);
        renderer.drawImage(Images.SCARY_MONSTER);
      }
    }

Here we're making a game with a base class for an character in the world. It provides a default `render()` method that tells the renderer where to render. The subclass overrides it and draws the specific image that's appropriate for that character.

There's an implied requirement here: if you override `render()` in a subclass, you *must* call `super.render()` *before* you do any drawing. If you don't, the transform won't be set and it'll draw wrong.

These hidden requirements rub me the wrong way. If you're implementing a subclass of `GameObject`, how are you supposed to know that you need to do that? You can document it, but it would be better if the base class itself made sure you did the right thing.

## render() and onRender()

To solve this, what I (and lots of other people) do is split these into two methods, like so:

    :::java
    class GameObject {
      float x, y;

      void render(Renderer renderer) {
        renderer.setTransform(x, y);
        onRender(renderer);
      }

      protected abstract void onRender();
    }

    class ScaryMonster extends GameObject {
      protected void onRender(Renderer renderer) {
        renderer.drawImage(Images.SCARY_MONSTER);
      }
    }

Our public `render()` method is now designed to *not* be overridden. It does the set-up it needs and calls the protected abstract `onRender()` method. That method *is* intended to be overridden, and by making it protected and abstract, it's clear you *must* override it. Marking it abstract also makes it clear that you don't need to call `super()`.

This lets the base class stay in control of the dispatch process. It can do set-up before and after the subclass's "overridden" method gets called. The dispatch order is reversed now. When you call `render()`, you hit the superclass *first* and then it calls `onRender()` in the subclass.

This is almost always how I design classes that I intend to be subclassed. It's rare that I override methods in my code that aren't abstract, and I've been on teams with style guides that enforced this pattern.

## Back to BETA

Of course, the problem with this is that it *is* a pattern. You have to make a pair of methods, and every time you have another level of subclassing, you need a new name. (If there was a subclass of `ScaryMonster` that wanted to override `onRender()` then `ScaryMonster` would have to add a `onOnRender()`.) This brings us back to BETA.

Overriding methods in BETA works exactly like this pattern, but baked right into the language. Instead of calling `super()` in the *derived* class, you call `inner()` in the *base* class. That tells it to chain *down* to the subclass at that point.

When you invoke an overridden method, dispatch starts at the base class (just like we want in the `GameObject` example) and then walks down to the subclasses at the superclass's whim. In other words, our example with BETA-style overriding would look like:

    :::java
    class GameObject {
      float x, y;

      void render(Renderer renderer) {
        renderer.setTransform(x, y);
        inner(renderer);
      }
    }

    class ScaryMonster extends GameObject {
      void render(Renderer renderer) {
        renderer.drawImage(Images.SCARY_MONSTER);
      }
    }

If you chain more than two levels of subclasses, BETA scales better because you don't need to keep coming up with new names. It has some other neat attributes too.

    :::java
    class GameObject {
      float x, y;

      void render(Renderer renderer) {
        renderer.setTransform(x, y);
        inner(renderer);
        renderer.restoreState();
      }
    }

    class ScaryMonster extends GameObject {
      void render(Renderer renderer) {
        renderer.drawImage(Images.SCARY_MONSTER);
      }
    }

Here, we've added a call to `restoreState()` after the call to `inner()`. By giving control of the dispatch to the base class, it can execute code both before *and* after the derived class code. `super()` doesn't let you do that. (Though `super()` does let you handle the opposite case: you can put code before and after the *base* class code in the derived method that calls `super()`.)

It also gives you a convenient way to control which methods are virtual and which aren't: if a method doesn't call `inner()` it implicitly can't be overridden since it cedes no control to a subclass.

- what happens if you call inner() and there is no subclass?
- mention paper that puts both styles into java
