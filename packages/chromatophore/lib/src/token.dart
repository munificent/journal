import 'category.dart';

/// A contigious piece of source code of the same grammatical category.
class Token {
  final String text;
  final Category category;

  Token(this.text, this.category);
}
