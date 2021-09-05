import '../category.dart';
import '../language.dart';
import 'patterns.dart';

Language makeJavaLanguage() {
  var language = Language();

  language.regExp(r'[{}()[\].,;!*/&%~+=<>|-]', Category.punctuation);

  // Import.
  language.capture('$b(import)($ss)(\w+(?:\.\w+)*)(;)',
      [Category.keyword, Category.text, Category.identifier, Category.text]);
  // Static import.
  language.capture(r'(import\s+static?)(\s+)(\w+(?:\.\w+)*(?:\.\*)?)(;)',
      [Category.keyword, Category.text, Category.identifier, Category.text]);
  // Package.
  language.capture(r'(package)(\s+)(\w+(?:\.\w+)*)(;)',
      [Category.keyword, Category.text, Category.identifier, Category.text]);

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.decimalNumber);
  language.regExp(r'0x[0-9a-fA-F]+', Category.hexInteger);
  language.regExp(r'[0-9]+[Lu]?', Category.integer);

  language.regExp(r'//.*', Category.lineComment);

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

  language.regExp(allCaps, Category.constant);

  // Capitalized type name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // TODO: Multi-character escapes?
  language.regExp(r"'\\?.'", Category.character);

  language.regExp(r'"', Category.string).push('string');

  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  return language;
}
