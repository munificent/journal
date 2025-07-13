---
title: Setting Up an SDL3 Mac App in XCode 16
categories: game-dev code macos
---

This is mainly a note for my future self, but making it a blog post in case it
helps anyone else. This weekend, I decided to try making a little SDL3 app on my
new M4 MacBook Pro. It took me a few hours to figure out how to get XCode to
play nice with the SDL3 framework given MacOS's paranoia around unsigned code
and malware.

Here's the summary for anyone whose Google searching takes them here. The
instructions are fairly similar to [the SDL3 README for MacOS][readme by hand]:

[readme by hand]: https://wiki.libsdl.org/SDL3/README-macos#setting-up-a-new-project-by-hand

1.  Start up XCode. Choose "File > New > Project...".

2.  Select "macOS", then under "Application" choose "App". *This step is
    important. Choosing "Command Line Tool" will **not** work.* Click "Next".

3.  Give your app a name. For "Interface", choose "XIB". For "Language", choose
    "Objective-C". Click "Next". Choose a place to save your project.

Now you have a vanilla "Hello World" Mac app. The next step is integrating SDL:

1.  Download [a release][releases] of SDL. As I'm writing this, the latest is
    3.2.16. Download the corresponding `.dmg` file. Open it in Finder.

2.  Open `SDL3.xcframework/macos-arm64_x86_64` and copy `SDL3.framework` from
    there to somewhere in your XCode project's source tree. (I made a `lib`
    folder and put it there in mine.)

3.  In XCode, in the file explorer on the left, click the top project icon to
    open the settings for it. In the main panel on the right, click the icon
    for your app target under "Targets" to open the target settings.

4.  Under "Frameworks, Libraries, and Embedded Content", click the "+" to add a
    new framework. In the popup that appears, click "Add Other... > Add
    Files...". Navigate to wherever you copied "SDL3.framework" and choose it.

[releases]: https://github.com/libsdl-org/SDL/releases

Then let's use SDL and verify everything is working.

1.  In `main.m`, comment out the entire `main()` function.

2.  Make a new `main.c` file and copy the contents of [hello.c][hello.c] from
    the SDL docs into it.

3.  Compile and run.

[hello.c]: https://github.com/libsdl-org/SDL/blob/main/docs/hello.c

If that all works, you should see a delightful pixelated "Hello World!" fill
your screen. Press any key to quit.

Let's make sure the full iteration loop works. (Read below to see why I feel
the need to verify this.):

1.  In `main.c` inside `SDL_AppIterate()`, change the message string.

2.  Hit Command-R to run. You should see your updated message on screen.

There you go, you now have a working shell of a Mac app with using a local
install of SDL3. You can probably delete the `main.m` file entirely and maybe
some of the other generated files that XCode put in the new project, but I
haven't figured that out yet.

Now here's all the wrong stuff I tried first before I got that working...

## Attempt 1: Download a release and use the xcframework

In XCode, I created a new "CLI Command" C app. That got me a "Hello, world!" up
and running without any problems. Then I copied the contents of [this SDL hello
example][hello] into my source file.

As expected, that failed to compile because it couldn't find `SDL3/SDL.h`. So
next is getting SDL linked in.

[hello]: https://github.com/libsdl-org/SDL/blob/main/docs/hello.c

The first thing I did was download [the 3.2.16 stable release
installer][installer]. I downloaded the DMG file and opened that. Then following
the instructions, I dragged the entire `SDL3.xcframework` directory into the
XCode project.

[installer]: https://github.com/libsdl-org/SDL/releases/tag/release-3.2.16

That correctly added a reference to the Framework and got XCode to a point where
it could resolve the include and compile the program. Great.

But when I ran it, it failed at startup. The OS tried to dynamically load the
SDL3 framework, but then balked because it thinks the framework isn't correctly
signed and safe to use. The OS gave me a popup error with "SDL3.framework Not
Opened" because "macOS cannot verify that this app is free from malware".

Crap.

## Attempt 2: Embed the framework

Poking around online, some people say this error can be fixed by embedding the
SDL framework in my app and having XCode sign it when it embeds it. In XCode, in
the target settings under "Build Phases", there is a panel for "Embed
Frameworks". I dragged `SDL3.xcframework` under there and checked "Code Sign On
Copy".

Alas, when I tried to compile, now I got a build error. It complained that two
tasks in the build were trying to produce the same file. I've lost the exact
error message but it looked like one of the tasks was a simple file copy and the
other was a "ProcessXCFramework" invocation. I'm guessing the latter is the task
that signs and embeds the framework.

I tried basically every combination of build settings to try to fix this:
removing the framework from "Link Binary with Libraries", checking "Copy only
when installing", and a bunch of other things I don't remember. Nothing worked.
Either I removed so much that the compiler couldn't find the framework at all,
or it got the duplicate build file error.

## Attempt 3: Don't use the entire "SDL3.xcframework"

I started watching [this video][video] to see if it could help. He doesn't use
the entire `SDL3.xcframework` bundle. Instead, he opens that, goes into
`macos-arm64_x86_64` and copies the `SDL3.framework` framework out of there.

[video]: https://www.youtube.com/watch?v=tRqgh8Xwe1E

I removed `SDL3.xcframework` from my XCode project and dragged `SDL3.framework`
into it instead. That gave me something that compiled, but when I tried to run,
it failed at load time with:

