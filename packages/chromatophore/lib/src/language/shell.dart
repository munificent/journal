import '../../chromatophore.dart';

Language makeShellLanguage() {
  var language = Language();
  // TODO: Do some actual syntax highlighting.
  language.regExp('.', Category.text);
  language.regExp(r'#.*', Category.lineComment);
  language.regExp(r'[\s\n\t]', Category.whitespace);
  return language;
}
