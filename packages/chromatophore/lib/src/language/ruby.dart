import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeRubyLanguage() {
  var language = Language();

  // Zero or more decimal digits with underscores in the middle but not at
  // either end.
  const digits = '[0-9]+(_[0-9]+)*';

  // Digits in various bases.
  const hex = '[0-9a-fA-F]';
  const octal = '[0-7]';
  const binary = '[01]';

  language.regExp('$digits(\\.$digits)?[eE]-?$digits', Category.number);
  language.regExp('$digits\\.$digits', Category.number);
  language.regExp('0[xX]$hex+(_$hex+)*', Category.number);
  language.regExp('0[oO]?$octal+(_$octal+)*', Category.number);
  language.regExp('0[bB]$binary+(_$binary+)*', Category.number);
  language.regExp('0[dD]$digits', Category.number);
  language.regExp(digits, Category.number);

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

  // Capitalized type or constant name.
  language.regExp(capsIdentifier, Category.typeName);

  language.regExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b\??', Category.identifier);

  language.regExp(r'[{}()[\].,;:]', Category.punctuation);
  language.regExp(r'[!*/&%~+=<>|-]', Category.operator);

  language.regExp(r'#.*', Category.lineComment);

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // TODO: Multi-line strings.
  doubleQuotedString(language);
  singleQuotedString(language);

  return language;
}
