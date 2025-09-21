import 'package:chromatophore/chromatophore.dart';
import 'package:typographic_markdown/typographic_markdown.dart';
import 'package:chromatophore/markdown.dart';
import 'package:markdown/markdown.dart';

import 'code/ascii_art.dart';
import 'code/finch.dart';
import 'code/jasic.dart';
import 'code/magpie.dart';
import 'code/vgs.dart';

final _languages = {
  'asciiart': makeAsciiArtLanguage(),
  'magpie1': makeMagpie1Language(),
  'magpie': makeMagpieLanguage(),
  'finch': makeFinchLanguage(),
  'jasic': makeJasicLanguage(),
  'vgs': makeVgsLanguage(),
};

String renderMarkdown(List<String> lines) {
  var document = Document(blockSyntaxes: [
    // TODO: Header syntax that adds anchor links.
    HighlightedCodeBlockSyntax(languages: _languages),
  ], inlineSyntaxes: [
    // Put inline Markdown code syntax before our smart quotes so that
    // quotes inside `code` spans don't get smartened.
    CodeSyntax(),
    ...allSyntaxes,
  ], extensionSet: ExtensionSet.gitHubFlavored);
  var ast = document.parseLines(lines);
  return HtmlRenderer().render(ast);
}
