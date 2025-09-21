import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';

import '../model/template.dart';

/// Parses a Betwixt HTML file to a [Template].
class TemplateBuilder extends Builder<StringAsset> {
  /// Match Markdown files in the static directory.
  @override
  bool matches(Key key, StringAsset source) =>
      (key.isWithin('asset/template') || key.isWithin('site')) &&
      (key.hasExtension('html') || key.hasExtension('xml'));

  @override
  Future<void> build(
      BuildContext context, Key key, StringAsset htmlFile) async {
    Future<String> readInclude(String name) {
      var includeSource = context.input<StringAsset>(
          Key.join('asset', 'template_include', '$name.html'));
      return includeSource.readString();
    }

    var template = await Template.compile(
        await htmlFile.readString(), key.toString(),
        loader: readInclude, reporter: MinibuildErrorReporter(context));

    if (template != null) {
      context.output(Key.join('betwixt', key), template);
    }
  }
}
