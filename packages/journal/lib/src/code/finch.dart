import 'package:chromatophore/chromatophore.dart';

Language makeFinchLanguage() {
  var language = Language();

  language.regExp("'.*", Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.number);
  language.regExp(r'[0-9]+', Category.number);

  language.keywords(Category.keyword, 'return self undefined');

  language.regExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*:', Category.keyword);

  // Not really a "type" name, but use that category for prototypes and
  // singletons.
  language.regExp(r'\b[A-Z][a-zA-Z0-9_]*\b', Category.typeName);

  language.regExp(r'\b[a-z_][a-zA-Z0-9_]*\b', Category.identifier);

  language.regExp(r'"', Category.string).push('string');

  language.regExp(r'[{}():|]', Category.punctuation);
  language.regExp(r'[+!$%^&*=<>/?~-]', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  return language;
}
