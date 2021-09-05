import 'package:test/test.dart';

import 'package:minibuild/minibuild.dart';

void main() {
  test('runs builder on multiple assets', () async {
    var graph = Graph([
      CapitalizeBuilder(),
    ]);

    graph.addAsset(Key('one.txt'), 'one');
    graph.addAsset(Key('two.txt'), 'two');
    graph.addAsset(Key('three.txt'), 'three');
    await expectBuild(graph, {
      'one.cap': 'ONE',
      'two.cap': 'TWO',
      'three.cap': 'THREE',
    });

    expectAssets(graph, {
      'one.txt': 'one',
      'two.txt': 'two',
      'three.txt': 'three',
      'one.cap': 'ONE',
      'two.cap': 'TWO',
      'three.cap': 'THREE',
    });
  });

  test('chains builders', () async {
    var graph = Graph([
      CapitalizeBuilder(),
      DuplicateBuilder(),
    ]);

    graph.addAsset(Key('one.txt'), 'one');
    graph.addAsset(Key('two.txt'), 'two');
    await expectBuild(graph, {
      'one.cap': 'ONE',
      'two.cap': 'TWO',
      'one.dup': 'ONEONE',
      'two.dup': 'TWOTWO',
    });

    expectAssets(graph, {
      'one.txt': 'one',
      'two.txt': 'two',
      'one.cap': 'ONE',
      'two.cap': 'TWO',
      'one.dup': 'ONEONE',
      'two.dup': 'TWOTWO',
    });
  });

  group('adding assets', () {
    test('creates new build', () async {
      var graph = Graph([
        CapitalizeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      await expectBuild(graph, {
        'one.cap': 'ONE',
      });

      graph.addAsset(Key('two.txt'), 'two');
      await expectBuild(graph, {
        'two.cap': 'TWO',
      });

      expectAssets(graph, {
        'one.txt': 'one',
        'two.txt': 'two',
        'one.cap': 'ONE',
        'two.cap': 'TWO',
      });
    });

    test('creates downstream builders', () async {
      var graph = Graph([
        CapitalizeBuilder(),
        DuplicateBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        'one.dup': 'ONEONE',
      });

      graph.addAsset(Key('two.txt'), 'two');
      await expectBuild(graph, {
        'two.cap': 'TWO',
        'two.dup': 'TWOTWO',
      });
    });

    test('builds group builders that declare it as an input', () async {
      var graph = Graph([
        MergeBuilder(),
      ]);

      graph.addAsset(Key('two.txt'), '2');
      await expectBuild(graph, {
        't.mer': 'two.txt:2',
      });

      graph.addAsset(Key('three.txt'), '3');
      await expectBuild(graph, {
        't.mer': 'three.txt:3,two.txt:2',
      });
    });

    test('does not touch unaffected group builders', () async {
      var graph = Graph([
        MergeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), '1');
      graph.addAsset(Key('two.txt'), '2');
      await expectBuild(graph, {
        'o.mer': 'one.txt:1',
        't.mer': 'two.txt:2',
      });

      graph.addAsset(Key('three.txt'), '3');
      await expectBuild(graph, {
        // Does not build "o.mer".
        't.mer': 'three.txt:3,two.txt:2',
      });
    });
  });

  group('modifying assets', () {
    test('rebuilds only affected build', () async {
      var graph = Graph([
        CapitalizeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      graph.addAsset(Key('two.txt'), 'two');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        'two.cap': 'TWO',
      });

      graph.addAsset(Key('one.txt'), 'touched');
      await expectBuild(graph, {
        'one.cap': 'TOUCHED',
      });
    });

    test('rebuilds downstream builders', () async {
      var graph = Graph([
        CapitalizeBuilder(),
        DuplicateBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        'one.dup': 'ONEONE',
      });

      graph.addAsset(Key('one.txt'), 'changed');
      await expectBuild(graph, {
        'one.cap': 'CHANGED',
        'one.dup': 'CHANGEDCHANGED',
      });
    });

    test('rebuilds group builders that declare it as an input', () async {
      var graph = Graph([
        IncludeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      graph.addAsset(Key('two.txt'), 'two');
      graph.addAsset(Key('main.inc'), 'one.txt,two.txt');
      await expectBuild(graph, {
        'main.out': 'one,two',
      });

      graph.addAsset(Key('two.txt'), 'changed');
      await expectBuild(graph, {
        'main.out': 'one,changed',
      });
    });

    test('rebuilds builder that read affected build as an input', () async {
      var graph = Graph([
        CapitalizeBuilder(),
        IncludeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      graph.addAsset(Key('main.inc'), 'one.cap');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        'main.out': 'ONE',
      });

      graph.addAsset(Key('one.txt'), 'changed');
      await expectBuild(graph, {
        'one.cap': 'CHANGED',
        'main.out': 'CHANGED',
      });
    });

    test('does not rebuild if the source is unchanged', () async {
      var graph = Graph([
        CapitalizeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      await expectBuild(graph, {
        'one.cap': 'ONE',
      });

      graph.addAsset(Key('one.txt'), 'one'); // Same.
      await expectBuild(graph, {});
    });

    test('does not rebuild if a produced output is unchanged', () async {
      var graph = Graph([
        CapitalizeBuilder(),
        DuplicateBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        'one.dup': 'ONEONE',
      });

      graph.addAsset(Key('one.txt'), 'OnE');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        // Does not build "one.dup".
      });
    });
  });

  group('removing assets', () {
    test('ignores unknown key', () async {
      var graph = Graph([]);
      graph.removeAsset(Key('unknown'));
      await expectBuild(graph, {});
    });

    test('removes them from the graph', () async {
      var graph = Graph([]);

      graph.addAsset(Key('one.txt'), 'one');
      graph.addAsset(Key('two.txt'), 'two');
      await expectBuild(graph, {});

      graph.removeAsset(Key('one.txt'));
      await expectBuild(graph, {});

      expectAssets(graph, {
        'two.txt': 'two',
      });
    });

    test('removes builders built from it', () async {
      var graph = Graph([
        CapitalizeBuilder(),
        DuplicateBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), 'one');
      graph.addAsset(Key('two.txt'), 'two');
      await expectBuild(graph, {
        'one.cap': 'ONE',
        'one.dup': 'ONEONE',
        'two.cap': 'TWO',
        'two.dup': 'TWOTWO'
      });

      graph.removeAsset(Key('one.txt'));
      await expectBuild(graph, {});

      expectAssets(graph, {
        'two.txt': 'two',
        'two.cap': 'TWO',
        'two.dup': 'TWOTWO',
      });
    });

    test('rebuilds group builders built from it', () async {
      var graph = Graph([
        MergeBuilder(),
      ]);

      graph.addAsset(Key('one.txt'), '1');
      graph.addAsset(Key('two.txt'), '2');
      graph.addAsset(Key('three.txt'), '3');
      await expectBuild(graph, {
        'o.mer': 'one.txt:1',
        't.mer': 'three.txt:3,two.txt:2',
      });

      graph.removeAsset(Key('three.txt'));
      await expectBuild(graph, {
        't.mer': 'two.txt:2',
      });

      expectAssets(graph, {
        'one.txt': '1',
        'two.txt': '2',
        'o.mer': 'one.txt:1',
        't.mer': 'two.txt:2',
      });
    });
  });
}

/// Validates that calling `build()` on [graph] builds [expected] where each
/// key is an asset key and each value is its contents.
Future<void> expectBuild(Graph graph, Map<String, String> expected) async {
  var built = await graph.build();

  var keys = expected.keys.map((key) => Key(key));
  expect(built, unorderedEquals(keys));
  for (var key in keys) {
    expect(graph.assets[key], expected[key.toString()]);
  }

  // Immediately building again should never do anything.
  expect(await graph.build(), isEmpty);
}

/// Validates that [graph] has all of the [expected] assets where each key is
/// an asset key string and each value is its contents and no other assets.
void expectAssets(Graph graph, Map<String, String> expected) {
  var keys = expected.keys.map((key) => Key(key));

  expect(graph.assets.keys, unorderedEquals(keys));
  for (var key in keys) {
    expect(graph.assets[key], expected[key.toString()]);
  }
}

class CapitalizeBuilder extends Builder<String> {
  @override
  bool matches(Key key, String string) => key.hasExtension('txt');

  @override
  Future<void> build(BuildContext context, Key key, String string) async {
    context.output(key.changeExtension('cap'), string.toUpperCase());
  }
}

class DuplicateBuilder extends Builder<String> {
  @override
  bool matches(Key key, String string) => key.hasExtension('cap');

  @override
  Future<void> build(BuildContext context, Key key, String string) async {
    context.output(key.changeExtension('dup'), string + string);
  }
}

class IncludeBuilder extends Builder<String> {
  @override
  bool matches(Key key, String string) => key.hasExtension('inc');

  @override
  Future<void> build(BuildContext context, Key key, String string) async {
    var results = [
      for (var line in string.split(',')) context.input<String>(Key(line))
    ];

    context.output(key.changeExtension('out'), results.join(','));
  }
}

class MergeBuilder extends GroupBuilder<String> {
  bool match(Key key, String string) => key.hasExtension('txt');

  @override
  void groupAsset(GroupContext context, Key key, String asset) {
    context.defineGroup(Key(key.toString().substring(0, 1)));
  }

  @override
  Future<void> build(
      BuildContext context, Key key, Map<Key, Object> strings) async {
    var keys = strings.keys.toList();
    keys.sort((a, b) => a.toString().compareTo(b.toString()));
    var results = [for (var key in keys) '$key:${strings[key]}'];

    context.output(key.changeExtension('mer'), results.join(','));
  }
}
