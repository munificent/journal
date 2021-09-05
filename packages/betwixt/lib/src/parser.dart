import 'ast.dart';
import 'error_reporter.dart';
import 'scanner.dart';
import 'token.dart';
import 'whitespace_simplifier.dart';

class Parser {
  static Stmt parseSource(ErrorReporter reporter, String source, String url) {
    var scanner = Scanner(source, url, reporter);
    var tokens = scanner.scan();
    tokens = WhitespaceSimplifier(tokens).simplify();
    var parser = Parser(tokens, reporter);
    return parser.parse();
  }

  final List<Token> _tokens;
  final ErrorReporter _reporter;
  int _currentIndex = 0;

  /// If this is true, we have already reported one error and are waiting to
  /// synchronize before reporting more.
  bool _panicMode = false;

  Parser(this._tokens, this._reporter);

  bool get _isDone => _currentIndex >= _tokens.length;

  Token get _current => _tokens[_currentIndex];
  Token get _previous => _tokens[_currentIndex - 1];

  Stmt parse() => _sequence();

  /// Parses a sequence of code and text until it hits the end of the file.
  ///
  /// If [endKeywords] is given, stops if it encounters `{{` followed by any of
  /// those keywords. This is used for parsing the contents of control flow tags.
  Stmt _sequence([List<TokenType>? endKeywords]) {
    var statements = <Stmt>[];

    while (!_isDone) {
      if (endKeywords?.any((keyword) => _peek(TokenType.openTag, keyword)) ??
          false) {
        break;
      }

      if (_match(TokenType.openTag)) {
        statements.add(_statement());
      } else if (_match(TokenType.text) ||
          _match(TokenType.newline) ||
          _match(TokenType.indent)) {
        // Concatenate adjacent text and whitespace tokens.
        if (statements.isNotEmpty && statements.last is TextStmt) {
          var last = statements.removeLast() as TextStmt;
          statements.add(TextStmt(last.text + _previous.text));
        } else {
          statements.add(TextStmt(_previous.text));
        }
      } else {
        // TODO: Better error message.
        _error('Unexpected token.');
        _advance();
      }
    }

    if (statements.length == 1) return statements.first;

    return SequenceStmt(statements);
  }

  Stmt _statement() {
    if (_match(TokenType.forKeyword)) {
      return _forStatement();
    } else if (_match(TokenType.ifKeyword)) {
      return _ifStatement();
    } else if (_match(TokenType.includeKeyword)) {
      return _includeStatement();
    } else if (_match(TokenType.letKeyword)) {
      return _letStatement();
    } else if (_match(TokenType.setKeyword)) {
      return _setStatement();
    } else {
      var expression = _expression();
      _expectCloseTag();
      return RenderStmt(expression);
    }
  }

  Stmt _forStatement() {
    var variable = _expect(TokenType.identifier, 'Expect variable name.');
    _expect(TokenType.inKeyword, 'Expect "in" after variable.');
    var expression = _expression();
    _expectCloseTag();

    var body = _sequence(const [
      TokenType.betweenKeyword,
      TokenType.elseKeyword,
      TokenType.endKeyword
    ]);

    Stmt? between;
    Token? betweenBefore;
    Token? betweenAfter;
    if (_match(TokenType.openTag, TokenType.betweenKeyword)) {
      if (_match(TokenType.identifier)) {
        betweenBefore = _previous;
        _expect(
            TokenType.andKeyword, 'Expect "and" between between variables.');
        betweenAfter =
            _expect(TokenType.identifier, 'Expect variable name after "and".');
        // TODO: Error if same name.
      }

      _expectCloseTag();
      between = _sequence(const [TokenType.elseKeyword, TokenType.endKeyword]);
    }

    Stmt? elseClause;
    if (_match(TokenType.openTag, TokenType.elseKeyword)) {
      _expectCloseTag();
      elseClause =
          _sequence(const [TokenType.endKeyword, TokenType.betweenKeyword]);

      // Cover grammar to handle out of order clauses.
      if (_match(TokenType.openTag, TokenType.betweenKeyword)) {
        _errorPrevious('Between clause must come before else clause.');

        if (_match(TokenType.identifier)) {
          _match(TokenType.andKeyword);
          _match(TokenType.identifier);
        }

        _expectCloseTag();
        between = _sequence(const [TokenType.endKeyword]);
      }
    }

    _expectEndTag('for');

    // TODO: Handle nulls better.
    return ForStmt(variable!, expression, body, between, betweenBefore,
        betweenAfter, elseClause);
  }

  Stmt _ifStatement() {
    var condition = _expression();
    _expectCloseTag();

    // TODO: This all feels really hacky.
    var thenStatement =
        _sequence(const [TokenType.elseKeyword, TokenType.endKeyword]);

    Stmt? elseStatement;
    if (_match(TokenType.openTag, TokenType.elseKeyword)) {
      _expectCloseTag();
      elseStatement = _sequence(const [TokenType.endKeyword]);
    }

    _expectEndTag('if');
    return IfStmt(condition, thenStatement, elseStatement);
  }

