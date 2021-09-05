- over time, userbase diverges
  - initially, all users new users
  - have same priorities around lang complexity, familiarity
  - similar delta on quantity of stuff to learn before productive
- as users get familiar, changes
  - for existing user, cost of language feature is small delta of additional
    complexity
  - new user, now face larger total delta
- new features are useful
  - most langs don't ship bad features
    - tend to be conservative
  - most of cost of new feature is just increase in overall complexity
  - if had magic button that would upload entire lang spec to all possible users
    then almost all features good
  - would probably be programming in c++
- incremental cognitive cost different from total
  - when someone sees page of code, need to understand almost all features it
    uses to understand it
  - so curve of language learned versus productivity is not smooth linear ramp
  - not 10% productive when know 10% of language
  - have to get over the hump
  - adding more features raises height of hump
  - provides no benefit until after it
- for existing user already over hump, different
  - new feature just small incremental learning cost to get incremental benefit

- almost like language has cohorts
  - if got in early at 1.0, easy to keep up
  - as language grows, you get more and more productive

- if show up later, have to scramble up steep slope
- eventually, slope gets so steep pipeline of new users diminishes
- see that with c++ now

- argument that c++ itself is example of this relative to c
  - many users prefer c over c++ because c is smaller and can fit in their head

- think see that with python soon
- believe part of why guido left is that he wanted to keep growing python
- wanted to focus on experienced cohort where more features = better
- but python still has big pipeline of new users, so lot of pressure to keep
  it simple
- don't think there is perfect solution
  - no way to have single language that is small, easily learned, highly
    productive for very experienced

- see tension in js
  - with classes, many arguments were
    - classes make js less minimal
      - minimal = less to learn
    - classes make common idioms more productive
      - need to know js enough to know common idioms before compelling

- came to head in scheme
  - scheme historically very minimal
    - designed as teaching language
  - over time some people wanted to use for larger real programs
  - had enough sway in steering committee to produce r6rs
    - big change to scheme, standardized lots of core libraries
    - syntax-case macros, lots of other stuff
  - many scheme impls didn't follow along, never implemented
  - spec maintainers outgrow their impls
  - mess

  - to resolve, bifurcated language: small and large

    In consequence, the Scheme Steering Committee decided in
    August 2009 to divide the standard into two separate but
    compatible languages — a “small” language, suitable for
    educators, researchers, and users of embedded languages,
    focused on R5RS compatibility, and a “large” language focused
    on the practical needs of mainstream software development,
    intended to become a replacement for R6RS.
    The present report describes the “small” language of that
    effort: therefore it cannot be considered in isolation as the
    successor to R6RS.

- common thread is that lang maintainers naturally identify strongest with
  experienced cohort so tend to side with growing instead of staying small for
  new users

- to some degree, static types are example of this
  - static types are lot to learn
  - not necessarily useful for new users and small programs
  - but really help productivity as program gets big
  - see almost every dyn lang today getting static type system
    - js -> typescript and flow
    - php -> hack
    - python -> type annotations
    - ruby -> "Matz announced in his RubyConf 2014 keynote that Ruby 3.0 might have a static type system."

- old image synth tool for mac, think kai's power tools had really odd ui
  - to avoid overloading new users, ui had "experience level" where at first
    only subset of features shown
  - had to unlock later ones as became more experienced
  - at the time, thought it was really weird to hide capability
- recall microsoft word had something similar for while where many menu items
  where hidden until you chose to show them

- see something similar but ad hoc in languages
  - "every uses subset of C++"
  - many textbooks use subset of language
  - style guides that restrict features

- learners do need to learn piece at a time, so some amount of incrementality
  in there
  - painful when lang not designed for it
  - get in situations where even simple "first" programs require many features
  - in c, printf("hi %s", name); requires understanding strings (char arrays),
    format strings, variadic functions, etc.
  - in java, hello world requires class, methods, static/instance, arrays,
    system.out, access control

- hard because language not really designed for it
  - langs tend to hang together where everything refers to everything else
  - hard to stratify or subset
  - if you decide to not use exceptions in c++, how do you ensure libs you
    reuse also don't?

- maybe something to this
  - imagine designing lang broken down into explicit stratified levels
  - smallest level 1 core for new users
  - each level adds more features for more sophisticated users
  - by making explicit in lang, can say "this program written in foo level 1"
  - tools can see
  - can influence lang design
    - ensure level 2 feature does not depend on level 3, etc.
  - structured path for users to follow
    - intro textbooks start on level 1
    - move through levels
    - instead of many random walks through entire design
  - of course, very hard problem is figuring out what those levels are
    - people learn different ways
    - start low level and build up to higher level concepts?
    - start high level and work down to more fine-grained primitives?
    - with es, you could say start with protos and then later say,
      "and now you can automate this pattern using a class"
    - or start with classes and then later say "and here's how those work under
      the hood"
    - not sure if there is right answer
    - might be good enough one
    - heuristic i would use it "does feature help small programs?" if not, move
      to later level
      - start procedural
      - later add oop, fp, etc.
      - static types is hard

- something about the lifecycle of a lang
  - embrace idea of cohort that begins when lang created
  - explicity target mostly that cohort
  - allow other new langs to come along for other cohorts
  - eventually cohort winnows and lang dies
  - lot of churn
  - lot of migration and legacy
  - not ideal
  - no one wants to be on dying language

