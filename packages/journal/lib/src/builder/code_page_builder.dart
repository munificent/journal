import 'dart:async';

import 'package:betwixt/betwixt.dart';
import 'package:journal/src/markdown.dart';
import 'package:minibuild/minibuild.dart';

import '../model/template.dart';
import '../model/post.dart';

/// Builds a page containing all code snippets.
class CodePageBuilder extends GroupBuilder<Post> {
  @override
  void groupAsset(GroupContext context, Key key, Post post) {
    context.defineGroup(Key('build/code.html'));
  }

  @override
  Future<void> build(
      BuildContext context, Key key, Map<Key, Post> posts) async {
    var sorted = posts.values.toList();
    sorted.sort((a, b) => a.url.compareTo(b.url));

    var lines = <String>[];
    for (var post in sorted) {
      var inCode = false;
      var showedTitle = false;

      for (var line in post.contents) {
        if (inCode) {
          lines.add(line);

          if (line.trim().startsWith('```')) {
            lines.add('');
            inCode = false;
          }
        } else {
          if (line.trim().startsWith('```')) {
            if (!showedTitle) {
              lines.add('## ${post.url}');
              lines.add('');
              showedTitle = true;
            }

            lines.add(line.trim().substring(3));
            lines.add('');
            lines.add(line);
            inCode = true;
          }
        }
      }
    }

    var codeHtml = renderMarkdown(context, lines);

    var postTemplate =
        context.input<Template>(Key('betwixt/asset/template/all_code.html'));
    var html =
        await renderTemplate(postTemplate, context, data: {'code': codeHtml});
    context.output(key, html);
  }
}
