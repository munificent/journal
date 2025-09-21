import 'package:chromatophore/chromatophore.dart';
import 'package:minibuild/minibuild.dart';
import 'package:typographic_markdown/typographic_markdown.dart';
import 'package:chromatophore/markdown.dart';
import 'package:markdown/markdown.dart';

import 'code/ascii_art.dart';
import 'code/finch.dart';
import 'code/jasic.dart';
import 'code/magpie.dart';
import 'code/vgs.dart';

String renderMarkdown(BuildContext context, List<String> lines) {
  var document = Document(blockSyntaxes: [
    // TODO: Header syntax that adds anchor links.
    HighlightedCodeBlockSyntax(languages: JournalLanguageProvider(context)),
  ], inlineSyntaxes: [
    // Put inline Markdown code syntax before our smart quotes so that
    // quotes inside `code` spans don't get smartened.
    CodeSyntax(),
    ...allSyntaxes,
  ], extensionSet: ExtensionSet.gitHubFlavored);
  var ast = document.parseLines(lines);
  return HtmlRenderer().render(ast);
}

class JournalLanguageProvider extends LanguageProvider {
  /// The custom languages used by my blog.
  static final Map<String, Language> _languages = {
    'asciiart': makeAsciiArtLanguage(),
    'magpie1': makeMagpie1Language(),
    'magpie': makeMagpieLanguage(),
    'finch': makeFinchLanguage(),
    'jasic': makeJasicLanguage(),
    'vgs': makeVgsLanguage(),
  };

  final BuildContext _context;

  JournalLanguageProvider(this._context);

  @override
  Language? find(String name) {
    var language = _languages[name] ?? super.find(name);
    if (language == null) {
      _context
          .error("Couldn't find a syntax highlighter for language \"$name\".");
    }

    return language;
  }
}
