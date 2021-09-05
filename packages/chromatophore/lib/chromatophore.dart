import 'src/formatter.dart';
import 'src/language.dart';
import 'src/lexer.dart';

export 'src/category.dart';
export 'src/formatter.dart';
export 'src/language.dart';

/// Takes a string of [source], parses it according to [language], and formats
/// the result using [formatter].
String highlight(Language language, String source, Formatter formatter) {
  return formatter.format(Lexer(language, source).tokenize());
}
