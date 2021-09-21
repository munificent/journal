import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makePythonLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+\.[0-9]+', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+[Lu]?', Category.number);

  language.keywords(
      Category.keyword,
      'and as assert break class continue def del elif else except finally '
      'for from global if import in is lambda nonlocal not or pass print '
      'raise return try while with yield');
  // TODO: Better category for this.
  language.keywords(Category.typeName, 'False None True');

  doubleQuotedString(language);
  singleQuotedString(language);
  doubleQuotedRawString(language);
  singleQuotedRawString(language);
  // TODO: Multi-line strings.

  // Capitalized type or constant name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.regExp(r'#.*', Category.lineComment);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  return language;
}
