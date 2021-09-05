import 'package:stack_trace/stack_trace.dart';

import 'key.dart';

/// The asset build graph.
class Graph {
  final List<BuilderBase> _builders;

  final Map<Key, Object> _sourceAssets = {};
  final Map<Key, Object> _assets = {};

  /// The complete set of source and generated assets.
  Map<Key, Object> get assets => Map.unmodifiable(_assets);

  /// The set of assets that have been added or modified since the last build.
  /// Any builders that could depend on these should be rebuilt.
  final Set<Key> _dirty = {};

  /// The assets that were output during the last build.
  final Set<Key> _builtKeys = {};

  /// The build nodes created in the previous build for each builder.
  final Map<BuilderBase, Map<Key, _BuildNode>> _buildNodes = {};

  /// Whether any assets were removed since the last build.
  bool _hasRemoved = false;

  /// Whether a build is currently running.
  bool _isBuilding = false;

  Graph(this._builders);

  bool get isBuilding => _isBuilding;

  /// Adds or updates the [asset] with [key].
  void addAsset(Key key, Object asset) {
    // TODO: Test.
    if (_isBuilding) throw StateError('Cannot modify assets during a build.');

    // Don't touch anything if the value is the same.
    if (_sourceAssets[key] == asset) return;

    _sourceAssets[key] = asset;
    _dirty.add(key);
  }

  /// Removes the existing asset with [key].
  ///
  /// Does nothing if an asset with that key doesn't exist.
  void removeAsset(Key key) {
    // TODO: Test.
    if (_isBuilding) throw StateError('Cannot remove assets during a build.');

    _sourceAssets.remove(key);
    _hasRemoved = true;
  }

  Future<List<Key>> build() async {
    // TODO: Test.
    if (_isBuilding) throw StateError('A build is already running.');

    // If this isn't the first build and no assets are dirty, then we know
    // nothing is going to change.
    if (_buildNodes.isNotEmpty && _dirty.isEmpty && !_hasRemoved) {
      return const [];
    }

    _isBuilding = true;

    try {
      // Clear all of the assets so that stale assets produced from removed
      // sources are cleared out.
      _assets.clear();
      _assets.addAll(_sourceAssets);

      for (var builder in _builders) {
        // Let the builder define build groups for the assets.
        var buildNodes = <Key, _BuildNode>{};
        _assets.forEach((key, asset) {
          builder._group(GroupContext(builder, buildNodes, key, asset));
        });

        // Build any nodes that are dirty.
        var futures = <Future<void>>[];
        for (var node in buildNodes.values) {
          var previousNode = _buildNodes[builder]?[node.group];
          if (_isDirty(previousNode, node)) {
            futures.add(_buildNode(previousNode, node));
          } else {
            // If the node does not need to be built, preserve it and its outputs.
            buildNodes[node.group] = previousNode!;
            _assets.addAll(previousNode.outputs);
          }
        }

        await Future.wait(futures);

        _buildNodes[builder] = buildNodes;
      }

      // Everything is clean now.
      _dirty.clear();
      _hasRemoved = false;

      // Tell the caller what was built.
      var builtKeys = _builtKeys.toList();
      _builtKeys.clear();
      return builtKeys;
    } finally {
      _isBuilding = false;
    }
  }

  /// Run the build for [node].
  ///
  /// Stores any outputs produced by the build and uses [previousNode] to
  /// determine which outputs have actually changed.
  Future<void> _buildNode(_BuildNode? previousNode, _BuildNode node) async {
    var context = BuildContext(this, node);

    try {
      await node.builder._build(context, node.group, node.declaredInputs);
    } catch (error, stack) {
      var chain = Chain.forTrace(stack).terse;
      print('Build error in ${node.builder.runtimeType} on "${node.group}":\n'
          '$error\n$chain');
      return;
    }

    // Add the outputs to the graph.
    node.outputs.forEach((key, asset) {
      _assets[key] = asset;
      _builtKeys.add(key);

      // If the asset changed, anything downstream is dirty.
      if (previousNode == null ||
          !previousNode.outputs.containsKey(key) ||
          previousNode.outputs[key] != asset) {
        _dirty.add(key);
      }
    });
  }

