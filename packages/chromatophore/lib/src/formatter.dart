import 'dart:convert';

import 'category.dart';
import 'token.dart';

const _escape = HtmlEscape(
    HtmlEscapeMode(escapeLtGt: true, escapeQuot: true, escapeApos: true));

/// Renders a series of [Token]s to a string.
abstract class Formatter {
  static final html = HtmlFormatter();

  // TODO: Do we want to support formatting to things other than strings?
  // Pygments can format to images.
  String format(Iterable<Token> tokens);
}

class HtmlFormatter implements Formatter {
  static const defaultStyle = {
    Category.annotation: 'a',
    Category.comment: 'c',
    Category.stringEscape: 'e',
    Category.identifier: 'i',
    Category.keyword: 'k',
    Category.number: 'n',
    Category.punctuation: 'p',
    Category.operator: 'o',
    Category.string: 's',
    Category.field: 'f',
    Category.typeName: 't',
    Category.preprocessor: 'r',
    Category.tag: 'g',
    Category.unrecognized: 'u',
    Category.metasyntax: 'x',
    Category.blue: 'blue',
    Category.red: 'red',
  };

  /// Maps categories to CSS class names.
  final Map<Category, String> _cssClasses;

  HtmlFormatter([this._cssClasses = defaultStyle]);

  @override
  String format(Iterable<Token> tokens) {
    var buffer = StringBuffer();

    for (var token in tokens) {
      String? style;
      for (Category? category = token.category;
          style == null && category != null;
          category = category.parent) {
        style = _cssClasses[category];
      }

      if (style != null) buffer.write('<span class="$style">');
      buffer.write(_escape.convert(token.text));
      if (style != null) buffer.write('</span>');
    }

    return buffer.toString();
  }
}
