import 'package:minibuild/minibuild.dart';

import '../markdown.dart';
import '../model/post.dart';

/// Converts a Markdown file in the post directory to a [Post] object.
class PostBuilder extends Builder<StringAsset> {
  static final _metadataPattern = RegExp(r'^(\w+):\s*(.*)$');
  static final _titlePattern =
      RegExp(r'^asset/post/(\d{4})-(\d\d)-(\d\d)-([a-z0-9-.]+)\.md$');

  final bool _includeTestPages;

  PostBuilder({bool includeTestPages = false})
      : _includeTestPages = includeTestPages;

  /// Match Markdown files in the static directory.
  @override
  bool matches(Key key, StringAsset source) =>
      key.isWithin('asset/post') && key.hasExtension('md');

  @override
  Future<void> build(
      BuildContext context, Key key, StringAsset markdownFile) async {
    var match = _titlePattern.firstMatch(key.toString());
    if (match == null) {
      context
          .error('Post filename should look like "1234-56-78-post-title.md".');
      return;
    }

    var year = int.parse(match[1]!);
    var month = int.parse(match[2]!);
    var day = int.parse(match[3]!);
    var titleUri = match[4]!;

    // Any "test" pages for using during development are set to year 3000. Skip
    // this if we aren't in a debug build.
    if (year == 3000 && !_includeTestPages) return;

    var lines = (await markdownFile.readString()).split('\n');

    String? title;
    var tags = <String>[];
    var contentLines = <String>[];

    // Read the frontmatter.
    if (lines.isNotEmpty && lines[0].trim() == '---') {
      for (var i = 1; i < lines.length; i++) {
        var line = lines[i].trim();
        if (line == '---') {
          // TODO: Slow.
          contentLines.addAll(lines.skip(i + 1));
          break;
        } else {
          if (_metadataPattern.firstMatch(line) case var match?) {
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

              case 'tags':
                tags = value.split(' ').toList();
                tags.sort();

              default:
                context.error('Unknown frontmatter metadata key "$key" '
                    'on line ${i + 1}:\n$line');
            }
          } else {
            context.error('Unparseable frontmatter on line ${i + 1}:\n$line');
          }
        }
      }
    } else {
      context.error('Missing frontmatter.');
    }

    if (title == null) {
      context.error('Missing post title in frontmatter.');

      // Use a temporary title so the rest of the build can continue.
      title = key.basenameWithoutExtension;
    }

    var html = renderMarkdown(context, contentLines);

    var postKey = Key.join('post', key.basenameWithoutExtension);
    context.output(
        postKey,
        Post(DateTime(year, month, day), title, titleUri, tags, contentLines,
            html));
  }
}
