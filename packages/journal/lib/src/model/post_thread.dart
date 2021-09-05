import 'package:collection/collection.dart';
import 'package:minibuild/minibuild.dart';

/// The lists of posts in newest to oldest order.
class PostThread {
  final List<Key> posts;

  PostThread(this.posts);

  // TODO: Handle there being zero posts.
  Key get newest => posts.first;

  Key? findNewer(Key postKey) {
    var index = posts.indexOf(postKey);
    if (index == -1) return null;
    if (index == 0) return null;
    return posts[index - 1];
  }

  Key? findOlder(Key postKey) {
    var index = posts.indexOf(postKey);
    if (index == -1) return null;
    if (index == posts.length - 1) return null;
    return posts[index + 1];
  }

  @override
  int get hashCode => const IterableEquality<Key>().hash(posts);

  @override
  bool operator ==(Object other) =>
      other is PostThread &&
      const IterableEquality<Key>().equals(posts, other.posts);
}
