---
layout: post
title: "Magpie Wants You!"
#categories: code, language, magpie, oscon
---
I've been very fortunate to get lots of feedback and encouragement so far
while I've worked on my [little language Magpie](http://magpie.stuffwithstuff.com), but I haven't actually
asked for people to get directly involved. I still had lots of basic syntax
and semantic decisions to make and it would have been an exercise in
frustration to drag anyone else along through that.

I may be entirely wrong, but I think I'm past the worst of that. Now that
[classes](http://magpie.stuffwithstuff.com/classes.html), [patterns](http://magpie.stuffwithstuff.com/patterns.html), and [multimethods](http://magpie.stuffwithstuff.com/multimethods.html) are implemented and
working, I believe Magpie may be at a point where adventurous souls could try
to play with it. Multimethods were the big missing piece, and I'm super
excited that they're working now. To give you an idea why, here's some fun
stuff they enable:

## Overloading Methods

Magpie is a dynamically-typed language (flirtations with optional static
typing notwithstanding). But in Magpie, every method is a multimethod, which
means you can overload them.

{% highlight magpie %}
def (this is String) split()
    this split(" ")
end

def (this is String) split(separator is String)
    ...
end
{% endhighlight %}

Here we've defined two `split` methods on strings. The first takes no
arguments, and the second takes a separator. This means you can do:

{% highlight magpie %}
"eenie-meenie-miney-moe" split("-")
{% endhighlight %}

or

{% highlight magpie %}
"eenie-meenie-miney-moe" split()
{% endhighlight %}

In most dynamic languages, you'd have to handle that by doing some manual
`instanceof` or `!== undefined` checks. In Magpie, it just works. You can
overload by arity or type, or both:

{% highlight magpie %}
def (this is String) split(maxResults is Int)
    ...
end

def (this is String) split(separator is String, maxResults is Int)
    ...
end
{% endhighlight %}

Pretty much any kind of argument list can be overloaded and it will pick the
right one at runtime based on what you actually pass it.

And just to clarify, you don't have to define all of these methods in one
place or even in one module. They can be anywhere you want. In fact, you're
free to define methods on types you didn't create, which leads us to…

## Sane Monkey-Patching

One of the most powerful features of Ruby is that you can extend existing
classes with new methods. This lets you define libraries which make the most
of Ruby's `object.method` syntax and can lead to beautifully readable APIs.

The problem, though, is that if two libraries happen to cram a method with the
*same* name on the *same* class, [all hell breaks loose](http://www.benjamincoe.com/post/6234388028/why-i-hate-ruby-or-at-least-some-common-practices-of). Very high on my
list of goals for Magpie was to solve this problem, which is why classes don't
own methods. Instead, they are lexically scoped like variables.

This means that when you define a method "on" a class like our `split` method
up there, you aren't touching the class at all. Instead, you're defining a
function in your local scope that happens to take a String as its left-hand
argument. Outside of the scope where you defined it, that method doesn't
exist.

If two different modules define methods on the same class with the same name,
there's no collision, as long as they don't import each other. You can even
use both of those modules in the same program without collision. You should be
free to define methods on any classes you like if it makes your code easier to
read.

## Do Actual Stuff

Of course, all of the neat language features in the world are pretty useless
if the language can't solve actual problems. For almost all of its history,
the only thing you could actually do with Magpie was print to standard out. I
know, not very inspiring.

Fortunately, I'm finally getting to the fun part of building real APIs for
file IO, concurrency, networking, etc. I have a *ton* of work to do here
(hopefully with your help!) but at least now you can read files and spawn
threads. To prove it, here's a toy asynchronous web server:

{% highlight magpie %}
import io
import net
import async

val server = ServerSocket new(8080)
while true do
    val socket = server accept()
    // Start a new thread to respond to the request.
    run with
        // Process the request (assume its a GET).
        val path = socket readLine() split(" ")[1]

        // Open the file being served.
        open("." + path) use with
            // Read it and write it to the socket.
            socket write(it read())
        end
        socket close()
    end
end
{% endhighlight %}

## Where You Come In

If you've ever had the desire to help build a programming language and its
ecosystem, and what you see here looks cool, I'd love to have you involved. It
will be a lot of work, and it's likely that more things are broken than
working, but you'll have the chance to get in on the ground floor. Hell, you
may be *building* the ground floor. If that sounds like fun, here's what you
can do:

*   Join [the mailing list](http://groups.google.com/group/magpie-lang?pli=1).
    It's… um… *dormant* right now, but with your help I hope we can get it
    going.

*   If you aren't an IRC noob like me, try to get a channel for Magpie set up
    and let me know. I'll try to hang out on it as much as I can.

*   Read [the guide](http://magpie.stuffwithstuff.com/). It still needs work,
    but the majority of the language features are documented there. Let me know
    if you find errors, omissions, or stuff that's unclear. Take a look at some
    [example programs](https://github.com/munificent/magpie/tree/master/example)too.

*   Try out the interpreter. [Clone the repo](https://github.com/munificent/magpie),
    build it, and try writing toy programs. What worked like you expected, and
    what didn't? Let me know, preferably on the list.

*   Start looking at the code. The current implementation is focused on
    simplicity and certainly not efficiency. If you can read Java you might not
    find it too difficult. If you're feeling brave, start hacking. Fleshing out
    APIs like IO would be hugely helpful, but scratch whatever itches you.

That's really about it. You might want to [follow me on twitter](http://twitter.com/#!/munificentbob) or [point
your RSS reader at my blog](http://journal.stuffwithstuff.com) too. Beyond that, we'll have to see where it goes from here.

## What Comes Next

Of course, it's entirely possible that no one will sign the charter for this
little voyage but me, and that's OK. I'll keep hacking on Magpie regardless,
but for the next few weeks, I've got something much more fun to focus on:
preparing for [my talk on Magpie at OSCON](http://www.oscon.com/oscon2011/public/schedule/detail/18551).

I feel like I didn't stress that enough. [OMG I'M GIVING A TALK ON MAGPIE AT
OSCON](http://www.oscon.com/oscon2011/public/schedule/detail/18551). It's hard to describe how that makes me feel. Kind of like kissing
the prettiest girl in middle school behind the bleachers but also I just drank
a huge cherry Slurpy and I kind of feel like I need to throw up. Something
like that.

I will be speaking on Thursday July 28th at 1:40 PM. I'm not sure if that
means that I'll be drinking *before* 1:40 or *after*. Perhaps a little bit of
both just to be safe.

So, if you're going to be at OSCON this year (and you should be because OMG
I'm giving a talk at it!), come see my talk. At the very worst, I promise to
give you a hug afterwards if you ask nicely. So even if the talk bombs, you
get a free hug.
