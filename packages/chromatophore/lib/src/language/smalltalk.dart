import '../category.dart';
import '../language.dart';

Language makeSmalltalkLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+(\.[0-9]+)?', Category.number);

  language.regExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*:', Category.keyword);

  language.regExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b', Category.identifier);

  language.regExp(r'[{}()[\].,;]', Category.punctuation);
  language.regExp(r'[:!*/&%~+=<>|-]', Category.operator);

  language.keywords(Category.keyword, 'self');

  language.regExp('"[^"]+?"', Category.blockComment);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.regExp("'", Category.string).push('string');

  language.ruleSet('string', () {
    language.regExp("'", Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  return language;
}
