import 'package:minibuild/minibuild.dart';

import '../model/post.dart';

/// Converts a Markdown file in the post directory to a [Post] object.
class PostBuilder extends Builder<StringAsset> {
  static final _metadataPattern = RegExp(r'^(\w+):\s*(.*)$');
  static final _titlePattern =
      RegExp(r'^asset/post/(\d{4})-(\d\d)-(\d\d)-([a-z0-9-.]+)\.md$');

  /// Match Markdown files in the static directory.
  @override
  bool matches(Key key, StringAsset source) =>
      key.isWithin('asset/post') && key.hasExtension('md');

  @override
  Future<void> build(
      BuildContext context, Key key, StringAsset markdownFile) async {
    var match = _titlePattern.firstMatch(key.toString());
    // TODO: Better error handling.
    if (match == null) throw Exception('Bad post title $key');

    var year = int.parse(match[1]!);
    var month = int.parse(match[2]!);
    var day = int.parse(match[3]!);
    var titleUri = match[4]!;

    var contents = await markdownFile.readString();
    var lines = contents.split('\n');
    if (lines.isEmpty) {
      // TODO: Better error handling.
      throw Exception('Empty post');
    }

    if (lines[0].trim() != '---') {
      // TODO: Better error handling.
      throw Exception('Missing frontmatter');
    }

    var title = '';
    var tags = <String>[];
    var contentLines = <String>[];

    for (var i = 1; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line == '---') {
        // TODO: Slow.
        contentLines.addAll(lines.skip(i + 1));
        break;
      } else {
        var match = _metadataPattern.firstMatch(line);
        if (match != null) {
          var key = match[1]!;
          var value = match[2]!;
          switch (key) {
            case 'title':
              title = value;
              // TODO: Hack. Unquote if quoted.
              if (title.startsWith('"')) {
                title = title.substring(1, title.length - 1);
                title = title.replaceAll('\\"', '"');
              }

            case 'layout':
              // TODO: Ignore old layout tags. Eventually these should be
              // removed from the posts.
              break;

            case 'categories':
              // TODO: Rename to 'tags'.
              tags = value.split(' ').toList();
              tags.sort();

            default:
              // TODO: Better error handling.
              throw Exception('Unknown metadata: $key');
          }
        } else {
          // TODO: Better error handling.
          throw Exception('Bad metadata: $line');
        }
      }
    }

    var postKey = Key.join('post', key.basenameWithoutExtension);
    context.output(postKey,
        Post(DateTime(year, month, day), title, titleUri, tags, contentLines));
  }
}
