import '../category.dart';
import '../language.dart';
import 'patterns.dart';

Language makePythonLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+\.[0-9]+', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+[Lu]?', Category.number);

  language.keywords(
      Category.keyword,
      'and as assert break class continue def del elif else except finally '
      'for from global if import in is lambda nonlocal not or pass raise '
      'return try while with yield');
  // TODO: Better category for this.
  language.keywords(Category.typeName, 'False None True');

  // Capitalized type or constant name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[{}()[\].,;:!*/&%~+=<>|-]', Category.punctuation);

  language.regExp(r'#.*', Category.lineComment);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // TODO: Multi-line strings.
  language.regExp('"', Category.string).push('double string');
  language.regExp("'", Category.string).push('single string');

  language.ruleSet('double string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  language.ruleSet('single string', () {
    language.regExp("'", Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  return language;
}
