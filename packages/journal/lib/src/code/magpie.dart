import 'package:chromatophore/chromatophore.dart';

const identifier = r'\b[a-zA-Z_][a-zA-Z0-9_]*\b';
const capsIdentifier = r'\b[A-Z][a-zA-Z0-9_]*\b';
const ss = ' +';

Language makeMagpie1Language() {
  var language = Language();

  _literalRules(language);

  // Function types.
  language.capture(r'(\bfn\b)( +)(\()', [
    Category.keyword,
    Category.whitespace,
    Category.punctuation
  ]).push('fn type');
  language.capture('(\\bfn\\b)( +)($identifier)( +)(\\()', [
    Category.keyword,
    Category.whitespace,
    Category.typeName,
    Category.whitespace,
    Category.punctuation
  ]).push('fn type');
  language.capture(r'(->)( +)(\()', [
    Category.operator,
    Category.whitespace,
    Category.punctuation
  ]).push('fn type');
  language.capture('(->)( +)($identifier)',
      [Category.operator, Category.whitespace, Category.typeName]);

  language.capture('(\\bstruct\\b)( +)($capsIdentifier)',
      [Category.keyword, Category.whitespace, Category.typeName]);

  language.keywords(
      Category.keyword,
      'and as def do else end extend false fn for if import interface is let '
      'or return struct then this true var while with');

  // Adjacent identifiers are typed declarations.
  language.capture('($identifier)($ss)($capsIdentifier)',
      [Category.identifier, Category.whitespace, Category.typeName]);

  language.regExp(identifier, Category.identifier);

  // Uses "'" for type arguments.
  language.capture(
      "(')($capsIdentifier)", [Category.punctuation, Category.typeName]);

  // One post uses "<foo>" as a metasyntax, so treat it specially.
  language.regExp('<$identifier>', Category.metasyntax);

  _punctuationRules(language);

  language.ruleSet('fn type', () {
    language.regExp(identifier, Category.typeName);
    language.verbatim(',', Category.punctuation);
    language.verbatim('->', Category.punctuation);
    language.regExp(r'[\s\n\t]', Category.whitespace);
    language.regExp(r'\)', Category.punctuation).pop();
  });

  return language;
}

Language makeMagpieLanguage() {
  var language = Language();

  _literalRules(language);

  // TODO: Hack. The `?` is an allowed identifier character, but we will end up
  // recognizing a keyword followed by `?` as a keyword and not a single
  // identifier.
  language.regExp(r'\btrue\?', Category.identifier);

  language.keywords(
      Category.keyword,
      'and as async case catch class def defclass do else end extend false fn '
      'for if import interface in is it let loop match nothing null or return '
      'shared struct then this true try val var while with');

  // Hack: These are not real keywords in Magpie, but a couple of posts use
  // Magpie as pseudo-code.
  language.keywords(Category.keyword, 'loop null');

  // Unquote.
  language.regExp(r'`[a-z_][a-zA-Z0-9_]*\b\??', Category.preprocessor);

  language.regExp(r'[A-Z][a-zA-Z0-9_\$]*\??', Category.typeName);
  language.regExp(r'[a-z_\$][a-zA-Z0-9_\$]*\??', Category.identifier);

  _punctuationRules(language);

  return language;
}

void _literalRules(Language language) {
  language.regExp(r'//.*', Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.number);
  language.regExp(r'[0-9]+?', Category.number);

  // Strings.
  language.regExp(r'"', Category.string).push('string');
  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    // TODO: Multi-character escapes?
    language.regExp('.', Category.string);
  });
}

void _punctuationRules(Language language) {
  language.regExp(r'[{}()[\],:;.]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);
}
