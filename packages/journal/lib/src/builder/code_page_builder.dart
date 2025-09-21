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

    var codePosts = <Map<String, Object>>[];
    for (var post in sorted) {
      var snippets = <Map<String, Object>>[];
      var inCode = false;
      var snippetLines = <String>[];
      var language = 'text';
      for (var line in post.contents) {
        if (inCode) {
          snippetLines.add(line);

          if (line.trim().startsWith('```')) {
            snippetLines.add('');
            inCode = false;
            snippets.add({
              'language': language,
              'code': renderMarkdown(context, snippetLines)
            });
            snippetLines.clear();
          }
        } else {
          if (line.trim().startsWith('```')) {
            language = line.trim().substring(3);
            if (language.isEmpty) language = 'text';
            snippetLines.add(line);
            inCode = true;
          }
        }
      }

      if (snippets.isNotEmpty) {
        codePosts.add({
          'post': post,
          'snippets': snippets,
        });
      }
    }

    var postTemplate =
        context.input<Template>(Key('betwixt/asset/template/all_code.html'));
    var html = await renderTemplate(postTemplate, context,
        data: {'code_posts': codePosts});
    context.output(key, html);
  }
}
