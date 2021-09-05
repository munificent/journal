# Minibuild

Minibuild is a library for creating dependency graphs of build steps,
running them, and incrementally updating them. It is conceptually similiar to
the old [barback] or [build_runner] packages, though much much simpler than
either.

It might be useful if you are writing an app that needs to create and manage a
dependency graph of operations. For example, imagine a static site generator
that reads a directory of Markdown files, templates, SASS files, etc. It has a
number of different build steps that convert those into the CSS and HTML files
for the final site. It likely offers a development server that watches the input
files and rebuilds the affected output files when inputs have changed. A system
like this might use minibuild internally in order to organize those build
operations. In return, minibuild runs the build steps, keeps track of all of the
outputs, and efficiently only reruns the steps that are necessary when inputs
have changed.

[barback]: https://pub.dev/packages/barback
[build_runner]: https://pub.dev/packages/build_runner
