import 'package:charcode/ascii.dart';
import 'package:source_span/source_span.dart';
import 'package:string_scanner/string_scanner.dart';

import 'error_reporter.dart';
import 'token.dart';

class Scanner {
  static final _identifierPattern = RegExp(r'[a-zA-Z_][a-zA-Z_0-9]*');
  static final _numberPattern = RegExp(r'[0-9]+(\.[0-9]+)?');
  static final _spacePattern = RegExp(r' +');
  static final _whitespacePattern = RegExp(r'\s+');

  static const _keywords = {
    'and': TokenType.andKeyword,
    'between': TokenType.betweenKeyword,
    'else': TokenType.elseKeyword,
    'end': TokenType.endKeyword,
    'false': TokenType.falseKeyword,
    'for': TokenType.forKeyword,
    'if': TokenType.ifKeyword,
    'in': TokenType.inKeyword,
    'include': TokenType.includeKeyword,
    'let': TokenType.letKeyword,
    'null': TokenType.nullKeyword,
    'or': TokenType.orKeyword,
    'set': TokenType.setKeyword,
    'true': TokenType.trueKeyword,
    'with': TokenType.withKeyword,
  };

  final SpanScanner _scanner;
  final ErrorReporter _reporter;
  final List<Token> _tokens = [];

  /// The open `{{` tags that have yet to have their closing `}}` tag scanned.
  final List<Token> _openTagStack = [];

  /// Whether we are currently inside literal text or template tags.
  bool _isInCode = false;

  Scanner(String source, String url, this._reporter)
      : _scanner = SpanScanner(source, sourceUrl: url);

  // TODO: Lazy?
  List<Token> scan() {
    // Emit an indent for any indentation on the first line.
    _indent();

    while (!_scanner.isDone) {
      if (_isInCode) {
        _scanCode();
      } else {
        _scanText();
      }
    }

    return _tokens;
  }

  void _scanCode() {
    while (!_scanner.isDone) {
      _skipWhitespace();
      if (_scanner.isDone) break;

      switch (_scanner.peekChar()) {
        case $lparen:
          _oneCharToken(TokenType.leftParen);
        case $rparen:
          _oneCharToken(TokenType.rightParen);
        case $exclamation:
          _oneOrTwoCharToken($equal, TokenType.bang, TokenType.bangEqual);
        case $comma:
          _oneCharToken(TokenType.comma);
        case $dot:
          _oneCharToken(TokenType.dot);
        case $equal:
          _oneOrTwoCharToken($equal, TokenType.equal, TokenType.equalEqual);
        case $minus:
          _oneCharToken(TokenType.minus);
        case $plus:
          _oneCharToken(TokenType.plus);
        case $double_quote:
          _stringLiteral();
        case _ when _scanner.scan('}}'):
          _addToken(TokenType.closeTag);

          // Link it to its open tag.
          if (_openTagStack.isNotEmpty) {
            _openTagStack.last.closeTag = _tokens.length - 1;
            _openTagStack.removeLast();
          }

          _isInCode = false;
          return;
        case _ when _scanner.scan(_identifierPattern):
          _addToken(_keywords[_scanner.lastMatch![0]!] ?? TokenType.identifier);
        case _ when _scanner.scan(_numberPattern):
          _addToken(TokenType.number);
        default:
          // TODO: Numbers.
          var start = _scanner.state;
          _scanner.readChar();
          _reporter.report(_scanner.spanFrom(start), 'Unexpected character.');
      }
    }
  }

  void _skipWhitespace() {
    _scanner.scan(_whitespacePattern);
  }

  void _stringLiteral() {
    var start = _scanner.state;

    // Consume the first '"'.
    _scanner.readChar();

    while (!_scanner.isDone) {
      var c = _scanner.readChar();
      if (c == $double_quote) {
        // TODO: Handle escapes.
        // Trim the quotes.
        var lexeme = _scanner.spanFrom(start).text;
        var string = lexeme.substring(1, lexeme.length - 1);
        _addToken(TokenType.string, start, string);
        return;
      }
      // TODO: Escapes, newlines.
    }

    _reporter.report(_scanner.spanFrom(start), 'Unterminated string.');
    // Add it anyway so we can continue to the parser.
    _addToken(TokenType.string, start);
  }

  void _scanText() {
    // TODO: Is there a cleaner way to do this?
    var start = _scanner.state;
    while (!_scanner.isDone) {
      if (_scanner.matches('\n')) {
        _addText(start);

        start = _scanner.state;
        _scanner.readChar();
        _addToken(TokenType.newline, start);
        _indent();
        start = _scanner.state;
      } else if (_scanner.matches('{{')) {
        // Emit the text before the '{{'.
        _addText(start);

        // Emit the '{{'.
        start = _scanner.state;
        _scanner.position += 2;
        _addToken(TokenType.openTag, start);
        _openTagStack.add(_tokens.last);

        _isInCode = true;
        return;
      } else {
        _scanner.readChar();
      }
    }

    // If we get here, we reached the end. Add the trailing text.
    _addText(start);
  }

  /// Scans whitespace at the beginning of the line and emits an indent token
  /// if there is any.
  void _indent() {
    if (_scanner.scan(_spacePattern)) {
      _addToken(TokenType.indent);
    }
  }

  void _oneCharToken(TokenType type) {
    var start = _scanner.state;
    _scanner.readChar();
    _addToken(type, start);
  }

  void _oneOrTwoCharToken(int nextChar, TokenType oneType, TokenType twoType) {
    var start = _scanner.state;
    _scanner.readChar();
    _addToken(_scanner.scanChar(nextChar) ? twoType : oneType, start);
  }

  void _addText(LineScannerState start) {
    // Skip empty text.
    if (_scanner.position - start.position == 0) return;

    var text = _scanner.substring(start.position, _scanner.position);

    // If anything remains, add it.
    if (text.isNotEmpty) {
      _addToken(TokenType.text, start, text);
    }
  }

  void _addToken(TokenType type, [LineScannerState? start, String? text]) {
    FileSpan span;
    if (start != null) {
      span = _scanner.spanFrom(start);
    } else {
      span = _scanner.lastSpan!;
    }

    _tokens.add(Token(type, span, text ?? span.text));
  }
}
