import 'package:minibuild/minibuild.dart';
import 'package:sass/sass.dart' as sass;

/// Compiles SCSS files to CSS.
class SassBuilder extends Builder<StringAsset> {
  @override
  bool matches(Key key, StringAsset source) =>
      key.isWithin('site') && key.hasExtension('scss');

  @override
  Future<void> build(
      BuildContext context, Key key, StringAsset sassFile) async {
    var sassSource = await sassFile.readString();

    // TODO: Pass in importer for modules.
    // TODO: Pass in error reporter that plumbs through build system.
    var result = sass.compileStringToResult(sassSource,
        color: true, style: sass.OutputStyle.expanded);

    var cssKey =
        Key.join('build', key.relativeTo('site')).changeExtension('css');
    context.output(cssKey, result.css);
  }
}
