import 'category.dart';
import 'language/c.dart';
import 'language/c_plus_plus.dart';
import 'language/c_sharp.dart';
import 'language/dart.dart';
import 'language/f_sharp.dart';
import 'language/fortran.dart';
import 'language/go.dart';
import 'language/java.dart';
import 'language/javascript.dart';
import 'language/lisp.dart';
import 'language/ocaml.dart';
import 'language/python.dart';
import 'language/ruby.dart';
import 'language/smalltalk.dart';
import 'language/xml.dart';
import 'rule.dart';

/// Defines the syntactic grammar for a language.
class Language {
  static final c = makeCLanguage();
  static final cPlusPlus = makeCPlusPlusLanguage();
  static final cSharp = makeCSharpLanguage();
  static final dart = makeDartLanguage();
  static final fortran = makeFortranLanguage();
  static final fSharp = makeFSharpLanguage();
  static final go = makeGoLanguage();
  static final java = makeJavaLanguage();
  static final javaScript = makeJavaScriptLanguage();
  static final lisp = makeLispLanguage();
  static final ocaml = makeOCamlLanguage();
  static final python = makePythonLanguage();
  static final ruby = makeRubyLanguage();
  static final smalltalk = makeSmalltalkLanguage();
  static final xml = makeXmlLanguage();

  static final _all = {
    'c': c,
    'cpp': cPlusPlus,
    'csharp': cSharp,
    'dart': dart,
    'fortran': fortran,
    'fsharp': fSharp,
    'go': go,
    'java': java,
    'javascript': javaScript,
    'lisp': lisp,
    'ocaml': ocaml,
    'python': python,
    'ruby': ruby,
    'smalltalk': smalltalk,
    'xml': xml,
  };

  static Language? find(String name) => _all[name.toLowerCase()];

  final Map<String, RuleSet> _ruleSets = {};

  /// The current rule set.
  RuleSet _ruleSet = RuleSet();

  Language() {
    _ruleSets['start'] = _ruleSet;
  }

  /// Get the rules for [ruleSet].
  ///
  /// The starting rule set is named 'start'.
  RuleSet rules(String ruleSet) {
    // TODO: Handle unknown name.
    var rules = _ruleSets[ruleSet]!;

    // TODO: Hackish. Flatten out any includes on first use.
    rules.flatten(this);

    return rules;
  }

  /// Creates a ruleset with [name] then calls [body]. All rules added to the
  /// language inside the callback are added to the ruleset.
  void ruleSet(String name, void Function() body) {
    var oldRules = _ruleSet;
    _ruleSet = RuleSet();

    try {
      body();
    } finally {
      _ruleSets[name] = _ruleSet;
      _ruleSet = oldRules;
    }
  }

  void include(String name) {
    _ruleSet.rules.add(IncludeRule(name));
  }

  RuleBuilder regExp(String regExp, Category category) {
    return _addRule(PatternRule(RegExp(regExp, multiLine: true), category));
  }

  RuleBuilder verbatim(String pattern, Category category) {
    return _addRule(PatternRule(pattern, category));
  }

  RuleBuilder capture(String regExp, List<Category> categories) {
    return _addRule(CaptureRule(RegExp(regExp, multiLine: true), categories));
  }

  RuleBuilder keywords(Category category, String keywords) {
    // TODO: Better way to escape regex characters.
    var words = keywords.split(' ').map((word) => word
        .replaceAll('?', r'\?')
        .replaceAll('+', r'\+')
        .replaceAll('*', r'\*')
        .replaceAll('.', r'\.'));
    return regExp('\\b(${words.join('|')})\\b', category);
  }

  RuleBuilder _addRule(Rule rule) {
    _ruleSet.rules.add(rule);
    return RuleBuilder._(this);
  }
}

class RuleSet {
  bool _isFlattened = false;

  final List<Rule> rules = [];

  /// Take any included rulesets and insert them in the rule list.
  void flatten(Language language) {
    if (_isFlattened) return;

    var seen = <String>{};
    var result = <Rule>[];

    void traverse(List<Rule> rules) {
      for (var rule in rules) {
        if (rule is IncludeRule) {
          if (!seen.contains(rule.name)) {
            var include = language._ruleSets[rule.name];
            if (include == null) {
              throw FormatException('Unknown ruleset "${rule.name}".');
            }

            traverse(include.rules);
            seen.add(rule.name);
          }
        } else {
          result.add(rule);
        }
      }
    }

    traverse(rules);
    rules.clear();
    rules.addAll(result);

    _isFlattened = true;
  }
}

class RuleBuilder {
  final Language _language;

  RuleBuilder._(this._language);

  RuleBuilder push(String ruleSet) {
    var rule = _language._ruleSet.rules.removeLast();
    _language._ruleSet.rules.add(PushRule(rule, ruleSet));
    return this;
  }

  RuleBuilder pop() {
    var rule = _language._ruleSet.rules.removeLast();
    _language._ruleSet.rules.add(PopRule(rule));
    return this;
  }
}
