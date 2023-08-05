import 'package:source_span/source_span.dart';

import 'string_extension.dart';

class Token {
  final TokenType type;
  final FileSpan span;

  /// The processed text of the token. For text and string literals, this means
  /// whitespace has been trimmed, escapes applied, etc.
  ///
  /// For all other tokens, this will be the raw lexeme.
  final String text;

  /// If this token is an open tag, the index of the matching closing tag.
  ///
  /// Otherwise -1.
  int closeTag = -1;

  Token(this.type, this.span, this.text);

  @override
  String toString() => '$type "${text.toStringLiteral()}" ${span.start}';
}

enum TokenType {
  /// Literal text.
  text,

  /// Newline in literal text.
  newline,

  /// Leading whitespace in literal text.
  indent,

  /// Beginning '{{' tag marker.
  openTag,

  /// ending '}}' tag marker.
  closeTag,

  /// Variable or function name.
  identifier,

  /// Literals.
  string,
  number,

  /// Punctuation.
  leftParen,
  rightParen,
  comma,
  dot,
  equal,
  // TODO: Implement.
  bang,
  minus,
  plus,
  bangEqual,
  equalEqual,
  // TODO: Others.

  /// Keywords.
  andKeyword,
  betweenKeyword,
  elseKeyword,
  endKeyword,
  falseKeyword,
  forKeyword,
  ifKeyword,
  inKeyword,
  includeKeyword,
  letKeyword,
  nullKeyword,
  orKeyword,
  setKeyword,
  trueKeyword,
  withKeyword,
}

extension TokenTypeExtension on TokenType {
  static const _names = {
    TokenType.text: 'text',
    TokenType.newline: 'newline',
    TokenType.indent: 'indent',
    TokenType.openTag: 'openTag',
    TokenType.closeTag: 'closeTag',
    TokenType.identifier: 'identifier',
    TokenType.string: 'string',
    TokenType.number: 'number',
    TokenType.leftParen: 'leftParen',
    TokenType.rightParen: 'rightParen',
    TokenType.comma: 'comma',
    TokenType.dot: 'dot',
    TokenType.equal: 'equal',
    TokenType.bang: 'bang',
    TokenType.minus: 'minus',
    TokenType.plus: 'plus',
    TokenType.bangEqual: 'bangEqual',
    TokenType.equalEqual: 'equalEqual',
    TokenType.andKeyword: 'and',
    TokenType.betweenKeyword: 'between',
    TokenType.elseKeyword: 'else',
    TokenType.endKeyword: 'end',
    TokenType.falseKeyword: 'false',
    TokenType.forKeyword: 'for',
    TokenType.ifKeyword: 'if',
    TokenType.inKeyword: 'in',
    TokenType.includeKeyword: 'include',
    TokenType.letKeyword: 'let',
    TokenType.nullKeyword: 'null',
    TokenType.orKeyword: 'ok',
    TokenType.setKeyword: 'set',
    TokenType.trueKeyword: 'true',
    TokenType.withKeyword: 'with',
  };

  String get name => _names[this]!;
}
