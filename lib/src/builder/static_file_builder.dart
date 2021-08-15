import 'package:minibuild/minibuild.dart';

class StaticFileBuilder extends Builder<BinaryAsset> {
  /// Match files in the static directory not matched by other builders.
  @override
  bool matches(Key key, BinaryAsset asset) =>
      key.isWithin('site') &&
      // TODO: Come up with a cleaner way to handle processed assets.
      !key.hasExtension('html') &&
      !key.hasExtension('scss');

  @override
  Future<void> build(BuildContext context, Key key, BinaryAsset input) async {
    var outputKey = Key.join('build', key.relativeTo('site'));
    context.output(outputKey, input);
  }
}
