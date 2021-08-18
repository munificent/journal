import 'package:chromatophore/chromatophore.dart';

Language makeMagpieLanguage() {
  var language = Language();

  language.regExp(r'//.*', Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.decimalNumber);
  language.regExp(r'[0-9]+?', Category.integer);

  // TODO: 'struct' should be a keyword in old Magpie.
  language.keywords(
      Category.keyword,
      'and as def do else end extend false fn for if import interface is or '
      'return then this true var while with');

  language.regExp(r'\b[A-Z][a-zA-Z0-9_]*\b\??', Category.typeName);
  language.regExp(r'\b[a-z_][a-zA-Z0-9_]*\b\??', Category.identifier);

  language.regExp(r'[{}()[\],:;.]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // Strings.
  language.regExp(r'"', Category.string).push('string');
  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    // TODO: Multi-character escapes?
    language.regExp('.', Category.string);
  });

  return language;
}
