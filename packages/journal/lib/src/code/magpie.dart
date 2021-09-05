import 'package:chromatophore/chromatophore.dart';

const identifier = r'\b[a-zA-Z_][a-zA-Z0-9_]*\b';
const capsIdentifier = r'\b[A-Z_][a-zA-Z0-9_]*\b';
const ss = ' +';

Language makeMagpie1Language() {
  var language = Language();

  language.regExp(r'//.*', Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.decimalNumber);
  language.regExp(r'[0-9]+?', Category.integer);

  // Function types.
  language.capture(r'(\bfn\b)( +)(\()',
      [Category.keyword, Category.whitespace, Category.punctuation]).push('fn type');
  language.capture('(\\bfn\\b)( +)($identifier)( +)(\\()',
      [Category.keyword, Category.whitespace, Category.typeName, Category.whitespace, Category.punctuation]).push('fn type');
  language.capture(r'(->)( +)(\()',
      [Category.operator, Category.whitespace, Category.punctuation]).push('fn type');
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
  language.capture("(')($capsIdentifier)",
      [Category.punctuation, Category.typeName]);

  // One post uses "<foo>" as a metasyntax, so treat it specially.
  language.regExp('<$identifier>', Category.metasyntax);

  language.regExp(r'[{}()[\],:;.]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // Strings.
  language.regExp(r'"', Category.string).push('string');
  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    // TODO: Multi-character escapes?
    language.regExp('.', Category.string);
  });

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

  language.regExp(r'//.*', Category.lineComment);

  language.regExp(r'[0-9]+\.[0-9]*', Category.decimalNumber);
  language.regExp(r'[0-9]+?', Category.integer);

  language.keywords(
      Category.keyword,
      'and as class def do else end extend false fn for if import interface is '
      'it let loop or return struct then this true var while with');
  // Hack: "loop" is not a real keyword in Magpie, but one post uses Magpie as
  // pseudo-code.

  language.regExp(r'\b[A-Z][a-zA-Z0-9_]*\b\??', Category.typeName);
  language.regExp(r'\b[a-z_][a-zA-Z0-9_]*\b\??', Category.identifier);

  language.regExp(r'[{}()[\],:;.]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // Strings.
  language.regExp(r'"', Category.string).push('string');
  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    // TODO: Multi-character escapes?
    language.regExp('.', Category.string);
  });

  return language;
}