  /// Whether [node] should be built based on the previous state of the same
  /// corresponding node.
  bool _isDirty(_BuildNode? previousNode, _BuildNode node) {
    // Never built this node.
    if (previousNode == null) return true;

    // See if all declared inputs are the same and all clean.
    for (var key in node.declaredInputs.keys) {
      if (!previousNode.declaredInputs.containsKey(key)) return true;

      // Input asset is dirty.
      if (_dirty.contains(key)) return true;
    }

    // See if any inputs were removed.
    for (var key in previousNode.declaredInputs.keys) {
      if (!node.declaredInputs.containsKey(key)) return true;
    }

    // If any other inputs read during the previous build are dirty, they will
    // be read again so this build is dirty too.
    for (var key in previousNode.readInputs) {
      if (_dirty.contains(key)) return true;
    }

    return false;
  }
}

abstract class BuilderBase {
  void _group(GroupContext context);

  Future<void> _build(BuildContext context, Key key, Map<Key, Object> inputs);
}

/// Separately builds each matching input asset of type [I].
abstract class Builder<I> extends BuilderBase {
  @override
  void _group(GroupContext context) {
    if (context._asset is I && matches(context._key, context._asset as I)) {
      context.defineGroup(context._key);
    }
  }

  @override
  Future<void> _build(
      BuildContext context, Key key, Map<Key, Object> inputs) async {
    await build(context, key, inputs.values.single as I);
  }

  /// Override this and `true` if this builder should apply to [asset].
  ///
  /// Defaults to `true`.
  bool matches(Key key, I asset) => true;

  /// Override this to apply this builder to the given key previously returned
  /// by [match()].
  Future<void> build(BuildContext context, Key key, I input);
}

/// Builder that aggregates inputs into user-defined atomic build groups.
abstract class GroupBuilder<I> extends BuilderBase {
  @override
  void _group(GroupContext context) {
    if (context._asset is! I) return;
    groupAsset(context, context._key, context._asset as I);
  }

  @override
  Future<void> _build(
      BuildContext context, Key key, Map<Key, Object> inputs) async {
    await build(context, key, Map<Key, I>.from(inputs));
  }

  /// Override this to specify which build groups should be created and should
  /// process [asset] as an input.
  void groupAsset(GroupContext context, Key key, I asset);

  /// Apply this builder to the given key previously returned by [match()].
  Future<void> build(BuildContext context, Key key, Map<Key, I> inputs);
}

class GroupContext {
  final BuilderBase builder;

  final Map<Key, _BuildNode> _nodes;

  /// The key associated with the asset in the current call to [declare()].
  final Key _key;

  /// The asset being processed.
  final Object _asset;

  GroupContext(this.builder, this._nodes, this._key, this._asset);

  /// Call this to define a build [group].
  ///
  /// The current asset being processed is implicitly declared as an input to
  /// this group. Multiple assets may define the same group, in which case the
  /// group will process all of them as a single build. A single asset may also
  /// define multiple groups, in which case it will be an input to all of those
  /// builds. In other words, groups can be used for one-to-many builds,
  /// many-to-one, and any other topology.
  void defineGroup(Key group) {
    var node = _nodes.putIfAbsent(group, () => _BuildNode(builder, group));
    node.declaredInputs[_key] = _asset;
  }
}

class BuildContext {
  final Graph _graph;
  final _BuildNode _node;

  BuildContext(this._graph, this._node);

  /// Gets the asset of type [T] with [key].
  T input<T extends Object>(Key key) {
    var asset = _graph._assets[key];
    if (asset is T) {
      _node.readInputs.add(key);
      return asset;
    }

    // TODO: Better exception.
    if (asset == null) throw Exception('Missing input $key.');

    // TODO: Better exception.
    throw Exception('Wrong input type ${asset.runtimeType} was not $T');
  }

  /// Add [asset] with [key] as an output from this build.
  void output(Key key, Object asset) {
    // TODO: Get this working again. Should be an error if two builders produce
    // the same output in the same build, but should be OK to rebuild the same
    // output across multiple builds.
    /*
    if (_graph.assets.containsKey(key)) {
      // TODO: Better error handling.
      throw Exception('Output collisition $key');
    }
    */

    // print('${_node.builder.runtimeType} -> $key');
    _node.outputs[key] = asset;
  }
}

class _BuildNode {
  final BuilderBase builder;

  /// The build group this node represents.
  final Key group;

  final Map<Key, Object> declaredInputs = {};

  /// The other non-declared inputs read during the build.
  final Set<Key> readInputs = {};

  /// The outputs this node generated.
  final Map<Key, Object> outputs = {};

  _BuildNode(this.builder, this.group);
}
