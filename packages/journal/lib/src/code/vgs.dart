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

  // TODO: Hack. The `?` is an allowed identifier character, but we will end up
  // recognizing a keyword followed by `?` as a keyword and not a single
  // identifier.
  language.regExp(r'\btrue\?', Category.identifier);

  language.keywords(
      Category.keyword,
      'and break case continue def do each else end for if in is match or rec '
      'return then var while');

  // Hack: These are not real keywords in Magpie, but a couple of posts use
  // Magpie as pseudo-code.
  language.keywords(Category.keyword, 'loop null');

  // Unquote.
  language.regExp(r'`[a-z_][a-zA-Z0-9_]*\b\??', Category.preprocessor);

  language.regExp(r'[A-Z][a-zA-Z0-9_\$]*\??', Category.typeName);
  language.regExp(r'[a-z_\$][a-zA-Z0-9_\$]*\??', Category.identifier);

  language.regExp(r'[{}()[\],:.]', Category.punctuation);
  language.regExp(r'(!|!=|=|==|>|>=|<|<=|-|\+|/|\*)', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  return language;
}
