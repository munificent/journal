import 'package:chromatophore/chromatophore.dart';

Language makeMagpieLanguage() {
  var language = Language();

  language.regExp(r'//.*', Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.decimalNumber);
  language.regExp(r'[0-9]+?', Category.integer);

  language.regExp(r'->', Category.keyword);
  language.regExp(r'<-', Category.keyword);
  language.verbatim('.', Category.keyword);

  // TODO: Only to match old site.
  language.regExp(r"[+*<>=']", Category.error);

  language.regExp(r'[{}()[\],:;!*/&%~+=<>|]', Category.punctuation);

  language.identifier();
  // TODO: 'struct' should be a keyword in old Magpie.
  language.keywords(
      Category.keyword, 'def do else end fn for if then var while');
  language.keywords(Category.boolean, 'false true');

  // Strings.
  language.push(r'"', Category.string, 'string');
  language.ruleSet('string');
  language.pop('"', Category.string);
  language.regExp(r'\\.', Category.stringEscape);
  // TODO: Multi-character escapes?
  language.regExp('.', Category.string);

  return language;
}