  Stmt _includeStatement() {
    var name = _expect(TokenType.string, 'Expect template name string.');
    if (name == null) return ErrorStmt();

    var variables = <String, Expr>{};
    if (_match(TokenType.withKeyword)) {
      do {
        var variable = _expect(TokenType.identifier, 'Expect variable name.');
        Expr value;
        if (_match(TokenType.equal)) {
          value = _expression();
        } else if (variable != null) {
          // If there is no value, look up the variable with the same name.
          value = VariableExpr(variable);
        } else {
          value = ErrorExpr();
        }

        if (variable != null) {
          variables[variable.text] = value;
        }
      } while (_match(TokenType.comma));
    }

    _expectCloseTag();

    return IncludeStmt(name, variables);
  }

  Stmt _letStatement() {
    var name = _expect(TokenType.identifier, 'Expect variable name.');
    // TODO: Make value optional?
    _expect(TokenType.equal, 'Expect "=" after variable name.');
    var value = _expression();
    _expectCloseTag();

    return LetStmt(name!, value);
  }

  Stmt _setStatement() {
    var name = _expect(TokenType.identifier, 'Expect variable name.');
    _expect(TokenType.equal, 'Expect "=" after variable name.');
    var value = _expression();
    _expectCloseTag();

    return SetStmt(name!, value);
  }

  Expr _expression() {
    // TODO: Operators, etc.
    return _equality();
  }

  Expr _equality() {
    var expr = _term();

    while (_match(TokenType.bangEqual) || _match(TokenType.equalEqual)) {
      var op = _previous;
      var right = _term();
      expr = BinaryExpr(expr, op, right);
    }

    return expr;
  }

  Expr _term() {
    var expr = _unary();

    while (_match(TokenType.plus) || _match(TokenType.minus)) {
      var op = _previous;
      var right = _unary();
      expr = BinaryExpr(expr, op, right);
    }

    return expr;
  }

  Expr _unary() {
    if (_match(TokenType.minus)) {
      var op = _previous;
      return UnaryExpr(op, _unary());
    }

    return _property();
  }

  Expr _property() {
    var expr = _primary();

    while (_match(TokenType.dot)) {
      var property =
          _expect(TokenType.identifier, 'Expect property name after ".".');
      if (property == null) break;

      expr = PropertyExpr(expr, property);
    }

    return expr;
  }

  Expr _primary() {
    if (_match(TokenType.identifier)) {
      var name = _previous;
      if (_match(TokenType.leftParen)) {
        return _call(name);
      } else {
        return VariableExpr(name);
      }
    } else if (_match(TokenType.falseKeyword)) {
      return LiteralExpr(_previous, false);
    } else if (_match(TokenType.nullKeyword)) {
      return LiteralExpr(_previous, null);
    } else if (_match(TokenType.trueKeyword)) {
      return LiteralExpr(_previous, true);
    } else if (_match(TokenType.number)) {
      var value = num.parse(_previous.text);
      return LiteralExpr(_previous, value);
    } else if (_match(TokenType.string)) {
      return LiteralExpr(_previous, _previous.text);
    } else {
      _error('Unexpected token.');
      _advance();
      return ErrorExpr();
    }
  }

  Expr _call(Token name) {
    var arguments = <Expr>[];
    if (!_match(TokenType.rightParen)) {
      do {
        arguments.add(_expression());
      } while (_match(TokenType.comma));
      _expect(TokenType.rightParen, 'Expect ")" after arguments.');
    }

    return CallExpr(name, arguments, _previous);
  }

  bool _match(TokenType type1, [TokenType? type2]) {
    if (!_peek(type1, type2)) return false;

    _advance();
    if (type2 != null) _advance();
    return true;
  }

  bool _peek(TokenType type1, [TokenType? type2]) {
    if (_isDone) return false;
    if (_current.type != type1) return false;
    if (type2 != null) {
      if (_currentIndex >= _tokens.length - 1) return false;
      if (_tokens[_currentIndex + 1].type != type2) return false;
    }
    return true;
  }

  Token _advance() {
    if (!_isDone) _currentIndex++;
    return _previous;
  }

  void _expectEndTag(String statement) {
    _expect(TokenType.openTag, '');
    _expect(TokenType.endKeyword, 'Expect "end" after $statement.');
    _expectCloseTag();
  }

  /// Consumes the next '}}' token. Also synchronizes to exit panic mode.
  void _expectCloseTag() {
    if (_match(TokenType.closeTag)) {
      _panicMode = false;
      return;
    }

    _error('Expect "}}".');

    // Synchronize. Discard tokens up through the next '}}' or up to the next
    // text.
    while (!_isDone) {
      _advance();

      if (_current.type == TokenType.closeTag) {
        _advance();
        return;
      }

      if (_current.type == TokenType.text) return;
    }
  }

  Token? _expect(TokenType type, String message) {
    assert(type != TokenType.closeTag, 'Use _expectCloseTag().');

    if (_isDone || !_match(type)) {
      _error(message);
      return null;
    }

    return _previous;
  }

  void _error(String message) {
    if (!_panicMode) {
      var token = _isDone ? _previous : _current;
      _reporter.report(token.span, message);
    }

    _panicMode = true;
  }

  void _errorPrevious(String message) {
    if (!_panicMode) {
      _reporter.report(_previous.span, message);
    }

    _panicMode = true;
  }
}
