import 'dart:async';

import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';

import '../model/template.dart';
import '../model/post.dart';

/// Builds a page for a post.
class PostPageBuilder extends Builder<Post> {
  @override
  Future<void> build(BuildContext context, Key key, Post post) async {
    var postTemplate =
        context.input<Template>(Key('betwixt/asset/template/post.html'));

    var html =
        await renderTemplate(postTemplate, context, postKey: key, post: post);
    context.output(Key.join('build', post.url, 'index.html'), html);
  }
}
