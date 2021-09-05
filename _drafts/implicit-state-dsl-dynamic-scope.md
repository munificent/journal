I'm gonna throw a hypothesis out there that goes against a lot of my deeply-held convictions about good software engineering. This is serious jimmy-rustling, stuff:

**A key ingredient of a beautiful DSL is hidden mutable state.**

Lispers and their avant garde bretheren Haskellers have been trying to beat the sin of state and mutation out of we filthy object-oriented programmers for years now and, miraculously, that lesson has actually started to sink in a bit in the past few years.

* dsls are "languages". moreso than general purpose programming languages, they try to speak the language of their domain, which makes them much closer to human languages. unlike programming languages, human languages rely *deeply* on implicit context. consider:

    heat a saucepan to medium heat
    add two tablespoons of butter
    when melted, whisk in two tablespoons of flour
    stir continuously until no lumps remain and the mixture turns golden brown

even if you're not much of a cook, you can probably figure out what's going on here. (this, in case you're wondering, this is how to make a roux.) but look at each line in isolation:

    add two tablespoons of butter

add them to *what*?

    when melted, whisk in two tablespoons of flour

when *what's* melted? the butter or the pan? what do we whisk the flour into?

    stir continuously until no lumps remain and the mixture turns golden brown

stir *what* continuously? lumps of *what*?

this would be literally a recipe for failure if you asked a robot to make it. (also, robots generally aren't a fan of french mother sauces.) there's all of these implied objects and context that has to just be understood.

but note, however, that most of the context doesn't come from the *outside*. on line two, we don't specify what we add the butter to, but that doesn't mean we add it to your personally list of favorite dairy products. you add it to the saucepan, which was mentioned explicitly in step one.

now imagine a dsl for making this recipe. it could look something a bit like this:

    saucepan.heat medium
    add 2.tablespoons.of butter
    wait until melted
    whisk 2.tablespoons.of flour
    stir until lumps

have all of these things that need an object: add, melted, lumps

if you were to implement this, you could do so by:

everytime you see an object, add it to a list of encountered objects. so on the first line, we'll add "saucepan".

when you get to a word that needs an object, find the most recently encountered object that can handle it. so when we get to "add", we need to find what to add it to. we walk the list backwards, find "saucepan" and we're groovy.

then we add butter to the list

when we get to "melted", we look back in the list and find butter.

this "most recent noun" list is, i think, actually kind of a neat way to model this. if you support for knowing which operations apply to which nouns, you can even do clever stuff like:

    add butter and salt
    wait until melted

here, "melted" will skip past "salt" because (unless you're cooking really exotic fare!) salt doesn't melt and then find butter.

but look at what the implementation of this requires: a hidden, mutable list of nouns. all of the dsl methods access this list and some of them implicitly modify it.

this sounds like a maintenance nightmare. and, it's true, the code in this dsl is very different from regular code. swapping two lines of code can significantly change its behavior, for example, because the implicit nouns being affected can change.

we could make it more explicit:

    saucepan.heat medium
    var butter = 2.tablespoons.of butter
    saucepan.add(butter)
    wait until butter.melted
    var flour = 2.tablespoons.of flour
    whisk flour until flour.no_lumps

this is definitely more explicit. there's no hidden state. it looks like real code.

but it's also a crappy dsl. i think the point of having a "dsl" and not just an api is to get closer towards your problem domain, even though that means getting farther from the language of programming.

but, of course, programming languages are themselves languages optimized for expressing things. they excel at many of the domain concerns of software engineering: encapsulation, modularity, reuse, etc. moving away from that language sacrifices some of that.

my take is that that is *ok* sometimes. the trick is knowing when. i think a good dsl can be a net win when the stuff you're expressing in it doesn't benefit as much from the full features of a programming language.

that usually means the stuff you write in it should be pretty small. you may have a lot of chunks of text in your dsl, but not a single monolithic blob of it. if you do, you'll really miss all of the reuse and modularity a real language gives you.

when you're programming in the small, hidden mutable implicit state is a lot less scary. we don't like that stuff because it makes it hard to reason about: when a program is big you can't fit it all in your head. you need to be able to just hold a piece in your head and know that other pieces don't affect it. hidden mutable state can get in the way of that. some random piece of code can modify the state in a weird way that the code you're working doesn't expect. weird action at a distance and tendrils of nastiness snaking through your program.

but when your entire program does fit in your head, it's not a big deal.

## implementing

if you're ok with the ideal of small-scale implicit state for dsls, the next question is how to implement it. this is where i bring in heresy number two: dynamic scope.

...
