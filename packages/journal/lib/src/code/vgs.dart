import 'package:chromatophore/chromatophore.dart';

Language makeVgsLanguage() {
  var language = Language();

  language.regExp(r'#.*', Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.number);
  language.regExp(r'[0-9]+?', Category.number);

  // Strings.
  language.regExp(r'"', Category.string).push('string');
  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    // TODO: Multi-character escapes?
    language.regExp('.', Category.string);
  });

  language.keywords(
      Category.keyword,
      'and break case continue def do each else end for if in is match or rec '
      'return then val var while');

  // For the post talking about access modifiers.
  language.keywords(Category.keyword, 'def_ rec_ val_ var_');

  language.regExp(r'[A-Z][a-zA-Z0-9_\$]*\??', Category.typeName);
  language.regExp(r'[a-z_\$][a-zA-Z0-9_\$]*\??', Category.identifier);

  language.regExp(r'[{}()[\],:.]', Category.punctuation);
  language.regExp(r'(!|!=|=|==|>|>=|<|<=|-|\+|/|\*)', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  return language;
}
