import 'category.dart';
import 'lexer.dart';

abstract class Rule {
  Pattern get pattern;

  void apply(Lexer lexer, Match match);
}

/// Parses a single regex where each capture group has a corresponding category.
class CaptureRule extends Rule {
  @override
  final Pattern pattern;
  final List<Category> categories;

  CaptureRule(this.pattern, this.categories);

  @override
  void apply(Lexer lexer, Match match) {
    for (var i = 0; i < categories.length; i++) {
      var category = categories[i];
      // TODO: Report better error if group not present.
      lexer.addToken(match[i + 1]!, category);
    }
  }
}

// TODO: This is a rule so that includes can be interleaved with other rules
// applied at the right time. But it's kind of weird because includes aren't
// actual functional rules.
//
// Probably want to split out Language and a separate builder API and have the
// latter flatten out includes as a post-processing step.
class IncludeRule extends Rule {
  final String name;

  @override
  Pattern get pattern => throw UnsupportedError('Cannot apply IncludeRule.');

  IncludeRule(this.name);

  @override
  void apply(Lexer lexer, Match match) =>
      throw UnsupportedError('Cannot apply IncludeRule.');
}

/// Parses a single regex and outputs the entire matched text as a single token
/// with the given [_category].
class PatternRule extends Rule {
  @override
  final Pattern pattern;
  final Category _category;

  /// Matches the given [pattern].
  PatternRule(this.pattern, this._category);

  @override
  void apply(Lexer lexer, Match match) {
    lexer.addToken(match[0]!, _category);
  }
}

/// Matches a single regex and pops the current rule set.
class PopRule extends Rule {
  final Rule _inner;

  PopRule(this._inner);

  @override
  Pattern get pattern => _inner.pattern;

  @override
  void apply(Lexer lexer, Match match) {
    _inner.apply(lexer, match);
    lexer.pop();
  }
}

/// Matches an inner rule and pushes a new rule set.
class PushRule extends Rule {
  final Rule _inner;
  final String _ruleSet;

  PushRule(this._inner, this._ruleSet);

  @override
  Pattern get pattern => _inner.pattern;

  @override
  void apply(Lexer lexer, Match match) {
    _inner.apply(lexer, match);
    lexer.push(_ruleSet);
  }
}