```
dyld[15605]: Library not loaded: @rpath/SDL3.framework/Versions/A/SDL3
Referenced from: <...> /Users/...
Reason: tried: '/Users/.../Build/Products/Debug/SDL3.framework/
Versions/A/SDL3' (no such file)
```

In the target settings, I again added the framework (but this time
`SDL3.framework` not `SDL3.xcframework` to "Embed frameworks"). For reasons
that are entirely unclear to me, that worked. I hit Command-R and...

<figure>
  <img class="framed" src="/image/2025/07/hello.gif">
  <figcaption>Hallelujah.</figcaption>
</figure>

All done, right? Not so fast. I made a tiny tweak to the code and tried to run
it again. The compile immediately failed with:

```
'SDL3/SDL.h' file not found
```

What? I literally just compiled and ran it. Just to make sure I wasn't crazy,
I cleaned the build directory and compiled again. That worked! "Hello World!"
popped up on screen again.

Build again... same error.

Clean build and then build. Works!

So I can build *once* but then something in the build directly causes any
subsequent compile to fail. The full error is:

```
Did not find header 'SDL.h' in framework 'SDL3' (loaded from
  '/Users/.../Index.noindex/Build/Products/Debug')
```

So what I *think* is happening is that in the first clean build, it locates the
framework inside my app's main directory. That framework does have the headers
so the compiler can find what it needs.

Then after that first build, the compiler starts using the framework that it
copied into the build directory. But when I look in there, `Debug` is completely
empty.

## Attempt 4: Project-relative DerivedData

I hate when tools stuff built data in random system directories unrelated to
the project I'm working on because those files end up sitting around forever.
So the next thing I did was go under "Project Settings" and changed the
"Derived Data" to be "Project-relative Location".

I cleaned and built successfully. But, again, if I made a trivial code change
and tried to build again, it failed. This time, though, there was actually
something in `DerivedData/my_app/Build/Products/Debug/`.

I can see an `SDL3.framework` directory under there. It contains
`Versions/A/SDL3` (and some other stuff). So the library is there as expected.
But there is no `Headers` directory under `Versions/A/`, nor is there a
`Headers` symlink in `SDL3.framework` pointing to it.

In theory, that's fine. In the compiled app, all that's needed is the library
itself. But for reasons I don't understand, XCode is trying to use this
semi-copied version of the framework for subsequent compiles instead of the
original one in my project's source tree.

## Attempt 5: Explicit header search path

OK, if XCode can't find the headers because it's looking in the wrong place,
maybe I can just tell it where to look. Under "Search Paths", I added
`lib/SDL3.framework/Headers` to "Header Search Paths". (I put the framework
under `lib` in my project tree, hence the `lib/` part.) Didn't help. Tried
making it recursive. Nope.

Maybe just `lib/SDL3.framework`? No.

I'm guessing the problem here is that the include paths look like `SDL3/SDL.h`,
not just `SDL.h`, so I need to get XCode to understand that the headers are
inside a framework to resolve the `SDL3/` part.

## Attempt 6: Framework search path

OK, so maybe it's not a header search path. Instead, I tried adding `lib/` to
"Framework Search Paths". No help. Making it recursive didn't help. Neither
did `lib/SDL3.framework`.

I do a bunch of Googling and eventually stumble onto [this old StackOverflow
post][so]. He specifically mentions only getting the error after the first
build, so this is my exact issue. And the author apparently found a solution!

[so]: https://stackoverflow.com/questions/63630876/xcode-cant-find-the-header-path-after-build/63668035

...which they described only as "It works know after certain changes!". So
helpful.

I eventually found [this Apple Developer forum thread][apple dev], which also
sounds like my problem.

[apple dev]: https://developer.apple.com/forums/thread/750074

## Attempt 7: An App instead of a CLI Command

The forum thread suggests that the issue may have something to do with creating
a "CLI Command" instead of an "App". I've always done the former in XCode
because that seemed like the simplest way to get a vanilla C/C++ app up and
running. In older versions of XCode/macOS, it worked fine. But maybe it doesn't
play nice with frameworks in later versions?

I trash the entire XCode project and create a new one. This time I choose "App"
instead of "CLI Command". I set the language to "Objective-C" (because that's
the "closest" to C, I guess -- I'm winging it here). I set "Interface" to "XIB"
based on [this README][macos readme].

[macos readme]: https://wiki.libsdl.org/SDL3/README-macos

I run it and get an empty window, the "Hello World" of GUI apps. OK.

I copy `SDL3.framework` out of `SDL3.xcframework/macos-arm64_x86-x64` into
`lib/` in my new app's source tree. Then in XCode, in the "General" tab of the
main target, under "Frameworks, Libraries, and Embedded Content", I click the
"+". From there I choose "Add Other...", "Add Files...", and add
`lib/SDL3.framework`.

I admit to feeling a moment of anticipation. Will this actually work?

I make a new `.c` file and paste in the `hello.c` SDL3 example code. I comment
out `main()` in the `main.m` that XCode generated. Compile and... it runs! I've
got an SDL3 "Hello World!" on screen again.

Now the real test... can I make a change and build again?

Yes! It works! *Finally!*

As far as I can tell, I am up and running now. I didn't have to add SDL3 to my
system framework path. (I didn't want to do that because ultimately, I want an
app that users can just run without having to install SDL themselves.)

So it looks like the failure mode was creating a "CLI Command" instead of an
"App". How on *Earth* would I be expected to know that?
