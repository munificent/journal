import 'dart:async';
import 'dart:io';

import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:watcher/watcher.dart';

import 'file_asset.dart';
import 'src/asset.dart';
import 'src/graph.dart';
import 'src/key.dart';

class BuildServer {
  final List<String> sourceDirectories;

  final String buildDirectory;

  final Graph _graph;
  final Pool _pool = Pool(64);

  /// The files that have been added or changed since the last build.
  final Map<Key, FileAsset> _changedFiles = {};

  /// The files that were removed since the last build.
  final Set<Key> _removedFiles = {};

  /// A short delay between when a file change event occurs and when the build
  /// starts. This lets us batch file changes together.
  Timer? _changeDebounce;

  BuildServer(
      {this.sourceDirectories = const [],
      this.buildDirectory = 'build',
      required List<BuilderBase> builders})
      : _graph = Graph(builders);

  Future<void> initialize() async {
    if (sourceDirectories.isNotEmpty) await _scanFiles();

    // Clean the build directory.
    var buildDir = Directory(buildDirectory);
    if (await buildDir.exists()) await buildDir.delete(recursive: true);

    // Run the initial build.
    await _build();
  }

  Future<void> _scanFiles() async {
    print('Reading input files...');
    for (var dir in sourceDirectories) {
      await for (var entry in Directory(dir).list(recursive: true)) {
        if (entry is! File) continue;

        // Skip hidden files like .DS_Store.
        if (_ignoreFile(entry.path)) continue;

        var file = FileAsset(entry);
        _graph.addAsset(file.path, file);
      }
    }
  }

  Future<void> _build() async {
    var watch = Stopwatch()..start();
    var built = await _graph.build();

    var written = 0;
    var futures = <Future<void>>[];
    for (var key in built) {
      if (!key.isWithin(buildDirectory)) continue;

      futures.add(_pool.withResource(() async {
        var path = p.fromUri(key.toString());
        await Directory(p.dirname(path)).create(recursive: true);

        var asset = _graph.assets[key]!;
        if (asset is BinaryAsset) {
          await File(path).writeAsBytes(await asset.readBytes());
          written++;
        } else if (asset is StringAsset) {
          await File(path).writeAsString(await asset.readString());
          written++;
        } else if (asset is String) {
          await File(path).writeAsString(asset);
          written++;
        } else {
          print("Don't know how to write '$path' (${asset.runtimeType}).");
        }
      }));
    }

    await Future.wait(futures);

    if (built.isNotEmpty) {
      var elapsed = watch.elapsedMilliseconds;
      var assets = built.length == 1 ? 'asset' : 'assets';
      var files = written == 1 ? 'file' : 'files';

      print('Generated ${built.length} $assets and wrote $written $files in '
          '${elapsed / 1000}s');
    }
  }

  Future<void> serve() async {
    for (var directory in sourceDirectories) {
      Watcher(directory).events.listen(_onWatchEvent);
    }

    var handler = const shelf.Pipeline().addHandler(_handleRequest);

    var server = await io.serve(handler, 'localhost', 8000);
    print('Serving at http://${server.address.host}:${server.port}');
  }

  Future<void> _onWatchEvent(WatchEvent event) async {
    var key = Key(event.path);

    if (_ignoreFile(event.path)) return;

    switch (event.type) {
      case ChangeType.ADD:
      case ChangeType.MODIFY:
        print('Changed $key');
        // TODO: What if `event.path` is a directory?
        _changedFiles[key] = FileAsset(File(event.path));

      case ChangeType.REMOVE:
        print('Removed $key');
        _removedFiles.add(key);
    }

    // If a build is already running, then we will look for changes after it
    // completes.
    if (!_graph.isBuilding) {
      // Reset or start the debounce timer.
      _changeDebounce?.cancel();
      _changeDebounce = Timer(Duration(milliseconds: 10), _afterDebounce);
    }
  }

  Future<void> _afterDebounce() async {
    _changeDebounce = null;

    // Other changes may come in while the current build is running. When that
    // happens, we'll immediately trigger a new build.
    while (_changedFiles.isNotEmpty || _removedFiles.isNotEmpty) {
      // Apply any changes to the graph.
      _changedFiles.forEach(_graph.addAsset);
      _removedFiles.forEach(_graph.removeAsset);
      _changedFiles.clear();
      _removedFiles.clear();

      await _build();
    }
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    var assetPath = p.url.normalize(p.url.fromUri(request.url));
    if (request.url.path.endsWith('/') || p.url.extension(assetPath) == '') {
      assetPath = p.url.normalize(p.url.join(assetPath, 'index.html'));
    }

    var extension = p.url.extension(assetPath).replaceAll('.', '');

    var asset = _graph.assets[Key.join(buildDirectory, assetPath)];
    if (asset != null) {
      Object? contents;
      if (asset is BinaryAsset) {
        contents = await asset.readBytes();
      } else if (asset is String) {
        contents = asset;
      } else {
        print("don't know how to serve $assetPath (${assetPath.runtimeType})");
      }

      return shelf.Response.ok(contents, headers: {
        // TODO: Handle unknown extension.
        HttpHeaders.contentTypeHeader: mimeFromExtension(extension)!
      });
    } else {
      print('${request.method} Not found: ${request.url} ($assetPath)');
      return shelf.Response.notFound('Could not find "$assetPath".');
    }
  }

  /// Whether [path] should be a file visible to the build or not.
  bool _ignoreFile(String path) {
    if (p.basename(path) == '.DS_Store') return true;

    return false;
  }
}
