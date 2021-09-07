import '../category.dart';
import '../language.dart';
import 'patterns.dart';

Language makeCLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+[Lu]?', Category.number);

  language.include('whitespace');

  // ALL_CAPS preprocessor macro use.
  language.regExp(allCaps, Category.preprocessor);

  // Capitalized type name.
  language.regExp(capsIdentifier, Category.typeName);

  // TODO: Make false and true a different category?
  language.keywords(
      Category.keyword,
      'break case const continue default do else enum extern false for '
      'goto if inline return sizeof static struct switch true typedef union '
      'while');
  language.keywords(
      Category.typeName,
      'bool char double FILE int size_t uint16_t uint32_t uint64_t uint8_t '
      'uintptr_t va_list void');

  language.regExp(identifier, Category.identifier);

  // TODO: Multi-character escapes?
  language.regExp(r"'\\?.'", Category.character);

  language.regExp(r'"', Category.string).push('string');

  language.regExp('#', Category.preprocessor).push('preprocessor');

  language.regExp(r'[{}()[\].,;!*/&%~+=<>|-]', Category.punctuation);

  language.ruleSet('block comment', () {
    language.regExp(r'/\*.*?\*/', Category.blockComment);
  });

  language.ruleSet('comment', () {
    language.regExp(r'//.*', Category.lineComment);
    language.include('block comment');
  });

  language.ruleSet('preprocessor', () {
    language.regExp(r'//.*', Category.lineComment).pop();
    language.include('block comment');
    language.regExp('.', Category.preprocessor);
    language.verbatim('\n', Category.text).pop();
  });

  language.ruleSet('space', () {
    language.regExp(r'[\s\n\t]', Category.whitespace);
  });

  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  language.ruleSet('whitespace', () {
    language.include('comment');
    language.include('space');
  });

  return language;
}
