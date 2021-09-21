import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeOCamlLanguage() {
  var language = Language();

  language.regExp(r'\(\*.*?\*\)', Category.blockComment);

  // TODO: Other number formats.
  language.regExp(r'[0-9]+(u?y|u?s|u?l|u?n|U?L|uL|u)?', Category.number);

  language.regExp(r'[{}()[\].,;]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  // A bare "_" is a pattern.
  language.regExp(r'\b_\b', Category.operator);

  language.keywords(
      Category.keyword,
      'and as assert asr begin class constraint do done downto else end '
      'exception external false for fun function functor if in include inherit '
      'initializer land lazy let lor lsl lsr lxor match method mod module '
      'mutable new nonrec object of open or private rec sig struct then to '
      'true try type val virtual when while with');

  // Capitalized names are type constructors, not types, but highlight them
  // differently from identifiers.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  doubleQuotedString(language);

  return language;
}
