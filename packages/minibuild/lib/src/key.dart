import 'package:path/path.dart' as p;

/// Uniquely identifies an asset or build step.
///
/// Keys are, by convention, relative URL paths.
class Key {
  final String _key;

  Key(this._key);

  factory Key.join(Object part1, Object part2, [Object? part3, Object? part4]) {
    var parts = [
      part1,
      part2,
      if (part3 != null) part3,
      if (part4 != null) part4,
    ];

    return Key(p.url.joinAll(parts.map((part) => part.toString())));
  }

  String get basename => p.url.basename(_key);

  String get basenameWithoutExtension => p.url.basenameWithoutExtension(_key);

  String get extension => p.url.extension(_key);

  /// Returns `true` if this key's path is within [path].
  bool isWithin(String path) => p.url.isWithin(path, _key);

  Key relativeTo(String parent) => Key(p.url.relative(_key, from: parent));

  Key changeExtension(String extension) =>
      Key('${p.url.withoutExtension(_key)}.$extension');

  Key basenameWithExtension(String extension) =>
      Key('${p.url.basenameWithoutExtension(_key)}.$extension');

  bool hasExtension(String extension) => p.url.extension(_key) == '.$extension';

  @override
  String toString() => _key;

  @override
  bool operator ==(Object other) => other is Key && _key == other._key;

  @override
  int get hashCode => _key.hashCode;
}
