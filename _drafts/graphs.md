thinking about bfs, dfs, dijkstra, best-first, and a*

in common
- start at single node
- incrementally visit new neighboring nodes, working outward
- never visit same node more than once

---

random notes:

- binary search tree traversal is special case of best-first
- binary search of array also best-first
  - behaves like tree even though not stored as tree

- a* is a best-first -- heuristic is "distance" to goal
- difference between tree and graph is just visited set
- find shortest path to all or one?
- early out or not?
- most explanations
  - don't show what algos have in common
  - say what it is but not why might prefer over other
- goal is to show sort of meta-algorithm that all follow then show how each
  refines specific portions of it

- what is graph?
  - some obvious example
    - map of cities and roads
  - slightly less obvious
    - maze, each cell is vertex, edges between cells with no wall
  - less obvious
    - ai for game
      - each vertex is state of game board
      - edge is move ai can make (or consider making)
      - goal is vertex where board is winning state
        - find paths to get there
  - abstractly
    - vertex is state of thing
    - edge is allowed way to transition to new or different state of thing
    - map "state of thing" is "where am i", transition is "drive on road"

- trees versus graphs
  - **todo: directed versus undir**
  - tree is just special graph where only one path to any given node
    - implies no loops
    - but can have non-tree graphs without loops - dag
  - trees simpler than dags simpler than graphs
  - can always model undir graph as dir graph by pairs of edges
  - if have algo works on digraph, works on dags, undir graphs, trees, etc.
  - all algos here do that
  - if know have tree or dag, can simplify algos a litle sometimes

- what answer looking for?
  - **todo: talk about how if can express problem as graph, can then use algo
    to get solution**
  - with map of cities and roads, path - list of roads to get from a to b
  - ditto for maze
  - often know two vertices and want to know if there is path between them at
    all
  - maybe want to find path, don't care which
  - maybe want "best" path, define "best" later

  - sometimes don't know what looking for, have starting vertex and want to
    see if can reach one of potentially many vertices with some criteria
    - maybe want best path to vertex
    - maybe want path to best vertex
    - ai for game trying to shoot player
      - find nearest tile that has los

  - sometimes solving multiple problems simultaneously
    - find best paths from one vertex to every other vertex
    - often faster to solve all at once than to repeat process for each vert


