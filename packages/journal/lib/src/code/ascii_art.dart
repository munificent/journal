import 'package:chromatophore/chromatophore.dart';

Language makeAsciiArtLanguage() {
  var language = Language();
  language.regExp('.', Category.text);
  language.regExp(r'[\s\n\t]', Category.whitespace);
  return language;
}
