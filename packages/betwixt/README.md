![Betwixt logo](betwixt.png)

Betwixt is an asynchronous, lazy template language written in [Dart].

[dart.dev]: https://dart.dev/

## Does the world need another template language?

No, it definitely does not. But I needed another template language
*implementation*, and if I'm going to bother implementing a language, I can't
resist the fun of designing one.

## Why did you need another template language implementation?

I was making a static site generator for my blog. For fast iteration, I wanted
the development server to rebuild only the pages actually affected by a file
change. Typical template language implementations don't play nicely with that
model. With most, you render a template by providing a big JSON map containing
every piece of data the template *might* use. From the dev server's point of
view, that means that every page now depends on every piece of data in the
entire system. Incrementality goes out the window.

I wanted a template engine that could render a template and ask the host app for
pieces of data *dynamically*. Instead of the host preemptively passing every bit
of data to the renderer, the renderer *requests* data only when it is actually
needed. This is what I mean by "lazy". The host app only calculates and provide
the data that the template actually ends up rendering.

Some of this data might be generated dynamically. It might even be produced
asynchronously. This means that right in the middle of rendering a template, the
template engine might need to call back into the host app to request some data
and then asynchronously suspend until the data is returned.

Most template engines I could find didn't support that, and there's no easy way
to add that to an existing renderer. Renderers are usually [tree-walk
interpreters], and since asynchrony [touches the entire callstack][color], it
essentially means rewriting the entire renderer to be asynchronous.

I decided to just write my own from scratch.

[tree-walk interpreters]: http://craftinginterpreters.com/a-map-of-the-territory.html#tree-walk-interpreters
[color]: https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/

## What is the language like?

Here's an example:

```
<!DOCTYPE html>
<html>
  {{ include "head" with title = "Posts by Date" }}
  <body>
    <h1>{{ escape(title) }}</h1>
    {{ let year = "" }}
    {{ for post in posts }}
      {{ if post.date.year != year }}
        <h2>{{ post.date.year }}</h2>
        {{ set year = post.date.year }}
      {{ end }}

      <a href="/{{ post.url }}">{{ post.date.shortMonth }}/{{ post.date.day }}:
        {{ post.title }}</a>
    {{ end }}
  </body>
</html>
```

Betwixt is inspired by [Liquid](https://shopify.github.io/liquid/). As you can
see, it has a rich expression syntax and control flow. I'm not a moralist when
it comes to logic in templates. Betwixt is written in Dart which is mostly a
statically compiled language. It's possible to load new Dart code into a running
command-line application, but it isn't particularly common or easy. With a
logic-less template language like Mustache, that would force you to restart the
program every time you need to write a little logic in the host app since the
template can't express it.

Instead, the model I use for Betwixt is that the host app's job is to expose the
entire model and make all the data available upon request. Since it is lazy,
that's still efficient. In the templates, you decide what you want to show and
how you want to show it. In other words, templates are your view layer.
