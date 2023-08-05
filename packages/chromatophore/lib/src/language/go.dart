import '../../chromatophore.dart';
import 'shared.dart';

Language makeGoLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+', Category.number);
  language.regExp(r'[0-9]+\.[0-9]+', Category.number);

  language.regExp(r'//.*', Category.lineComment);

  language.keywords(
      Category.keyword,
      'break default func interface select case defer go map struct chan else '
      'goto package switch const fallthrough if range type continue for import '
      'return var');
  language.keywords(
      Category.typeName,
      'bool byte complex128 complex64 float32 float64 int int16 int32 int64 '
      'int8 rune string uint uint16 uint32 uint64 uint8 uintptr');

  // TODO: Recognize user-defined type names in declarations.

  // Heuristic: Assume a `*` followed by an identifier is a pointer type.
  language
      .capture('(\\*)($identifier)', [Category.operator, Category.typeName]);

  // Heuristic: Assume a `*` followed by a dotted identifier is a pointer type.
  language.capture('(\\*)($identifier)(\\.)($identifier)', [
    Category.operator,
    Category.identifier,
    Category.punctuation,
    Category.typeName
  ]);

  // This isn't real Go syntax, but it is in my proposed syntax for Go post:
  language.keywords(Category.keyword, 'as do new');

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  doubleQuotedString(language);

  return language;
}
