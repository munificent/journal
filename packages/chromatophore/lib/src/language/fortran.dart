import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeFortranLanguage() {
  // TODO: This is just a bare-bones sketch.
  var language = Language();

  language.regExp(r'[0-9]+', Category.number);

  language.regExp(r'[{}()[\].,;]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.keywords(Category.keyword, 'do end for print');

  language.regExp(identifier, Category.identifier);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  return language;
}
