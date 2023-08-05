import '../../chromatophore.dart';
import 'shared.dart';

Language makeLispLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+', Category.number);
  language.regExp(r'[0-9]+\.[0-9]+', Category.number);

  language.regExp(r';.*', Category.lineComment);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.regExp(r'[{}()[\]]', Category.punctuation);
  language.regExp(r'[a-zA-Z0-9_!*/&%~+=<>|-]', Category.identifier);

  doubleQuotedString(language);

  return language;
}
