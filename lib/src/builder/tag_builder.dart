import 'package:minibuild/minibuild.dart';

import '../model/post.dart';
import '../model/tag_set.dart';

/// Collects the tags from all the posts and outputs a [Tag] for each.
class TagBuilder extends GroupBuilder<Post> {
  @override
  void groupAsset(GroupContext context, Key key, Post post) {
    for (var tag in post.tags) {
      context.defineGroup(Key.join('tag', tag));
    }
  }

  @override
  Future<void> build(
      BuildContext context, Key key, Map<Key, Post> posts) async {
    var keys = posts.keys.toList();
    keys.sort((a, b) => posts[b]!.date.compareTo(posts[a]!.date));
    context.output(key, Tag(key.basename, keys));
  }
}
