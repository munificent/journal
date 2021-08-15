import 'package:minibuild/minibuild.dart';

import '../model/post.dart';
import '../model/post_thread.dart';

/// Generates the ordered list of Posts.
class PostThreadBuilder extends GroupBuilder<Post> {
  @override
  void groupAsset(GroupContext context, Key key, Post post) {
    // TODO: Hardcoded monolithic key is kind of lame.
    context.defineGroup(Key('post_thread'));
  }

  @override
  Future<void> build(
      BuildContext context, Key key, Map<Key, Post> posts) async {
    var keys = posts.keys.toList();
    keys.sort((a, b) => posts[b]!.date.compareTo(posts[a]!.date));

    context.output(key, PostThread(keys));
  }
}
