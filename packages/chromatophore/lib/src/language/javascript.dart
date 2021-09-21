import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeJavaScriptLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+', Category.number);

  cStyleComments(language);

  // TODO: Hack. For "What Color is Your Function?" post.
  language.verbatim('()red', Category.red);
  language.verbatim('red_function', Category.red);
  language.verbatim('()blue', Category.blue);
  language.verbatim('blue_function', Category.blue);

  language.keywords(
      Category.keyword,
      'abstract arguments await boolean break byte case catch char class const '
      'continue debugger default delete do double else enum eval export '
      'extends false final finally float for function goto if implements '
      'import in instanceof int interface let long native new null package '
      'private protected public return short static super switch synchronized '
      'this throw throws transient true try typeof var void volatile while '
      'with yield');

  // Capitalized type name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // TODO: Should ":" be an operator or punctuation? Used as punctuation in
  // object literals, but an operator in "?:".
  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[?!*/&%~+=<>|-]', Category.operator);

  singleQuotedString(language);
  doubleQuotedString(language);

  return language;
}
