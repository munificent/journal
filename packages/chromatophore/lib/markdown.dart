import 'dart:convert';

import 'package:markdown/markdown.dart';

import 'chromatophore.dart';

/// Custom code block formatter that chromatophone for syntax highlighting.
class HighlightedCodeBlockSyntax extends BlockSyntax {
  static final _codeFencePattern = RegExp(r'^(\s*)```(.*)$');

  final Map<String, Language> _languages;
  final HtmlFormatter _formatter;

  @override
  RegExp get pattern => _codeFencePattern;

  HighlightedCodeBlockSyntax(
      {Map<String, Language> languages = const {},
      Map<Category, String>? cssClasses})
      : _languages = languages,
        _formatter =
            cssClasses == null ? HtmlFormatter() : HtmlFormatter(cssClasses);

  @override
  bool canParse(BlockParser parser) =>
      pattern.firstMatch(parser.current) != null;

  @override
  List<String> parseChildLines(BlockParser parser) {
    var childLines = <String>[];
    parser.advance();

    while (!parser.isDone) {
      var match = pattern.firstMatch(parser.current);
      if (match == null) {
        childLines.add(parser.current);
        parser.advance();
      } else {
        parser.advance();
        break;
      }
    }

    return childLines;
  }

  @override
  Node parse(BlockParser parser) {
    // Get the syntax identifier, if there is one.
    var match = pattern.firstMatch(parser.current)!;
    var indent = match[1]!.length;
    var languageName = match[2]!;
    if (languageName == '') languageName = 'text';

    var childLines = parseChildLines(parser);

    Language? language;

    // Don't syntax highlight text.
    if (languageName != 'text') {
      language = _languages[languageName] ?? Language.find(languageName);
      if (language == null) {
        // print('Cannot find highlighter for "$languageName".');
        // TODO: Better error reporting.
      }
    }

    String code;
    if (language == null) {
      var buffer = StringBuffer();

      for (var line in childLines) {
        if (buffer.isNotEmpty) buffer.writeln();

        // Strip off any leading indentation.
        if (line.length > indent) line = line.substring(indent);

        buffer.write(const HtmlEscape().convert(line));
      }

      code = buffer.toString();
    } else {
      // TODO: Is there something faster than joining the lines?
      code = highlight(language, childLines.join('\n'), _formatter);
    }

    // TODO: This is just to be compatible with the Pygments output from the
    // old blog. Simplify this once no longer trying to match the old HTML.
    var element = Element.text('code', code);
    element.attributes['class'] = 'language-$languageName';
    element.attributes['data-lang'] = languageName;

    element = Element('pre', [element]);
    element = Element('div', [element]);
    element.attributes['class'] = 'highlight';

    return element;
  }
}
