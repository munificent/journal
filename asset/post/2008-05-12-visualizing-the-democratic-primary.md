---
title: "Visualizing the Democratic Primary"
categories: politics visualization
---

Like lots and lots of people, I've been following this year's election very
closely. I'm not into sports, so this is about as close to it as I get. And,
like an avid sports fan, I'm transfixed by the stats: the numbers that tell how
the teams are doing. Here's how CNN shows it (as of 5/12/09):

![CNN’s election results “graph”](/image/2008/05/cnn.png)

Very pretty. Lots of smiling faces and exciting vertical lines. Unfortunately,
for all those pixels, there's a hell of a lot of [chartjunk][]. It's enough to
drive a [Tufte][]-fanboy like me crazy. Lets focus on just the actual chart part
of the image:

[chartjunk]: http://en.wikipedia.org/wiki/Chartjunk
[tufte]: http://www.edwardtufte.com/tufte/newet

![Where’s the top?](/image/2008/05/cnn-bars.png)

See anything missing? I'll give you a hint. This is showing the status of the
democratic candidate *race*. Don't races usually have finish lines? For all we
can tell, Obama and Clinton are neck and neck (argh, graphical pun not
intended)... somewhere... in the middle of the race.

But that isn't the case at all. Let's see if we can improve it a bit:

![Here at least we can see the goal line](/image/2008/05/ok-graph.png)

This actually shows the status of the race *relative to the finish line*. As you
can see, the finish line is looming but Obama and Clinton are still pretty
close. Clinton has about 89% of the votes that Obama has so far.

But actually, I still don't think this is the best we can do. The way I look at
it, the accumulated votes aren't as important as the *remaining votes needed*.
It's distance from the finish line that matters. If you're running a 500 meter
sprint and you're 20 meters behind your opponent 100 meters in, you've still got
400 meters to catch up. If you're 20 meters behind and 40 from the finish line,
it's over.

It's the relative remaining distance that matters. Let's focus on that:

![The democratic candidate race](/image/2008/05/better-graph.png)

Now things don't look so close. Let's see what the upcoming races can hope to
do:

![Upcoming primaries shown to scale](/image/2008/05/upcoming-graph.png)

It becomes obvious how much of a challenge Clinton has ahead of her.
