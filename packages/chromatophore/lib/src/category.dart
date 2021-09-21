// TODO: Docs.
class Category {
  static const Category comment = Category('comment');
  static const Category lineComment = Category('lineComment', comment);
  static const Category blockComment = Category('blockComment', comment);

  /// An expression that creates a literal value of some type.
  static const Category literal = Category('literal');

  /// A number literal, including integer, floating-point, scientific, hex, etc.
  static const Category number = Category('number', literal);

  /// A string literal.
  static const Category string = Category('string', literal);

  /// A character literal.
  static const Category character = Category('character', string);

  /// An escape sequence inside a string or character literal.
  static const Category stringEscape = Category('stringEscape', string);

  static const Category identifier = Category('identifier');
  static const Category keyword = Category('keyword', identifier);
  static const Category typeName = Category('typeName', identifier);
  static const Category field = Category('field', identifier);

  static const Category preprocessor = Category('preprocessor');
  // Metadata annotations and attributes.
  static const Category annotation = Category('annotation');

  static const Category punctuation = Category('punctuation');
  static const Category operator = Category('operator', punctuation);

  // TODO: Should this be in core chromatophore?
  static const Category metasyntax = Category('metasyntax');

  /// Tag in a markup language like XML.
  static const Category tag = Category('tag', text);

  static const Category text = Category('text');
  static const Category whitespace = Category('whitespace');
  static const Category unrecognized = Category('unrecognized', text);

  // TODO: Hack. For "What Color is Your Function?" post.
  static const Category blue = Category('blue');
  static const Category red = Category('red');

  final String name;
  final Category? parent;

  const Category(this.name, [this.parent]);

  @override
  String toString() {
    if (parent == null) return name;
    return '$parent.$name';
  }
}
