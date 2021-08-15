import 'dart:async';

import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';

import '../model/template_data.dart';
import '../model/post.dart';

/// Builds a page for a post.
class PostPageBuilder extends Builder<Post> {
  @override
  Future<void> build(BuildContext context, Key key, Post post) async {
    var postTemplate =
        context.input<Template>(Key('betwixt/asset/template/post.html'));

    // TODO: Pass in error reporter that plumbs through build system.
    var html = await postTemplate.render((String property) =>
        templateData(context, property, postKey: key, post: post));

    context.output(Key.join('build', post.url, 'index.html'), html);
  }
}
