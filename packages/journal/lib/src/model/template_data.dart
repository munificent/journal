import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';

import '../model/post.dart';
import 'post_thread.dart';
import 'tag_set.dart';

/// Make the build date final so that the output doesn't spontaneously change
/// even though no input has changed.
late final _buildDate = DateTime.now();

Object? templateData(BuildContext context, String property,
    {Key? postKey,
    Post? post,
    Tag? tag,
    String? tagTitle,
    Map<String, Object?>? data}) {
  switch (property) {
    case 'build_date':
      return _buildDate;

    case 'post':
      return post;

    case 'all_posts':
      var thread = context.input<PostThread>(Key('post_thread'));
      return [for (var key in thread.posts) context.input<Post>(key)];

    case 'first_post':
      var thread = context.input<PostThread>(Key('post_thread'));
      return context.input<Post>(thread.newest);

    case 'older_post':
      // TODO: In the template for these links, the titles are not escaped
      // to match the old output, but they should be.
      var thread = context.input<PostThread>(Key('post_thread'));
      postKey ??= thread.newest;
      var olderKey = thread.findOlder(postKey);
      if (olderKey == null) return null;
      return context.input<Post>(olderKey);

    case 'newer_post':
      if (postKey == null) return null;

      var thread = context.input<PostThread>(Key('post_thread'));
      var newerKey = thread.findNewer(postKey);
      if (newerKey == null) return null;
      return context.input<Post>(newerKey);

    case 'post_count':
      return context.input<PostThread>(Key('post_thread')).posts.length;

    case 'tags':
      var tagSet = context.input<TagSet>(Key('tagset'));
      var tags = tagSet.tags.toList();

      // Sort by descending count then by name.
      tags.sort((a, b) {
        var countCompare = tagSet.postCount(b).compareTo(tagSet.postCount(a));
        if (countCompare != 0) return countCompare;
        return a.compareTo(b);
      });

      // Convert to maps.
      var tagMaps = [
        for (var tag in tags) {'name': tag, 'count': tagSet.postCount(tag)}
      ];

      return tagMaps;

    case 'tag_posts':
      if (tag == null) return null;
      return tag.posts.map((key) => context.input<Post>(key)).toList();

    case 'tag_title':
      return tagTitle;

    default:
      if (data != null && data.containsKey(property)) {
        return data[property];
      }

      return TemplateData.unknownProperty;
  }
}
