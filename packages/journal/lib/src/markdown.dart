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
    HeaderWithAnchorSyntax(),
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

/// Parses atx-style headers, and adds generated IDs to the generated elements.
class HeaderWithAnchorSyntax extends HeaderSyntax {
  const HeaderWithAnchorSyntax();

  @override
  Node parse(BlockParser parser) {
    var element = super.parse(parser) as Element;

    if (element.children case var children?) {
      // Hack. The markdown package parses block syntax before parsing any
      // inline syntax, so if the header contains any inline tags (like a link)
      // then they will still be UnparsedText nodes at this point. We don't
      // want that Markdown to end up in the ID, so eagerly parse the inline
      // syntax here.
      // TODO: Update to the latest markdown package and see if it's better.
      _parseInlineContent(parser, children);
    }

    // If the header already contains an explicit link, then don't automatically
    // wrap it in a link. (This is true for the "40 Songs" post.)
    if (_containsLink(element)) return element;

    var id = _generateAnchorHash(element);

    // Add a separate anchor span.
    var anchorSpan = Element.text('span', '#$id');
    anchorSpan.attributes['class'] = 'anchor';

    // Wrap everything in a link.
    var link = Element('a', [...?element.children, anchorSpan]);
    link.attributes['href'] = '#$id';

    // Replace the contents of the header tag with the link.
    element = Element(element.tag, [link]);
    element.generatedId = id;
    return element;
  }

  /// Generates a valid HTML anchor from the inner text of [element].
  String _generateAnchorHash(Element element) {
    return element.textContent
        .toLowerCase()
        .replaceAll(RegExp(r'\&[a-z]+;'), '') // Remove HTML entities.
        .replaceAll(RegExp(r'[^a-z0-9 _-]'), '') // Remove other characters.
        .trim() // Now remove leading and trailing whitespace.
        .replaceAll(RegExp(r'\s+'), '-'); // Replace whitespace with `-`.
  }

  void _parseInlineContent(BlockParser parser, List<Node> nodes) {
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node is UnparsedContent) {
        var inlineNodes = parser.document.parseInline(node.textContent);
        nodes.removeAt(i);
        nodes.insertAll(i, inlineNodes);
        i += inlineNodes.length - 1;
      } else if (node is Element && node.children != null) {
        _parseInlineContent(parser, node.children!);
      }
    }
  }

  bool _containsLink(Node node) {
    if (node is! Element) return false;
    if (node.tag == 'a') return true;
    return node.children?.any(_containsLink) ?? false;
  }
}
