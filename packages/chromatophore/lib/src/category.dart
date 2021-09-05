// TODO: Docs.
class Category {
  static const Category comment = Category('comment');
  static const Category lineComment = Category('lineComment', comment);
  static const Category blockComment = Category('blockComment', comment);

  static const Category literal = Category('literal');
  static const Category number = Category('number', literal);
  static const Category decimalNumber = Category('decimalNumber', number);
  static const Category hexInteger = Category('hexInteger', number);
  static const Category integer = Category('integer', number);

  static const Category identifier = Category('identifier');
  static const Category keyword = Category('keyword', identifier);
  static const Category typeName = Category('typeName', identifier);
  static const Category field = Category('field', identifier);
  static const Category constant = Category('constant', identifier);
  static const Category boolean = Category('boolean', Category.identifier);

  static const Category string = Category('string');
  static const Category character = Category('character', string);
  static const Category stringEscape = Category('stringEscape', string);

  static const Category preprocessor = Category('preprocessor');
  // Metadata annotations and attributes.
  static const Category annotation = Category('annotation');

  static const Category punctuation = Category('punctuation');
  static const Category operator = Category('operator', punctuation);

  // TODO: Should this be in core chromatophore?
  static const Category metasyntax = Category('metasyntax');

  static const Category text = Category('text');
  static const Category whitespace = Category('whitespace');
  static const Category unrecognized = Category('unrecognized', text);

  final String name;
  final Category? parent;

  const Category(this.name, [this.parent]);

  @override
  String toString() {
    if (parent == null) return name;
    return '$parent.$name';
  }
}
