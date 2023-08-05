import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeJavaLanguage() {
  var language = Language();

  // Import.
  language.capture(r'$b(import)($ss)(\w+(?:\.\w+)*)(;)',
      [Category.keyword, Category.text, Category.identifier, Category.text]);
  // Static import.
  language.capture(r'(import\s+static?)(\s+)(\w+(?:\.\w+)*(?:\.\*)?)(;)',
      [Category.keyword, Category.text, Category.identifier, Category.text]);
  // Package.
  language.capture(r'(package)(\s+)(\w+(?:\.\w+)*)(;)',
      [Category.keyword, Category.text, Category.identifier, Category.text]);

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+[Lu]?', Category.number);

  cStyleComments(language);

  // Annotation.
  language.regExp('@$identifier', Category.annotation);

  language.keywords(
      Category.keyword,
      'abstract assert break case catch class const continue default do '
      'else enum extends false final finally for goto if implements import '
      'instanceof interface native new null package private protected public '
      'return static strictfp super switch synchronized this throw throws '
      'transient true try volatile while');
  language.keywords(
      Category.typeName, 'boolean byte char double float int long short void');

  // Treat final constants as normal identifiers. Match this first so that all
  // caps names aren't treated as type names.
  language.regExp(allCaps, Category.identifier);

  // Capitalized type name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.regExp(r'[{}()[\].,;]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  // TODO: Multi-character escapes?
  language.regExp(r"'\\?.'", Category.character);

  doubleQuotedString(language);

  return language;
}
