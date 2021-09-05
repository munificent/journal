import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';

import '../model/template_data.dart';

/// Renders a Betwixt template in `site/` to an HTML file.
class TemplatePageBuilder extends Builder<Template> {
  /// Match Markdown files in the static directory.
  @override
  bool matches(Key key, Template template) => key.isWithin('betwixt/site');

  @override
  Future<void> build(BuildContext context, Key key, Template template) async {
    // TODO: Pass in error reporter that plumbs through build system.
    var html = await template
        .render((String property) => templateData(context, property));

    context.output(Key.join('build', key.relativeTo('betwixt/site')), html);
  }
}
