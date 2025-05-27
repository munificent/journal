import '../../chromatophore.dart';
import 'shared.dart';

Language makeOberonLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+', Category.number);
  language.regExp(r'[0-9]+\.[0-9]+', Category.number);

  language.keywords(
      Category.keyword,
      'ARRAY BEGIN BY CASE CONST DIV DO ELSE ELSIF END EXIT FOR IF IMPORT IN '
      'IS LOOP MOD MODULE NIL OF OR POINTER PROCEDURE RECORD REPEAT RETURN '
      'THEN TO TYPE UNTIL VAR WHILE WITH');

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.regExp(identifier, Category.identifier);

  doubleQuotedString(language);

  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  return language;
}
