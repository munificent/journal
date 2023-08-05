import 'package:string_scanner/string_scanner.dart';

import 'category.dart';
import 'language.dart';
import 'token.dart';

class Lexer {
  final Language _language;
  final StringScanner _scanner;
  final List<Token> _tokens = [];

  /// The pushdown automata stack of rules being lexed.
  ///
  /// The topmost (last) element is the current set of rules.
  final List<RuleSet> _ruleStack = [];

  Category _currentCategory = Category.unrecognized;
  final StringBuffer _currentToken = StringBuffer();

  // TODO: Allow passing in some kind of URL identifier for scanner errors?
  Lexer(this._language, String source) : _scanner = StringScanner(source);

  List<Token> tokenize() {
    // Start in the starting ruleset.
    _ruleStack.add(_language.rules('start'));

    while (!_scanner.isDone) {
      var matchedRule = false;
      for (var rule in _ruleStack.last.rules) {
        if (_scanner.scan(rule.pattern)) {
          matchedRule = true;
          rule.apply(this, _scanner.lastMatch!);
          // TODO: Make sure that the rule actually advanced the scanner.
          break;
        }
      }

      if (!matchedRule) {
        // Don't get stuck if nothing matches.
        _startToken(Category.unrecognized);
        _currentToken.writeCharCode(_scanner.readChar());
      }
    }

    _endToken();
    return _tokens;
  }

  void addToken(String text, Category category) {
    if (text.isEmpty) return;

    _startToken(category);
    // TODO: Might not want to implicitly collapse all tokens.
    _currentToken.write(text);
  }

  void push(String ruleSet) {
    _ruleStack.add(_language.rules(ruleSet));
  }

  void pop() {
    _ruleStack.removeLast();
  }

  /// Begin a token with [category], ending the previous token if needed.
  void _startToken(Category category) {
    if (_currentCategory != category) {
      _endToken();
      _currentCategory = category;
    }
  }

  /// End the current token if there is one.
  void _endToken() {
    if (_currentToken.isEmpty) return;
    _tokens.add(Token(_currentToken.toString(), _currentCategory));
    _currentToken.clear();
  }
}
