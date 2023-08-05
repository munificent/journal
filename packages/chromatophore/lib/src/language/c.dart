import '../../chromatophore.dart';
import 'shared.dart';

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
      'bool char double FILE float int size_t uint16_t uint32_t uint64_t '
      'uint8_t uintptr_t va_list void');

  language.regExp(identifier, Category.identifier);

  // TODO: Multi-character escapes?
  language.regExp(r"'\\?.'", Category.character);

  doubleQuotedString(language);

  cPreprocessor(language);
  cStyleComments(language);

  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.ruleSet('space', () {
    language.regExp(r'[\s\n\t]', Category.whitespace);
  });

  language.ruleSet('whitespace', () {
    language.include('comment');
    language.include('space');
  });

  return language;
}
