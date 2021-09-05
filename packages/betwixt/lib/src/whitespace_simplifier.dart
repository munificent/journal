import 'token.dart';

/// Discards whitespace around block-style control flow tags.
///
/// We do this as a separate pass after scanning because we don't know which
/// `{{` tags will correspond to block-style control flow until more tokens
/// have been scanned after it.
class WhitespaceSimplifier {
  final List<Token> _input;
  final List<Token?> _working = [];

  WhitespaceSimplifier(this._input);

  List<Token> simplify() {
    _working.addAll(_input);

    // Strip unnecessary whitespace and newlines from block control flow.
    const controlFlowTypes = {
      TokenType.betweenKeyword,
      TokenType.elseKeyword,
      TokenType.endKeyword,
      TokenType.forKeyword,
      TokenType.ifKeyword,
      TokenType.includeKeyword,
      TokenType.letKeyword,
      TokenType.setKeyword,
    };

    for (var i = 0; i < _working.length - 1; i++) {
      // Look for an open tag.
      var tagToken = _working[i];
      if (tagToken == null) continue;
      if (tagToken.type != TokenType.openTag) continue;

      // See if it's for control flow.
      var keyword = _working[i + 1];
      if (keyword == null || !controlFlowTypes.contains(keyword.type)) continue;

      // See if the open tag is at the beginning of the line.
      if (!_isAtBeginningOfLine(i)) continue;

      // See if the close tag is at the end of the line.
      if (tagToken.closeTag == -1) continue;
      // TODO: Allow trailing whitespace.
      if (!_match(tagToken.closeTag + 1, TokenType.newline)) continue;

      // Discard leading indentation.
      if (_match(i - 1, TokenType.indent)) {
        _working[i - 1] = null;
      }

      // Discard trailing newline.
      _working[tagToken.closeTag + 1] = null;
    }

    return _working.whereType<Token>().toList();
  }

  /// Whether the token at [i] is at the beginning of a line with potentially
  /// indentation before it.
  bool _isAtBeginningOfLine(int i) {
    // If it's the first tag, it is.
    if (i == 0) return true;

    var before = _working[i - 1];

    // The only tokens we remove are indents and newlines, so if the previous
    // token is removed, this token must start a line.
    if (before == null) return true;

    return before.type == TokenType.indent || before.type == TokenType.newline;
  }

  bool _match(int i, TokenType type) {
    if (i < 0 || i >= _working.length) return false;

    var token = _working[i];
    if (token == null) return false;
    return token.type == type;
  }
}
