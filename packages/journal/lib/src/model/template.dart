import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';
import 'package:source_span/source_span.dart';

import '../model/post.dart';
import 'post_thread.dart';
import 'tag_set.dart';

/// Make the build date final so that the output doesn't spontaneously change
/// even though no input has changed.
late final _buildDate = DateTime.now();

Future<String> renderTemplate(Template template, BuildContext context,
    {Key? postKey, Post? post, Tag? tag, Map<String, Object?>? data}) async {
  Object? getProperty(String property) {
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
        var olderKey = thread.findOlder(postKey ?? thread.newest);
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
        tags.sort();
        var tagMaps = [
          for (var tag in tags) {'name': tag, 'count': tagSet.postCount(tag)}
        ];

        return tagMaps;
      case 'tag_posts':
        if (tag == null) return null;
        return tag.posts.map((key) => context.input<Post>(key)).toList();
      default:
        if (data != null && data.containsKey(property)) {
          return data[property];
        }
        return TemplateData.unknownProperty;
    }
  }

  return await template.render(getProperty,
      reporter: MinibuildErrorReporter(context));
}

/// A Betwixt error reporter that plumbs the error through to Minibuild.
class MinibuildErrorReporter implements ErrorReporter {
  final BuildContext _context;

  MinibuildErrorReporter(this._context);

  @override
  void report(SourceSpan span, String message) {
    _context.error(span.message(message));
  }
}
