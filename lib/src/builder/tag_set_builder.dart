import 'package:minibuild/minibuild.dart';

import '../model/tag_set.dart';

/// Collects the tags and outputs a [TagSet].
class TagSetBuilder extends GroupBuilder<Tag> {
  @override
  void groupAsset(GroupContext context, Key key, Tag tag) {
    // TODO: Hardcoded monolithic key is kind of lame.
    context.defineGroup(Key('tagset'));
  }

  @override
  Future<void> build(BuildContext context, Key key, Map<Key, Tag> tags) async {
    // TODO: Hokey. Have TagSet do this?
    var tagMap = {for (var tag in tags.values) tag.name: tag.posts.length};
    context.output(key, TagSet(tagMap));
  }
}
