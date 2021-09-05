import 'package:collection/collection.dart';
import 'package:minibuild/minibuild.dart';

/// All of the tags and their post counts.
class TagSet {
  final Map<String, int> _counts;

  TagSet(this._counts);

  Iterable<String> get tags => _counts.keys;

  int postCount(String tag) => _counts[tag]!;

  @override
  int get hashCode => const MapEquality<String, int>().hash(_counts);

  @override
  bool operator ==(Object other) =>
      other is TagSet &&
      const MapEquality<String, int>().equals(_counts, other._counts);
}

class Tag {
  final String name;

  /// The [Key]s of the posts with this tag, sorted by date.
  final List<Key> posts;

  Tag(this.name, this.posts);

  @override
  String toString() => 'Tag($name, ${posts.length})';

  @override
  int get hashCode => name.hashCode ^ const IterableEquality<Key>().hash(posts);

  @override
  bool operator ==(Object other) =>
      other is Tag &&
      name == other.name &&
      const IterableEquality<Key>().equals(posts, other.posts);
}
