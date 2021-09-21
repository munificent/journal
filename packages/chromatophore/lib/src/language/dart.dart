import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeDartLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+', Category.number);

  cStyleComments(language);

  // Annotation.
  language.regExp('@$identifier', Category.annotation);

  // TODO: Handle contextual keywords better.
  language.keywords(
      Category.keyword,
      'abstract as assert async await break case catch class const continue '
      'covariant default deferred do dynamic else enum export extends '
      'extension external factory false final finally for Function get hide '
      'if implements import in interface is late library mixin new null on '
      'operator part required rethrow return set show static super switch sync '
      'this throw true try typedef var void while with yield');

  language.keywords(Category.typeName, 'bool double int num string void');

  // Capitalized type name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[?!*/&%~+=<>|-]', Category.operator);

  singleQuotedString(language);
  doubleQuotedString(language);

  return language;
}
