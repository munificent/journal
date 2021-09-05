import '../category.dart';
import '../language.dart';
import 'patterns.dart';

Language makeRubyLanguage() {
  var language = Language();

  // Zero or more decimal digits with underscores in the middle but not at
  // either end.
  const digits = '[0-9]+(_[0-9]+)*';

  // Digits in various bases.
  const hex = '[0-9a-fA-F]';
  const octal = '[0-7]';
  const binary = '[01]';

  language.regExp('$digits(\\.$digits)?[eE]-?$digits', Category.decimalNumber);
  language.regExp('$digits\\.$digits', Category.decimalNumber);
  language.regExp('0[xX]$hex+(_$hex+)*', Category.hexInteger);
  // TODO: Hack. Uses hexInteger for all explicit-base numbers.
  language.regExp('0[oO]?$octal+(_$octal+)*', Category.hexInteger);
  language.regExp('0[bB]$binary+(_$binary+)*', Category.hexInteger);
  language.regExp('0[dD]$digits', Category.integer);
  language.regExp(digits, Category.integer);

  language.keywords(
      Category.preprocessor, '__ENCODING__ __FILE__ __LINE__ BEGIN END');
  language.keywords(
      Category.keyword,
      'alias and begin break case class syntax def defined? do else elsif end '
      'ensure for if in module next not or redo rescue retry return self super '
      'then undef unless until when while yield');
  // TODO: Better category for this.
  language.keywords(Category.typeName, 'false nil true');

  language.regExp(r'@[a-zA-Z_][a-zA-Z0-9_]*\b', Category.field);

  language.regExp(allCaps, Category.constant);

  // Capitalized type or constant name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b\??', Category.identifier);

  language.regExp(r'[{}()[\].,;:!*/&%~+=<>|-]', Category.punctuation);

  language.regExp(r'#.*', Category.lineComment);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // TODO: Multi-line strings.
  language.regExp('"', Category.string).push('double string');
  language.regExp("'", Category.string).push('single string');

  language.ruleSet('double string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  language.ruleSet('single string', () {
    language.regExp("'", Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  return language;
}
